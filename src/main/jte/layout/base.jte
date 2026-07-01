@import gg.jte.Content

@param String page
@param Content content
@param String title = "Archiver"
@param long inboxCount = 0
@param boolean watchdogRunning = false
@param String contextPath = ""

<!doctype html>
<html lang="fr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <base href="${contextPath}/">
    <title>${title} - Archiver</title>
    <link rel="stylesheet" href="css/app.css">
    <script src="https://unpkg.com/htmx.org@2.0.3" defer></script>
    <script src="https://unpkg.com/sortablejs@1.15.3/Sortable.min.js" defer></script>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js" defer></script>
</head>
<body>

<nav class="sidebar d-flex flex-column">
    <div class="sidebar-brand">Archiver</div>
    <ul class="nav flex-column mt-2">
        <li class="nav-item">
            <a class="nav-link ${page.equals("inbox") ? "active" : ""}" href="inbox">
                Inbox
                <span id="inbox-sidebar-badge">
                    @if(inboxCount > 0)
                        <span class="badge bg-warning text-dark">${inboxCount}</span>
                    @endif
                </span>
                <span class="${watchdogRunning ? "text-success" : "text-secondary"} ms-1"
                      style="font-size: 0.6em"
                      title="${watchdogRunning ? "Watchdog actif" : "Watchdog inactif"}">●</span>
            </a>
        </li>
        <li class="nav-item">
            <a class="nav-link ${page.equals("archive") ? "active" : ""}" href="archive">Archive</a>
        </li>
        <li class="nav-item mt-3">
            <a class="nav-link ${page.equals("rules") ? "active" : ""}" href="rules">Règles</a>
        </li>
        <li class="nav-item">
            <a class="nav-link ${page.equals("fields") ? "active" : ""}" href="fields">Champs</a>
        </li>
        <li class="nav-item">
            <a class="nav-link ${page.equals("doctypes") ? "active" : ""}" href="doctypes">Types</a>
        </li>
        <li class="nav-item">
            <a class="nav-link ${page.equals("tags") ? "active" : ""}" href="tags">Tags</a>
        </li>
        <li class="nav-item mt-auto">
            <a class="nav-link ${page.equals("audit") ? "active" : ""}" href="audit">Audit</a>
        </li>
        <li class="nav-item">
            <a class="nav-link ${page.equals("settings") ? "active" : ""}" href="settings">Réglages</a>
        </li>
    </ul>
</nav>

<div class="main-content" id="mainContent">
    ${content}
</div>

<!-- Document preview drawer -->
<div id="previewDrawer" class="preview-drawer">
    <div class="preview-drawer-header">
        <span class="preview-drawer-title text-truncate flex-grow-1 small fw-semibold" id="drawerTitle"></span>
        <button type="button" class="btn-close" onclick="closePreviewDrawer()"></button>
    </div>
    <div class="preview-drawer-body">
        <iframe id="drawerFrame" src="" style="flex: 1; border: none; width: 100%; height: 100%; display: none"></iframe>
        <div id="drawerImgWrap" style="flex: 1; overflow: auto; display: none; background: #f0f0f0; align-items: center; justify-content: center">
            <img id="drawerImg" src="" alt="" style="max-width: 100%; object-fit: contain; display: block; margin: auto">
        </div>
    </div>
</div>

<style>
    .preview-drawer {
        position: fixed;
        top: 0;
        right: 0;
        width: 45%;
        height: 100vh;
        background: #fff;
        box-shadow: -4px 0 24px rgba(0,0,0,0.12);
        transform: translateX(100%);
        transition: transform 0.25s ease;
        z-index: 1040;
        display: flex;
        flex-direction: column;
    }
    .preview-drawer.open { transform: translateX(0); }
    .preview-drawer-header {
        display: flex;
        align-items: center;
        padding: 0.5rem 1rem;
        border-bottom: 1px solid #dee2e6;
        gap: 0.75rem;
        min-height: 48px;
    }
    .preview-drawer-body {
        flex: 1;
        overflow: hidden;
        display: flex;
        flex-direction: column;
    }
    #mainContent.drawer-open { margin-right: 45%; }
</style>

<script>
    function openPreviewDrawer(url, mime, title) {
        const frame = document.getElementById('drawerFrame');
        const imgWrap = document.getElementById('drawerImgWrap');
        const img = document.getElementById('drawerImg');
        document.getElementById('drawerTitle').textContent = title || '';
        if (mime && mime.startsWith('image/')) {
            frame.style.display = 'none';
            imgWrap.style.display = 'flex';
            img.src = url;
        } else {
            imgWrap.style.display = 'none';
            frame.style.display = '';
            frame.src = url;
        }
        document.getElementById('previewDrawer').classList.add('open');
        document.getElementById('mainContent').classList.add('drawer-open');
    }
    function closePreviewDrawer() {
        document.getElementById('previewDrawer').classList.remove('open');
        document.getElementById('mainContent').classList.remove('drawer-open');
        document.getElementById('drawerFrame').src = '';
        document.getElementById('drawerImg').src = '';
    }
</script>

<!-- Document preview modal -->
<div class="modal fade" id="previewModal" tabindex="-1">
    <div class="modal-dialog modal-xl modal-fullscreen-lg-down">
        <div class="modal-content" style="height: 90vh">
            <div class="modal-header py-2">
                <h6 class="modal-title text-truncate" id="previewModalLabel" style="max-width: 80%"></h6>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body p-0" style="overflow: hidden; flex: 1; display: flex; flex-direction: column">
                <iframe id="previewFrame" src="" style="flex: 1; border: none; width: 100%; height: 100%; display: none"></iframe>
                <div id="previewImgWrap" style="flex: 1; overflow: auto; display: none; background: #f0f0f0; align-items: center; justify-content: center">
                    <img id="previewImg" src="" alt="" style="max-width: 100%; max-height: 100%; object-fit: contain; display: block; margin: auto">
                </div>
            </div>
        </div>
    </div>
</div>

<script>
    (function () {
        const modal = document.getElementById('previewModal');
        modal.addEventListener('show.bs.modal', function (e) {
            const btn = e.relatedTarget;
            const url = btn.dataset.previewUrl;
            const mime = btn.dataset.mimeType || '';
            const title = btn.dataset.title || '';
            document.getElementById('previewModalLabel').textContent = title;
            const frame = document.getElementById('previewFrame');
            const imgWrap = document.getElementById('previewImgWrap');
            const img = document.getElementById('previewImg');
            if (mime.startsWith('image/')) {
                frame.style.display = 'none';
                imgWrap.style.display = 'flex';
                img.src = url;
            } else {
                imgWrap.style.display = 'none';
                frame.style.display = '';
                frame.src = url;
            }
        });
        modal.addEventListener('hide.bs.modal', function () {
            document.getElementById('previewFrame').src = '';
            document.getElementById('previewImg').src = '';
        });
    })();
</script>

</body>
</html>
