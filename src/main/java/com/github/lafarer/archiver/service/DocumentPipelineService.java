package com.github.lafarer.archiver.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.github.lafarer.archiver.config.ArchiverProperties;
import com.github.lafarer.archiver.model.ClassificationHistory;
import com.github.lafarer.archiver.model.CustomFieldDef;
import com.github.lafarer.archiver.model.Document;
import com.github.lafarer.archiver.model.StoragePathRule;
import com.github.lafarer.archiver.model.enums.AnalysisStatus;
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
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class DocumentPipelineService {

    private final ArchiverProperties props;
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
    private final InboxEventService inboxEventService;
    private final DocumentStubService documentStubService;
    private final ObjectMapper objectMapper;

    // Second line of defense against duplicate processing (first is the watchdog debounce).
    // Tracks filenames currently running through the pipeline. putIfAbsent is atomic,
    // so concurrent calls for the same filename are safely rejected.
    private final Set<String> inFlight = ConcurrentHashMap.newKeySet();

    @EventListener(ApplicationReadyEvent.class)
    public void cleanupStaleAnalyzing() {
        documentRepository.deleteByAnalysisStatus(AnalysisStatus.ANALYZING);
    }

    // Creates the stub synchronously (hash + dedup + DB insert + SSE).
    // Returns the stub ID, or null if the file was a duplicate (and possibly deleted).
    // Called from the UI upload path so the stubs exist before the redirect fires.
    public Long createStubSync(Path file, ArchiveService.SourceType sourceType) throws IOException {
        String hash = sha256(file);
        var existing = documentRepository.findBySha256Hash(hash);
        if (existing.isPresent()) {
            log.info("Duplicate detected, skipping: {}", file.getFileName());
            if (sourceType == ArchiveService.SourceType.INBOX) {
                Document dup = existing.get();
                boolean isPendingSourceFile = !dup.isClassified()
                    && dup.getSourcePath() != null
                    && file.toAbsolutePath().equals(props.getInboxPath().resolve(dup.getSourcePath()).toAbsolutePath());
                if (!isPendingSourceFile) {
                    Files.deleteIfExists(file);
                    log.info("Removed duplicate from inbox: {}", file.getFileName());
                }
            }
            return null;
        }
        Long stubId = documentStubService.createStub(file, hash);
        inboxEventService.notifyInboxChanged();
        return stubId;
    }

    // Async analysis for an already-created stub. Must be called via the Spring proxy
    // (i.e. from another bean) for @Async to take effect.
    @Async
    public void analyzeFromStub(Long stubId, Path file, ArchiveService.SourceType sourceType) {
        try {
            Document doc = process(stubId, file, sourceType);
            if (doc != null && !doc.isClassified()) {
                inboxEventService.notifyInboxChanged();
            }
        } catch (Exception e) {
            log.error("Analysis failed for {}: {}", file.getFileName(), e.getMessage(), e);
            documentRepository.deleteById(stubId);
            inboxEventService.notifyInboxChanged();
        }
    }

    // Used by the watchdog - fully async (stub creation + analysis in the same thread).
    @Async
    public void processAsync(Path file, ArchiveService.SourceType sourceType) {
        String filename = file.getFileName().toString();
        // Reject if another thread is already processing this filename.
        // This is the safety net when the watchdog debounce is not tight enough.
        if (!inFlight.add(filename)) {
            log.info("Already in flight, skipping: {}", filename);
            return;
        }
        Long stubId = null;
        try {
            stubId = createStubSync(file, sourceType);
            if (stubId == null) return;
            Document doc = process(stubId, file, sourceType);
            if (doc != null && !doc.isClassified()) {
                inboxEventService.notifyInboxChanged();
            }
        } catch (Exception e) {
            log.error("Pipeline failed for {}: {}", file.getFileName(), e.getMessage(), e);
            if (stubId != null) {
                documentRepository.deleteById(stubId);
                inboxEventService.notifyInboxChanged();
            }
        } finally {
            // Always release the lock so the file can be reprocessed later if needed.
            inFlight.remove(filename);
        }
    }

    @Transactional
    public Document process(Long stubId, Path file, ArchiveService.SourceType sourceType) throws IOException {
        Document doc = documentRepository.findById(stubId)
            .orElseThrow(() -> new IllegalArgumentException("Stub not found: " + stubId));

        // Step 1 - pre-extraction
        ExtractionResult extraction = extractionService.extract(file);
        doc.setFilesystemMtime(extraction.filesystemMtime());

        // Step 2 - AI analysis (always called)
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
            ruleHints,
            null
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

        // Step 3 - populate document entity from analysis
        applyAnalysis(doc, analysis);
        doc.setAnalysisStatus(AnalysisStatus.COMPLETE);

        // Step 4 - resolve path
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
            doc = archiveAndFinalize(doc, file, resolved, sourceType);
        } else {
            // Leave in pending state for UI validation
            doc = documentRepository.save(doc);
            log.info("Document pending validation: {}", doc.getOriginalFilename());
        }

        return doc;
    }

    @Transactional
    public Document reanalyze(Long documentId, String hint) throws IOException {
        Document doc = documentRepository.findById(documentId)
            .orElseThrow(() -> new IllegalArgumentException("Document not found: " + documentId));

        Path file = doc.getSourcePath() != null
            ? props.getInboxPath().resolve(doc.getSourcePath())
            : props.getInboxPath().resolve(doc.getOriginalFilename());

        ExtractionResult extraction = extractionService.extract(file);

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
            file, extraction.fileType(), extraction.extractedText(),
            extraction.pdfMetadata(), extraction.filenameDateHint(),
            cfHints, typeHints, tagHints, ruleHints, hint
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

        doc.getCustomFields().clear();
        applyAnalysis(doc, analysis);

        ResolvedPath resolved = pathResolverService.resolve(
            analysis.appliedRuleId(),
            doc.getDocumentType(), doc.getDocumentDate(),
            doc.getTitle(), doc.getIssuer(), doc.getCustomFields()
        );
        doc.setResolvedPath(resolved.relativePath());
        doc.setAppliedRule(resolved.appliedRule());

        return documentRepository.save(doc);
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

        return archiveAndFinalize(doc, sourceFile, resolved, ArchiveService.SourceType.MANUAL);
    }

    private Document archiveAndFinalize(
        Document doc, Path sourceFile, ResolvedPath resolved,
        ArchiveService.SourceType sourceType
    ) throws IOException {
        String relPath = resolved.relativePath() + extension(sourceFile);
        Path archivedFile = archiveService.archive(sourceFile, relPath, sourceType);

        doc.setResolvedPath(relPath);
        sidecarService.write(archivedFile, doc);
        doc.setSidecarPath(props.getArchivePath().relativize(sidecarService.sidecarPathFor(archivedFile)).toString());
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

    @Transactional
    public void reclassify(Long documentId) throws IOException {
        Document doc = documentRepository.findById(documentId)
            .orElseThrow(() -> new IllegalArgumentException("Document not found: " + documentId));

        String oldRelPath = doc.getResolvedPath();
        Path oldFile = props.getArchivePath().resolve(oldRelPath);

        ResolvedPath resolved = pathResolverService.resolve(
            doc.getAppliedRule() != null ? doc.getAppliedRule().getId() : null,
            doc.getDocumentType(), doc.getDocumentDate(),
            doc.getTitle(), doc.getIssuer(), doc.getCustomFields()
        );
        String newRelPath = resolved.relativePath() + extension(oldFile);

        if (newRelPath.equals(oldRelPath)) {
            log.info("Document {} already at correct path, skipping reclassification", documentId);
            return;
        }

        Path newFile = archiveService.reclassify(oldFile, newRelPath);
        String actualNewRelPath = props.getArchivePath().relativize(newFile).toString();

        Path oldSidecar = sidecarService.sidecarPathFor(oldFile);
        if (Files.exists(oldSidecar)) {
            Path newSidecar = sidecarService.sidecarPathFor(newFile);
            Files.createDirectories(newSidecar.getParent());
            Files.move(oldSidecar, newSidecar, java.nio.file.StandardCopyOption.ATOMIC_MOVE);
            doc.setSidecarPath(props.getArchivePath().relativize(newSidecar).toString());
        }

        ClassificationHistory history = new ClassificationHistory();
        history.setDocument(doc);
        history.setOldPath(oldRelPath);
        history.setOldRule(doc.getAppliedRule());
        history.setNewPath(actualNewRelPath);
        history.setNewRule(resolved.appliedRule());
        history.setTrigger(ClassificationTrigger.RULE_CHANGE);
        historyRepository.save(history);

        doc.setResolvedPath(actualNewRelPath);
        doc.setAppliedRule(resolved.appliedRule());
        documentRepository.save(doc);

        log.info("Reclassified document {}: {} → {}", documentId, oldRelPath, actualNewRelPath);
    }

    @Transactional
    public Document reanalyzeArchived(Long documentId, String hint) throws IOException {
        Document doc = documentRepository.findById(documentId)
            .orElseThrow(() -> new IllegalArgumentException("Document not found: " + documentId));

        Path file = props.getArchivePath().resolve(doc.getResolvedPath());

        ExtractionResult extraction = extractionService.extract(file);

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
            file, extraction.fileType(), extraction.extractedText(),
            extraction.pdfMetadata(), extraction.filenameDateHint(),
            cfHints, typeHints, tagHints, ruleHints, hint
        );

        if (analysis.documentType() != null) {
            documentTypeService.autoRegister(
                analysis.documentType().slug(), analysis.documentType().label(), analysis.documentType().description()
            );
        }
        if (analysis.tags() != null) {
            analysis.tags().forEach(t -> tagService.autoRegister(t.slug(), t.label(), t.description()));
        }

        doc.getCustomFields().clear();
        applyAnalysis(doc, analysis);

        // Preserve current file location; update applied rule so proposedPath reflects new analysis
        ResolvedPath resolved = pathResolverService.resolve(
            analysis.appliedRuleId(),
            doc.getDocumentType(), doc.getDocumentDate(),
            doc.getTitle(), doc.getIssuer(), doc.getCustomFields()
        );
        doc.setAppliedRule(resolved.appliedRule());

        doc = documentRepository.save(doc);
        sidecarService.write(file, doc);

        log.info("Re-analyzed archived document {}: {}", documentId, doc.getOriginalFilename());
        return doc;
    }

    @Transactional
    public void refreshResolvedPath(Document doc) {
        ResolvedPath resolved = pathResolverService.resolve(
            doc.getAppliedRule() != null ? doc.getAppliedRule().getId() : null,
            doc.getDocumentType(), doc.getDocumentDate(),
            doc.getTitle(), doc.getIssuer(), doc.getCustomFields()
        );
        doc.setResolvedPath(resolved.relativePath());
        doc.setAppliedRule(resolved.appliedRule());
        documentRepository.save(doc);
    }

    public int applyRuleToAll(Long ruleId) throws IOException {
        List<Document> docs = documentRepository.findAllByAppliedRuleId(ruleId);
        int moved = 0;
        for (Document doc : docs) {
            String before = doc.getResolvedPath();
            reclassify(doc.getId());
            Document updated = documentRepository.findById(doc.getId()).orElse(doc);
            if (!updated.getResolvedPath().equals(before)) moved++;
        }
        log.info("Applied rule {}: {} document(s) moved", ruleId, moved);
        return moved;
    }

    public record ProposedPathParts(String full, String existing, String newPart) {}

    public ProposedPathParts proposedPath(Document doc) {
        ResolvedPath resolved = pathResolverService.resolve(
            doc.getAppliedRule() != null ? doc.getAppliedRule().getId() : null,
            doc.getDocumentType(), doc.getDocumentDate(),
            doc.getTitle(), doc.getIssuer(), doc.getCustomFields()
        );
        String full = resolved.relativePath() + extension(Path.of(doc.getOriginalFilename()));
        return splitProposedPath(full);
    }

    private ProposedPathParts splitProposedPath(String relPath) {
        String[] segments = relPath.split("/");
        Path current = props.getArchivePath();
        int existingCount = 0;
        // Walk directory segments (all but the last, which is the filename)
        for (int i = 0; i < segments.length - 1; i++) {
            Path next = current.resolve(segments[i]);
            if (Files.isDirectory(next)) {
                current = next;
                existingCount = i + 1;
            } else {
                break;
            }
        }
        String existing = existingCount > 0
            ? String.join("/", java.util.Arrays.copyOfRange(segments, 0, existingCount)) + "/"
            : "";
        String newPart = relPath.substring(existing.length());
        return new ProposedPathParts(relPath, existing, newPart);
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
        doc.setAiReasoning(a.reasoning());
        doc.setAiModel(settingService.get("ai_model"));

        if (a.customFields() != null) {
            Map<String, Object> prov = new LinkedHashMap<>();
            a.customFields().forEach((k, v) -> {
                doc.getCustomFields().put(k, v.value());
                prov.put(k, Map.of(
                    "source",     v.source() != null ? v.source() : "ai",
                    "confidence", v.confidence() != null ? v.confidence() : 0.0
                ));
            });
            try {
                doc.setCustomFieldsProvenance(objectMapper.writeValueAsString(prov));
            } catch (Exception e) {
                log.warn("Failed to serialize custom_fields_provenance: {}", e.getMessage());
            }
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
