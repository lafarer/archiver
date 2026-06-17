package com.github.lafarer.archiver.web;

import com.github.lafarer.archiver.model.Document;
import com.github.lafarer.archiver.model.StoragePathRule;
import com.github.lafarer.archiver.repository.DocumentRepository;
import com.github.lafarer.archiver.repository.StoragePathRuleRepository;
import com.github.lafarer.archiver.service.DocumentPipelineService;
import com.github.lafarer.archiver.service.PathResolverService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Controller
@RequestMapping("/rules")
@RequiredArgsConstructor
public class RulesController {

    private final StoragePathRuleRepository ruleRepository;
    private final DocumentRepository documentRepository;
    private final PathResolverService pathResolverService;
    private final DocumentPipelineService pipelineService;

    public record SimulateResult(Document document, String newPath, boolean changed) {}

    private static final int PAGE_SIZE = 20;

    private static String stripExtension(String path) {
        if (path == null) return null;
        int dot = path.lastIndexOf('.');
        int slash = path.lastIndexOf('/');
        return (dot > slash) ? path.substring(0, dot) : path;
    }

    @GetMapping
    public String index(Model model) {
        List<StoragePathRule> rules = ruleRepository.findByActiveTrueOrderByPriorityAsc();
        Map<Long, Long> docCounts = documentRepository.countGroupedByAppliedRule().stream()
            .collect(Collectors.toMap(r -> (Long) r[0], r -> (Long) r[1]));
        model.addAttribute("rules", rules);
        model.addAttribute("docCounts", docCounts);
        model.addAttribute("page", "rules");
        return "rules/index";
    }

    @GetMapping("/new")
    public String newForm(Model model) {
        model.addAttribute("rule", new StoragePathRule());
        model.addAttribute("docPage", Page.empty());
        model.addAttribute("results", List.of());
        model.addAttribute("pathTemplate", "");
        model.addAttribute("page", "rules");
        return "rules/form";
    }

    @GetMapping("/{id}/edit")
    public String editForm(@PathVariable Long id, Model model) {
        StoragePathRule rule = ruleRepository.findById(id)
            .orElseThrow(() -> new IllegalArgumentException("Rule not found: " + id));
        Page<Document> docPage = documentRepository.findByAppliedRuleId(id, PageRequest.of(0, PAGE_SIZE));
        model.addAttribute("rule", rule);
        model.addAttribute("docPage", docPage);
        model.addAttribute("results", List.of());
        model.addAttribute("pathTemplate", "");
        model.addAttribute("outOfSyncCount", countOutOfSync(id, rule.getPathTemplate()));
        if (!model.containsAttribute("message")) model.addAttribute("message", null);
        model.addAttribute("page", "rules");
        return "rules/form";
    }

    @GetMapping("/{id}/documents")
    public String documents(@PathVariable Long id,
                            @RequestParam(defaultValue = "0") int page,
                            @RequestParam(defaultValue = "") String pathTemplate,
                            Model model) {
        Page<Document> docPage = documentRepository.findByAppliedRuleId(id, PageRequest.of(page, PAGE_SIZE));
        List<SimulateResult> results = List.of();
        if (!pathTemplate.isBlank()) {
            results = docPage.getContent().stream()
                .map(doc -> {
                    String newPath = pathResolverService.simulatePath(pathTemplate, doc);
                    boolean changed = !newPath.equals(stripExtension(doc.getResolvedPath()));
                    return new SimulateResult(doc, newPath, changed);
                })
                .collect(Collectors.toList());
        }
        model.addAttribute("ruleId", id);
        model.addAttribute("docPage", docPage);
        model.addAttribute("results", results);
        model.addAttribute("pathTemplate", pathTemplate);
        return "rules/docs_fragment";
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
        return "redirect:/rules/" + id + "/edit";
    }

    @PostMapping("/{id}/apply")
    public String apply(@PathVariable Long id, RedirectAttributes ra) throws IOException {
        int moved = pipelineService.applyRuleToAll(id);
        ra.addFlashAttribute("message",
            moved == 0 ? "Tous les documents sont déjà à jour."
            : moved == 1 ? "1 document déplacé."
            : moved + " documents déplacés.");
        return "redirect:/rules/" + id + "/edit";
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

    private long countOutOfSync(Long ruleId, String pathTemplate) {
        if (pathTemplate == null || pathTemplate.isBlank()) return 0;
        return documentRepository.findAllByAppliedRuleId(ruleId).stream()
            .filter(doc -> {
                String proposed = pathResolverService.simulatePath(pathTemplate, doc);
                return !proposed.equals(stripExtension(doc.getResolvedPath()));
            })
            .count();
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
