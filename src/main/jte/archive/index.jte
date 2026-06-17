@import com.github.lafarer.archiver.model.Document
@import org.springframework.data.domain.Page
@import java.util.List

@param Page<Document> documents
@param String q
@param String selectedType
@param String selectedIssuer
@param List<String> selectedTags
@param List<String> allTypes
@param List<String> allIssuers
@param List<String> allTags
@param String page

@template.layout.base(page = page, title = "Archive", content = @`

<div class="page-header">
    <h1>Archive</h1>
</div>

<form id="archive-filters" class="page-filters"
      hx-get="/archive"
      hx-trigger="change, keyup changed delay:400ms"
      hx-target="#doc-list"
      hx-swap="innerHTML">

    <input type="search" name="q" class="form-control form-control-sm"
           style="width:200px" placeholder="Rechercher…" value="${q}">

    <select name="type" class="form-select form-select-sm" style="width:auto">
        <option value="">Tous les types</option>
        @for(String t : allTypes)
            <option value="${t}" selected="${t.equals(selectedType)}">${t}</option>
        @endfor
    </select>

    <input type="text" name="issuer" class="form-control form-control-sm"
           style="width:160px" placeholder="Émetteur…"
           value="${selectedIssuer}" list="issuer-list" autocomplete="off">
    <datalist id="issuer-list">
        @for(String iss : allIssuers)
            <option value="${iss}">${iss}</option>
        @endfor
    </datalist>

    <div class="dropdown">
        !{int tagCount = selectedTags.size();}
        <button type="button" class="btn btn-sm btn-outline-secondary dropdown-toggle"
                data-bs-toggle="dropdown" data-bs-auto-close="outside">
            Tags
            @if(tagCount > 0)
                <span class="badge bg-primary ms-1">${tagCount}</span>
            @endif
        </button>
        <ul class="dropdown-menu px-1 py-1" style="max-height:260px;overflow-y:auto;min-width:180px">
            @for(String tag : allTags)
                !{boolean checked = selectedTags.contains(tag);}
                <li>
                    <label class="dropdown-item d-flex align-items-center gap-2 py-1" style="cursor:pointer">
                        <input type="checkbox" name="tag" value="${tag}" checked="${checked}">
                        <span class="tag">${tag}</span>
                    </label>
                </li>
            @endfor
        </ul>
    </div>

    @if(!q.isBlank() || !selectedType.isBlank() || !selectedIssuer.isBlank() || !selectedTags.isEmpty())
        <a href="/archive" class="btn btn-sm btn-link text-muted p-0">Effacer</a>
    @endif

</form>

<div class="page-body">
    <div id="doc-list">
        @template.archive.list_fragment(documents = documents, q = q, selectedType = selectedType, selectedIssuer = selectedIssuer, selectedTags = selectedTags)
    </div>
</div>

`)
