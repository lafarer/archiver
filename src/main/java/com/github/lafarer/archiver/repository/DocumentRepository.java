package com.github.lafarer.archiver.repository;

import com.github.lafarer.archiver.model.Document;
import com.github.lafarer.archiver.model.enums.AnalysisStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface DocumentRepository extends JpaRepository<Document, Long>, JpaSpecificationExecutor<Document> {

    Optional<Document> findBySha256Hash(String sha256Hash);

    List<Document> findByClassifiedFalseOrderByCreatedAtDesc();

    void deleteByAnalysisStatus(AnalysisStatus status);

    Page<Document> findByClassifiedTrue(Pageable pageable);

    @Query("SELECT d FROM Document d WHERE d.appliedRule.id = :ruleId AND d.classified = true ORDER BY d.classifiedAt DESC")
    Page<Document> findByAppliedRuleId(@Param("ruleId") Long ruleId, Pageable pageable);

    @Query("SELECT d FROM Document d WHERE d.appliedRule.id = :ruleId AND d.classified = true")
    List<Document> findAllByAppliedRuleId(@Param("ruleId") Long ruleId);

    @Query("SELECT d.appliedRule.id, COUNT(d) FROM Document d WHERE d.appliedRule IS NOT NULL AND d.classified = true GROUP BY d.appliedRule.id")
    List<Object[]> countGroupedByAppliedRule();

    @Query("SELECT DISTINCT d.documentType FROM Document d WHERE d.classified = true AND d.documentType IS NOT NULL ORDER BY d.documentType")
    List<String> findDistinctDocumentTypes();

    @Query("SELECT DISTINCT d.issuer FROM Document d WHERE d.classified = true AND d.issuer IS NOT NULL ORDER BY d.issuer")
    List<String> findDistinctIssuers();

    @Query("SELECT DISTINCT d.issuer FROM Document d WHERE d.issuer IS NOT NULL ORDER BY d.issuer")
    List<String> findAllDistinctIssuers();

    @Query(value = "SELECT DISTINCT jt.value FROM document d, json_each(d.tags) jt WHERE d.is_classified = 1 ORDER BY jt.value", nativeQuery = true)
    List<String> findDistinctTagValues();

    @Query(value = """
            SELECT DISTINCT json_extract(custom_fields, :jsonPath)
            FROM document
            WHERE is_classified = 1
              AND json_extract(custom_fields, :jsonPath) IS NOT NULL
              AND json_extract(custom_fields, :jsonPath) != ''
            ORDER BY 1
            """, nativeQuery = true)
    List<String> findDistinctCustomFieldValues(@Param("jsonPath") String jsonPath);

    @Query(value = """
            SELECT DISTINCT json_extract(custom_fields, :jsonPath)
            FROM document
            WHERE json_extract(custom_fields, :jsonPath) IS NOT NULL
              AND json_extract(custom_fields, :jsonPath) != ''
            ORDER BY 1
            """, nativeQuery = true)
    List<String> findAllDistinctCustomFieldValues(@Param("jsonPath") String jsonPath);

    @Query("SELECT SUM(d.fileSizeBytes) FROM Document d WHERE d.classified = true")
    Long sumFileSizeBytesClassified();
}
