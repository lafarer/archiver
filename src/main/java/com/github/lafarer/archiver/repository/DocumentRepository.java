package com.github.lafarer.archiver.repository;

import com.github.lafarer.archiver.model.Document;
import com.github.lafarer.archiver.model.enums.AnalysisStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface DocumentRepository extends JpaRepository<Document, Long> {

    Optional<Document> findBySha256Hash(String sha256Hash);

    List<Document> findByClassifiedFalseOrderByCreatedAtDesc();

    void deleteByAnalysisStatus(AnalysisStatus status);

    Page<Document> findByClassifiedTrue(Pageable pageable);

    @Query("SELECT d FROM Document d WHERE d.appliedRule.id = :ruleId AND d.classified = true ORDER BY d.classifiedAt DESC")
    Page<Document> findByAppliedRuleId(@Param("ruleId") Long ruleId, Pageable pageable);

    @Query("SELECT d.appliedRule.id, COUNT(d) FROM Document d WHERE d.appliedRule IS NOT NULL AND d.classified = true GROUP BY d.appliedRule.id")
    List<Object[]> countGroupedByAppliedRule();

    @Query(value = """
            SELECT DISTINCT json_extract(custom_fields, :jsonPath)
            FROM document
            WHERE is_classified = 1
              AND json_extract(custom_fields, :jsonPath) IS NOT NULL
              AND json_extract(custom_fields, :jsonPath) != ''
            ORDER BY 1
            """, nativeQuery = true)
    List<String> findDistinctCustomFieldValues(@Param("jsonPath") String jsonPath);
}
