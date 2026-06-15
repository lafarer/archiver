@import com.github.lafarer.archiver.model.Document
@import java.util.List

@param List<Document> documents
@param String archiveRoot

<span id="inbox-sidebar-badge" hx-swap-oob="true">
    @if(!documents.isEmpty())
        <span class="badge bg-warning text-dark">${documents.size()}</span>
    @endif
</span>

<h1 id="inbox-header-title" hx-swap-oob="true">
    Inbox <span class="badge bg-secondary">${documents.size()}</span>
</h1>

@template.inbox.doclist(documents = documents, archiveRoot = archiveRoot)
