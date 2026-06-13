@import com.github.lafarer.archiver.model.Document
@import java.util.List

@param List<Document> documents
@param String page

@template.layout.base(page = page, title = "Archive", content = @`

<div class="page-header">
    <h1>Archive</h1>
    <input type="search" class="form-control form-control-sm w-25"
           placeholder="Rechercher…"
           hx-get="/archive" hx-trigger="keyup changed delay:300ms"
           hx-target="#doc-list" hx-include="this" name="q">
</div>

<div class="page-body">
    <div id="doc-list">
        @if(documents.isEmpty())
            <div class="text-center text-muted py-5">Aucun document archivé.</div>
        @else
            <table class="table table-hover bg-white rounded">
                <thead class="table-light">
                    <tr>
                        <th>Date</th>
                        <th>Type</th>
                        <th>Titre</th>
                        <th>Émetteur</th>
                        <th>Tags</th>
                        <th></th>
                    </tr>
                </thead>
                <tbody>
                    @for(Document doc : documents)
                        <tr>
                            <td class="text-nowrap">${doc.getDocumentDate() != null ? doc.getDocumentDate() : "—"}</td>
                            <td><span class="badge bg-light text-dark">${doc.getDocumentType() != null ? doc.getDocumentType() : "—"}</span></td>
                            <td>${doc.getTitle() != null ? doc.getTitle() : doc.getOriginalFilename()}</td>
                            <td>${doc.getIssuer() != null ? doc.getIssuer() : "—"}</td>
                            <td>
                                @for(String tag : doc.getTags())
                                    <span class="tag">${tag}</span>
                                @endfor
                            </td>
                            <td class="text-end d-flex gap-1 justify-content-end">
                                @if(doc.getMimeType() != null && (doc.getMimeType().startsWith("image/") || doc.getMimeType().equals("application/pdf")))
                                    !{String docTitle = doc.getTitle() != null ? doc.getTitle() : doc.getOriginalFilename();}
                                    <button class="btn btn-sm btn-outline-primary"
                                            data-bs-toggle="modal" data-bs-target="#previewModal"
                                            data-preview-url="/documents/${doc.getId()}/file"
                                            data-mime-type="${doc.getMimeType()}"
                                            data-title="${docTitle}">Aperçu</button>
                                @endif
                                <a href="/archive/${doc.getId()}" class="btn btn-sm btn-outline-secondary">Détail</a>
                            </td>
                        </tr>
                    @endfor
                </tbody>
            </table>
        @endif
    </div>
</div>

`)
