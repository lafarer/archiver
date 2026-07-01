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
    @for(Document doc : documents)
        @if(doc.getAnalysisStatus() == AnalysisStatus.ANALYZING)
            <div class="doc-card opacity-75">
                <div class="d-flex align-items-center gap-2 text-muted">
                    <span class="spinner-border spinner-border-sm" role="status"></span>
                    <span>Analyse en cours — ${doc.getOriginalFilename()}</span>
                </div>
            </div>
        @else
            !{boolean incomplete = doc.getTitle() == null || doc.getDocumentDate() == null;}
            <div class="doc-card ${incomplete ? "doc-card-incomplete" : ""}">
                <div class="doc-card-header">
                    <span class="badge bg-light text-dark">${doc.getDocumentType() != null ? doc.getDocumentType() : "?"}</span>
                    @if(incomplete)
                        <span class="badge bg-warning text-dark">⚠ Incomplet</span>
                    @endif
                    <span class="doc-card-date">${doc.getDocumentDate() != null ? doc.getDocumentDate() : "date inconnue"}</span>
                </div>
                <div class="doc-card-title">${doc.getTitle() != null ? doc.getTitle() : doc.getOriginalFilename()}</div>
                @if(doc.getIssuer() != null)
                    <div class="doc-card-issuer">${doc.getIssuer()}</div>
                @endif
                @if(doc.getResolvedPath() != null)
                    <div class="doc-card-path" title="${doc.getResolvedPath()}">${doc.getResolvedPath()}</div>
                @endif
                <div class="doc-card-footer">
                    <div class="doc-card-tags">
                        @for(String tag : doc.getTags())
                            <span class="tag">${tag}</span>
                        @endfor
                    </div>
                    <div class="doc-card-actions">
                        @if(doc.getMimeType() != null && (doc.getMimeType().startsWith("image/") || doc.getMimeType().equals("application/pdf")))
                            !{String docTitle = doc.getTitle() != null ? doc.getTitle() : doc.getOriginalFilename();}
                            <button class="btn btn-sm btn-outline-primary"
                                    data-bs-toggle="modal" data-bs-target="#previewModal"
                                    data-preview-url="/documents/${doc.getId()}/file"
                                    data-mime-type="${doc.getMimeType()}"
                                    data-title="${docTitle}">Aperçu</button>
                        @endif
                        <a href="inbox/${doc.getId()}/edit" class="btn btn-sm btn-outline-secondary">Éditer</a>
                        <form method="post" action="inbox/${doc.getId()}/validate" class="d-inline">
                            <button type="submit" class="btn btn-sm btn-success">Valider ✓</button>
                        </form>
                    </div>
                </div>
            </div>
        @endif
    @endfor
@endif
