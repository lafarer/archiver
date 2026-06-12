package com.github.lafarer.archiver.service;

import com.github.lafarer.archiver.model.enums.DocumentFileType;

import java.nio.file.Path;
import java.util.List;

public interface AiAnalysisService {

    record CustomFieldHint(String name, String label, String description) {}

    record RuleHint(Long id, String label, String conditionNl) {}

    record FieldValue(String value, String source, Double confidence) {}

    record AnalysisResult(
        String reasoning,
        String documentType,
        FieldValue title,
        FieldValue documentDate,
        String documentDatePrecision,
        FieldValue issuer,
        FieldValue description,
        List<String> tags,
        java.util.Map<String, FieldValue> customFields,
        Long appliedRuleId
    ) {}

    AnalysisResult analyze(
        Path file,
        DocumentFileType fileType,
        String extractedText,       // null for scanned/image
        java.util.Map<String, String> pdfMetadata,
        String filenameDateHint,
        List<CustomFieldHint> customFields,
        List<RuleHint> rules
    );
}
