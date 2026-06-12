package com.github.lafarer.archiver.repository;

import com.github.lafarer.archiver.model.TagDef;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TagDefRepository extends JpaRepository<TagDef, Long> {
    Optional<TagDef> findBySlug(String slug);
    boolean existsBySlug(String slug);
    List<TagDef> findAllByOrderByLabelAsc();
    List<TagDef> findByEnabledTrueOrderByLabelAsc();
}
