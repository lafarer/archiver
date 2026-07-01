@import com.github.lafarer.archiver.model.CustomFieldDef
@import java.util.List

@param List<CustomFieldDef> fields
@param String page
@param boolean watchdogRunning = false

@template.layout.base(page = page, title = "Champs", watchdogRunning = watchdogRunning, content = @`

<div class="page-header">
    <h1>Champs personnalisés</h1>
    <a href="fields/new" class="btn btn-primary btn-sm">+ Nouveau champ</a>
</div>

<div class="page-body">
    @if(fields.isEmpty())
        <div class="text-center text-muted py-5">Aucun champ personnalisé défini.</div>
    @else
        <div class="list-group">
            @for(CustomFieldDef field : fields)
                <div class="list-group-item d-flex justify-content-between align-items-start">
                    <div>
                        <div class="fw-semibold">
                            ${field.getLabel()}
                            <code class="ms-2 text-muted small">${field.getSlug()}</code>
                            <span class="badge bg-light text-dark ms-1">${field.getFieldType().name().toLowerCase()}</span>
                        </div>
                        <div class="text-muted small mt-1">${field.getDescription()}</div>
                    </div>
                    <div class="d-flex gap-1">
                        <a href="fields/${field.getId()}/edit" class="btn btn-sm btn-outline-secondary">Éditer</a>
                        <form method="post" action="fields/${field.getId()}/delete"
                              onsubmit="return confirm('Supprimer ce champ ?')">
                            <button class="btn btn-sm btn-outline-danger">×</button>
                        </form>
                    </div>
                </div>
            @endfor
        </div>
    @endif
</div>

`)
