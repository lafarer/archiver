package com.github.lafarer.archiver.service;

import com.github.lafarer.archiver.model.StoragePathRule;
import com.github.lafarer.archiver.repository.StoragePathRuleRepository;
import com.github.slugify.Slugify;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
@RequiredArgsConstructor
@Slf4j
public class PathResolverService {

    private final StoragePathRuleRepository ruleRepository;
    private static final Slugify SLUGIFY = Slugify.builder().build();
    // [var?]sep — optional variable: if absent, var and following separator are omitted
    private static final Pattern OPT_VARIABLE = Pattern.compile("\\[(\\w+)\\?]([-/._]?)");
    // [var] — required variable: if absent, replaced by '_inconnu'
    private static final Pattern REQ_VARIABLE = Pattern.compile("\\[(\\w+)]");

    public record ResolvedPath(String relativePath, StoragePathRule appliedRule) {}

    private static final String FALLBACK_TEMPLATE = "Documents/[yyyy]/[mm]/[document_type]-[title]";

    public ResolvedPath resolve(
        Long aiSelectedRuleId,
        String documentType,
        String documentDate,
        String title,
        String issuer,
        Map<String, String> customFields
    ) {
        StoragePathRule rule = selectRule(aiSelectedRuleId);
        String template = rule != null ? rule.getPathTemplate() : FALLBACK_TEMPLATE;
        String path = renderTemplate(template, documentType, documentDate, title, issuer, customFields);
        return new ResolvedPath(path, rule);  // rule may be null — Document.appliedRule is nullable
    }

    private StoragePathRule selectRule(Long aiSelectedRuleId) {
        if (aiSelectedRuleId != null) {
            return ruleRepository.findById(aiSelectedRuleId).orElseGet(this::defaultRule);
        }
        return defaultRule();
    }

    private StoragePathRule defaultRule() {
        return ruleRepository.findByIsDefaultTrue().orElse(null);
    }

    private String renderTemplate(
        String template,
        String documentType,
        String documentDate,
        String title,
        String issuer,
        Map<String, String> customFields
    ) {
        String yyyy = parseYear(documentDate);
        String mm   = parseMonth(documentDate);
        String dd   = parseDay(documentDate);

        Map<String, String> vars = new java.util.HashMap<>(customFields != null ? customFields : Map.of());
        vars.put("document_type", slug(documentType, "_inconnu"));
        vars.put("title",         slug(title, "_inconnu"));
        vars.put("issuer",        slug(issuer, "_inconnu"));
        vars.put("yyyy",          yyyy);
        vars.put("mm",            mm);
        vars.put("dd",            dd);

        // Pass 1 — optional variables: [var?]sep → "value+sep" or "" when absent
        Matcher optM = OPT_VARIABLE.matcher(template);
        StringBuffer pass1 = new StringBuffer();
        while (optM.find()) {
            String key = optM.group(1);
            String sep = optM.group(2);
            String value = vars.get(key);
            if (value != null && !value.isBlank()) {
                optM.appendReplacement(pass1, Matcher.quoteReplacement(slug(value, "") + sep));
            } else {
                optM.appendReplacement(pass1, "");
            }
        }
        optM.appendTail(pass1);

        // Pass 2 — required variables: [var] → value or "_inconnu"
        Matcher reqM = REQ_VARIABLE.matcher(pass1);
        StringBuilder pass2 = new StringBuilder();
        while (reqM.find()) {
            String key = reqM.group(1);
            String value = vars.getOrDefault(key, null);
            if (value == null) {
                log.warn("Path template variable [{}] not resolved — using '_inconnu'", key);
                value = "_inconnu";
            }
            reqM.appendReplacement(pass2, Matcher.quoteReplacement(slug(value, "_inconnu")));
        }
        reqM.appendTail(pass2);
        return pass2.toString();
    }

    private String slug(String value, String fallback) {
        if (value == null || value.isBlank()) return fallback;
        String s = SLUGIFY.slugify(value);
        return s.isBlank() ? fallback : s;
    }

    private String parseYear(String date) {
        return (date != null && date.length() >= 4) ? date.substring(0, 4) : "_";
    }

    private String parseMonth(String date) {
        return (date != null && date.length() >= 7) ? date.substring(5, 7) : "_";
    }

    private String parseDay(String date) {
        return (date != null && date.length() == 10) ? date.substring(8, 10) : "_";
    }
}
