@import com.github.lafarer.archiver.model.DocumentTypeDef
@import java.util.List

@param List<DocumentTypeDef> types
@param String page
@param boolean watchdogRunning = false

@template.layout.base(page = page, title = "Types de document", watchdogRunning = watchdogRunning, content = @`

<div class="page-header">
    <h1>Types de document</h1>
    <a href="doctypes/new" class="btn btn-primary btn-sm">+ Nouveau type</a>
</div>

<div class="page-body">

    @if(types.isEmpty())
        <div class="text-center text-muted py-5">Aucun type de document défini.</div>
    @else
        <div class="list-group">
            @for(DocumentTypeDef type : types)
                <div class="list-group-item d-flex justify-content-between align-items-start ${type.isEnabled() ? "" : "opacity-50"}">
                    <div class="me-3 flex-grow-1">
                        <div class="d-flex align-items-center gap-2 mb-1">
                            <span class="fw-semibold">${type.getLabel()}</span>
                            <code class="text-muted small">${type.getSlug()}</code>
                            @if(!type.isEnabled())
                                <span class="badge bg-secondary">désactivé</span>
                            @endif
                        </div>
                        @if(type.getDescription() != null && !type.getDescription().isBlank())
                            <div class="text-muted small">${type.getDescription()}</div>
                        @endif
                    </div>
                    <div class="d-flex gap-1 flex-shrink-0">
                        <form method="post" action="doctypes/${type.getId()}/toggle">
                            <button class="btn btn-sm ${type.isEnabled() ? "btn-outline-secondary" : "btn-outline-success"}"
                                    title="${type.isEnabled() ? "Désactiver" : "Activer"}">
                                ${type.isEnabled() ? "✕" : "✓"}
                            </button>
                        </form>
                        <a href="doctypes/${type.getId()}/edit" class="btn btn-sm btn-outline-secondary">Éditer</a>
                        <form method="post" action="doctypes/${type.getId()}/delete"
                              onsubmit="return confirm('Supprimer ce type ?')">
                            <button class="btn btn-sm btn-outline-danger">×</button>
                        </form>
                    </div>
                </div>
            @endfor
        </div>
    @endif

</div>

`)
