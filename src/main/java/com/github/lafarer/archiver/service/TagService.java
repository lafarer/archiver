package com.github.lafarer.archiver.service;

import com.github.lafarer.archiver.model.TagDef;
import com.github.lafarer.archiver.repository.TagDefRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class TagService {

    private final TagDefRepository repository;

    private static final List<TagDef> DEFAULTS = List.of(
        // Énergie & logement
        new TagDef("eau",          "Eau",                   "Factures et contrats liés à la consommation d'eau."),
        new TagDef("electricite",  "Électricité",           "Factures et contrats d'électricité."),
        new TagDef("gaz",          "Gaz",                   "Factures et contrats de gaz."),
        new TagDef("internet",     "Internet / Box",        "Factures et contrats internet ou téléphone fixe."),
        new TagDef("telephone",    "Téléphone mobile",      "Factures et contrats de téléphonie mobile."),
        new TagDef("logement",     "Logement",              "Documents liés à l'habitation : loyer, charges, copropriété."),
        // Travaux & équipement
        new TagDef("travaux",      "Travaux",               "Devis, factures et autorisations de travaux ou rénovation."),
        new TagDef("entretien",    "Entretien",             "Contrats et factures d'entretien (chaudière, climatisation, ascenseur…)."),
        new TagDef("reparation",   "Réparation",            "Factures de réparation d'appareils, véhicules ou équipements."),
        new TagDef("electromenager","Électroménager",       "Documents liés aux appareils électroménagers (achat, garantie, réparation)."),
        new TagDef("electronique", "Électronique",          "Documents liés aux appareils électroniques (ordinateur, téléphone, TV…)."),
        new TagDef("mobilier",     "Mobilier",              "Documents liés aux meubles et à la décoration intérieure."),
        new TagDef("outillage",    "Outillage",             "Documents liés aux outils, machines et matériel de bricolage."),
        // Véhicule
        new TagDef("vehicule",     "Véhicule",              "Documents liés aux véhicules : voiture, moto, vélo, scooter."),
        // Finances
        new TagDef("banque",       "Banque",                "Relevés, virements, prélèvements et documents bancaires."),
        new TagDef("impots",       "Impôts",                "Déclarations, avis d'imposition et documents fiscaux."),
        new TagDef("assurance",    "Assurance",             "Contrats, attestations, cotisations et remboursements d'assurance."),
        new TagDef("credit",       "Crédit / Prêt",         "Contrats de prêt immobilier ou à la consommation, tableaux d'amortissement."),
        new TagDef("epargne",      "Épargne / Investissement","Relevés de comptes d'épargne, PEA, assurance-vie, livrets."),
        // Santé
        new TagDef("sante",        "Santé",                 "Documents médicaux : ordonnances, comptes rendus, bilans, analyses."),
        new TagDef("mutuelle",     "Mutuelle",              "Documents de complémentaire santé : contrats, décomptes, attestations."),
        // Famille & administration
        new TagDef("famille",      "Famille",               "Documents d'état civil et actes familiaux (naissance, mariage, divorce…)."),
        new TagDef("juridique",    "Juridique",             "Contrats, jugements, décisions de justice et documents légaux."),
        new TagDef("administratif","Administratif",         "Courriers et formulaires d'organismes publics (CAF, CPAM, mairie…)."),
        new TagDef("sinistre",     "Sinistre",              "Documents liés à un sinistre : déclaration, expertise, remboursement assurance."),
        // Loisirs & autres
        new TagDef("voyage",       "Voyage",                "Billets, réservations, hébergements et documents de voyage."),
        new TagDef("abonnement",   "Abonnement",            "Contrats et factures d'abonnements divers (streaming, sport, presse…).")
    );

    @EventListener(ApplicationReadyEvent.class)
    @Transactional
    public void seedDefaults() {
        DEFAULTS.forEach(def -> {
            if (repository.findBySlug(def.getSlug()).isEmpty()) {
                repository.save(def);
            }
        });
    }

    public List<TagDef> findAll() {
        return repository.findAllByOrderByLabelAsc();
    }

    public List<TagDef> findEnabled() {
        return repository.findByEnabledTrueOrderByLabelAsc();
    }

    @Transactional
    public void autoRegister(String slug, String label, String description) {
        if (slug == null || repository.findBySlug(slug).isPresent()) return;
        TagDef def = new TagDef(
            slug,
            label != null && !label.isBlank() ? label : slug,
            description
        );
        repository.save(def);
        log.info("Auto-registered new tag from AI: {}", slug);
    }
}
