package com.github.lafarer.archiver.service;

import com.github.lafarer.archiver.model.enums.DocumentFileType;
import lombok.extern.slf4j.Slf4j;
import org.apache.pdfbox.Loader;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDDocumentInformation;
import org.apache.pdfbox.text.PDFTextStripper;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.attribute.BasicFileAttributes;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
@Slf4j
public class ExtractionService {

    private static final int NATIVE_PDF_TEXT_THRESHOLD = 100;

    private static final Pattern[] DATE_PATTERNS = {
        Pattern.compile("(\\d{4})-(\\d{2})-(\\d{2})"),  // 2024-03-15
        Pattern.compile("(\\d{2})\\.(\\d{2})\\.(\\d{4})"), // 15.03.2024
        Pattern.compile("(\\d{2})-(\\d{2})-(\\d{4})"),  // 15-03-2024
        Pattern.compile("(\\d{4})(\\d{2})(\\d{2})"),    // 20240315
        Pattern.compile("(\\d{4})-(\\d{2})"),            // 2024-03
        Pattern.compile("(\\d{4})"),                     // 2024
    };

    public record ExtractionResult(
        DocumentFileType fileType,
        String extractedText,
        Map<String, String> pdfMetadata,
        String filenameDateHint,
        Instant filesystemMtime
    ) {}

    public ExtractionResult extract(Path file) {
        String mimeType = detectMimeType(file);
        Instant mtime = getFilesystemMtime(file);
        String filenameDateHint = parseDateFromFilename(file.getFileName().toString());

        if (mimeType.equals("application/pdf")) {
            return extractPdf(file, filenameDateHint, mtime);
        } else {
            return new ExtractionResult(DocumentFileType.IMAGE, null, null, filenameDateHint, mtime);
        }
    }

    private ExtractionResult extractPdf(Path file, String filenameDateHint, Instant mtime) {
        try (PDDocument doc = Loader.loadPDF(file.toFile())) {
            String text = new PDFTextStripper().getText(doc);
            Map<String, String> metadata = extractPdfMetadata(doc.getDocumentInformation());
            boolean isNative = text != null && text.strip().length() > NATIVE_PDF_TEXT_THRESHOLD;
            DocumentFileType type = isNative ? DocumentFileType.NATIVE_PDF : DocumentFileType.SCANNED_PDF;
            return new ExtractionResult(type, isNative ? text : null, metadata, filenameDateHint, mtime);
        } catch (IOException e) {
            log.warn("PDF extraction failed for {}: {}", file.getFileName(), e.getMessage());
            return new ExtractionResult(DocumentFileType.SCANNED_PDF, null, null, filenameDateHint, mtime);
        }
    }

    private Map<String, String> extractPdfMetadata(PDDocumentInformation info) {
        Map<String, String> meta = new HashMap<>();
        if (info.getTitle()    != null) meta.put("Title",    info.getTitle());
        if (info.getAuthor()   != null) meta.put("Author",   info.getAuthor());
        if (info.getSubject()  != null) meta.put("Subject",  info.getSubject());
        if (info.getKeywords() != null) meta.put("Keywords", info.getKeywords());
        if (info.getCreator()  != null) meta.put("Creator",  info.getCreator());
        if (info.getProducer() != null) meta.put("Producer", info.getProducer());
        try {
            if (info.getCreationDate() != null)
                meta.put("CreationDate", info.getCreationDate().toInstant().toString());
            if (info.getModificationDate() != null)
                meta.put("ModDate", info.getModificationDate().toInstant().toString());
        } catch (Exception ignored) {}
        return meta;
    }

    public String parseDateFromFilename(String filename) {
        for (Pattern p : DATE_PATTERNS) {
            Matcher m = p.matcher(filename);
            if (m.find()) return m.group();
        }
        return null;
    }

    private String detectMimeType(Path file) {
        try {
            String probe = Files.probeContentType(file);
            if (probe != null) return probe;
        } catch (IOException ignored) {}
        String name = file.getFileName().toString().toLowerCase();
        if (name.endsWith(".pdf")) return "application/pdf";
        if (name.endsWith(".jpg") || name.endsWith(".jpeg")) return "image/jpeg";
        if (name.endsWith(".png"))  return "image/png";
        if (name.endsWith(".tiff") || name.endsWith(".tif")) return "image/tiff";
        return "application/octet-stream";
    }

    private Instant getFilesystemMtime(Path file) {
        try {
            return Files.readAttributes(file, BasicFileAttributes.class).lastModifiedTime().toInstant();
        } catch (IOException e) {
            return Instant.now();
        }
    }
}
