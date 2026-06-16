@import com.github.lafarer.archiver.model.Document
@import com.github.lafarer.archiver.web.RulesController.SimulateResult
@import org.springframework.data.domain.Page
@import java.util.List

@param Long ruleId
@param Page<Document> docPage
@param List<SimulateResult> results
@param String pathTemplate

!{boolean simulated = !results.isEmpty();}

@if(docPage.isEmpty())
<div class="list-group-item text-muted">Aucun document archivé avec cette règle.</div>
@elseif(simulated)
    @for(SimulateResult r : results)
    <div class="list-group-item ${r.changed() ? "list-group-item-warning" : ""}">
        <div class="d-flex justify-content-between align-items-start">
            <div class="text-truncate me-2">${r.document().getTitle() != null ? r.document().getTitle() : r.document().getOriginalFilename()}</div>
            @if(r.changed())
                <span class="badge bg-warning text-dark flex-shrink-0">déplacé</span>
            @endif
        </div>
        @if(r.changed())
        <div class="text-decoration-line-through text-muted font-monospace text-truncate" style="font-size:0.75rem">${r.document().getResolvedPath()}</div>
        <div class="font-monospace text-truncate" style="font-size:0.75rem">→ ${r.newPath()}</div>
        @else
        <div class="text-muted font-monospace text-truncate" style="font-size:0.75rem">${r.document().getResolvedPath()}</div>
        @endif
    </div>
    @endfor
@else
    @for(Document doc : docPage.getContent())
    <div class="list-group-item">
        <div class="text-truncate">${doc.getTitle() != null ? doc.getTitle() : doc.getOriginalFilename()}</div>
        <div class="text-muted font-monospace text-truncate" style="font-size:0.75rem">${doc.getResolvedPath()}</div>
    </div>
    @endfor
@endif

@if(docPage.getTotalPages() > 1)
<div class="d-flex justify-content-between align-items-center px-3 py-2 border-top">
    <span class="text-muted small">Page ${docPage.getNumber() + 1} / ${docPage.getTotalPages()}</span>
    <div class="btn-group btn-group-sm">
        <button class="btn btn-outline-secondary ${docPage.hasPrevious() ? "" : "disabled"}"
                hx-get="/rules/${ruleId}/documents?page=${docPage.getNumber() - 1}"
                hx-include="#docFragTemplate"
                hx-target="#docs-body"
                hx-swap="innerHTML">‹</button>
        <button class="btn btn-outline-secondary ${docPage.hasNext() ? "" : "disabled"}"
                hx-get="/rules/${ruleId}/documents?page=${docPage.getNumber() + 1}"
                hx-include="#docFragTemplate"
                hx-target="#docs-body"
                hx-swap="innerHTML">›</button>
    </div>
</div>
@endif
