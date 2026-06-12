package com.github.lafarer.archiver.service;

import com.github.lafarer.archiver.model.Setting;
import com.github.lafarer.archiver.repository.SettingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class SettingService {

    private final SettingRepository repository;

    private static final Map<String, String> DEFAULTS = Map.of(
        "watchdog_enabled",     "false",
        "ai_model",             "claude-sonnet-4-6",
        "confidence_threshold", "0.75",
        "import_mode",          "copy"  // "copy" | "move"
    );

    @EventListener(ApplicationReadyEvent.class)
    @Transactional
    public void seedDefaults() {
        DEFAULTS.forEach((key, value) ->
            repository.findById(key).orElseGet(() -> repository.save(new Setting(key, value)))
        );
    }

    public String get(String key) {
        return repository.findById(key)
            .map(Setting::getValue)
            .orElse(DEFAULTS.getOrDefault(key, ""));
    }

    public boolean getBoolean(String key) {
        return "true".equalsIgnoreCase(get(key));
    }

    public double getDouble(String key) {
        try { return Double.parseDouble(get(key)); } catch (NumberFormatException e) { return 0; }
    }

    @Transactional
    public void set(String key, String value) {
        repository.save(new Setting(key, value));
    }

    @Transactional
    public void setAll(Map<String, String> values) {
        values.forEach(this::set);
    }
}
