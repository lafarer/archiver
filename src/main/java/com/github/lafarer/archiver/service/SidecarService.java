package com.github.lafarer.archiver.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.github.lafarer.archiver.model.Document;
import com.github.lafarer.archiver.service.AiAnalysisService.AnalysisResult;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.Path;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

@Service
@Slf4j
public class SidecarService {

    private final ObjectMapper mapper = new ObjectMapper()
        .enable(SerializationFeature.INDENT_OUTPUT);

    public Path sidecarPathFor(Path archivedFile) {
        String name = "." + archivedFile.getFileName().toString() + ".json";
        return archivedFile.getParent().resolve(name);
    }

    public void write(Path archivedFile, Document document, AnalysisResult analysis) {
        Path sidecar = sidecarPathFor(archivedFile);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("schema_version", 1);
        data.put("extracted_at", Instant.now().toString());
        data.put("ai_model", "claude-sonnet-4-6");
        data.put("ai_reasoning", analysis.reasoning());
        data.put("document_type", document.getDocumentType());
        data.put("title", document.getTitle());
        data.put("document_date", document.getDocumentDate());
        data.put("document_date_precision", document.getDocumentDatePrecision());
        data.put("issuer", document.getIssuer());
        data.put("description", document.getDescription());
        data.put("tags", document.getTags());
        data.put("custom_fields", document.getCustomFields());
        data.put("resolved_path", document.getResolvedPath());
        data.put("applied_rule", document.getAppliedRule() != null
            ? document.getAppliedRule().getLabel() : null);
        data.put("provenance", buildProvenance(document, analysis));

        try {
            mapper.writeValue(sidecar.toFile(), data);
            log.debug("Sidecar written: {}", sidecar);
        } catch (IOException e) {
            log.error("Failed to write sidecar for {}: {}", archivedFile, e.getMessage());
        }
    }

    private Map<String, Object> buildProvenance(Document doc, AnalysisResult analysis) {
        Map<String, Object> p = new LinkedHashMap<>();
        addProvenance(p, "title",         doc.getTitleSource(),         doc.getTitleConfidence());
        addProvenance(p, "document_date", doc.getDocumentDateSource(),  doc.getDocumentDateConfidence());
        addProvenance(p, "issuer",        doc.getIssuerSource(),        doc.getIssuerConfidence());
        if (analysis.customFields() != null) {
            analysis.customFields().forEach((k, v) ->
                p.put(k, Map.of("source", v.source(), "confidence", v.confidence() != null ? v.confidence() : 0.0))
            );
        }
        return p;
    }

    private void addProvenance(Map<String, Object> map, String field, Object source, Double confidence) {
        if (source == null) return;
        map.put(field, Map.of(
            "source",     source.toString().toLowerCase(),
            "confidence", confidence != null ? confidence : 1.0
        ));
    }
}
