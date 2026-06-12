package com.github.lafarer.archiver.service;

import com.github.lafarer.archiver.model.Setting;
import com.github.lafarer.archiver.repository.SettingRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

@Service
@RequiredArgsConstructor
public class SettingService {

    private final SettingRepository repository;

    public String get(String key) {
        return repository.findById(key)
            .map(Setting::getValue)
            .orElse("");
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
