@import com.github.lafarer.archiver.model.CustomFieldDef
@import com.github.lafarer.archiver.model.enums.FieldType

@param CustomFieldDef field
@param String page
@param boolean watchdogRunning = false
@param String contextPath = ""

!{String pageTitle = field.getId() == null ? "Nouveau champ" : "Éditer " + field.getLabel();}
@template.layout.base(page = page, title = pageTitle, watchdogRunning = watchdogRunning, contextPath = contextPath, content = @`

<div class="page-header">
    <h1>${pageTitle}</h1>
</div>

<div class="page-body" style="max-width: 600px">
    <form method="post" action="${field.getId() == null ? "fields" : "fields/" + field.getId()}">
        <div class="d-flex flex-column gap-3">

            <div>
                <label class="form-label" for="slug">Slug <span class="text-muted small">(identifiant unique, ex: numero_contrat)</span></label>
                <input type="text" id="slug" name="slug" class="form-control"
                       value="${field.getSlug() != null ? field.getSlug() : ""}"
                       pattern="[a-z0-9_]+" readonly="${field.getId() != null}" required>
            </div>

            <div>
                <label class="form-label" for="label">Libellé</label>
                <input type="text" id="label" name="label" class="form-control"
                       value="${field.getLabel() != null ? field.getLabel() : ""}" required>
            </div>

            <div>
                <label class="form-label" for="fieldType">Type</label>
                <select id="fieldType" name="fieldType" class="form-select">
                    <option value="TEXT"   selected="${FieldType.TEXT.equals(field.getFieldType())}">Texte</option>
                    <option value="DATE"   selected="${FieldType.DATE.equals(field.getFieldType())}">Date</option>
                    <option value="NUMBER" selected="${FieldType.NUMBER.equals(field.getFieldType())}">Nombre</option>
                    <option value="AMOUNT" selected="${FieldType.AMOUNT.equals(field.getFieldType())}">Montant</option>
                </select>
            </div>

            <div>
                <label class="form-label" for="description">
                    Description <span class="text-muted small">(contexte fourni à l'IA)</span>
                </label>
                <textarea id="description" name="description" class="form-control" rows="3">${field.getDescription() != null ? field.getDescription() : ""}</textarea>
            </div>

            <div class="d-flex gap-2">
                <button type="submit" class="btn btn-primary">Enregistrer</button>
                <a href="fields" class="btn btn-outline-secondary">Annuler</a>
            </div>
        </div>
    </form>
</div>

`)
