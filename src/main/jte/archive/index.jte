@import com.github.lafarer.archiver.model.Document
@import org.springframework.data.domain.Page

@param Page<Document> documents
@param String q
@param String page

@template.layout.base(page = page, title = "Archive", content = @`

<div class="page-header">
    <h1>Archive <span class="badge bg-secondary">${documents.getTotalElements()}</span></h1>
    <input type="search" class="form-control form-control-sm w-25"
           placeholder="Rechercher…"
           hx-get="/archive" hx-trigger="keyup changed delay:300ms"
           hx-target="#doc-list" hx-swap="innerHTML" hx-include="this" name="q"
           value="${q != null ? q : ""}">
</div>

<div class="page-body">
    <div id="doc-list">
        @template.archive.list_fragment(documents = documents, q = q != null ? q : "")
    </div>
</div>

`)
