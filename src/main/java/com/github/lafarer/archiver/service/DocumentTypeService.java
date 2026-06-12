package com.github.lafarer.archiver.service;

import com.github.lafarer.archiver.model.DocumentTypeDef;
import com.github.lafarer.archiver.repository.DocumentTypeDefRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class DocumentTypeService {

    private final DocumentTypeDefRepository repository;

    public List<DocumentTypeDef> findAll() {
        return repository.findAllByOrderByLabelAsc();
    }

    public List<DocumentTypeDef> findEnabled() {
        return repository.findByEnabledTrueOrderByLabelAsc();
    }

    @Transactional
    public void autoRegister(String slug, String label, String description) {
        if (slug == null || repository.findBySlug(slug).isPresent()) return;
        DocumentTypeDef def = new DocumentTypeDef(
            slug,
            label != null && !label.isBlank() ? label : slug,
            description
        );
        repository.save(def);
        log.info("Auto-registered new document type from AI: {}", slug);
    }
}
