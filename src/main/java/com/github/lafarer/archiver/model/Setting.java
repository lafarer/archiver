package com.github.lafarer.archiver.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Table(name = "setting")
@Getter @Setter
@NoArgsConstructor
@AllArgsConstructor
public class Setting {

    @Id
    @Column(length = 80)
    private String key;

    @Column(nullable = false, columnDefinition = "TEXT")
    private String value;
}
