@import com.github.lafarer.archiver.model.StoragePathRule

@param StoragePathRule rule
@param String page

@template.layout.base(page = page, title = "Règle", content = @`

<div class="page-header">
    <h1>${rule.getId() == null ? "Nouvelle règle" : "Modifier la règle"}</h1>
</div>

<div class="page-body">
    <div class="card" style="max-width: 640px">
        <div class="card-body">
            <form method="post" action="${rule.getId() == null ? "/rules" : "/rules/" + rule.getId()}">

                <div class="mb-3">
                    <label class="form-label fw-semibold">Label</label>
                    <input type="text" name="label" class="form-control"
                           value="${rule.getLabel() != null ? rule.getLabel() : ""}" required>
                </div>

                <div class="mb-3">
                    <label class="form-label fw-semibold">Priorité</label>
                    <input type="number" name="priority" class="form-control"
                           value="${rule.getPriority()}" min="1">
                </div>

                <div class="mb-3">
                    <label class="form-label fw-semibold">Condition <small class="text-muted">(langage naturel)</small></label>
                    <textarea name="conditionNl" class="form-control" rows="2"
                              placeholder="ex: La catégorie est assurance et ne concerne pas un véhicule"
                    >${rule.getConditionNl() != null ? rule.getConditionNl() : ""}</textarea>
                    <div class="form-text">Laisser vide pour une règle inconditionnelle (par défaut).</div>
                </div>

                <div class="mb-3">
                    <label class="form-label fw-semibold">Template de chemin</label>
                    <input type="text" name="pathTemplate" class="form-control font-monospace"
                           value="${rule.getPathTemplate() != null ? rule.getPathTemplate() : ""}"
                           placeholder="ex: Assurances/[issuer]-[numero_contrat]/[yyyy]/[yyyy]-[mm]-[dd]-[title]"
                           required>
                    <div class="form-text">Variables : [title] [yyyy] [mm] [dd] [document_type] [issuer] [&lt;custom_field&gt;]</div>
                </div>

                <div class="mb-4">
                    <div class="form-check">
                        <input class="form-check-input" type="checkbox" name="isDefault"
                               value="true" id="isDefault" checked="${rule.isDefault()}">
                        <label class="form-check-label" for="isDefault">Règle par défaut</label>
                    </div>
                </div>

                <div class="d-flex gap-2">
                    <button type="submit" class="btn btn-primary">Enregistrer</button>
                    <a href="/rules" class="btn btn-outline-secondary">Annuler</a>
                </div>

            </form>
        </div>
    </div>
</div>

`)
