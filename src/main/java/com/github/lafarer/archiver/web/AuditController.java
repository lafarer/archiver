package com.github.lafarer.archiver.web;

import com.github.lafarer.archiver.config.ArchiverProperties;
import com.github.lafarer.archiver.model.Document;
import com.github.lafarer.archiver.repository.DocumentRepository;
import com.github.lafarer.archiver.service.ArchiveService;
import com.github.lafarer.archiver.service.DocumentPipelineService;
import com.github.lafarer.archiver.service.SidecarService;
import com.github.lafarer.archiver.service.StorageAuditService;
import com.github.lafarer.archiver.service.StorageAuditService.AnomalyType;
import com.github.lafarer.archiver.service.StorageAuditService.AuditEntry;
import com.github.lafarer.archiver.service.StorageAuditService.AuditReport;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.security.DigestInputStream;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.List;

@Controller
@RequestMapping("/audit")
@RequiredArgsConstructor
@Slf4j
public class AuditController {

    private final StorageAuditService auditService;
    private final DocumentRepository documentRepository;
    private final ArchiveService archiveService;
    private final SidecarService sidecarService;
    private final DocumentPipelineService pipelineService;
    private final ArchiverProperties props;

    @GetMapping
    public String index(@RequestParam(defaultValue = "false") boolean run,
                        Model model) throws IOException {
        AuditReport report = null;
        if (run) {
            report = auditService.scan();
        }
        model.addAttribute("report", report);
        if (!model.containsAttribute("message")) model.addAttribute("message", null);
        model.addAttribute("page", "audit");
        return "audit/index";
    }

    // --- Individual repair actions ---

    @PostMapping("/repair/delete-record/{id}")
    public String deleteRecord(@PathVariable Long id,
                               RedirectAttributes ra) throws IOException {
        Document doc = documentRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Document not found: " + id));
        if (doc.getResolvedPath() != null) {
            archiveService.delete(props.getArchivePath().resolve(doc.getResolvedPath()));
        }
        documentRepository.deleteById(id);
        ra.addFlashAttribute("message", "Enregistrement supprimé.");
        return "redirect:/audit?run=true";
    }

    @PostMapping("/repair/delete-sidecar")
    public String deleteSidecar(@RequestParam String relPath,
                                RedirectAttributes ra) throws IOException {
        Path sidecar = sidecarService.sidecarPathFor(props.getArchivePath().resolve(relPath));
        Files.deleteIfExists(sidecar);
        ra.addFlashAttribute("message", "Sidecar supprimé.");
        return "redirect:/audit?run=true";
    }

    @PostMapping("/repair/regenerate-sidecar/{id}")
    public String regenerateSidecar(@PathVariable Long id,
                                    RedirectAttributes ra) {
        Document doc = documentRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Document not found: " + id));
        Path filePath = props.getArchivePath().resolve(doc.getResolvedPath());
        sidecarService.write(filePath, doc);
        ra.addFlashAttribute("message", "Sidecar régénéré.");
        return "redirect:/audit?run=true";
    }

    // --- Bulk repair actions ---

    @PostMapping("/repair/delete-all-ghosts")
    public String deleteAllGhosts(RedirectAttributes ra) throws IOException {
        AuditReport report = auditService.scan();
        var entries = report.byType().getOrDefault(AnomalyType.GHOST_RECORD, java.util.List.of());
        int count = 0;
        for (var entry : entries) {
            documentRepository.deleteById(entry.dbRecord().getId());
            count++;
        }
        ra.addFlashAttribute("message", count + " enregistrement(s) fantôme(s) supprimé(s).");
        return "redirect:/audit?run=true";
    }

    @PostMapping("/repair/delete-all-missing")
    public String deleteAllMissing(RedirectAttributes ra) throws IOException {
        AuditReport report = auditService.scan();
        var entries = report.byType().getOrDefault(AnomalyType.MISSING_FILE, java.util.List.of());
        int count = 0;
        for (var entry : entries) {
            if (entry.dbRecord().getResolvedPath() != null) {
                archiveService.delete(props.getArchivePath().resolve(entry.dbRecord().getResolvedPath()));
            }
            documentRepository.deleteById(entry.dbRecord().getId());
            count++;
        }
        ra.addFlashAttribute("message", count + " enregistrement(s) supprimé(s) (fichier manquant).");
        return "redirect:/audit?run=true";
    }

    @PostMapping("/repair/delete-all-orphan-sidecars")
    public String deleteAllOrphanSidecars(RedirectAttributes ra) throws IOException {
        AuditReport report = auditService.scan();
        var entries = report.byType().getOrDefault(AnomalyType.ORPHAN_SIDECAR, java.util.List.of());
        int count = 0;
        for (var entry : entries) {
            Path sidecar = sidecarService.sidecarPathFor(props.getArchivePath().resolve(entry.relPath()));
            if (Files.deleteIfExists(sidecar)) count++;
        }
        ra.addFlashAttribute("message", count + " sidecar(s) orphelin(s) supprimé(s).");
        return "redirect:/audit?run=true";
    }

    @PostMapping("/repair/regenerate-all-sidecars")
    public String regenerateAllSidecars(RedirectAttributes ra) throws IOException {
        AuditReport report = auditService.scan();
        var entries = report.byType().getOrDefault(AnomalyType.FILE_WITHOUT_SIDECAR, java.util.List.of());
        int count = 0;
        for (var entry : entries) {
            Path filePath = props.getArchivePath().resolve(entry.relPath());
            sidecarService.write(filePath, entry.dbRecord());
            count++;
        }
        ra.addFlashAttribute("message", count + " sidecar(s) régénéré(s).");
        return "redirect:/audit?run=true";
    }

    // --- Re-analyze untracked archive files (step 5a) ---

    @PostMapping("/repair/reanalyze-archive-file")
    public String reanalyzeArchiveFile(@RequestParam String relPath,
                                       RedirectAttributes ra) throws IOException {
        Path archiveFile = props.getArchivePath().resolve(relPath);
        if (!Files.exists(archiveFile)) {
            ra.addFlashAttribute("message", "Fichier introuvable : " + relPath);
            return "redirect:/audit?run=true";
        }
        Files.createDirectories(props.getInboxPath());
        Path inboxFile = resolveInboxConflict(props.getInboxPath().resolve(archiveFile.getFileName()));
        Files.move(archiveFile, inboxFile, StandardCopyOption.ATOMIC_MOVE);
        Long stubId = pipelineService.createStubSync(inboxFile, ArchiveService.SourceType.INBOX);
        if (stubId != null) {
            pipelineService.analyzeFromStub(stubId, inboxFile, ArchiveService.SourceType.INBOX);
        }
        ra.addFlashAttribute("message", "Ré-analyse lancée : " + archiveFile.getFileName());
        return "redirect:/audit?run=true";
    }

    @PostMapping("/repair/reanalyze-all-untracked")
    public String reanalyzeAllUntracked(RedirectAttributes ra) throws IOException {
        AuditReport report = auditService.scan();
        List<AuditEntry> entries = report.byType().getOrDefault(AnomalyType.UNTRACKED_NO_SIDECAR, List.of());
        Files.createDirectories(props.getInboxPath());
        int count = 0;
        for (AuditEntry entry : entries) {
            Path archiveFile = props.getArchivePath().resolve(entry.relPath());
            if (!Files.exists(archiveFile)) continue;
            Path inboxFile = resolveInboxConflict(props.getInboxPath().resolve(archiveFile.getFileName()));
            Files.move(archiveFile, inboxFile, StandardCopyOption.ATOMIC_MOVE);
            Long stubId = pipelineService.createStubSync(inboxFile, ArchiveService.SourceType.INBOX);
            if (stubId != null) {
                pipelineService.analyzeFromStub(stubId, inboxFile, ArchiveService.SourceType.INBOX);
                count++;
            }
        }
        ra.addFlashAttribute("message", count + " fichier(s) envoyé(s) en ré-analyse.");
        return "redirect:/audit?run=true";
    }

    // --- Analyze inbox orphans (step 5b) ---

    @PostMapping("/repair/analyze-inbox-orphan")
    public String analyzeInboxOrphan(@RequestParam String relPath,
                                     RedirectAttributes ra) throws IOException {
        Path inboxFile = props.getInboxPath().resolve(relPath);
        if (!Files.exists(inboxFile)) {
            ra.addFlashAttribute("message", "Fichier introuvable : " + relPath);
            return "redirect:/audit?run=true";
        }
        Long stubId = pipelineService.createStubSync(inboxFile, ArchiveService.SourceType.INBOX);
        if (stubId != null) {
            pipelineService.analyzeFromStub(stubId, inboxFile, ArchiveService.SourceType.INBOX);
        }
        ra.addFlashAttribute("message", "Analyse lancée : " + inboxFile.getFileName());
        return "redirect:/audit?run=true";
    }

    @PostMapping("/repair/analyze-all-inbox-orphans")
    public String analyzeAllInboxOrphans(RedirectAttributes ra) throws IOException {
        AuditReport report = auditService.scan();
        List<AuditEntry> entries = report.byType().getOrDefault(AnomalyType.INBOX_ORPHAN, List.of());
        int count = 0;
        for (AuditEntry entry : entries) {
            Path inboxFile = props.getInboxPath().resolve(entry.relPath());
            if (!Files.exists(inboxFile)) continue;
            Long stubId = pipelineService.createStubSync(inboxFile, ArchiveService.SourceType.INBOX);
            if (stubId != null) {
                pipelineService.analyzeFromStub(stubId, inboxFile, ArchiveService.SourceType.INBOX);
                count++;
            }
        }
        ra.addFlashAttribute("message", count + " fichier(s) envoyé(s) en analyse.");
        return "redirect:/audit?run=true";
    }

    // --- Import from sidecar (step 4) ---

    @PostMapping("/repair/import-sidecar")
    public String importSidecar(@RequestParam String relPath,
                                RedirectAttributes ra) throws IOException {
        int imported = importEntry(relPath);
        ra.addFlashAttribute("message", imported == 1 ? "Document importé." : "Document déjà présent (doublon ignoré).");
        return "redirect:/audit?run=true";
    }

    @PostMapping("/repair/import-all-sidecars")
    public String importAllSidecars(RedirectAttributes ra) throws IOException {
        AuditReport report = auditService.scan();
        List<AuditEntry> entries = report.byType().getOrDefault(AnomalyType.UNTRACKED_WITH_SIDECAR, List.of());
        int imported = 0;
        for (AuditEntry entry : entries) {
            imported += importEntry(entry.relPath());
        }
        ra.addFlashAttribute("message", imported + " document(s) importé(s).");
        return "redirect:/audit?run=true";
    }

    private int importEntry(String relPath) throws IOException {
        Path docFile = props.getArchivePath().resolve(relPath);
        Path sidecarFile = sidecarService.sidecarPathFor(docFile);
        if (!Files.exists(docFile) || !Files.exists(sidecarFile)) return 0;

        String hash = sha256(docFile);
        if (documentRepository.findBySha256Hash(hash).isPresent()) {
            log.info("Skipping duplicate during import: {}", relPath);
            return 0;
        }

        Document doc = sidecarService.importDocument(sidecarFile);
        doc.setOriginalFilename(docFile.getFileName().toString());
        doc.setResolvedPath(relPath);
        doc.setSidecarPath(props.getArchivePath().relativize(sidecarFile).toString());
        doc.setSha256Hash(hash);
        doc.setMimeType(probeType(docFile));
        doc.setFileSizeBytes(Files.size(docFile));
        doc.setFilesystemMtime(Files.getLastModifiedTime(docFile).toInstant());
        documentRepository.save(doc);
        log.info("Imported from sidecar: {}", relPath);
        return 1;
    }

    private Path resolveInboxConflict(Path target) {
        if (!Files.exists(target)) return target;
        String name = target.getFileName().toString();
        int dot = name.lastIndexOf('.');
        String base = dot > 0 ? name.substring(0, dot) : name;
        String ext  = dot > 0 ? name.substring(dot)    : "";
        int i = 1;
        Path candidate;
        do {
            candidate = target.getParent().resolve(base + "-" + i + ext);
            i++;
        } while (Files.exists(candidate));
        return candidate;
    }

    private String sha256(Path file) throws IOException {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            try (InputStream is = new DigestInputStream(Files.newInputStream(file), md)) {
                is.transferTo(OutputStream.nullOutputStream());
            }
            return HexFormat.of().formatHex(md.digest());
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        }
    }

    private String probeType(Path file) throws IOException {
        String type = Files.probeContentType(file);
        return type != null ? type : "application/octet-stream";
    }
}
