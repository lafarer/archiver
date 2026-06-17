package com.github.lafarer.archiver.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.github.lafarer.archiver.model.Document;
import com.github.lafarer.archiver.model.enums.DatePrecision;
import com.github.lafarer.archiver.model.enums.FieldSource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.Path;
import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
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

    public void write(Path archivedFile, Document document) {
        Path sidecar = sidecarPathFor(archivedFile);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("schema_version", 1);
        data.put("extracted_at", Instant.now().toString());
        data.put("ai_model", document.getAiModel());
        data.put("ai_reasoning", document.getAiReasoning());
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
        data.put("provenance", buildProvenance(document));

        try {
            mapper.writeValue(sidecar.toFile(), data);
            log.debug("Sidecar written: {}", sidecar);
        } catch (IOException e) {
            log.error("Failed to write sidecar for {}: {}", archivedFile, e.getMessage());
        }
    }

    /**
     * Reads a sidecar JSON and returns a Document populated with its metadata.
     * File-derived fields (sha256, mimeType, fileSize, mtime, resolvedPath, originalFilename)
     * are left null - the caller must fill them from the actual file.
     */
    @SuppressWarnings("unchecked")
    public Document importDocument(Path sidecarPath) throws IOException {
        Map<String, Object> data = mapper.readValue(sidecarPath.toFile(), new TypeReference<>() {});
        Document doc = new Document();
        doc.setDocumentType(str(data, "document_type"));
        doc.setTitle(str(data, "title"));
        doc.setDocumentDate(str(data, "document_date"));
        doc.setIssuer(str(data, "issuer"));
        doc.setDescription(str(data, "description"));
        doc.setAiModel(str(data, "ai_model"));
        doc.setAiReasoning(str(data, "ai_reasoning"));

        Object rawPrec = data.get("document_date_precision");
        if (rawPrec != null) {
            try { doc.setDocumentDatePrecision(DatePrecision.valueOf(rawPrec.toString())); }
            catch (IllegalArgumentException ignored) {}
        }

        Object rawTags = data.get("tags");
        if (rawTags instanceof List<?> list) {
            List<String> tags = new ArrayList<>();
            list.forEach(t -> tags.add(t.toString()));
            doc.setTags(tags);
        }

        Object rawCf = data.get("custom_fields");
        if (rawCf instanceof Map<?, ?> cfMap) {
            cfMap.forEach((k, v) -> doc.getCustomFields().put(k.toString(), v != null ? v.toString() : ""));
        }

        Object rawExtracted = data.get("extracted_at");
        if (rawExtracted != null) {
            try { doc.setClassifiedAt(Instant.parse(rawExtracted.toString())); }
            catch (Exception ignored) {}
        }

        Object rawProv = data.get("provenance");
        if (rawProv instanceof Map<?, ?> provMap) {
            applyProvenance(doc, (Map<String, Object>) provMap);
        }

        doc.setClassified(true);
        return doc;
    }

    @SuppressWarnings("unchecked")
    private void applyProvenance(Document doc, Map<String, Object> provenance) {
        Map<String, Object> titleProv = (Map<String, Object>) provenance.get("title");
        if (titleProv != null) {
            doc.setTitleSource(parseSource(titleProv.get("source")));
            doc.setTitleConfidence(parseDouble(titleProv.get("confidence")));
        }
        Map<String, Object> dateProv = (Map<String, Object>) provenance.get("document_date");
        if (dateProv != null) {
            doc.setDocumentDateSource(parseSource(dateProv.get("source")));
            doc.setDocumentDateConfidence(parseDouble(dateProv.get("confidence")));
        }
        Map<String, Object> issuerProv = (Map<String, Object>) provenance.get("issuer");
        if (issuerProv != null) {
            doc.setIssuerSource(parseSource(issuerProv.get("source")));
            doc.setIssuerConfidence(parseDouble(issuerProv.get("confidence")));
        }
    }

    private static String str(Map<String, Object> map, String key) {
        Object v = map.get(key);
        return v != null ? v.toString() : null;
    }

    private static FieldSource parseSource(Object v) {
        if (v == null) return null;
        try { return FieldSource.valueOf(v.toString().toUpperCase()); }
        catch (IllegalArgumentException e) { return null; }
    }

    private static Double parseDouble(Object v) {
        if (v instanceof Number n) return n.doubleValue();
        return null;
    }

    private Map<String, Object> buildProvenance(Document doc) {
        Map<String, Object> p = new LinkedHashMap<>();
        addProvenance(p, "title",         doc.getTitleSource(),         doc.getTitleConfidence());
        addProvenance(p, "document_date", doc.getDocumentDateSource(),  doc.getDocumentDateConfidence());
        addProvenance(p, "issuer",        doc.getIssuerSource(),        doc.getIssuerConfidence());

        String cfProv = doc.getCustomFieldsProvenance();
        if (cfProv != null && !cfProv.isBlank() && !cfProv.equals("{}")) {
            try {
                Map<String, Map<String, Object>> parsed = mapper.readValue(cfProv, new TypeReference<>() {});
                p.putAll(parsed);
            } catch (Exception e) {
                log.warn("Failed to parse custom_fields_provenance: {}", e.getMessage());
            }
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
