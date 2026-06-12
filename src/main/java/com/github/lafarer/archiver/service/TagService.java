package com.github.lafarer.archiver.service;

import com.github.lafarer.archiver.model.TagDef;
import com.github.lafarer.archiver.repository.TagDefRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class TagService {

    private final TagDefRepository repository;

    public List<TagDef> findAll() {
        return repository.findAllByOrderByLabelAsc();
    }

    public List<TagDef> findEnabled() {
        return repository.findByEnabledTrueOrderByLabelAsc();
    }

    @Transactional
    public void autoRegister(String slug, String label, String description) {
        if (slug == null || repository.findBySlug(slug).isPresent()) return;
        TagDef def = new TagDef(
            slug,
            label != null && !label.isBlank() ? label : slug,
            description
        );
        repository.save(def);
        log.info("Auto-registered new tag from AI: {}", slug);
    }
}
