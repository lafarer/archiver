package com.github.lafarer.archiver.web;

import com.github.lafarer.archiver.config.ArchiverProperties;
import com.github.lafarer.archiver.model.Document;
import com.github.lafarer.archiver.repository.CustomFieldDefRepository;
import com.github.lafarer.archiver.repository.DocumentRepository;
import com.github.lafarer.archiver.repository.DocumentSpecs;
import com.github.lafarer.archiver.repository.DocumentTypeDefRepository;
import com.github.lafarer.archiver.service.ArchiveService;
import com.github.lafarer.archiver.service.DocumentPipelineService;
import org.springframework.data.jpa.domain.Specification;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;
import jakarta.servlet.http.HttpServletRequest;

import java.io.IOException;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("/archive")
@RequiredArgsConstructor
public class ArchiveController {

    private final DocumentRepository documentRepository;
    private final CustomFieldDefRepository customFieldDefRepository;
    private final DocumentTypeDefRepository documentTypeDefRepository;
    private final DocumentPipelineService pipelineService;
    private final ArchiveService archiveService;
    private final ArchiverProperties props;

    private static final int PAGE_SIZE = 25;

    @GetMapping
    public String index(@RequestParam(required = false) String q,
                        @RequestParam(required = false) String type,
                        @RequestParam(required = false) String issuer,
                        @RequestParam(name = "tag", required = false) List<String> selectedTags,
                        @RequestParam(defaultValue = "0") int page,
                        @RequestParam Map<String, String> allParams,
                        HttpServletRequest request,
                        Model model) {
        PageRequest pageable = PageRequest.of(page, PAGE_SIZE,
            Sort.by(Sort.Direction.DESC, "documentDate", "createdAt"));

        // Collect active custom field filters from cf_* params
        Map<String, String> selectedCustomFields = new HashMap<>();
        allParams.forEach((key, value) -> {
            if (key.startsWith("cf_") && !value.isBlank())
                selectedCustomFields.put(key.substring(3), value);
        });

        Specification<Document> spec = DocumentSpecs.classified();
        if (q != null && !q.isBlank())           spec = spec.and(DocumentSpecs.queryMatches(q));
        if (type != null && !type.isBlank())     spec = spec.and(DocumentSpecs.hasType(type));
        if (issuer != null && !issuer.isBlank()) spec = spec.and(DocumentSpecs.issuerContains(issuer));
        if (selectedTags != null && !selectedTags.isEmpty()) spec = spec.and(DocumentSpecs.hasAnyTag(selectedTags));
        for (var entry : selectedCustomFields.entrySet())
            spec = spec.and(DocumentSpecs.hasCustomField(entry.getKey(), entry.getValue()));

        Page<Document> documents = documentRepository.findAll(spec, pageable);

        // Build per-field distinct value suggestions
        var customFieldDefs = customFieldDefRepository.findAll();
        Map<String, List<String>> cfSuggestions = new LinkedHashMap<>();
        for (var def : customFieldDefs)
            cfSuggestions.put(def.getSlug(), documentRepository.findDistinctCustomFieldValues("$." + def.getSlug()));

        model.addAttribute("documents", documents);
        model.addAttribute("q",                   q != null ? q : "");
        model.addAttribute("selectedType",         type != null ? type : "");
        model.addAttribute("selectedIssuer",       issuer != null ? issuer : "");
        model.addAttribute("selectedTags",         selectedTags != null ? selectedTags : List.of());
        model.addAttribute("selectedCustomFields", selectedCustomFields);
        model.addAttribute("allTypes",   documentRepository.findDistinctDocumentTypes());
        model.addAttribute("allIssuers", documentRepository.findDistinctIssuers());
        model.addAttribute("allTags",    documentRepository.findDistinctTagValues());
        model.addAttribute("customFieldDefs",  customFieldDefs);
        model.addAttribute("cfSuggestions",    cfSuggestions);
        model.addAttribute("page", "archive");

        boolean htmx = "true".equals(request.getHeader("HX-Request"));
        return htmx ? "archive/list_fragment" : "archive/index";
    }

    @GetMapping("/{id}")
    public String detail(@PathVariable Long id, Model model) {
        Document doc = documentRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Document not found: " + id));
        var defs = customFieldDefRepository.findAll();
        model.addAttribute("document", doc);
        model.addAttribute("customFieldDefs", defs);
        model.addAttribute("fieldSuggestions", buildFieldSuggestions(defs));
        model.addAttribute("documentTypeDefs", documentTypeDefRepository.findByEnabledTrueOrderByLabelAsc());
        model.addAttribute("proposedPath", pipelineService.proposedPath(doc));
        model.addAttribute("page", "archive");
        return "archive/detail";
    }

    private Map<String, List<String>> buildFieldSuggestions(List<com.github.lafarer.archiver.model.CustomFieldDef> defs) {
        Map<String, List<String>> result = new LinkedHashMap<>();
        for (var def : defs) {
            result.put(def.getSlug(), documentRepository.findDistinctCustomFieldValues("$." + def.getSlug()));
        }
        return result;
    }

    @PostMapping("/{id}/delete")
    public String delete(@PathVariable Long id, RedirectAttributes redirectAttributes) throws IOException {
        Document doc = documentRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Document not found: " + id));
        if (doc.getResolvedPath() != null) {
            archiveService.delete(props.getArchivePath().resolve(doc.getResolvedPath()));
        }
        documentRepository.deleteById(id);
        redirectAttributes.addFlashAttribute("message", "Document supprimé.");
        return "redirect:/archive";
    }

    @PostMapping("/{id}/reclassify")
    public String reclassify(@PathVariable Long id, RedirectAttributes redirectAttributes) throws IOException {
        pipelineService.reclassify(id);
        redirectAttributes.addFlashAttribute("message", "Document reclassifié et déplacé.");
        return "redirect:/archive/" + id;
    }

    @PostMapping("/{id}/reanalyze")
    public String reanalyze(@PathVariable Long id,
                            @RequestParam(required = false) String hint,
                            RedirectAttributes redirectAttributes) throws IOException {
        pipelineService.reanalyzeArchived(id, hint);
        redirectAttributes.addFlashAttribute("message", "Document ré-analysé par l'IA.");
        return "redirect:/archive/" + id;
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
        documentRepository.save(doc);
        redirectAttributes.addFlashAttribute("message", "Document mis à jour.");
        return "redirect:/archive/" + id;
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
            if (tags        != null) doc.setTags(java.util.List.of(tags.split(",\\s*")));
        }
    }
}
