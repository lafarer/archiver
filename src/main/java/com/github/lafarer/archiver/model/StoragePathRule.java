package com.github.lafarer.archiver.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;

@Entity
@Table(name = "storage_path_rule")
@Getter @Setter
public class StoragePathRule {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private short priority;

    @Column(nullable = false)
    private String label;

    // Natural language condition interpreted by AI. Null means unconditional (default rule).
    @Column(name = "condition_nl", columnDefinition = "TEXT")
    private String conditionNl;

    @Column(name = "path_template", nullable = false, length = 1024)
    private String pathTemplate;

    @Column(name = "is_default", nullable = false)
    private boolean isDefault = false;

    @Column(name = "is_active", nullable = false)
    private boolean active = true;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private Instant updatedAt;
}
