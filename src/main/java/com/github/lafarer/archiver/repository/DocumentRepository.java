package com.github.lafarer.archiver.repository;

import com.github.lafarer.archiver.model.Document;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

public interface DocumentRepository extends JpaRepository<Document, Long> {

    Optional<Document> findBySha256Hash(String sha256Hash);

    List<Document> findByClassifiedFalseOrderByCreatedAtDesc();

    Page<Document> findByClassifiedTrue(Pageable pageable);

    @Query("SELECT d FROM Document d WHERE d.appliedRule.id = :ruleId AND d.classified = true")
    List<Document> findByAppliedRuleId(Long ruleId);
}
