package com.github.lafarer.archiver.service;

import com.github.lafarer.archiver.model.DocumentTypeDef;
import com.github.lafarer.archiver.repository.DocumentTypeDefRepository;
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
public class DocumentTypeService {

    private final DocumentTypeDefRepository repository;

    private static final List<DocumentTypeDef> DEFAULTS = List.of(
        // Finances
        new DocumentTypeDef("facture",           "Facture",                    "Facture commerciale pour l'achat de biens ou services. Contient un numéro de facture, une date, un montant TTC et un émetteur."),
        new DocumentTypeDef("releve-bancaire",   "Relevé bancaire",            "Relevé de compte bancaire ou d'épargne listant les opérations débit/crédit sur une période."),
        new DocumentTypeDef("virement",          "Avis de virement",           "Confirmation d'un virement bancaire entrant ou sortant."),
        new DocumentTypeDef("recu",              "Reçu / Ticket de caisse",    "Justificatif de paiement, ticket de caisse ou reçu émis par un commerçant."),
        new DocumentTypeDef("quittance",         "Quittance",                  "Quittance de loyer ou de paiement attestant la réception d'un règlement."),
        new DocumentTypeDef("devis",             "Devis",                      "Proposition commerciale détaillant prestations et prix avant commande."),
        new DocumentTypeDef("bon-de-commande",   "Bon de commande",            "Document formalisant une commande de biens ou services auprès d'un fournisseur."),
        new DocumentTypeDef("avoir",             "Avoir / Note de crédit",     "Note de crédit émise par un fournisseur, remboursement partiel ou total d'une facture."),
        // Impôts & administration
        new DocumentTypeDef("avis-imposition",       "Avis d'imposition",           "Avis d'imposition sur le revenu émis par les impôts. Contient le montant à payer et le revenu fiscal de référence."),
        new DocumentTypeDef("declaration-impots",    "Déclaration de revenus",      "Formulaire de déclaration annuelle des revenus (2042, 2044…)."),
        new DocumentTypeDef("taxe-fonciere",         "Taxe foncière",               "Avis de taxe foncière pour un bien immobilier."),
        new DocumentTypeDef("taxe-habitation",       "Taxe d'habitation",           "Avis de taxe d'habitation pour une résidence."),
        new DocumentTypeDef("courrier-administratif","Courrier administratif",       "Courrier officiel d'un organisme public (CAF, CPAM, Pôle Emploi, mairie, préfecture…)."),
        new DocumentTypeDef("formulaire",            "Formulaire administratif",    "Formulaire à remplir ou déjà complété (Cerfa, demande de prestation…)."),
        // Contrats & assurances
        new DocumentTypeDef("contrat",               "Contrat",                     "Contrat entre deux parties (service, abonnement, location…)."),
        new DocumentTypeDef("avenant",               "Avenant",                     "Modification ou complément à un contrat existant."),
        new DocumentTypeDef("attestation-assurance", "Attestation d'assurance",     "Attestation prouvant la souscription d'une assurance (auto, habitation, RC…)."),
        new DocumentTypeDef("police-assurance",      "Police d'assurance",          "Contrat d'assurance complet détaillant les garanties, franchises et cotisations."),
        new DocumentTypeDef("resiliation",           "Résiliation",                 "Lettre ou confirmation de résiliation d'un contrat ou abonnement."),
        new DocumentTypeDef("garantie",              "Garantie",                    "Certificat ou bon de garantie pour un appareil ou produit acheté."),
        // Santé
        new DocumentTypeDef("ordonnance",            "Ordonnance médicale",         "Prescription médicale d'un médecin pour des médicaments ou actes médicaux."),
        new DocumentTypeDef("compte-rendu-medical",  "Compte rendu médical",        "Compte rendu de consultation, d'hospitalisation ou d'examen médical (radio, scanner…)."),
        new DocumentTypeDef("remboursement-sante",   "Remboursement santé",         "Décompte de remboursement de l'Assurance Maladie (CPAM) ou d'une mutuelle."),
        new DocumentTypeDef("mutuelle",              "Mutuelle / Complémentaire",   "Contrat ou attestation de complémentaire santé (mutuelle)."),
        new DocumentTypeDef("vaccination",           "Carnet de vaccination",       "Attestation ou carnet de vaccination."),
        new DocumentTypeDef("analyse",               "Résultats d'analyse",         "Résultats d'analyses biologiques, radiologiques ou autres examens."),
        // Emploi & revenus
        new DocumentTypeDef("fiche-de-paie",         "Fiche de paie",               "Bulletin de salaire mensuel. Contient salaire brut, cotisations, net à payer, IBAN et informations employeur."),
        new DocumentTypeDef("contrat-travail",       "Contrat de travail",          "Contrat d'embauche (CDI, CDD, apprentissage…)."),
        new DocumentTypeDef("rupture-contrat",       "Rupture de contrat",          "Lettre ou solde de tout compte lié à une rupture conventionnelle, démission ou licenciement."),
        new DocumentTypeDef("attestation-emploi",    "Attestation d'emploi",        "Certificat de travail ou attestation employeur prouvant une activité salariée."),
        new DocumentTypeDef("attestation-chomage",   "Attestation chômage",         "Attestation d'ouverture de droits ou de versement d'allocations chômage (France Travail)."),
        new DocumentTypeDef("bilan-formation",       "Formation / Certification",   "Attestation de formation professionnelle, bilan de compétences ou certification."),
        // Logement
        new DocumentTypeDef("bail",                  "Bail / Contrat de location",  "Contrat de location d'un logement ou local commercial."),
        new DocumentTypeDef("etat-des-lieux",        "État des lieux",              "État des lieux d'entrée ou de sortie d'un logement loué."),
        new DocumentTypeDef("quittance-loyer",       "Quittance de loyer",          "Reçu mensuel confirmant le paiement du loyer par le locataire."),
        new DocumentTypeDef("acte-vente",            "Acte de vente immobilier",    "Acte notarié formalisant la vente ou l'achat d'un bien immobilier."),
        new DocumentTypeDef("diagnostic",            "Diagnostic immobilier",       "Rapport de diagnostic technique (DPE, amiante, électricité, plomb…)."),
        new DocumentTypeDef("permis-construire",     "Permis de construire",        "Autorisation administrative pour des travaux ou constructions."),
        new DocumentTypeDef("pv-assemblee",          "PV d'assemblée générale",     "Procès-verbal d'assemblée générale de copropriété."),
        // Identité & famille
        new DocumentTypeDef("identite",              "Carte d'identité",            "Document officiel d'identité nationale ou titre de séjour."),
        new DocumentTypeDef("passeport",             "Passeport",                   "Passeport ou document de voyage officiel."),
        new DocumentTypeDef("diplome",               "Diplôme / Attestation scolaire","Diplôme officiel (bac, licence, master…) ou relevé de notes."),
        new DocumentTypeDef("acte-naissance",        "Acte de naissance",           "Acte d'état civil certifiant une naissance."),
        new DocumentTypeDef("acte-mariage",          "Acte de mariage / PACS",      "Acte d'état civil certifiant un mariage ou un PACS."),
        new DocumentTypeDef("livret-famille",        "Livret de famille",           "Document officiel récapitulant l'état civil d'une famille."),
        new DocumentTypeDef("jugement",              "Jugement / Décision de justice","Décision ou jugement rendu par un tribunal ou une autorité administrative."),
        // Véhicule
        new DocumentTypeDef("carte-grise",           "Carte grise",                 "Certificat d'immatriculation d'un véhicule."),
        new DocumentTypeDef("controle-technique",    "Contrôle technique",          "Rapport de contrôle technique périodique d'un véhicule."),
        new DocumentTypeDef("assurance-auto",        "Assurance automobile",        "Contrat ou attestation d'assurance pour un véhicule."),
        new DocumentTypeDef("facture-reparation",    "Facture de réparation",       "Facture d'un garage ou prestataire pour l'entretien ou la réparation d'un véhicule.")
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

    public List<DocumentTypeDef> findAll() {
        return repository.findAllByOrderByLabelAsc();
    }

    public List<DocumentTypeDef> findEnabled() {
        return repository.findByEnabledTrueOrderByLabelAsc();
    }

    @Transactional
    public void autoRegister(String slug, String label, String description) {
        if (slug == null || repository.findBySlug(slug).isPresent()) return;
        DocumentTypeDef def = new DocumentTypeDef(
            slug,
            label != null && !label.isBlank() ? label : slug,
            description
        );
        repository.save(def);
        log.info("Auto-registered new document type from AI: {}", slug);
    }
}
