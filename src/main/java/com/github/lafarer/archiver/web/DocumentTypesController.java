package com.github.lafarer.archiver.web;

import com.github.lafarer.archiver.model.DocumentTypeDef;
import com.github.lafarer.archiver.repository.DocumentTypeDefRepository;
import com.github.lafarer.archiver.service.DocumentTypeService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/doctypes")
@RequiredArgsConstructor
public class DocumentTypesController {

    private final DocumentTypeService documentTypeService;
    private final DocumentTypeDefRepository repository;

    @GetMapping
    public String index(Model model) {
        model.addAttribute("types", documentTypeService.findAll());
        model.addAttribute("page", "doctypes");
        return "doctypes/index";
    }

    @GetMapping("/new")
    public String newForm(Model model) {
        model.addAttribute("type", new DocumentTypeDef());
        model.addAttribute("page", "doctypes");
        return "doctypes/form";
    }

    @GetMapping("/{id}/edit")
    public String editForm(@PathVariable Long id, Model model) {
        DocumentTypeDef type = repository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Type not found: " + id));
        model.addAttribute("type", type);
        model.addAttribute("page", "doctypes");
        return "doctypes/form";
    }

    @PostMapping
    public String create(@ModelAttribute DocumentTypeForm form, RedirectAttributes ra) {
        if (repository.existsBySlug(form.slug())) {
            ra.addFlashAttribute("error", "Un type avec ce slug existe déjà.");
            return "redirect:/doctypes/new";
        }
        repository.save(new DocumentTypeDef(form.slug(), form.label(), form.description()));
        ra.addFlashAttribute("message", "Type créé.");
        return "redirect:/doctypes";
    }

    @PostMapping("/{id}")
    public String update(@PathVariable Long id, @ModelAttribute DocumentTypeForm form, RedirectAttributes ra) {
        DocumentTypeDef type = repository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Type not found: " + id));
        type.setLabel(form.label());
        type.setDescription(form.description());
        repository.save(type);
        ra.addFlashAttribute("message", "Type mis à jour.");
        return "redirect:/doctypes";
    }

    @PostMapping("/{id}/toggle")
    public String toggle(@PathVariable Long id, RedirectAttributes ra) {
        DocumentTypeDef type = repository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Type not found: " + id));
        type.setEnabled(!type.isEnabled());
        repository.save(type);
        return "redirect:/doctypes";
    }

    @PostMapping("/{id}/delete")
    public String delete(@PathVariable Long id, RedirectAttributes ra) {
        repository.deleteById(id);
        ra.addFlashAttribute("message", "Type supprimé.");
        return "redirect:/doctypes";
    }

    public record DocumentTypeForm(String slug, String label, String description) {}
}
