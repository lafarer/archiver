package com.github.lafarer.archiver.web;

import com.github.lafarer.archiver.model.StoragePathRule;
import com.github.lafarer.archiver.repository.StoragePathRuleRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.List;

@Controller
@RequestMapping("/rules")
@RequiredArgsConstructor
public class RulesController {

    private final StoragePathRuleRepository ruleRepository;

    @GetMapping
    public String index(Model model) {
        List<StoragePathRule> rules = ruleRepository.findByActiveTrueOrderByPriorityAsc();
        model.addAttribute("rules", rules);
        model.addAttribute("page", "rules");
        return "rules/index";
    }

    @GetMapping("/new")
    public String newForm(Model model) {
        model.addAttribute("rule", new StoragePathRule());
        model.addAttribute("page", "rules");
        return "rules/form";
    }

    @GetMapping("/{id}/edit")
    public String editForm(@PathVariable Long id, Model model) {
        StoragePathRule rule = ruleRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Rule not found: " + id));
        model.addAttribute("rule", rule);
        model.addAttribute("page", "rules");
        return "rules/form";
    }

    @PostMapping
    public String create(@ModelAttribute StoragePathRule rule, RedirectAttributes ra) {
        ensureSingleDefault(rule);
        ruleRepository.save(rule);
        ra.addFlashAttribute("message", "Règle créée.");
        return "redirect:/rules";
    }

    @PostMapping("/{id}")
    public String update(@PathVariable Long id,
                         @ModelAttribute StoragePathRule form,
                         RedirectAttributes ra) {
        StoragePathRule rule = ruleRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Rule not found: " + id));
        rule.setLabel(form.getLabel());
        rule.setConditionNl(form.getConditionNl());
        rule.setPathTemplate(form.getPathTemplate());
        rule.setPriority(form.getPriority());
        if (form.isDefault()) ensureSingleDefault(form);
        rule.setDefault(form.isDefault());
        ruleRepository.save(rule);
        ra.addFlashAttribute("message", "Règle mise à jour.");
        return "redirect:/rules";
    }

    @PostMapping("/{id}/delete")
    public String delete(@PathVariable Long id, RedirectAttributes ra) {
        ruleRepository.deleteById(id);
        ra.addFlashAttribute("message", "Règle supprimée.");
        return "redirect:/rules";
    }

    @PostMapping("/reorder")
    @ResponseBody
    public void reorder(@RequestBody List<Long> orderedIds) {
        for (int i = 0; i < orderedIds.size(); i++) {
            final short priority = (short) (i + 1);
            ruleRepository.findById(orderedIds.get(i)).ifPresent(r -> {
                r.setPriority(priority);
                ruleRepository.save(r);
            });
        }
    }

    private void ensureSingleDefault(StoragePathRule incoming) {
        if (incoming.isDefault()) {
            ruleRepository.findByIsDefaultTrue().ifPresent(existing -> {
                existing.setDefault(false);
                ruleRepository.save(existing);
            });
        }
    }
}
