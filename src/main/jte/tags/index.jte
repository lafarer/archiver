@import com.github.lafarer.archiver.model.TagDef
@import java.util.List

@param List<TagDef> tags
@param String page
@param boolean watchdogRunning = false

@template.layout.base(page = page, title = "Tags", watchdogRunning = watchdogRunning, content = @`

<div class="page-header">
    <h1>Tags</h1>
    <a href="/tags/new" class="btn btn-primary btn-sm">+ Nouveau tag</a>
</div>

<div class="page-body">

    @if(tags.isEmpty())
        <div class="text-center text-muted py-5">Aucun tag défini.</div>
    @else
        <div class="list-group">
            @for(TagDef tag : tags)
                <div class="list-group-item d-flex justify-content-between align-items-start ${tag.isEnabled() ? "" : "opacity-50"}">
                    <div class="me-3 flex-grow-1">
                        <div class="d-flex align-items-center gap-2 mb-1">
                            <span class="fw-semibold">${tag.getLabel()}</span>
                            <code class="text-muted small">${tag.getSlug()}</code>
                            @if(!tag.isEnabled())
                                <span class="badge bg-secondary">désactivé</span>
                            @endif
                        </div>
                        @if(tag.getDescription() != null && !tag.getDescription().isBlank())
                            <div class="text-muted small">${tag.getDescription()}</div>
                        @endif
                    </div>
                    <div class="d-flex gap-1 flex-shrink-0">
                        <form method="post" action="/tags/${tag.getId()}/toggle">
                            <button class="btn btn-sm ${tag.isEnabled() ? "btn-outline-secondary" : "btn-outline-success"}"
                                    title="${tag.isEnabled() ? "Désactiver" : "Activer"}">
                                ${tag.isEnabled() ? "✕" : "✓"}
                            </button>
                        </form>
                        <a href="/tags/${tag.getId()}/edit" class="btn btn-sm btn-outline-secondary">Éditer</a>
                        <form method="post" action="/tags/${tag.getId()}/delete"
                              onsubmit="return confirm('Supprimer ce tag ?')">
                            <button class="btn btn-sm btn-outline-danger">×</button>
                        </form>
                    </div>
                </div>
            @endfor
        </div>
    @endif

</div>

`)
