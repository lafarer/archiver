package com.github.lafarer.archiver.web;

import com.github.lafarer.archiver.model.TagDef;
import com.github.lafarer.archiver.repository.TagDefRepository;
import com.github.lafarer.archiver.service.GlobalSidecarService;
import com.github.lafarer.archiver.service.TagService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

@Controller
@RequestMapping("/tags")
@RequiredArgsConstructor
public class TagsController {

    private final TagService tagService;
    private final TagDefRepository repository;
    private final GlobalSidecarService globalSidecarService;

    @GetMapping
    public String index(Model model) {
        model.addAttribute("tags", tagService.findAll());
        model.addAttribute("page", "tags");
        return "tags/index";
    }

    @GetMapping("/new")
    public String newForm(Model model) {
        model.addAttribute("tag", new TagDef());
        model.addAttribute("page", "tags");
        return "tags/form";
    }

    @GetMapping("/{id}/edit")
    public String editForm(@PathVariable Long id, Model model) {
        TagDef tag = repository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Tag not found: " + id));
        model.addAttribute("tag", tag);
        model.addAttribute("page", "tags");
        return "tags/form";
    }

    @PostMapping
    public String create(@ModelAttribute TagForm form, RedirectAttributes ra) {
        if (repository.existsBySlug(form.slug())) {
            ra.addFlashAttribute("error", "Un tag avec ce slug existe déjà.");
            return "redirect:/tags/new";
        }
        repository.save(new TagDef(form.slug(), form.label(), form.description()));
        globalSidecarService.refresh();
        ra.addFlashAttribute("message", "Tag créé.");
        return "redirect:/tags";
    }

    @PostMapping("/{id}")
    public String update(@PathVariable Long id, @ModelAttribute TagForm form, RedirectAttributes ra) {
        TagDef tag = repository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Tag not found: " + id));
        tag.setLabel(form.label());
        tag.setDescription(form.description());
        repository.save(tag);
        globalSidecarService.refresh();
        ra.addFlashAttribute("message", "Tag mis à jour.");
        return "redirect:/tags";
    }

    @PostMapping("/{id}/toggle")
    public String toggle(@PathVariable Long id) {
        TagDef tag = repository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Tag not found: " + id));
        tag.setEnabled(!tag.isEnabled());
        repository.save(tag);
        globalSidecarService.refresh();
        return "redirect:/tags";
    }

    @PostMapping("/{id}/delete")
    public String delete(@PathVariable Long id, RedirectAttributes ra) {
        repository.deleteById(id);
        globalSidecarService.refresh();
        ra.addFlashAttribute("message", "Tag supprimé.");
        return "redirect:/tags";
    }

    public record TagForm(String slug, String label, String description) {}
}
