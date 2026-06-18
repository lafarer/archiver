package com.github.lafarer.archiver.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.github.lafarer.archiver.config.ArchiverProperties;
import com.github.lafarer.archiver.model.CustomFieldDef;
import com.github.lafarer.archiver.model.DocumentTypeDef;
import com.github.lafarer.archiver.model.StoragePathRule;
import com.github.lafarer.archiver.model.TagDef;
import com.github.lafarer.archiver.repository.CustomFieldDefRepository;
import com.github.lafarer.archiver.repository.DocumentTypeDefRepository;
import com.github.lafarer.archiver.repository.StoragePathRuleRepository;
import com.github.lafarer.archiver.repository.TagDefRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;

@Service
@Slf4j
@RequiredArgsConstructor
public class GlobalSidecarService {

    private final ArchiverProperties props;
    private final StoragePathRuleRepository ruleRepository;
    private final CustomFieldDefRepository customFieldDefRepository;
    private final DocumentTypeDefRepository documentTypeDefRepository;
    private final TagDefRepository tagDefRepository;

    private final ObjectMapper mapper = new ObjectMapper()
            .enable(SerializationFeature.INDENT_OUTPUT);

    @EventListener(ApplicationReadyEvent.class)
    public void initIfMissing() {
        if (!Files.exists(sidecarPath())) {
            log.info("Global reference sidecar not found, creating from current DB state");
            refresh();
        }
    }

    public void refresh() {
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("schema_version", 1);
        data.put("updated_at", Instant.now().toString());
        data.put("storage_path_rules", ruleRepository.findAll().stream()
                .sorted((a, b) -> Short.compare(a.getPriority(), b.getPriority()))
                .map(this::ruleToMap).toList());
        data.put("custom_field_defs", customFieldDefRepository.findAll().stream()
                .map(this::fieldToMap).toList());
        data.put("document_type_defs", documentTypeDefRepository.findAll().stream()
                .map(this::typeToMap).toList());
        data.put("tag_defs", tagDefRepository.findAll().stream()
                .map(this::tagToMap).toList());
        writeAtomic(data);
    }

    private Path sidecarPath() {
        return props.getRoot().resolve(".archiver-reference.json");
    }

    private void writeAtomic(Map<String, Object> data) {
        Path target = sidecarPath();
        Path tmp = target.resolveSibling(".archiver-reference.json.tmp");
        try {
            mapper.writeValue(tmp.toFile(), data);
            Files.move(tmp, target, StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE);
            log.debug("Global reference sidecar refreshed: {}", target);
        } catch (IOException e) {
            log.error("Failed to write global reference sidecar: {}", e.getMessage());
            try { Files.deleteIfExists(tmp); } catch (IOException ignored) {}
        }
    }

    private Map<String, Object> ruleToMap(StoragePathRule r) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("priority", r.getPriority());
        m.put("label", r.getLabel());
        m.put("condition_nl", r.getConditionNl());
        m.put("path_template", r.getPathTemplate());
        m.put("is_default", r.isDefault());
        m.put("active", r.isActive());
        return m;
    }

    private Map<String, Object> fieldToMap(CustomFieldDef f) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("slug", f.getSlug());
        m.put("label", f.getLabel());
        m.put("description", f.getDescription());
        m.put("field_type", f.getFieldType());
        return m;
    }

    private Map<String, Object> typeToMap(DocumentTypeDef t) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("slug", t.getSlug());
        m.put("label", t.getLabel());
        m.put("description", t.getDescription());
        m.put("enabled", t.isEnabled());
        return m;
    }

    private Map<String, Object> tagToMap(TagDef t) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("slug", t.getSlug());
        m.put("label", t.getLabel());
        m.put("description", t.getDescription());
        m.put("enabled", t.isEnabled());
        return m;
    }
}
