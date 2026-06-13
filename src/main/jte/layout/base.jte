@import gg.jte.Content

@param String page
@param Content content
@param String title = "Archiver"
@param long inboxCount = 0

<!doctype html>
<html lang="fr">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>${title} — Archiver</title>
    <link rel="stylesheet" href="/css/app.css">
    <script src="https://unpkg.com/htmx.org@2.0.3" defer></script>
    <script src="https://unpkg.com/sortablejs@1.15.3/Sortable.min.js" defer></script>
</head>
<body>

<nav class="sidebar d-flex flex-column">
    <div class="sidebar-brand">Archiver</div>
    <ul class="nav flex-column mt-2">
        <li class="nav-item">
            <a class="nav-link ${page.equals("inbox") ? "active" : ""}" href="/inbox">
                Inbox
                @if(inboxCount > 0)
                    <span class="badge bg-warning text-dark">${inboxCount}</span>
                @endif
            </a>
        </li>
        <li class="nav-item">
            <a class="nav-link ${page.equals("archive") ? "active" : ""}" href="/archive">Archive</a>
        </li>
        <li class="nav-item mt-3">
            <a class="nav-link ${page.equals("rules") ? "active" : ""}" href="/rules">Règles</a>
        </li>
        <li class="nav-item">
            <a class="nav-link ${page.equals("fields") ? "active" : ""}" href="/fields">Champs</a>
        </li>
        <li class="nav-item">
            <a class="nav-link ${page.equals("doctypes") ? "active" : ""}" href="/doctypes">Types</a>
        </li>
        <li class="nav-item">
            <a class="nav-link ${page.equals("tags") ? "active" : ""}" href="/tags">Tags</a>
        </li>
        <li class="nav-item mt-auto">
            <a class="nav-link ${page.equals("settings") ? "active" : ""}" href="/settings">Réglages</a>
        </li>
    </ul>
</nav>

<div class="main-content">
    ${content}
</div>

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
