package com.github.lafarer.archiver.web;

import com.github.lafarer.archiver.model.Document;
import com.github.lafarer.archiver.repository.DocumentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

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
}
