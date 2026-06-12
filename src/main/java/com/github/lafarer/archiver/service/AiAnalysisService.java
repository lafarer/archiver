package com.github.lafarer.archiver.service;

import com.github.lafarer.archiver.model.enums.DocumentFileType;

import java.nio.file.Path;
import java.util.List;

public interface AiAnalysisService {

    record CustomFieldHint(String slug, String label, String description) {}

    record DocumentTypeHint(String slug, String label, String description) {}

    record DocumentTypeResult(String slug, String label, String description) {}

    record TagHint(String slug, String label, String description) {}

    record TagResult(String slug, String label, String description) {}

    record RuleHint(Long id, String label, String conditionNl) {}

    record FieldValue(String value, String source, Double confidence) {}

    record AnalysisResult(
        String reasoning,
        DocumentTypeResult documentType,
        FieldValue title,
        FieldValue documentDate,
        String documentDatePrecision,
        FieldValue issuer,
        FieldValue description,
        List<TagResult> tags,
        java.util.Map<String, FieldValue> customFields,
        Long appliedRuleId
    ) {}

    AnalysisResult analyze(
        Path file,
        DocumentFileType fileType,
        String extractedText,
        java.util.Map<String, String> pdfMetadata,
        String filenameDateHint,
        List<CustomFieldHint> customFields,
        List<DocumentTypeHint> documentTypes,
        List<TagHint> tags,
        List<RuleHint> rules
    );
}
