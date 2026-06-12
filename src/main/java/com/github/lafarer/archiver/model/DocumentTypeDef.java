package com.github.lafarer.archiver.model;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "document_type_def")
@Getter @Setter @NoArgsConstructor
public class DocumentTypeDef {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false, length = 80)
    private String slug;

    @Column(nullable = false)
    private String label;

    @Column(columnDefinition = "TEXT")
    private String description;

    private boolean enabled = true;

    public DocumentTypeDef(String slug, String label, String description) {
        this.slug = slug;
        this.label = label;
        this.description = description;
    }
}
