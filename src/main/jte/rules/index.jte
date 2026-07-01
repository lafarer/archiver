@import com.github.lafarer.archiver.model.StoragePathRule
@import java.util.List
@import java.util.Map

@param List<StoragePathRule> rules
@param Map<Long, Long> docCounts
@param Map<Long, Long> outOfSyncCounts
@param boolean hasDefaultRule
@param String page
@param String message = null
@param boolean watchdogRunning = false
@param String contextPath = ""

@template.layout.base(page = page, title = "Règles", watchdogRunning = watchdogRunning, contextPath = contextPath, content = @`

<div class="page-header">
    <h1>Règles de stockage</h1>
    <a href="rules/new" class="btn btn-primary btn-sm">+ Nouvelle règle</a>
</div>

<div class="page-body">
    @if(message != null)
    <div class="alert alert-success alert-dismissible fade show" role="alert">
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
    @endif
    @if(!hasDefaultRule)
    <div class="alert alert-warning">
        Aucune règle par défaut définie. Les documents qui ne correspondent à aucune règle ne pourront pas être archivés. <a href="rules/new">Créez une règle par défaut</a>.
    </div>
    @endif
    <div id="rules-list">
        @for(StoragePathRule rule : rules)
            <div class="rule-item" data-id="${rule.getId()}">
                <span class="rule-handle">⠿</span>
                <span class="rule-priority">${rule.getPriority()}</span>
                <div class="rule-body">
                    <div class="rule-label">
                        ${rule.getLabel()}
                        @if(rule.isDefault())
                            <span class="badge bg-primary ms-1">défaut</span>
                        @endif
                        @if(!rule.isActive())
                            <span class="badge bg-secondary ms-1">inactif</span>
                        @endif
                        !{long count = docCounts.getOrDefault(rule.getId(), 0L);}
                        @if(count > 0)
                            <span class="badge bg-light text-secondary border ms-1">${count} doc${count > 1 ? "s" : ""}</span>
                        @endif
                        !{long outOfSync = outOfSyncCounts.getOrDefault(rule.getId(), 0L);}
                        @if(outOfSync > 0)
                            <span class="badge bg-warning text-dark ms-1">${outOfSync} à déplacer</span>
                        @endif
                    </div>
                    @if(rule.getConditionNl() != null)
                        <div class="rule-condition">"${rule.getConditionNl()}"</div>
                    @endif
                    <div class="rule-template">${rule.getPathTemplate()}</div>
                </div>
                <div class="d-flex gap-1">
                    <a href="rules/${rule.getId()}/edit" class="btn btn-sm btn-outline-secondary">Éditer</a>
                    <form method="post" action="rules/${rule.getId()}/delete"
                          onsubmit="return confirm('Supprimer cette règle ?')">
                        <button class="btn btn-sm btn-outline-danger">×</button>
                    </form>
                </div>
            </div>
        @endfor
    </div>
</div>

<script>
    new Sortable(document.getElementById('rules-list'), {
        handle: '.rule-handle',
        animation: 150,
        onEnd: function() {
            const ids = [...document.querySelectorAll('.rule-item')].map(el => el.dataset.id);
            fetch('${contextPath}/rules/reorder', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify(ids.map(Number))
            });
        }
    });
</script>

`)
