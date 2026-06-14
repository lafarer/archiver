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
                    @if(doc.getMimeType() != null && (doc.getMimeType().startsWith("image/") || doc.getMimeType().equals("application/pdf")))
                        !{String docTitle = doc.getTitle() != null ? doc.getTitle() : doc.getOriginalFilename();}
                        <button class="btn btn-outline-primary btn-sm"
                                data-bs-toggle="modal" data-bs-target="#previewModal"
                                data-preview-url="/documents/${doc.getId()}/file"
                                data-mime-type="${doc.getMimeType()}"
                                data-title="${docTitle}">Aperçu</button>
                    @endif
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
                <h5 class="modal-title">Importer</h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <form method="post" action="/inbox/upload" enctype="multipart/form-data">
                <div class="modal-body d-flex flex-column gap-2">
                    <input type="file" name="files" class="form-control" multiple
                           accept=".pdf,.jpg,.jpeg,.png,.tiff">
                    <div class="text-center text-muted small">ou</div>
                    <button type="button" class="btn btn-outline-secondary btn-sm" id="folderPickBtn">
                        Sélectionner un dossier…
                    </button>
                    <input type="file" id="folderPicker" class="d-none" webkitdirectory multiple>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Annuler</button>
                    <button type="submit" class="btn btn-primary">Importer</button>
                </div>
            </form>
        </div>
    </div>
</div>

<div id="dropOverlay" class="drop-overlay d-none">
    <div class="drop-overlay-inner">
        <div class="fs-3 mb-2">📂</div>
        <div>Déposer les fichiers ou dossiers ici</div>
    </div>
</div>

<script>
(function() {
    const overlay = document.getElementById('dropOverlay');
    let dragCounter = 0;

    document.addEventListener('dragenter', e => {
        e.preventDefault();
        dragCounter++;
        overlay.classList.remove('d-none');
    });

    document.addEventListener('dragleave', e => {
        dragCounter--;
        if (dragCounter === 0) overlay.classList.add('d-none');
    });

    document.addEventListener('dragover', e => e.preventDefault());

    document.addEventListener('drop', async e => {
        e.preventDefault();
        dragCounter = 0;
        overlay.classList.add('d-none');

        const files = await collectFiles(e.dataTransfer);
        if (files.length > 0) await uploadFiles(files);
    });

    async function collectFiles(dataTransfer) {
        const files = [];

        async function readEntry(entry) {
            if (!entry || entry.name.startsWith('.')) return;
            if (entry.isFile) {
                files.push(await new Promise((res, rej) => entry.file(res, rej)));
            } else if (entry.isDirectory) {
                const reader = entry.createReader();
                let batch;
                do {
                    batch = await new Promise((res, rej) => reader.readEntries(res, rej));
                    for (const e of batch) await readEntry(e);
                } while (batch.length > 0);
            }
        }

        for (const item of [...dataTransfer.items]) {
            const entry = item.webkitGetAsEntry?.();
            if (entry) await readEntry(entry);
        }
        return files;
    }

    async function uploadFiles(files) {
        const fd = new FormData();
        for (const f of files) fd.append('files', f);
        await fetch('/inbox/upload', { method: 'POST', body: fd });
        location.reload();
    }

    // Folder picker button
    document.getElementById('folderPickBtn').addEventListener('click', () => {
        document.getElementById('folderPicker').click();
    });

    document.getElementById('folderPicker').addEventListener('change', async function() {
        const files = [...this.files].filter(f => !f.name.startsWith('.'));
        if (files.length > 0) {
            bootstrap.Modal.getInstance(document.getElementById('uploadModal'))?.hide();
            await uploadFiles(files);
        }
    });
}());
</script>

`)
