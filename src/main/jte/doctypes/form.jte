@import com.github.lafarer.archiver.model.DocumentTypeDef

@param DocumentTypeDef type
@param String page

!{String pageTitle = type.getId() == null ? "Nouveau type de document" : "Éditer " + type.getLabel();}
@template.layout.base(page = page, title = pageTitle, content = @`

<div class="page-header">
    <h1>${pageTitle}</h1>
</div>

<div class="page-body" style="max-width: 600px">
    <form method="post" action="${type.getId() == null ? "/doctypes" : "/doctypes/" + type.getId()}">
        <div class="d-flex flex-column gap-3">

            <div>
                <label class="form-label" for="slug">Slug <span class="text-muted small">(identifiant unique, ex: fiche-de-paie)</span></label>
                <input type="text" id="slug" name="slug" class="form-control"
                       value="${type.getSlug() != null ? type.getSlug() : ""}"
                       pattern="[a-z0-9\-]+" required>
            </div>

            <div>
                <label class="form-label" for="label">Libellé</label>
                <input type="text" id="label" name="label" class="form-control"
                       value="${type.getLabel() != null ? type.getLabel() : ""}" required>
            </div>

            <div>
                <label class="form-label" for="description">
                    Description <span class="text-muted small">(contexte fourni à l'IA pour identifier ce type)</span>
                </label>
                <textarea id="description" name="description" class="form-control" rows="4">${type.getDescription() != null ? type.getDescription() : ""}</textarea>
            </div>

            <div class="d-flex gap-2">
                <button type="submit" class="btn btn-primary">Enregistrer</button>
                <a href="/doctypes" class="btn btn-outline-secondary">Annuler</a>
            </div>
        </div>
    </form>
</div>

`)
