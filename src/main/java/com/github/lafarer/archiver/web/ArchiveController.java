package com.github.lafarer.archiver.web;

import com.github.lafarer.archiver.model.Document;
import com.github.lafarer.archiver.repository.DocumentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;

@Controller
@RequestMapping("/archive")
@RequiredArgsConstructor
public class ArchiveController {

    private final DocumentRepository documentRepository;

    @GetMapping
    public String index(@RequestParam(required = false) String type,
                        @RequestParam(required = false) String tag,
                        @RequestParam(required = false) String q,
                        Model model) {
        List<Document> documents = documentRepository.findByClassifiedTrueOrderByDocumentDateDescCreatedAtDesc();
        model.addAttribute("documents", documents);
        model.addAttribute("page", "archive");
        return "archive/index";
    }

    @GetMapping("/{id}")
    public String detail(@PathVariable Long id, Model model) {
        Document doc = documentRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Document not found: " + id));
        model.addAttribute("document", doc);
        model.addAttribute("page", "archive");
        return "archive/detail";
    }

    @PostMapping("/{id}")
    public String update(@PathVariable Long id,
                         @ModelAttribute DocumentForm form,
                         RedirectAttributes redirectAttributes) {
        Document doc = documentRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Document not found: " + id));
        form.applyTo(doc);
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
