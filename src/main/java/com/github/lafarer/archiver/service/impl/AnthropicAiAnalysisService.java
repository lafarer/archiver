package com.github.lafarer.archiver.service.impl;

import com.anthropic.client.AnthropicClient;
import com.anthropic.client.okhttp.AnthropicOkHttpClient;
import com.anthropic.models.messages.*;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.github.lafarer.archiver.service.AiAnalysisService;
import com.github.lafarer.archiver.model.enums.DocumentFileType;
import com.github.lafarer.archiver.service.SettingService;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.rendering.PDFRenderer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.*;

@Service
@RequiredArgsConstructor
@Slf4j
public class AnthropicAiAnalysisService implements AiAnalysisService {

    @Value("${anthropic.api-key}")
    private String apiKey;

    private final SettingService settingService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    private AnthropicClient client;

    @PostConstruct
    void init() {
        client = AnthropicOkHttpClient.builder()
            .apiKey(apiKey)
            .build();
    }

    @Override
    public AnalysisResult analyze(
        Path file,
        DocumentFileType fileType,
        String extractedText,
        Map<String, String> pdfMetadata,
        String filenameDateHint,
        List<CustomFieldHint> customFields,
        List<RuleHint> rules
    ) {
        String model = settingService.get("ai_model");

        List<ContentBlock> userContent = buildUserContent(
            file, fileType, extractedText, pdfMetadata, filenameDateHint, rules
        );

        MessageCreateParams params = MessageCreateParams.builder()
            .model(model)
            .maxTokens(2048)
            .system(buildSystemPrompt(customFields))
            .messages(List.of(
                MessageParam.builder()
                    .role(MessageParam.Role.USER)
                    .content(MessageParam.Content.ofBlockParams(userContent))
                    .build()
            ))
            .build();

        Message response = client.messages().create(params);
        String json = extractText(response);

        return parseResponse(json);
    }

    private String buildSystemPrompt(List<CustomFieldHint> customFields) {
        StringBuilder sb = new StringBuilder();
        sb.append("""
            You are a document analysis assistant. Analyze the provided document and return a JSON object.

            KNOWN DOCUMENT TYPES (non-exhaustive, suggest a better one if needed):
            facture, contrat, courrier, diplome, identite, bulletin, fiche-de-paie, acte, notice,
            attestation, releve, devis, bon-de-commande, garantie, quittance, ordonnance

            KNOWN TAGS (non-exhaustive, add relevant ones):
            eau, energie, internet, telephone, entretien, juridique, electromenager, electronique,
            mobilier, outillage, sinistre, travaux, assurance, sante, banque, impots, famille

            CUSTOM FIELDS — evaluate applicability for this document:
            """);

        customFields.forEach(cf -> sb.append(String.format(
            "  - %s (%s): %s%n", cf.name(), cf.label(), cf.description()
        )));

        sb.append("""

            RESPONSE FORMAT (strict JSON, no markdown):
            {
              "reasoning": "Brief explanation of your analysis",
              "document_type": "string",
              "title": { "value": "string", "source": "ai", "confidence": 0.0 },
              "document_date": { "value": "YYYY or YYYY-MM or YYYY-MM-DD", "source": "ai|pdf_metadata|filename", "confidence": 0.0 },
              "document_date_precision": "year|month|day",
              "issuer": { "value": "string", "source": "ai", "confidence": 0.0 },
              "description": { "value": "string", "source": "ai", "confidence": 0.0 },
              "tags": ["string"],
              "custom_fields": {
                "field_name": { "applicable": true, "value": "string", "confidence": 0.0 }
              },
              "applied_rule_id": null
            }

            For custom fields, only include applicable ones with a non-null value.
            Set applied_rule_id to the ID of the matching rule, or null if none match (default will be used).
            """);

        return sb.toString();
    }

    private List<ContentBlock> buildUserContent(
        Path file, DocumentFileType fileType,
        String extractedText, Map<String, String> pdfMetadata,
        String filenameDateHint, List<RuleHint> rules
    ) {
        List<ContentBlock> blocks = new ArrayList<>();

        // Pre-extracted context
        StringBuilder context = new StringBuilder("PRE-EXTRACTED INFORMATION:\n");
        if (pdfMetadata != null && !pdfMetadata.isEmpty()) {
            context.append("PDF Metadata: ").append(pdfMetadata).append("\n");
        }
        if (filenameDateHint != null) {
            context.append("Filename date hint: ").append(filenameDateHint).append("\n");
        }
        context.append("File type: ").append(fileType).append("\n\n");

        if (rules != null && !rules.isEmpty()) {
            context.append("STORAGE PATH RULES (select the most appropriate, or null for default):\n");
            rules.forEach(r -> context.append(String.format(
                "  ID %d — %s: %s%n", r.id(), r.label(),
                r.conditionNl() != null ? r.conditionNl() : "(default)"
            )));
            context.append("\n");
        }

        blocks.add(ContentBlock.ofRequestTextBlock(
            RequestTextBlock.builder().text(context.toString()).build()
        ));

        // Document content
        if (extractedText != null && !extractedText.isBlank()) {
            blocks.add(ContentBlock.ofRequestTextBlock(
                RequestTextBlock.builder()
                    .text("DOCUMENT TEXT:\n" + truncate(extractedText, 8000))
                    .build()
            ));
        } else {
            // Vision: encode first page as image
            try {
                String base64 = encodeFirstPage(file, fileType);
                if (base64 != null) {
                    blocks.add(ContentBlock.ofRequestImageBlock(
                        RequestImageBlock.builder()
                            .source(Base64ImageSource.builder()
                                .mediaType(Base64ImageSource.MediaType.IMAGE_JPEG)
                                .data(base64)
                                .build())
                            .build()
                    ));
                }
            } catch (Exception e) {
                log.warn("Could not encode document as image: {}", e.getMessage());
            }
        }

        return blocks;
    }

    private String encodeFirstPage(Path file, DocumentFileType fileType) throws Exception {
        BufferedImage image;
        if (fileType == DocumentFileType.SCANNED_PDF) {
            try (PDDocument doc = PDDocument.load(file.toFile())) {
                image = new PDFRenderer(doc).renderImageWithDPI(0, 150);
            }
        } else {
            image = ImageIO.read(file.toFile());
        }
        if (image == null) return null;

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        ImageIO.write(image, "JPEG", out);
        return Base64.getEncoder().encodeToString(out.toByteArray());
    }

    private String extractText(Message response) {
        return response.content().stream()
            .filter(b -> b instanceof TextBlock)
            .map(b -> ((TextBlock) b).text())
            .findFirst()
            .orElse("{}");
    }

    private AnalysisResult parseResponse(String json) {
        try {
            Map<String, Object> map = objectMapper.readValue(json, new TypeReference<>() {});

            String reasoning       = str(map, "reasoning");
            String documentType    = str(map, "document_type");
            String datePrecision   = str(map, "document_date_precision");
            FieldValue title       = fieldValue(map, "title");
            FieldValue date        = fieldValue(map, "document_date");
            FieldValue issuer      = fieldValue(map, "issuer");
            FieldValue description = fieldValue(map, "description");

            @SuppressWarnings("unchecked")
            List<String> tags = (List<String>) map.getOrDefault("tags", List.of());

            @SuppressWarnings("unchecked")
            Map<String, Object> cfRaw = (Map<String, Object>) map.getOrDefault("custom_fields", Map.of());
            Map<String, FieldValue> customFields = new LinkedHashMap<>();
            cfRaw.forEach((k, v) -> {
                if (v instanceof Map<?, ?> m) {
                    Object applicable = m.get("applicable");
                    if (!Boolean.FALSE.equals(applicable) && m.get("value") != null) {
                        customFields.put(k, new FieldValue(
                            String.valueOf(m.get("value")),
                            "ai",
                            m.get("confidence") instanceof Number n ? n.doubleValue() : null
                        ));
                    }
                }
            });

            Long ruleId = map.get("applied_rule_id") instanceof Number n ? n.longValue() : null;

            return new AnalysisResult(reasoning, documentType, title, date, datePrecision,
                issuer, description, tags, customFields, ruleId);

        } catch (Exception e) {
            log.error("Failed to parse AI response: {}", e.getMessage());
            return new AnalysisResult("Parse error", null, null, null, null,
                null, null, List.of(), Map.of(), null);
        }
    }

    private String str(Map<String, Object> map, String key) {
        Object v = map.get(key);
        return v != null ? String.valueOf(v) : null;
    }

    @SuppressWarnings("unchecked")
    private FieldValue fieldValue(Map<String, Object> map, String key) {
        Object raw = map.get(key);
        if (!(raw instanceof Map<?, ?> m)) return null;
        Object value = m.get("value");
        if (value == null) return null;
        return new FieldValue(
            String.valueOf(value),
            String.valueOf(m.getOrDefault("source", "ai")),
            m.get("confidence") instanceof Number n ? n.doubleValue() : null
        );
    }

    private String truncate(String text, int maxLen) {
        return text.length() <= maxLen ? text : text.substring(0, maxLen) + "…";
    }
}
