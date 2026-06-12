package com.github.lafarer.archiver.model;

import com.github.lafarer.archiver.model.enums.FieldType;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "custom_field_def")
@Getter @Setter
public class CustomFieldDef {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(unique = true, nullable = false, length = 80)
    private String slug; // used in path templates, e.g. "numero_contrat"

    @Column(nullable = false)
    private String label;

    @Column(columnDefinition = "TEXT", nullable = false)
    private String description; // sent to AI to determine applicability

    @Enumerated(EnumType.STRING)
    @Column(name = "field_type", nullable = false)
    private FieldType fieldType = FieldType.TEXT;
}
