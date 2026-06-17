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
@param List<CustomFieldDef> customFieldDefs
@param Set<Long> outOfSyncIds = java.util.Set.of()
@param String navBase = ""

!{boolean hasFilters = !q.isBlank() || !selectedType.isBlank() || !selectedIssuer.isBlank() || !selectedTags.isEmpty() || !selectedCustomFields.isEmpty();}
@if(hasFilters)
<div class="d-flex flex-wrap gap-2 mb-3 align-items-center">
    @if(!q.isBlank())
        <span class="badge rounded-pill bg-secondary d-flex align-items-center gap-1">
            <span>Recherche : ${q}</span>
            <button type="button" class="btn-close btn-close-white" style="font-size:0.6rem"
                    onclick="removeFilter('q', '')"></button>
        </span>
    @endif
    @if(!selectedType.isBlank())
        <span class="badge rounded-pill bg-secondary d-flex align-items-center gap-1">
            <span>Type : ${selectedType}</span>
            <button type="button" class="btn-close btn-close-white" style="font-size:0.6rem"
                    onclick="removeFilter('type', '')"></button>
        </span>
    @endif
    @if(!selectedIssuer.isBlank())
        <span class="badge rounded-pill bg-secondary d-flex align-items-center gap-1">
            <span>Émetteur : ${selectedIssuer}</span>
            <button type="button" class="btn-close btn-close-white" style="font-size:0.6rem"
                    onclick="removeFilter('issuer', '')"></button>
        </span>
    @endif
    @for(String tag : selectedTags)
        <span class="badge rounded-pill bg-secondary d-flex align-items-center gap-1">
            <span>${tag}</span>
            <button type="button" class="btn-close btn-close-white" style="font-size:0.6rem"
                    onclick="removeFilter('tag', '${tag}')"></button>
        </span>
    @endfor
    @for(var entry : selectedCustomFields.entrySet())
        !{String cfLabel = customFieldDefs.stream().filter(d -> d.getSlug().equals(entry.getKey())).map(d -> d.getLabel()).findFirst().orElse(entry.getKey());}
        <span class="badge rounded-pill bg-secondary d-flex align-items-center gap-1">
            <span>${cfLabel} : ${entry.getValue()}</span>
            <button type="button" class="btn-close btn-close-white" style="font-size:0.6rem"
                    onclick="removeFilter('cf_${entry.getKey()}', '')"></button>
        </span>
    @endfor
</div>
@endif

@if(documents.isEmpty())
    <div class="text-center text-muted py-5">Aucun document trouvé.</div>
@else
    <div class="text-muted small mb-2">${documents.getTotalElements()} document${documents.getTotalElements() > 1 ? "s" : ""}</div>
    !{int[] navPos = {0};}
    @for(Document doc : documents.getContent())
        !{int pos = navPos[0]++;}
        <div class="doc-card">
            <div class="doc-card-header">
                <span class="badge bg-light text-dark">${doc.getDocumentType() != null ? doc.getDocumentType() : "-"}</span>
                @if(outOfSyncIds.contains(doc.getId()))
                    <span class="badge bg-warning text-dark">⚠ chemin modifié</span>
                @endif
                <span class="doc-card-date">${doc.getDocumentDate() != null ? doc.getDocumentDate() : "-"}</span>
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
                    <a href="/archive/${doc.getId()}?pos=${pos}${navBase.isEmpty() ? "" : "&" + navBase}" class="btn btn-sm btn-outline-secondary">Détail</a>
                </div>
            </div>
        </div>
    @endfor

    @if(documents.getTotalPages() > 1)
        <nav class="d-flex justify-content-between align-items-center mt-3">
            <span class="text-muted small">
                Page ${documents.getNumber() + 1} / ${documents.getTotalPages()}
            </span>
            <ul class="pagination pagination-sm mb-0">
                <li class="page-item ${documents.isFirst() ? "disabled" : ""}">
                    <a class="page-link" href="#"
                       hx-get="/archive" hx-include="#archive-filters"
                       hx-vals='{"page":"${documents.getNumber() - 1}"}'
                       hx-target="#doc-list" hx-swap="innerHTML">‹</a>
                </li>
                @for(int p = 0; p < documents.getTotalPages(); p++)
                    @if(Math.abs(p - documents.getNumber()) <= 2)
                        <li class="page-item ${p == documents.getNumber() ? "active" : ""}">
                            <a class="page-link" href="#"
                               hx-get="/archive" hx-include="#archive-filters"
                               hx-vals='{"page":"${p}"}'
                               hx-target="#doc-list" hx-swap="innerHTML">${p + 1}</a>
                        </li>
                    @endif
                @endfor
                <li class="page-item ${documents.isLast() ? "disabled" : ""}">
                    <a class="page-link" href="#"
                       hx-get="/archive" hx-include="#archive-filters"
                       hx-vals='{"page":"${documents.getNumber() + 1}"}'
                       hx-target="#doc-list" hx-swap="innerHTML">›</a>
                </li>
            </ul>
        </nav>
    @endif
@endif

<script>
function removeFilter(name, value) {
    var form = document.getElementById('archive-filters');
    if (!form) return;
    if (value === '') {
        var el = form.elements[name];
        if (!el) return;
        if (el.type === 'checkbox') { el.checked = false; }
        else { el.value = ''; }
    } else {
        var boxes = form.querySelectorAll('input[name="' + name + '"]');
        boxes.forEach(function(cb) { if (cb.value === value) cb.checked = false; });
    }
    htmx.trigger(form, 'change');
}
</script>
