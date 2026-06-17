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
import org.apache.pdfbox.Loader;
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

    @Value("${archiver.anthropic.api-key}")
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
        List<DocumentTypeHint> documentTypes,
        List<TagHint> tags,
        List<RuleHint> rules,
        String hint
    ) {
        String model = settingService.get("ai_model");

        List<ContentBlockParam> userContent = buildUserContent(
            file, fileType, extractedText, pdfMetadata, filenameDateHint, rules, hint
        );

        TextBlockParam systemBlock = TextBlockParam.builder()
            .text(buildSystemPrompt(customFields, documentTypes, tags))
            .cacheControl(CacheControlEphemeral.builder().build())
            .build();

        MessageCreateParams params = MessageCreateParams.builder()
            .model(model)
            .maxTokens(2048)
            .system(MessageCreateParams.System.ofTextBlockParams(List.of(systemBlock)))
            .messages(List.of(
                MessageParam.builder()
                    .role(MessageParam.Role.USER)
                    .content(MessageParam.Content.ofBlockParams(userContent))
                    .build()
            ))
            .build();

        if (hint != null && !hint.isBlank()) {
            log.info("Sending re-analysis with hint: {}", hint);
        }
        log.debug("AI model used: {}", model);
        log.debug("User content blocks: {}", userContent.size());
        Message response = client.messages().create(params);
        String json = stripMarkdown(extractText(response));
        log.debug("AI raw response: {}", json);

        return parseResponse(json);
    }

    private String buildSystemPrompt(List<CustomFieldHint> customFields, List<DocumentTypeHint> documentTypes, List<TagHint> tags) {
        StringBuilder sb = new StringBuilder();
        sb.append("""
            You are a document analysis assistant. Analyze the provided document and return a JSON object.

            USER HINT: If the user message starts with "USER HINT:", it provides authoritative context that MUST override your own analysis. Follow it strictly for document_type, applied_rule_id, custom fields (especially adresse_bien, membre_famille, etc.), and any other classification decision. Extract the hint's information directly into the relevant JSON fields.

            """);

        if (documentTypes != null && !documentTypes.isEmpty()) {
            sb.append("KNOWN DOCUMENT TYPES (non-exhaustive - suggest a better slug if none fits):\n");
            documentTypes.forEach(dt -> sb.append(String.format(
                "  - %s (%s): %s%n", dt.slug(), dt.label(), dt.description()
            )));
        } else {
            sb.append("""
                KNOWN DOCUMENT TYPES (non-exhaustive, suggest a better one if needed):
                facture, contrat, courrier, diplome, identite, fiche-de-paie, attestation,
                releve, devis, garantie, quittance, ordonnance
                """);
        }

        sb.append("\n");
        if (tags != null && !tags.isEmpty()) {
            sb.append("KNOWN TAGS (non-exhaustive - add new ones if needed):\n");
            tags.forEach(t -> sb.append(String.format(
                "  - %s (%s): %s%n", t.slug(), t.label(), t.description()
            )));
        } else {
            sb.append("""
                KNOWN TAGS (non-exhaustive, add relevant ones):
                eau, electricite, gaz, internet, telephone, logement, travaux, entretien,
                electromenager, electronique, vehicule, banque, impots, assurance, sante,
                mutuelle, famille, juridique, sinistre, voyage, abonnement
                """);
        }

        sb.append("""

            CUSTOM FIELDS - evaluate applicability for this document:
            """);

        customFields.forEach(cf -> sb.append(String.format(
            "  - %s (%s): %s%n", cf.slug(), cf.label(), cf.description()
        )));

        sb.append("""

            CRITICAL: respond with raw JSON only. No markdown, no code fences, no explanation before or after. The very first character of your response must be '{' and the last must be '}'.

            RESPONSE FORMAT:
            {
              "reasoning": "Brief explanation of your analysis",
              "document_type": {
                "slug": "kebab-case-slug",
                "label": "Libellé lisible en français",
                "description": "Description courte aidant à identifier ce type (uniquement si slug absent de la liste)"
              },
              "title": { "value": "string", "source": "ai", "confidence": 0.0 },
              "document_date": { "value": "YYYY or YYYY-MM or YYYY-MM-DD", "source": "ai|pdf_metadata|filename", "confidence": 0.0 },
              "document_date_precision": "year|month|day",
              "issuer": { "value": "string", "source": "ai", "confidence": 0.0 },
              "description": { "value": "string", "source": "ai", "confidence": 0.0 },
              "tags": [
                { "slug": "assurance" },
                { "slug": "nouveau-tag", "label": "Nouveau tag", "description": "Description en français" }
              ],
              "custom_fields": {
                "field_name": { "applicable": true, "value": "string", "confidence": 0.0 }
              },
              "applied_rule_id": null
            }

            For tags: each tag is an object with at minimum a slug. Known tags need only the slug.
            For new tags not in the list, add label (in French) and description.
            For document_type: always use a slug from the known list when it fits.
            If none fits, invent a new kebab-case slug and provide label + description.
            If the slug is from the known list, label and description can be omitted.
            For custom fields, only include applicable ones with a non-null value.
            Set applied_rule_id to the ID of the matching rule, or null if none match (default will be used).
            """);

        return sb.toString();
    }

    private List<ContentBlockParam> buildUserContent(
        Path file, DocumentFileType fileType,
        String extractedText, Map<String, String> pdfMetadata,
        String filenameDateHint, List<RuleHint> rules, String hint
    ) {
        List<ContentBlockParam> blocks = new ArrayList<>();

        if (hint != null && !hint.isBlank()) {
            blocks.add(ContentBlockParam.ofText(
                TextBlockParam.builder()
                    .text("""
                        USER HINT (AUTHORITATIVE - OVERRIDES YOUR ANALYSIS):
                        %s

                        You MUST act on this hint:
                        1. If the hint names a storage location or folder (e.g. "Actes du logement", "Travaux", "Entretiens"), find the rule whose label or path_template contains those keywords and set applied_rule_id to its ID. Do NOT evaluate whether the document type perfectly matches the rule description - the user's classification decision is final.
                        2. Extract any address, person name, or other identifiers from the hint and set the corresponding custom fields (e.g. adresse_bien, membre_famille).
                        3. Infer document_type, title, issuer from the hint if the document content is ambiguous.
                        4. Do NOT let visual or textual document analysis override this hint.
                        """.formatted(hint.trim()))
                    .build()
            ));
        }

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
                "  ID %d - %s: %s%n", r.id(), r.label(),
                r.conditionNl() != null ? r.conditionNl() : "(default)"
            )));
            context.append("\n");
        }

        blocks.add(ContentBlockParam.ofText(
            TextBlockParam.builder().text(context.toString()).build()
        ));

        // Document content
        if (extractedText != null && !extractedText.isBlank()) {
            blocks.add(ContentBlockParam.ofText(
                TextBlockParam.builder()
                    .text("DOCUMENT TEXT:\n" + truncate(extractedText, 8000))
                    .build()
            ));
        } else {
            // Vision: encode first page as image
            try {
                String base64 = encodeFirstPage(file, fileType);
                if (base64 != null) {
                    blocks.add(ContentBlockParam.ofImage(
                        ImageBlockParam.builder()
                            .source(ImageBlockParam.Source.ofBase64Image(Base64ImageSource.builder()
                                .mediaType(Base64ImageSource.MediaType.IMAGE_JPEG)
                                .data(base64)
                                .build()))
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
            try (PDDocument doc = Loader.loadPDF(file.toFile())) {
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
            .filter(ContentBlock::isText)
            .map(b -> b.asText().text())
            .findFirst()
            .orElse("{}");
    }

    private String stripMarkdown(String text) {
        String t = text.trim();
        if (t.startsWith("```")) {
            int newline = t.indexOf('\n');
            int closing = t.lastIndexOf("```");
            if (newline > 0 && closing > newline) {
                return t.substring(newline + 1, closing).trim();
            }
        }
        return t;
    }

    private AnalysisResult parseResponse(String json) {
        try {
            Map<String, Object> map = objectMapper.readValue(json, new TypeReference<>() {});

            String reasoning              = str(map, "reasoning");
            DocumentTypeResult documentType = documentTypeResult(map);
            String datePrecision          = str(map, "document_date_precision");
            FieldValue title       = fieldValue(map, "title");
            FieldValue date        = fieldValue(map, "document_date");
            FieldValue issuer      = fieldValue(map, "issuer");
            FieldValue description = fieldValue(map, "description");

            @SuppressWarnings("unchecked")
            List<Object> rawTags = (List<Object>) map.getOrDefault("tags", List.of());
            List<TagResult> tags = rawTags.stream().map(this::parseTagResult).filter(t -> t != null).toList();

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
                null, null, List.<TagResult>of(), Map.of(), null);
        }
    }

    private TagResult parseTagResult(Object raw) {
        if (raw instanceof Map<?, ?> rawMap) {
            @SuppressWarnings("unchecked")
            Map<String, Object> m = (Map<String, Object>) rawMap;
            String slug = str(m, "slug");
            return slug != null ? new TagResult(slug, str(m, "label"), str(m, "description")) : null;
        }
        return raw != null ? new TagResult(String.valueOf(raw), null, null) : null;
    }

    private DocumentTypeResult documentTypeResult(Map<String, Object> map) {
        Object raw = map.get("document_type");
        if (raw instanceof Map<?, ?> rawMap) {
            @SuppressWarnings("unchecked")
            Map<String, Object> m = (Map<String, Object>) rawMap;
            String slug = str(m, "slug");
            return slug != null ? new DocumentTypeResult(slug, str(m, "label"), str(m, "description")) : null;
        }
        // Fallback: AI returned a plain string
        return raw != null ? new DocumentTypeResult(String.valueOf(raw), null, null) : null;
    }

    private String str(Map<String, Object> map, String key) {
        Object v = map.get(key);
        return v != null ? String.valueOf(v) : null;
    }

    @SuppressWarnings("unchecked")
    private FieldValue fieldValue(Map<String, Object> map, String key) {
        Object raw = map.get(key);
        if (!(raw instanceof Map<?, ?> rawMap)) return null;
        @SuppressWarnings("unchecked")
        Map<String, Object> m = (Map<String, Object>) rawMap;
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
