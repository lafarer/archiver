package com.github.lafarer.archiver.repository;

import com.github.lafarer.archiver.model.DocumentTypeDef;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface DocumentTypeDefRepository extends JpaRepository<DocumentTypeDef, Long> {
    Optional<DocumentTypeDef> findBySlug(String slug);
    boolean existsBySlug(String slug);
    List<DocumentTypeDef> findAllByOrderByLabelAsc();
    List<DocumentTypeDef> findByEnabledTrueOrderByLabelAsc();
}
