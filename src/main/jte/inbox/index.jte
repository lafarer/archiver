@import com.github.lafarer.archiver.model.Document
@import java.util.List

@param List<Document> documents
@param String archiveRoot
@param String page
@param String uploadError = null

@template.layout.base(page = page, title = "Inbox", inboxCount = documents.size(), content = @`

<div class="page-header">
    <h1 id="inbox-header-title">Inbox <span class="badge bg-secondary">${documents.size()}</span></h1>
    <button class="btn btn-primary btn-sm" data-bs-toggle="modal" data-bs-target="#uploadModal">
        + Importer
    </button>
</div>

@if(uploadError != null)
<div class="alert alert-danger alert-dismissible fade show" id="uploadErrorAlert" role="alert">
    Fichier trop volumineux. La taille maximale autorisée est de 200 Mo.
    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
</div>
@endif

<div class="page-body" id="inbox-list">
    @template.inbox.doclist(documents = documents, archiveRoot = archiveRoot)
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
document.addEventListener('DOMContentLoaded', function() {
    const source = new EventSource('/inbox/events');
    source.addEventListener('inbox-updated', () => {
        htmx.ajax('GET', '/inbox/fragment', { target: '#inbox-list', swap: 'innerHTML' });
    });
    window.addEventListener('beforeunload', () => source.close());
});
</script>

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
        const response = await fetch('/inbox/upload', { method: 'POST', body: fd });
        if (response.url && response.url.includes('uploadError=')) {
            showUploadError('Fichier trop volumineux. La taille maximale autorisée est de 200 Mo.');
        } else {
            location.reload();
        }
    }

    function showUploadError(message) {
        let el = document.getElementById('uploadErrorAlert');
        if (!el) {
            el = document.createElement('div');
            el.id = 'uploadErrorAlert';
            el.className = 'alert alert-danger alert-dismissible fade show';
            el.setAttribute('role', 'alert');
            el.innerHTML = '<span class="error-msg"></span><button type="button" class="btn-close" data-bs-dismiss="alert"></button>';
            const pageBody = document.getElementById('inbox-list');
            pageBody.parentNode.insertBefore(el, pageBody);
        }
        el.querySelector('.error-msg').textContent = message;
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
