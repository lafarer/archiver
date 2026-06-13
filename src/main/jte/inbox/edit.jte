@import com.github.lafarer.archiver.model.Document
@import com.github.lafarer.archiver.model.CustomFieldDef
@import java.util.List

@param Document document
@param List<CustomFieldDef> customFieldDefs
@param String proposedPath
@param String page

!{String pageTitle = "Éditer — " + (document.getTitle() != null ? document.getTitle() : document.getOriginalFilename());}
@template.layout.base(page = page, title = pageTitle, content = @`

!{boolean previewable = document.getMimeType() != null && (document.getMimeType().startsWith("image/") || document.getMimeType().equals("application/pdf"));}
!{String previewTitle = document.getTitle() != null ? document.getTitle() : document.getOriginalFilename();}
<div class="page-header">
    <h1>
        <a href="/inbox" class="text-decoration-none text-muted me-2">←</a>
        Vérification du document
    </h1>
    @if(previewable)
        <button type="button" class="btn btn-outline-primary btn-sm"
                onclick="openPreviewDrawer('/documents/${document.getId()}/file', '${document.getMimeType()}', '${previewTitle}')">
            Aperçu
        </button>
    @endif
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

<div class="page-body">

    <div class="mb-3 text-muted small">
        Fichier : <strong>${document.getOriginalFilename()}</strong>
        &nbsp;·&nbsp; → <code>${proposedPath}</code>
    </div>

    <form method="post" action="/inbox/${document.getId()}">

        <div class="d-flex flex-column gap-3" style="max-width: 700px">

            <div>
                <label class="form-label" for="documentType">Type de document</label>
                <input type="text" id="documentType" name="documentType" class="form-control"
                       value="${document.getDocumentType() != null ? document.getDocumentType() : ""}"
                       placeholder="ex: facture, contrat, notice…">
            </div>

            <div>
                !{Double titleConf = document.getTitleConfidence();}
                <label class="form-label d-flex justify-content-between" for="title">
                    <span>Titre</span>
                    @if(titleConf != null)
                        <span class="text-muted small">confiance : ${String.format("%.0f%%", titleConf * 100)}</span>
                    @endif
                </label>
                <input type="text" id="title" name="title" class="form-control"
                       value="${document.getTitle() != null ? document.getTitle() : ""}">
            </div>

            <div>
                !{Double dateConf = document.getDocumentDateConfidence();}
                <label class="form-label d-flex justify-content-between" for="documentDate">
                    <span>Date <span class="text-muted small">(AAAA, AAAA-MM ou AAAA-MM-JJ)</span></span>
                    @if(dateConf != null)
                        <span class="text-muted small">confiance : ${String.format("%.0f%%", dateConf * 100)}</span>
                    @endif
                </label>
                <input type="text" id="documentDate" name="documentDate" class="form-control"
                       value="${document.getDocumentDate() != null ? document.getDocumentDate() : ""}"
                       pattern="\d{4}(-\d{2}(-\d{2})?)?" placeholder="ex: 2024-03-15">
            </div>

            <div>
                !{Double issuerConf = document.getIssuerConfidence();}
                <label class="form-label d-flex justify-content-between" for="issuer">
                    <span>Émetteur</span>
                    @if(issuerConf != null)
                        <span class="text-muted small">confiance : ${String.format("%.0f%%", issuerConf * 100)}</span>
                    @endif
                </label>
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
                       value="${tagsValue}"
                       placeholder="ex: assurance, logement">
            </div>

            @if(!customFieldDefs.isEmpty())
                <hr class="my-1">
                <div class="text-muted small fw-semibold mb-1">Champs personnalisés</div>
                @for(CustomFieldDef cf : customFieldDefs)
                    !{String cfValue = document.getCustomFields().getOrDefault(cf.getSlug(), "");}
                    <div>
                        <label class="form-label" for="cf_${cf.getSlug()}">${cf.getLabel()}</label>
                        <input type="text" id="cf_${cf.getSlug()}" name="cf_${cf.getSlug()}"
                               class="form-control" value="${cfValue}"
                               placeholder="${cf.getDescription() != null ? cf.getDescription() : ""}">
                    </div>
                @endfor
            @endif

            <div class="d-flex gap-2 mt-2">
                <button type="submit" class="btn btn-outline-secondary">Enregistrer</button>
            </div>

        </div>

    </form>

    <hr class="my-4" style="max-width: 700px">

    <div style="max-width: 700px">
        <form method="post" action="/inbox/${document.getId()}/validate">
            <button type="submit" class="btn btn-success">Valider et archiver ✓</button>
        </form>
    </div>

</div>

`)
