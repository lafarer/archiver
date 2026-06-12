@import com.github.lafarer.archiver.model.Document
@import java.util.List

@param List<Document> documents
@param String page

@template.layout.base(page = page, title = "Inbox", inboxCount = documents.size(), content = @`

<div class="page-header">
    <h1>Inbox <span class="badge bg-secondary">${documents.size()}</span></h1>
    <button class="btn btn-primary btn-sm" data-bs-toggle="modal" data-bs-target="#uploadModal">
        + Importer
    </button>
</div>

<div class="page-body">

    @if(documents.isEmpty())
        <div class="text-center text-muted py-5">
            <p>Aucun document en attente.</p>
            <p class="small">Déposez des fichiers dans le dossier inbox ou utilisez le bouton Importer.</p>
        </div>
    @else
        @for(Document doc : documents)
            <div class="document-card ${doc.getTitle() == null || doc.getDocumentDate() == null ? "has-warnings" : ""}">
                <div class="doc-meta">
                    <div class="d-flex align-items-center gap-2 mb-1">
                        <span class="doc-type">${doc.getDocumentType() != null ? doc.getDocumentType() : "?"}</span>
                        @if(doc.getTitle() == null || doc.getDocumentDate() == null)
                            <span class="badge bg-warning text-dark">⚠ Incomplet</span>
                        @endif
                    </div>
                    <div class="doc-title">${doc.getTitle() != null ? doc.getTitle() : doc.getOriginalFilename()}</div>
                    <div class="doc-subtitle">
                        ${doc.getIssuer() != null ? doc.getIssuer() : "—"}
                        &nbsp;·&nbsp;
                        ${doc.getDocumentDate() != null ? doc.getDocumentDate() : "date inconnue"}
                    </div>
                    @if(!doc.getTags().isEmpty())
                        <div class="mt-1">
                            @for(String tag : doc.getTags())
                                <span class="tag">${tag}</span>
                            @endfor
                        </div>
                    @endif
                    @if(doc.getResolvedPath() != null)
                        <div class="doc-path">→ ${doc.getResolvedPath()}</div>
                    @endif
                </div>
                <div class="d-flex flex-column gap-1">
                    <a href="/inbox/${doc.getId()}/edit" class="btn btn-outline-secondary btn-sm">Éditer</a>
                    <form method="post" action="/inbox/${doc.getId()}/validate">
                        <button type="submit" class="btn btn-success btn-sm w-100">Valider ✓</button>
                    </form>
                </div>
            </div>
        @endfor
    @endif

</div>

<!-- Upload modal -->
<div class="modal fade" id="uploadModal" tabindex="-1">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">Importer un document</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="post" action="/inbox/upload" enctype="multipart/form-data">
                <div class="modal-body">
                    <input type="file" name="file" class="form-control"
                           accept=".pdf,.jpg,.jpeg,.png,.tiff">
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Annuler</button>
                    <button type="submit" class="btn btn-primary">Importer</button>
                </div>
            </form>
        </div>
    </div>
</div>

`)
