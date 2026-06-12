package com.github.lafarer.archiver.repository;

import com.github.lafarer.archiver.model.ClassificationHistory;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ClassificationHistoryRepository extends JpaRepository<ClassificationHistory, Long> {

    List<ClassificationHistory> findByDocumentIdOrderByCreatedAtDesc(Long documentId);
}
