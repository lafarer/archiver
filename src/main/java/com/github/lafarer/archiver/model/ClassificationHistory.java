package com.github.lafarer.archiver.model;

import com.github.lafarer.archiver.model.enums.ClassificationTrigger;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;

@Entity
@Table(name = "classification_history")
@Getter @Setter
public class ClassificationHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "document_id")
    private Document document;

    @Column(name = "old_path")
    private String oldPath; // null on first classification

    @Column(name = "new_path", nullable = false)
    private String newPath;

    // SET NULL on delete — history preserved when rules are deleted
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "old_rule_id", foreignKey = @ForeignKey(name = "fk_history_old_rule"))
    private StoragePathRule oldRule;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "new_rule_id", foreignKey = @ForeignKey(name = "fk_history_new_rule"))
    private StoragePathRule newRule;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ClassificationTrigger trigger;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "triggering_rule_change_id", foreignKey = @ForeignKey(name = "fk_history_triggering_rule"))
    private StoragePathRule triggeringRuleChange;

    @Column(columnDefinition = "TEXT")
    private String notes;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private Instant createdAt;
}
