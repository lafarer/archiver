package com.github.lafarer.archiver.repository;

import com.github.lafarer.archiver.model.CustomFieldDef;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface CustomFieldDefRepository extends JpaRepository<CustomFieldDef, Long> {

    Optional<CustomFieldDef> findByName(String name);

    boolean existsByName(String name);
}
