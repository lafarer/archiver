@import com.github.lafarer.archiver.model.Document

@param Document document
@param String page

!{String pageTitle = document.getTitle() != null ? document.getTitle() : document.getOriginalFilename();}
!{boolean previewable = document.getMimeType() != null && (document.getMimeType().startsWith("image/") || document.getMimeType().equals("application/pdf"));}
@template.layout.base(page = page, title = pageTitle, content = @`

!{String previewTitle = document.getTitle() != null ? document.getTitle() : document.getOriginalFilename();}
<div class="page-header">
    <h1>
        <a href="/archive" class="text-decoration-none text-muted me-2">←</a>
        ${pageTitle}
    </h1>
    @if(previewable)
        <button type="button" class="btn btn-outline-primary btn-sm"
                onclick="openPreviewDrawer('/documents/${document.getId()}/file', '${document.getMimeType()}', '${previewTitle}')">
            Aperçu
        </button>
    @endif
</div>

<div class="page-body">

    <div class="mb-3 text-muted small">
        Fichier : <strong>${document.getOriginalFilename()}</strong>
        @if(document.getResolvedPath() != null)
            &nbsp;·&nbsp; → <code>${document.getResolvedPath()}</code>
        @endif
    </div>

    <form method="post" action="/archive/${document.getId()}">

        <div class="d-flex flex-column gap-3" style="max-width: 700px">

            <div>
                <label class="form-label" for="documentType">Type de document</label>
                <input type="text" id="documentType" name="documentType" class="form-control"
                       value="${document.getDocumentType() != null ? document.getDocumentType() : ""}">
            </div>

            <div>
                <label class="form-label" for="title">Titre</label>
                <input type="text" id="title" name="title" class="form-control"
                       value="${document.getTitle() != null ? document.getTitle() : ""}">
            </div>

            <div>
                <label class="form-label" for="documentDate">
                    Date <span class="text-muted small">(AAAA, AAAA-MM ou AAAA-MM-JJ)</span>
                </label>
                <input type="text" id="documentDate" name="documentDate" class="form-control"
                       value="${document.getDocumentDate() != null ? document.getDocumentDate() : ""}"
                       pattern="\d{4}(-\d{2}(-\d{2})?)?" placeholder="ex: 2024-03-15">
            </div>

            <div>
                <label class="form-label" for="issuer">Émetteur</label>
                <input type="text" id="issuer" name="issuer" class="form-control"
                       value="${document.getIssuer() != null ? document.getIssuer() : ""}">
            </div>

            <div>
                <label class="form-label" for="description">Description</label>
                <textarea id="description" name="description" class="form-control" rows="2">${document.getDescription() != null ? document.getDescription() : ""}</textarea>
            </div>

            <div>
                <label class="form-label" for="tags">
                    Tags <span class="text-muted small">(séparés par des virgules)</span>
                </label>
                !{String tagsValue = document.getTags().isEmpty() ? "" : String.join(", ", document.getTags());}
                <input type="text" id="tags" name="tags" class="form-control"
                       value="${tagsValue}">
            </div>

            <div class="d-flex gap-2 mt-2">
                <button type="submit" class="btn btn-outline-secondary">Enregistrer</button>
                <a href="/archive" class="btn btn-link text-muted">Annuler</a>
            </div>

        </div>

    </form>

</div>

@if(previewable)
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            openPreviewDrawer(
                '/documents/${document.getId()}/file',
                '${document.getMimeType()}',
                '${previewTitle}'
            );
        });
    </script>
@endif

`)
