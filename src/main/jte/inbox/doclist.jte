@import com.github.lafarer.archiver.model.Document
@import com.github.lafarer.archiver.model.enums.AnalysisStatus
@import java.util.List

@param List<Document> documents
@param String archiveRoot

@if(documents.isEmpty())
    <div class="text-center text-muted py-5">
        <p>Aucun document en attente.</p>
        <p class="small">Déposez des fichiers dans le dossier inbox ou utilisez le bouton Importer.</p>
    </div>
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
                @if(doc.getAnalysisStatus() == AnalysisStatus.ANALYZING)
                    <tr class="align-middle opacity-75">
                        <td colspan="5" class="text-muted">
                            <span class="spinner-border spinner-border-sm me-2" role="status"></span>
                            ${doc.getOriginalFilename()}
                        </td>
                        <td></td>
                    </tr>
                @else
                    !{boolean incomplete = doc.getTitle() == null || doc.getDocumentDate() == null;}
                    <tr class="align-middle ${incomplete ? "table-warning" : ""}">
                        <td class="text-nowrap">${doc.getDocumentDate() != null ? doc.getDocumentDate() : "-"}</td>
                        <td>
                            <span class="badge bg-light text-dark">${doc.getDocumentType() != null ? doc.getDocumentType() : "?"}</span>
                            @if(incomplete)
                                <span class="badge bg-warning text-dark ms-1">⚠</span>
                            @endif
                        </td>
                        <td>
                            <div>${doc.getTitle() != null ? doc.getTitle() : doc.getOriginalFilename()}</div>
                            @if(doc.getResolvedPath() != null)
                                <div class="text-truncate text-muted font-monospace" style="font-size:0.72rem"
                                     title="${doc.getResolvedPath()}">${doc.getResolvedPath()}</div>
                            @endif
                        </td>
                        <td>${doc.getIssuer() != null ? doc.getIssuer() : "-"}</td>
                        <td>
                            @for(String tag : doc.getTags())
                                <span class="tag">${tag}</span>
                            @endfor
                        </td>
                        <td class="text-end">
                            <div class="d-flex gap-1 justify-content-end">
                                @if(doc.getMimeType() != null && (doc.getMimeType().startsWith("image/") || doc.getMimeType().equals("application/pdf")))
                                    !{String docTitle = doc.getTitle() != null ? doc.getTitle() : doc.getOriginalFilename();}
                                    <button class="btn btn-sm btn-outline-primary"
                                            data-bs-toggle="modal" data-bs-target="#previewModal"
                                            data-preview-url="/documents/${doc.getId()}/file"
                                            data-mime-type="${doc.getMimeType()}"
                                            data-title="${docTitle}">Aperçu</button>
                                @endif
                                <a href="/inbox/${doc.getId()}/edit" class="btn btn-sm btn-outline-secondary">Éditer</a>
                                <form method="post" action="/inbox/${doc.getId()}/validate" class="d-inline">
                                    <button type="submit" class="btn btn-sm btn-success">Valider ✓</button>
                                </form>
                            </div>
                        </td>
                    </tr>
                @endif
            @endfor
        </tbody>
    </table>
@endif
