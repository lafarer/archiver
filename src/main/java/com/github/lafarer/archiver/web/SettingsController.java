package com.github.lafarer.archiver.web;

import com.github.lafarer.archiver.config.ArchiverProperties;
import com.github.lafarer.archiver.service.SettingService;
import com.github.lafarer.archiver.service.WatchdogService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.mvc.support.RedirectAttributes;

import java.util.Map;

@Controller
@RequestMapping("/settings")
@RequiredArgsConstructor
public class SettingsController {

    private final SettingService settingService;
    private final WatchdogService watchdogService;
    private final ArchiverProperties props;

    @GetMapping
    public String index(Model model) {
        model.addAttribute("settings",   settingService);
        model.addAttribute("props",      props);
        model.addAttribute("watchdogRunning", watchdogService.isRunning());
        model.addAttribute("page",       "settings");
        return "settings/index";
    }

    @PostMapping
    public String save(@RequestParam Map<String, String> params, RedirectAttributes ra) {
        boolean watchdogBefore = settingService.getBoolean("watchdog_enabled");

        settingService.setAll(Map.of(
            "watchdog_enabled",       params.getOrDefault("watchdog_enabled", "false"),
            "watchdog_debounce_ms",   params.getOrDefault("watchdog_debounce_ms", "1500"),
            "auto_archive_enabled",   params.getOrDefault("auto_archive_enabled", "false"),
            "ai_model",               params.getOrDefault("ai_model", "claude-haiku-4-5"),
            "confidence_threshold",   params.getOrDefault("confidence_threshold", "0.75"),
            "import_mode",            params.getOrDefault("import_mode", "copy")
        ));

        boolean watchdogAfter = settingService.getBoolean("watchdog_enabled");
        if (!watchdogBefore && watchdogAfter) watchdogService.start();
        else if (watchdogBefore && !watchdogAfter) watchdogService.stop();

        ra.addFlashAttribute("message", "Réglages enregistrés.");
        return "redirect:/settings";
    }
}
