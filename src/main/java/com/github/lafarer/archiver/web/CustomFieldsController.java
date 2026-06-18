package com.github.lafarer.archiver.web;

import com.github.lafarer.archiver.model.CustomFieldDef;
import com.github.lafarer.archiver.repository.CustomFieldDefRepository;
import com.github.lafarer.archiver.service.GlobalSidecarService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/fields")
@RequiredArgsConstructor
public class CustomFieldsController {

    private final CustomFieldDefRepository repository;
    private final GlobalSidecarService globalSidecarService;

    @GetMapping
    public String index(Model model) {
        model.addAttribute("fields", repository.findAll());
        model.addAttribute("page", "fields");
        return "fields/index";
    }

    @GetMapping("/new")
    public String newForm(Model model) {
        model.addAttribute("field", new CustomFieldDef());
        model.addAttribute("page", "fields");
        return "fields/form";
    }

    @GetMapping("/{id}/edit")
    public String editForm(@PathVariable Long id, Model model) {
        model.addAttribute("field", repository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Field not found: " + id)));
        model.addAttribute("page", "fields");
        return "fields/form";
    }

    @PostMapping
    public String create(@ModelAttribute CustomFieldDef field, RedirectAttributes ra) {
        if (repository.existsBySlug(field.getSlug())) {
            ra.addFlashAttribute("error", "Un champ avec ce slug existe déjà.");
            return "redirect:/fields/new";
        }
        repository.save(field);
        globalSidecarService.refresh();
        ra.addFlashAttribute("message", "Champ créé.");
        return "redirect:/fields";
    }

    @PostMapping("/{id}")
    public String update(@PathVariable Long id, @ModelAttribute CustomFieldDef form, RedirectAttributes ra) {
        CustomFieldDef field = repository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Field not found: " + id));
        field.setLabel(form.getLabel());
        field.setDescription(form.getDescription());
        field.setFieldType(form.getFieldType());
        repository.save(field);
        globalSidecarService.refresh();
        ra.addFlashAttribute("message", "Champ mis à jour.");
        return "redirect:/fields";
    }

    @PostMapping("/{id}/delete")
    public String delete(@PathVariable Long id, RedirectAttributes ra) {
        repository.deleteById(id);
        globalSidecarService.refresh();
        ra.addFlashAttribute("message", "Champ supprimé.");
        return "redirect:/fields";
    }
}
