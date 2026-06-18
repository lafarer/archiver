package com.github.lafarer.archiver.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.github.lafarer.archiver.config.ArchiverProperties;
import com.github.lafarer.archiver.config.DatabaseInitState;
import com.github.lafarer.archiver.model.CustomFieldDef;
import com.github.lafarer.archiver.model.DocumentTypeDef;
import com.github.lafarer.archiver.model.StoragePathRule;
import com.github.lafarer.archiver.model.TagDef;
import com.github.lafarer.archiver.model.enums.FieldType;
import com.github.lafarer.archiver.repository.CustomFieldDefRepository;
import com.github.lafarer.archiver.repository.DocumentTypeDefRepository;
import com.github.lafarer.archiver.repository.StoragePathRuleRepository;
import com.github.lafarer.archiver.repository.TagDefRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@Slf4j
@RequiredArgsConstructor
public class GlobalSidecarService {

    private final ArchiverProperties props;
    private final DatabaseInitState initState;
    private final StoragePathRuleRepository ruleRepository;
    private final CustomFieldDefRepository customFieldDefRepository;
    private final DocumentTypeDefRepository documentTypeDefRepository;
    private final TagDefRepository tagDefRepository;
    private final SidecarImportService sidecarImportService;

    private final ObjectMapper mapper = new ObjectMapper()
            .enable(SerializationFeature.INDENT_OUTPUT);

    @EventListener(ApplicationReadyEvent.class)
    public void onStartup() {
        Path sidecar = sidecarPath();
        if (initState.isFreshlyCreated() && Files.exists(sidecar)) {
            log.info("Fresh DB with existing global sidecar - restoring reference data automatically");
            restoreFromSidecar();
            autoImportDocuments();
        } else if (!Files.exists(sidecar)) {
            log.info("Global reference sidecar not found, creating from current DB state");
            refresh();
        }
        // DB exists and sidecar exists → nothing to do
    }

    private void autoImportDocuments() {
        try {
            log.info("Auto-importing archived documents from sidecars...");
            int imported = sidecarImportService.importAllUntracked();
            log.info("Auto-import complete: {} document(s) restored from sidecars", imported);
        } catch (Exception e) {
            log.error("Auto-import of documents failed: {}", e.getMessage(), e);
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

    @Transactional
    @SuppressWarnings("unchecked")
    public void restoreFromSidecar() {
        try {
            Map<String, Object> data = mapper.readValue(sidecarPath().toFile(), new TypeReference<>() {});

            ruleRepository.deleteAll();
            customFieldDefRepository.deleteAll();
            documentTypeDefRepository.deleteAll();
            tagDefRepository.deleteAll();

            List<Map<String, Object>> rules = (List<Map<String, Object>>) data.getOrDefault("storage_path_rules", List.of());
            List<StoragePathRule> ruleEntities = rules.stream().map(m -> {
                StoragePathRule r = new StoragePathRule();
                r.setPriority(((Number) m.get("priority")).shortValue());
                r.setLabel((String) m.get("label"));
                r.setConditionNl((String) m.get("condition_nl"));
                r.setPathTemplate((String) m.get("path_template"));
                r.setDefault(Boolean.TRUE.equals(m.get("is_default")));
                r.setActive(Boolean.TRUE.equals(m.get("active")));
                return r;
            }).toList();
            ruleRepository.saveAll(ruleEntities);

            List<Map<String, Object>> fields = (List<Map<String, Object>>) data.getOrDefault("custom_field_defs", List.of());
            List<CustomFieldDef> fieldEntities = fields.stream().map(m -> {
                CustomFieldDef f = new CustomFieldDef();
                f.setSlug((String) m.get("slug"));
                f.setLabel((String) m.get("label"));
                f.setDescription((String) m.get("description"));
                f.setFieldType(FieldType.valueOf((String) m.get("field_type")));
                return f;
            }).toList();
            customFieldDefRepository.saveAll(fieldEntities);

            List<Map<String, Object>> types = (List<Map<String, Object>>) data.getOrDefault("document_type_defs", List.of());
            List<DocumentTypeDef> typeEntities = types.stream().map(m -> {
                DocumentTypeDef t = new DocumentTypeDef();
                t.setSlug((String) m.get("slug"));
                t.setLabel((String) m.get("label"));
                t.setDescription((String) m.get("description"));
                t.setEnabled(Boolean.TRUE.equals(m.get("enabled")));
                return t;
            }).toList();
            documentTypeDefRepository.saveAll(typeEntities);

            List<Map<String, Object>> tags = (List<Map<String, Object>>) data.getOrDefault("tag_defs", List.of());
            List<TagDef> tagEntities = tags.stream().map(m -> {
                TagDef t = new TagDef();
                t.setSlug((String) m.get("slug"));
                t.setLabel((String) m.get("label"));
                t.setDescription((String) m.get("description"));
                t.setEnabled(Boolean.TRUE.equals(m.get("enabled")));
                return t;
            }).toList();
            tagDefRepository.saveAll(tagEntities);

            log.info("Reference data restored: {} rules, {} fields, {} types, {} tags",
                    ruleEntities.size(), fieldEntities.size(), typeEntities.size(), tagEntities.size());

        } catch (IOException e) {
            log.error("Failed to restore from global sidecar: {}", e.getMessage());
        }
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
