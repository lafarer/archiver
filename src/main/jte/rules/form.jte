@import com.github.lafarer.archiver.model.StoragePathRule
@import com.github.lafarer.archiver.model.Document
@import com.github.lafarer.archiver.web.RulesController.SimulateResult
@import org.springframework.data.domain.Page
@import java.util.List

@param StoragePathRule rule
@param Page<Document> docPage
@param List<SimulateResult> results
@param String pathTemplate
@param long outOfSyncCount = 0
@param StoragePathRule existingDefault = null
@param String page
@param String message = null
@param boolean watchdogRunning = false

@template.layout.base(page = page, title = "Règle", watchdogRunning = watchdogRunning, content = @`

<div class="page-header">
    <h1>${rule.getId() == null ? "Nouvelle règle" : "Modifier la règle"}</h1>
</div>

<div class="page-body">

    @if(message != null)
    <div class="alert alert-success alert-dismissible fade show" role="alert" style="max-width: 640px">
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
    @endif

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
                    @if(existingDefault != null)
                    <div id="defaultWarning" class="form-text text-warning mt-1" style="display:none">
                        ⚠ Remplacera <strong>${existingDefault.getLabel()}</strong> comme règle par défaut.
                    </div>
                    <script>
                    (function() {
                        var cb = document.getElementById('isDefault');
                        var warn = document.getElementById('defaultWarning');
                        function update() { warn.style.display = cb.checked ? '' : 'none'; }
                        cb.addEventListener('change', update);
                        update();
                    })();
                    </script>
                    @endif
                </div>

                <div class="d-flex gap-2">
                    <button type="submit" class="btn btn-primary">Enregistrer</button>
                    <a href="/rules" class="btn btn-outline-secondary">Annuler</a>
                </div>

            </form>
        </div>
    </div>

    @if(rule.getId() != null)
    <div class="card mt-4" style="max-width: 640px">
        <div class="card-header fw-semibold d-flex justify-content-between align-items-center">
            <span>
                Documents concernés <span class="badge bg-secondary ms-1">${docPage.getTotalElements()}</span>
                @if(outOfSyncCount > 0)
                    <span class="badge bg-warning text-dark ms-1">${outOfSyncCount} à déplacer</span>
                @elseif(docPage.getTotalElements() > 0)
                    <span class="badge bg-success ms-1">à jour</span>
                @endif
            </span>
            @if(docPage.getTotalElements() > 0)
            <div class="d-flex align-items-center gap-2">
                <%-- Tracks the template used for simulate; persists across HTMX swaps of #docs-body --%>
                <input type="hidden" id="docFragTemplate" name="pathTemplate" value="${pathTemplate}">
                <button type="button" class="btn btn-sm btn-outline-secondary"
                        onclick="document.getElementById('docFragTemplate').value=document.querySelector('[name=pathTemplate]').value"
                        hx-get="/rules/${rule.getId()}/documents"
                        hx-include="#docFragTemplate"
                        hx-vals='{"page":"0"}'
                        hx-target="#docs-body"
                        hx-swap="innerHTML">Simuler</button>
                @if(outOfSyncCount > 0)
                <form method="post" action="/rules/${rule.getId()}/apply" class="d-inline">
                    <button type="submit" class="btn btn-sm btn-warning">
                        Appliquer (${outOfSyncCount})
                    </button>
                </form>
                @endif
            </div>
            @endif
        </div>
        <div id="docs-body" class="list-group list-group-flush small">
            @template.rules.docs_fragment(ruleId = rule.getId(), docPage = docPage, results = results, pathTemplate = pathTemplate)
        </div>
    </div>
    @endif
</div>

`)
