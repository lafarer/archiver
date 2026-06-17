package com.github.lafarer.archiver.repository;

import com.github.lafarer.archiver.model.Document;
import org.springframework.data.jpa.domain.Specification;

import java.util.List;

public class DocumentSpecs {

    public static Specification<Document> classified() {
        return (root, query, cb) -> cb.isTrue(root.get("classified"));
    }

    public static Specification<Document> queryMatches(String q) {
        return (root, query, cb) -> {
            String pattern = "%" + q.toLowerCase() + "%";
            return cb.or(
                cb.like(cb.lower(root.get("title")), pattern),
                cb.like(cb.lower(root.get("issuer")), pattern),
                cb.like(cb.lower(root.get("documentType")), pattern)
            );
        };
    }

    public static Specification<Document> hasType(String type) {
        return (root, query, cb) -> cb.equal(root.get("documentType"), type);
    }

    public static Specification<Document> issuerContains(String issuer) {
        return (root, query, cb) ->
            cb.like(cb.lower(root.get("issuer")), "%" + issuer.toLowerCase() + "%");
    }

    // Tags are stored as a JSON array string e.g. ["eau","logement"].
    // Matching "%\"tag\"%" is safe for slugified tag values.
    public static Specification<Document> hasAnyTag(List<String> tags) {
        return (root, query, cb) -> {
            var predicates = tags.stream()
                .map(tag -> cb.like(root.<String>get("tags"), "%\"" + tag + "\"%"))
                .toArray(jakarta.persistence.criteria.Predicate[]::new);
            return cb.or(predicates);
        };
    }

    // Custom fields are stored as JSON e.g. {"adresse_bien":"Paris"}.
    // Uses SQLite json_extract via cb.function() for a LIKE match.
    public static Specification<Document> hasCustomField(String slug, String value) {
        return (root, query, cb) -> {
            var jsonExtract = cb.function("json_extract", String.class,
                root.get("customFields"), cb.literal("$." + slug));
            return cb.like(cb.lower(jsonExtract), "%" + value.toLowerCase() + "%");
        };
    }
}
