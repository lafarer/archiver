package com.github.lafarer.archiver.web;

import com.github.lafarer.archiver.model.Document;
import com.github.lafarer.archiver.repository.CustomFieldDefRepository;
import com.github.lafarer.archiver.repository.DocumentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;
import java.util.Map;

@Controller
@RequestMapping("/archive")
@RequiredArgsConstructor
public class ArchiveController {

    private final DocumentRepository documentRepository;
    private final CustomFieldDefRepository customFieldDefRepository;

    private static final int PAGE_SIZE = 25;

    @GetMapping
    public String index(@RequestParam(required = false) String type,
                        @RequestParam(required = false) String tag,
                        @RequestParam(required = false) String q,
                        @RequestParam(defaultValue = "0") int page,
                        Model model) {
        PageRequest pageable = PageRequest.of(page, PAGE_SIZE,
            Sort.by(Sort.Direction.DESC, "documentDate", "createdAt"));
        Page<Document> documents = documentRepository.findByClassifiedTrue(pageable);
        model.addAttribute("documents", documents);
        model.addAttribute("page", "archive");
        return "archive/index";
    }

    @GetMapping("/{id}")
    public String detail(@PathVariable Long id, Model model) {
        Document doc = documentRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Document not found: " + id));
        model.addAttribute("document", doc);
        model.addAttribute("customFieldDefs", customFieldDefRepository.findAll());
        model.addAttribute("page", "archive");
        return "archive/detail";
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
