package com.github.lafarer.archiver.model;

import com.github.lafarer.archiver.model.converter.StringListConverter;
import com.github.lafarer.archiver.model.converter.StringMapConverter;
import com.github.lafarer.archiver.model.enums.AnalysisStatus;
import com.github.lafarer.archiver.model.enums.DatePrecision;
import com.github.lafarer.archiver.model.enums.FieldSource;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Entity
@Table(name = "document")
@Getter @Setter
public class Document {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    // Analysis fields
    @Column(name = "document_type")
    private String documentType;

    private String title;

    @Enumerated(EnumType.STRING)
    @Column(name = "title_source")
    private FieldSource titleSource;

    @Column(name = "title_confidence")
    private Double titleConfidence;

    @Column(name = "document_date")
    private String documentDate; // "2024", "2024-03", "2024-03-15"

    @Enumerated(EnumType.STRING)
    @Column(name = "document_date_precision")
    private DatePrecision documentDatePrecision;

    @Enumerated(EnumType.STRING)
    @Column(name = "document_date_source")
    private FieldSource documentDateSource;

    @Column(name = "document_date_confidence")
    private Double documentDateConfidence;

    private String issuer;

    @Enumerated(EnumType.STRING)
    @Column(name = "issuer_source")
    private FieldSource issuerSource;

    @Column(name = "issuer_confidence")
    private Double issuerConfidence;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "ai_reasoning", columnDefinition = "TEXT")
    private String aiReasoning;

    @Column(name = "ai_model")
    private String aiModel;

    @Column(name = "custom_fields_provenance", columnDefinition = "TEXT")
    private String customFieldsProvenance = "{}";

    @Convert(converter = StringListConverter.class)
    @Column(columnDefinition = "TEXT")
    private List<String> tags = new ArrayList<>();

    @Convert(converter = StringMapConverter.class)
    @Column(name = "custom_fields", columnDefinition = "TEXT")
    private Map<String, String> customFields = new HashMap<>();

    // File info
    @Column(name = "original_filename", nullable = false)
    private String originalFilename;

    @Column(name = "source_path")
    private String sourcePath;

    @Column(name = "sha256_hash", unique = true, nullable = false)
    private String sha256Hash;

    @Column(name = "mime_type", nullable = false)
    private String mimeType;

    @Column(name = "file_size_bytes")
    private Long fileSizeBytes;

    @Column(name = "filesystem_mtime")
    private Instant filesystemMtime;

    // Classification
    @Column(name = "resolved_path")
    private String resolvedPath;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "applied_rule_id")
    private StoragePathRule appliedRule;

    @Column(name = "is_classified", nullable = false)
    private boolean classified = false;

    @Column(name = "classified_at")
    private Instant classifiedAt;

    @Column(name = "sidecar_path")
    private String sidecarPath;

    @Enumerated(EnumType.STRING)
    @Column(name = "analysis_status", nullable = false)
    private AnalysisStatus analysisStatus = AnalysisStatus.COMPLETE;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private Instant updatedAt;
}
