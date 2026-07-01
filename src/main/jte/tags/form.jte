@import com.github.lafarer.archiver.model.TagDef

@param TagDef tag
@param String page
@param boolean watchdogRunning = false
@param String contextPath = ""

!{String pageTitle = tag.getId() == null ? "Nouveau tag" : "Éditer " + tag.getLabel();}
@template.layout.base(page = page, title = pageTitle, watchdogRunning = watchdogRunning, contextPath = contextPath, content = @`

<div class="page-header">
    <h1>${pageTitle}</h1>
</div>

<div class="page-body" style="max-width: 600px">
    <form method="post" action="${tag.getId() == null ? "/tags" : "/tags/" + tag.getId()}">
        <div class="d-flex flex-column gap-3">

            <div>
                <label class="form-label" for="slug">Slug <span class="text-muted small">(identifiant unique, ex: assurance)</span></label>
                <input type="text" id="slug" name="slug" class="form-control"
                       value="${tag.getSlug() != null ? tag.getSlug() : ""}"
                       pattern="[a-z0-9\-]+" readonly="${tag.getId() != null}" required>
            </div>

            <div>
                <label class="form-label" for="label">Libellé</label>
                <input type="text" id="label" name="label" class="form-control"
                       value="${tag.getLabel() != null ? tag.getLabel() : ""}" required>
            </div>

            <div>
                <label class="form-label" for="description">
                    Description <span class="text-muted small">(contexte fourni à l'IA)</span>
                </label>
                <textarea id="description" name="description" class="form-control" rows="3">${tag.getDescription() != null ? tag.getDescription() : ""}</textarea>
            </div>

            <div class="d-flex gap-2">
                <button type="submit" class="btn btn-primary">Enregistrer</button>
                <a href="tags" class="btn btn-outline-secondary">Annuler</a>
            </div>
        </div>
    </form>
</div>

`)
