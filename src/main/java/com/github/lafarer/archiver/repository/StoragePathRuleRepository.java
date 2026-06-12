package com.github.lafarer.archiver.repository;

import com.github.lafarer.archiver.model.StoragePathRule;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface StoragePathRuleRepository extends JpaRepository<StoragePathRule, Long> {

    List<StoragePathRule> findByActiveTrueOrderByPriorityAsc();

    Optional<StoragePathRule> findByIsDefaultTrue();

    boolean existsByIsDefaultTrue();
}
