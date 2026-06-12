package com.github.lafarer.archiver.repository;

import com.github.lafarer.archiver.model.Setting;
import org.springframework.data.jpa.repository.JpaRepository;

public interface SettingRepository extends JpaRepository<Setting, String> {
}
