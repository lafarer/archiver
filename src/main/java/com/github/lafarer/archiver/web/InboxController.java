package com.github.lafarer.archiver.web;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.github.lafarer.archiver.config.ArchiverProperties;
import com.github.lafarer.archiver.model.Document;
import com.github.lafarer.archiver.repository.CustomFieldDefRepository;
import com.github.lafarer.archiver.repository.DocumentRepository;
import com.github.lafarer.archiver.repository.DocumentTypeDefRepository;
import com.github.lafarer.archiver.repository.TagDefRepository;
import com.github.lafarer.archiver.service.ArchiveService;
import com.github.lafarer.archiver.service.DocumentPipelineService;
import com.github.lafarer.archiver.service.InboxEventService;
import com.github.lafarer.archiver.service.WatchdogService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MaxUploadSizeExceededException;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("/inbox")
@RequiredArgsConstructor
public class InboxController {

    private final DocumentRepository documentRepository;
    private final DocumentPipelineService pipelineService;
    private final ArchiverProperties props;
    private final CustomFieldDefRepository customFieldDefRepository;
    private final DocumentTypeDefRepository documentTypeDefRepository;
    private final TagDefRepository tagDefRepository;
    private final InboxEventService inboxEventService;
    private final WatchdogService watchdogService;
    private final ObjectMapper objectMapper;

    @GetMapping
    public String index(Model model, @RequestParam(required = false) String uploadError) {
        List<Document> pending = documentRepository.findByClassifiedFalseOrderByCreatedAtDesc();
        model.addAttribute("documents", pending);
        model.addAttribute("archiveRoot", props.getRoot().toString());
        model.addAttribute("uploadError", uploadError);
        model.addAttribute("page", "inbox");
        return "inbox/index";
    }

    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public String handleMaxUploadSize() {
        return "redirect:/inbox?uploadError=size";
    }

    @GetMapping(value = "/events", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter events() {
        return inboxEventService.subscribe();
    }

    @GetMapping("/fragment")
    public String fragment(Model model) {
        model.addAttribute("documents", documentRepository.findByClassifiedFalseOrderByCreatedAtDesc());
        model.addAttribute("archiveRoot", props.getRoot().toString());
        return "inbox/fragment";
    }

    @PostMapping("/upload")
    public String upload(@RequestParam("files") List<MultipartFile> files,
                         RedirectAttributes redirectAttributes) throws IOException {
        int count = 0;
        for (MultipartFile file : files) {
            if (file.isEmpty()) continue;
            Path dest = resolveInboxPath(file.getOriginalFilename());
            file.transferTo(dest);
            // Create stub synchronously so it exists before the redirect renders the page,
            // then launch analysis in a separate async thread via the Spring proxy.
            Long stubId = pipelineService.createStubSync(dest, ArchiveService.SourceType.INBOX);
            if (stubId != null) {
                pipelineService.analyzeFromStub(stubId, dest, ArchiveService.SourceType.INBOX);
                count++;
            }
        }
        String msg = count == 1 ? "Document en cours d'analyse…" : count + " documents en cours d'analyse…";
        redirectAttributes.addFlashAttribute("message", msg);
        return "redirect:/inbox";
    }

    private Path resolveInboxPath(String originalFilename) {
        // Strip any directory components to prevent path traversal
        String filename = Path.of(originalFilename != null ? originalFilename : "upload").getFileName().toString();
        String base = filename;
        String ext = "";
        int dot = filename.lastIndexOf('.');
        if (dot > 0) {
            base = filename.substring(0, dot);
            ext  = filename.substring(dot);
        }
        Path candidate = props.getInboxPath().resolve(filename);
        int i = 1;
        while (Files.exists(candidate)) {
            candidate = props.getInboxPath().resolve(base + "-" + i + ext);
            i++;
        }
        return candidate;
    }

    @GetMapping("/{id}/edit")
    public String edit(@PathVariable Long id, Model model) {
        Document doc = documentRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Document not found: " + id));
        var defs = customFieldDefRepository.findAll();
        model.addAttribute("document", doc);
        model.addAttribute("customFieldDefs", defs);
        model.addAttribute("issuerSuggestions", documentRepository.findDistinctIssuers());
        model.addAttribute("fieldSuggestions", buildFieldSuggestions(defs));
        model.addAttribute("documentTypeDefs", documentTypeDefRepository.findByEnabledTrueOrderByLabelAsc());
        model.addAttribute("allTagDefs", tagDefRepository.findByEnabledTrueOrderByLabelAsc());
        model.addAttribute("proposedPath", pipelineService.proposedPath(doc));
        model.addAttribute("cfProvenance", buildCfProvenance(doc));
        model.addAttribute("page", "inbox");
        if (!model.containsAttribute("message")) model.addAttribute("message", null);
        return "inbox/edit";
    }

    private Map<String, List<String>> buildFieldSuggestions(List<com.github.lafarer.archiver.model.CustomFieldDef> defs) {
        Map<String, List<String>> result = new LinkedHashMap<>();
        for (var def : defs) {
            result.put(def.getSlug(), documentRepository.findDistinctCustomFieldValues("$." + def.getSlug()));
        }
        return result;
    }

    private Map<String, String> buildCfProvenance(Document doc) {
        Map<String, String> result = new LinkedHashMap<>();
        String json = doc.getCustomFieldsProvenance();
        if (json == null || json.isBlank() || "{}".equals(json)) return result;
        try {
            Map<String, Map<String, Object>> prov = objectMapper.readValue(json, new TypeReference<>() {});
            prov.forEach((slug, info) -> {
                String src = info.get("source") instanceof String s ? s : null;
                Double conf = info.get("confidence") instanceof Number n ? n.doubleValue() : null;
                String label = cfSourceLabel(src);
                String confStr = conf != null && conf > 0 ? String.format("%.0f%%", conf * 100) : null;
                if (label != null && confStr != null) result.put(slug, label + " · " + confStr);
                else if (label != null) result.put(slug, label);
                else if (confStr != null) result.put(slug, confStr);
            });
        } catch (Exception ignored) {}
        return result;
    }

    private static String cfSourceLabel(String source) {
        if (source == null) return "IA";
        return switch (source.toLowerCase()) {
            case "ai"           -> "IA";
            case "pdf_metadata" -> "PDF";
            case "filename"     -> "Nom du fichier";
            case "filesystem"   -> "Système";
            case "manual"       -> "Manuel";
            default             -> source;
        };
    }

    @PostMapping("/{id}")
    public String update(@PathVariable Long id,
                         @ModelAttribute DocumentForm form,
                         @RequestParam Map<String, String> allParams,
                         RedirectAttributes redirectAttributes) {
        Document doc = documentRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Document not found: " + id));
        form.applyTo(doc);
        allParams.forEach((key, value) -> {
            if (key.startsWith("cf_")) {
                String slug = key.substring(3);
                if (value != null && !value.isBlank()) {
                    doc.getCustomFields().put(slug, value.trim());
                } else {
                    doc.getCustomFields().remove(slug);
                }
            }
        });
        pipelineService.refreshResolvedPath(doc);
        redirectAttributes.addFlashAttribute("message", "Document mis à jour.");
        return "redirect:/inbox/" + id + "/edit";
    }

    @PostMapping("/{id}/reanalyze")
    public String reanalyze(@PathVariable Long id,
                            @RequestParam(required = false) String hint,
                            RedirectAttributes redirectAttributes) throws IOException {
        pipelineService.reanalyze(id, hint);
        redirectAttributes.addFlashAttribute("message", "Document ré-analysé.");
        return "redirect:/inbox/" + id + "/edit";
    }

    @PostMapping("/{id}/validate")
    public String validate(@PathVariable Long id,
                           RedirectAttributes redirectAttributes) throws IOException {
        Document doc = documentRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Document not found: " + id));
        Path sourcePath = doc.getSourcePath() != null
            ? props.getInboxPath().resolve(doc.getSourcePath())
            : props.getInboxPath().resolve(doc.getOriginalFilename());
        pipelineService.validateAndArchive(id, sourcePath);
        inboxEventService.notifyInboxChanged();
        redirectAttributes.addFlashAttribute("message", "Document archivé.");
        return "redirect:/inbox";
    }

    @PostMapping("/rescan")
    public String rescan() {
        watchdogService.rescanInbox();
        return "redirect:/inbox";
    }

    @DeleteMapping("/{id}")
    public String delete(@PathVariable Long id, RedirectAttributes redirectAttributes) {
        documentRepository.deleteById(id);
        inboxEventService.notifyInboxChanged();
        redirectAttributes.addFlashAttribute("message", "Document supprimé.");
        return "redirect:/inbox";
    }

    public record DocumentForm(
        String documentType, String title, String documentDate,
        String issuer, String description, String tags
    ) {
        public void applyTo(Document doc) {
            if (documentType != null) doc.setDocumentType(documentType);
            if (title       != null) doc.setTitle(title);
            if (documentDate != null) doc.setDocumentDate(documentDate);
            if (issuer      != null) doc.setIssuer(issuer);
            if (description != null) doc.setDescription(description);
            if (tags        != null) doc.setTags(java.util.Arrays.stream(tags.split(",\\s*")).filter(t -> !t.isBlank()).toList());
        }
    }
}
