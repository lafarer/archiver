package com.github.lafarer.archiver.service;

import com.github.lafarer.archiver.model.ClassificationHistory;
import com.github.lafarer.archiver.model.CustomFieldDef;
import com.github.lafarer.archiver.model.Document;
import com.github.lafarer.archiver.model.StoragePathRule;
import com.github.lafarer.archiver.model.enums.ClassificationTrigger;
import com.github.lafarer.archiver.model.enums.DatePrecision;
import com.github.lafarer.archiver.model.enums.FieldSource;
import com.github.lafarer.archiver.repository.ClassificationHistoryRepository;
import com.github.lafarer.archiver.repository.CustomFieldDefRepository;
import com.github.lafarer.archiver.repository.DocumentRepository;
import com.github.lafarer.archiver.repository.StoragePathRuleRepository;
import com.github.lafarer.archiver.service.AiAnalysisService.*;
import com.github.lafarer.archiver.service.ExtractionService.ExtractionResult;
import com.github.lafarer.archiver.service.PathResolverService.ResolvedPath;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class DocumentPipelineService {

    private final ExtractionService extractionService;
    private final AiAnalysisService aiAnalysisService;
    private final PathResolverService pathResolverService;
    private final SidecarService sidecarService;
    private final ArchiveService archiveService;
    private final SettingService settingService;
    private final DocumentTypeService documentTypeService;
    private final TagService tagService;
    private final DocumentRepository documentRepository;
    private final CustomFieldDefRepository customFieldDefRepository;
    private final StoragePathRuleRepository storagePathRuleRepository;
    private final ClassificationHistoryRepository historyRepository;

    @Async
    public void processAsync(Path file, ArchiveService.SourceType sourceType) {
        try {
            process(file, sourceType);
        } catch (Exception e) {
            log.error("Pipeline failed for {}: {}", file.getFileName(), e.getMessage(), e);
        }
    }

    @Transactional
    public Document process(Path file, ArchiveService.SourceType sourceType) throws IOException {
        String hash = sha256(file);
        if (documentRepository.findBySha256Hash(hash).isPresent()) {
            log.info("Duplicate detected, skipping: {}", file.getFileName());
            if (sourceType == ArchiveService.SourceType.INBOX) {
                try {
                    Files.deleteIfExists(file);
                    log.info("Removed duplicate from inbox: {}", file.getFileName());
                } catch (IOException e) {
                    log.warn("Could not remove duplicate from inbox: {}", e.getMessage());
                }
            }
            return null;
        }

        // Step 1 — pre-extraction
        ExtractionResult extraction = extractionService.extract(file);

        // Step 2 — AI analysis (always called)
        List<CustomFieldHint> cfHints = customFieldDefRepository.findAll().stream()
            .map(cf -> new CustomFieldHint(cf.getSlug(), cf.getLabel(), cf.getDescription()))
            .collect(Collectors.toList());

        List<DocumentTypeHint> typeHints = documentTypeService.findEnabled().stream()
            .map(dt -> new DocumentTypeHint(dt.getSlug(), dt.getLabel(), dt.getDescription()))
            .collect(Collectors.toList());

        List<TagHint> tagHints = tagService.findEnabled().stream()
            .map(t -> new TagHint(t.getSlug(), t.getLabel(), t.getDescription()))
            .collect(Collectors.toList());

        List<RuleHint> ruleHints = storagePathRuleRepository.findByActiveTrueOrderByPriorityAsc().stream()
            .map(r -> new RuleHint(r.getId(), r.getLabel(), r.getConditionNl()))
            .collect(Collectors.toList());

        AnalysisResult analysis = aiAnalysisService.analyze(
            file,
            extraction.fileType(),
            extraction.extractedText(),
            extraction.pdfMetadata(),
            extraction.filenameDateHint(),
            cfHints,
            typeHints,
            tagHints,
            ruleHints
        );

        if (analysis.documentType() != null) {
            documentTypeService.autoRegister(
                analysis.documentType().slug(),
                analysis.documentType().label(),
                analysis.documentType().description()
            );
        }

        if (analysis.tags() != null) {
            analysis.tags().forEach(t -> tagService.autoRegister(t.slug(), t.label(), t.description()));
        }

        // Step 3 — build document entity
        Document doc = new Document();
        doc.setOriginalFilename(file.getFileName().toString());
        doc.setSourcePath(file.toAbsolutePath().toString());
        doc.setSha256Hash(hash);
        doc.setMimeType(Files.probeContentType(file));
        doc.setFileSizeBytes(Files.size(file));
        doc.setFilesystemMtime(extraction.filesystemMtime());

        applyAnalysis(doc, analysis);

        // Step 4 — resolve path
        Map<String, String> cfValues = doc.getCustomFields();
        ResolvedPath resolved = pathResolverService.resolve(
            analysis.appliedRuleId(),
            doc.getDocumentType(),
            doc.getDocumentDate(),
            doc.getTitle(),
            doc.getIssuer(),
            cfValues
        );

        boolean autoArchive = isAboveThreshold(analysis);
        doc.setResolvedPath(resolved.relativePath());
        doc.setAppliedRule(resolved.appliedRule());

        if (autoArchive) {
            doc = archiveAndFinalize(doc, file, resolved, analysis, sourceType);
        } else {
            // Leave in pending state for UI validation
            doc = documentRepository.save(doc);
            log.info("Document pending validation: {}", doc.getOriginalFilename());
        }

        return doc;
    }

    public Document validateAndArchive(Long documentId, Path sourceFile) throws IOException {
        Document doc = documentRepository.findById(documentId)
            .orElseThrow(() -> new IllegalArgumentException("Document not found: " + documentId));

        ResolvedPath resolved = pathResolverService.resolve(
            doc.getAppliedRule() != null ? doc.getAppliedRule().getId() : null,
            doc.getDocumentType(), doc.getDocumentDate(),
            doc.getTitle(), doc.getIssuer(), doc.getCustomFields()
        );
        doc.setResolvedPath(resolved.relativePath());
        doc.setAppliedRule(resolved.appliedRule());

        DocumentTypeResult dummyType = doc.getDocumentType() != null
            ? new DocumentTypeResult(doc.getDocumentType(), null, null) : null;
        List<TagResult> dummyTags = doc.getTags().stream().map(s -> new TagResult(s, null, null)).toList();
        AnalysisResult dummyAnalysis = new AnalysisResult(
            null, dummyType, null, null, null, null, null,
            dummyTags, Map.of(), doc.getAppliedRule() != null ? doc.getAppliedRule().getId() : null
        );

        return archiveAndFinalize(doc, sourceFile, resolved, dummyAnalysis, ArchiveService.SourceType.MANUAL);
    }

    private Document archiveAndFinalize(
        Document doc, Path sourceFile, ResolvedPath resolved,
        AnalysisResult analysis, ArchiveService.SourceType sourceType
    ) throws IOException {
        String relPath = resolved.relativePath() + extension(sourceFile);
        Path archivedFile = archiveService.archive(sourceFile, relPath, sourceType);

        doc.setResolvedPath(relPath);
        sidecarService.write(archivedFile, doc, analysis);
        doc.setSidecarPath(sidecarService.sidecarPathFor(archivedFile).toString());
        doc.setClassified(true);
        doc.setClassifiedAt(Instant.now());

        doc = documentRepository.save(doc);

        ClassificationHistory history = new ClassificationHistory();
        history.setDocument(doc);
        history.setNewPath(relPath);
        history.setNewRule(resolved.appliedRule());
        history.setTrigger(ClassificationTrigger.MANUAL);
        historyRepository.save(history);

        log.info("Archived: {} → {}", doc.getOriginalFilename(), relPath);
        return doc;
    }

    private void applyAnalysis(Document doc, AnalysisResult a) {
        if (a.documentType() != null) doc.setDocumentType(a.documentType().slug());

        if (a.title() != null) {
            doc.setTitle(a.title().value());
            doc.setTitleSource(FieldSource.AI);
            doc.setTitleConfidence(a.title().confidence());
        }
        if (a.documentDate() != null) {
            doc.setDocumentDate(a.documentDate().value());
            doc.setDocumentDateSource(parseSource(a.documentDate().source()));
            doc.setDocumentDateConfidence(a.documentDate().confidence());
            doc.setDocumentDatePrecision(parsePrecision(a.documentDatePrecision()));
        }
        if (a.issuer() != null) {
            doc.setIssuer(a.issuer().value());
            doc.setIssuerSource(FieldSource.AI);
            doc.setIssuerConfidence(a.issuer().confidence());
        }
        if (a.description() != null) {
            doc.setDescription(a.description().value());
        }
        if (a.tags() != null) {
            doc.setTags(a.tags().stream().map(TagResult::slug).toList());
        }
        if (a.customFields() != null) {
            a.customFields().forEach((k, v) -> doc.getCustomFields().put(k, v.value()));
        }
    }

    private boolean isAboveThreshold(AnalysisResult analysis) {
        if (!settingService.getBoolean("auto_archive_enabled")) return false;
        double threshold = settingService.getDouble("confidence_threshold");
        if (analysis.title() == null || analysis.documentDate() == null || analysis.issuer() == null)
            return false;
        Double minConf = List.of(
            analysis.title().confidence(),
            analysis.documentDate().confidence(),
            analysis.issuer().confidence()
        ).stream().filter(c -> c != null).min(Double::compareTo).orElse(0.0);
        return minConf >= threshold;
    }

    private FieldSource parseSource(String source) {
        if (source == null) return FieldSource.AI;
        return switch (source.toLowerCase()) {
            case "pdf_metadata" -> FieldSource.PDF_METADATA;
            case "filename"     -> FieldSource.FILENAME;
            case "filesystem"   -> FieldSource.FILESYSTEM;
            case "manual"       -> FieldSource.MANUAL;
            default             -> FieldSource.AI;
        };
    }

    private DatePrecision parsePrecision(String precision) {
        if (precision == null) return DatePrecision.DAY;
        return switch (precision.toLowerCase()) {
            case "year"  -> DatePrecision.YEAR;
            case "month" -> DatePrecision.MONTH;
            default      -> DatePrecision.DAY;
        };
    }

    private String extension(Path file) {
        String name = file.getFileName().toString();
        int dot = name.lastIndexOf('.');
        return dot > 0 ? name.substring(dot) : "";
    }

    private String sha256(Path file) throws IOException {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            md.update(Files.readAllBytes(file));
            return HexFormat.of().formatHex(md.digest());
        } catch (Exception e) {
            throw new IOException("SHA-256 failed", e);
        }
    }
}
