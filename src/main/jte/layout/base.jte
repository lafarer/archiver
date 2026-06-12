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
        <li class="nav-item mt-auto">
            <a class="nav-link ${page.equals("settings") ? "active" : ""}" href="/settings">Réglages</a>
        </li>
    </ul>
</nav>

<div class="main-content">
    ${content}
</div>

</body>
</html>
