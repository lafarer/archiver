@import com.github.lafarer.archiver.model.Document
@import com.github.lafarer.archiver.model.CustomFieldDef
@import org.springframework.data.domain.Page
@import java.util.List
@import java.util.Map
@import java.util.Set

@param Page<Document> documents
@param String q
@param String selectedType
@param String selectedIssuer
@param List<String> selectedTags
@param Map<String, String> selectedCustomFields
@param List<String> allTypes
@param List<String> allIssuers
@param List<String> allTags
@param List<CustomFieldDef> customFieldDefs
@param Map<String, List<String>> cfSuggestions
@param Set<Long> outOfSyncIds
@param String totalSize = ""
@param String sort = "date_desc"
@param String page
@param boolean watchdogRunning = false

@template.layout.base(page = page, title = "Archive", watchdogRunning = watchdogRunning, content = @`

<div class="page-header">
    <h1>Archive @if(!totalSize.isEmpty())<span class="text-muted fw-normal small ms-2">${totalSize}</span>@endif</h1>
</div>

!{int activeFilterCount = (selectedType.isBlank() ? 0 : 1) + (selectedIssuer.isBlank() ? 0 : 1) + selectedTags.size() + selectedCustomFields.size();}

<form id="archive-filters"
      hx-get="/archive"
      hx-trigger="change, keyup changed delay:400ms"
      hx-target="#doc-list"
      hx-swap="innerHTML">

    <div class="page-filters">
        <input type="search" name="q" class="form-control form-control-sm"
               style="width:240px" placeholder="Rechercher…" value="${q}">

        <select name="sort" class="form-select form-select-sm" style="width:auto">
            <option value="date_desc"  selected="${sort.equals("date_desc")}">Date ↓</option>
            <option value="date_asc"   selected="${sort.equals("date_asc")}">Date ↑</option>
            <option value="title_asc"  selected="${sort.equals("title_asc")}">Titre A→Z</option>
            <option value="title_desc" selected="${sort.equals("title_desc")}">Titre Z→A</option>
            <option value="issuer_asc" selected="${sort.equals("issuer_asc")}">Émetteur A→Z</option>
            <option value="type_asc"   selected="${sort.equals("type_asc")}">Type A→Z</option>
        </select>

        <button type="button" class="btn btn-sm ${activeFilterCount > 0 ? "btn-primary" : "btn-outline-secondary"}"
                data-bs-toggle="offcanvas" data-bs-target="#filtersPanel">
            Filtres
            @if(activeFilterCount > 0)
                <span class="badge bg-white text-primary ms-1">${activeFilterCount}</span>
            @endif
        </button>

        @if(activeFilterCount > 0)
            <a href="/archive" class="btn btn-sm btn-link text-muted p-0">Effacer</a>
        @endif
    </div>

    <%-- Offcanvas panel --%>
    <div class="offcanvas offcanvas-end" tabindex="-1" id="filtersPanel" style="width:320px"
         data-bs-backdrop="false" data-bs-scroll="true">
        <div class="offcanvas-header border-bottom">
            <h6 class="offcanvas-title fw-semibold">Filtres</h6>
            <button type="button" class="btn-close" data-bs-dismiss="offcanvas"></button>
        </div>

        <div class="offcanvas-body d-flex flex-column gap-4 py-3">

            <div>
                <label class="form-label fw-semibold small">Type de document</label>
                <select name="type" class="form-select form-select-sm">
                    <option value="">Tous</option>
                    @for(String t : allTypes)
                        <option value="${t}" selected="${t.equals(selectedType)}">${t}</option>
                    @endfor
                </select>
            </div>

            <div>
                <label class="form-label fw-semibold small">Émetteur</label>
                <input type="text" name="issuer" class="form-control form-control-sm"
                       placeholder="Rechercher un émetteur…"
                       value="${selectedIssuer}" list="issuer-list" autocomplete="off">
                <datalist id="issuer-list">
                    @for(String iss : allIssuers)
                        <option value="${iss}">${iss}</option>
                    @endfor
                </datalist>
            </div>

            <div>
                <label class="form-label fw-semibold small">Tags</label>
                <div class="d-flex flex-column gap-1" style="max-height:220px;overflow-y:auto">
                    @for(String tag : allTags)
                        !{boolean checked = selectedTags.contains(tag);}
                        <label class="d-flex align-items-center gap-2 py-1 px-1 rounded" style="cursor:pointer">
                            <input type="checkbox" name="tag" value="${tag}" checked="${checked}">
                            <span class="tag">${tag}</span>
                        </label>
                    @endfor
                </div>
            </div>

            @if(!customFieldDefs.isEmpty())
            <div>
                <div class="fw-semibold small border-top pt-3 mb-3">Champs personnalisés</div>
                <div class="d-flex flex-column gap-3">
                    @for(CustomFieldDef def : customFieldDefs)
                        !{String cfKey = "cf_" + def.getSlug();}
                        !{String cfVal = selectedCustomFields.getOrDefault(def.getSlug(), "");}
                        !{List<String> suggestions = cfSuggestions.getOrDefault(def.getSlug(), List.of());}
                        <div>
                            <label class="form-label form-label-sm small">${def.getLabel()}</label>
                            <input type="text" name="${cfKey}" class="form-control form-control-sm"
                                   placeholder="${def.getLabel()}…" value="${cfVal}"
                                   list="cf-list-${def.getSlug()}" autocomplete="off">
                            @if(!suggestions.isEmpty())
                                <datalist id="cf-list-${def.getSlug()}">
                                    @for(String v : suggestions)
                                        <option value="${v}">${v}</option>
                                    @endfor
                                </datalist>
                            @endif
                        </div>
                    @endfor
                </div>
            </div>
            @endif

        </div>

        <div class="p-3 border-top">
            <a href="/archive" class="btn btn-outline-secondary btn-sm w-100">Effacer tout</a>
        </div>
    </div>

</form>

<div class="page-body">
    <div id="doc-list">
        @template.archive.list_fragment(documents = documents, q = q, selectedType = selectedType, selectedIssuer = selectedIssuer, selectedTags = selectedTags, selectedCustomFields = selectedCustomFields, customFieldDefs = customFieldDefs, outOfSyncIds = outOfSyncIds)
    </div>
</div>

<script>
(function() {
    var panel = document.getElementById('filtersPanel');
    var main  = document.getElementById('mainContent');
    if (!panel || !main) return;
    panel.addEventListener('show.bs.offcanvas',  function() { main.classList.add('filter-panel-open'); });
    panel.addEventListener('hidden.bs.offcanvas', function() { main.classList.remove('filter-panel-open'); });
})();
</script>

`)
