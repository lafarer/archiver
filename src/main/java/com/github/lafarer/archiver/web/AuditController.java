package com.github.lafarer.archiver.web;

import com.github.lafarer.archiver.config.ArchiverProperties;
import com.github.lafarer.archiver.model.Document;
import com.github.lafarer.archiver.repository.DocumentRepository;
import com.github.lafarer.archiver.service.ArchiveService;
import com.github.lafarer.archiver.service.SidecarService;
import com.github.lafarer.archiver.service.StorageAuditService;
import com.github.lafarer.archiver.service.StorageAuditService.AnomalyType;
import com.github.lafarer.archiver.service.StorageAuditService.AuditReport;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

@Controller
@RequestMapping("/audit")
@RequiredArgsConstructor
@Slf4j
public class AuditController {

    private final StorageAuditService auditService;
    private final DocumentRepository documentRepository;
    private final ArchiveService archiveService;
    private final SidecarService sidecarService;
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
}
