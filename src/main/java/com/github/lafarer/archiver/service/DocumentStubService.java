package com.github.lafarer.archiver.service;

import com.github.lafarer.archiver.config.ArchiverProperties;
import com.github.lafarer.archiver.model.Document;
import com.github.lafarer.archiver.model.enums.AnalysisStatus;
import com.github.lafarer.archiver.repository.DocumentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;

@Service
@RequiredArgsConstructor
public class DocumentStubService {

    private final DocumentRepository documentRepository;
    private final ArchiverProperties props;

    @Transactional
    public Long createStub(Path file, String hash) throws IOException {
        Document stub = new Document();
        stub.setOriginalFilename(file.getFileName().toString());
        stub.setSourcePath(props.getInboxPath().relativize(file.toAbsolutePath()).toString());
        stub.setSha256Hash(hash);
        String mimeType = Files.probeContentType(file);
        stub.setMimeType(mimeType != null ? mimeType : "application/octet-stream");
        stub.setFileSizeBytes(Files.size(file));
        stub.setFilesystemMtime(Files.getLastModifiedTime(file).toInstant());
        stub.setAnalysisStatus(AnalysisStatus.ANALYZING);
        return documentRepository.save(stub).getId();
    }
}
