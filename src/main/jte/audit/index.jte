@import com.github.lafarer.archiver.service.StorageAuditService.AuditReport
@import com.github.lafarer.archiver.service.StorageAuditService.AuditEntry
@import com.github.lafarer.archiver.service.StorageAuditService.AnomalyType
@import java.util.List
@import java.util.Map

@param AuditReport report = null
@param String page
@param String message = null
@param boolean watchdogRunning = false
@param String contextPath = ""

@template.layout.base(page = page, title = "Audit", watchdogRunning = watchdogRunning, contextPath = contextPath, content = @`

<div class="page-header">
    <h1>Audit de stockage</h1>
    <a href="audit?run=true" class="btn btn-outline-primary btn-sm">
        ${report == null ? "Lancer l'audit" : "Rafraîchir"}
    </a>
</div>

<div class="page-body">

    @if(message != null)
    <div class="alert alert-success alert-dismissible fade show" role="alert">
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
    @endif

    @if(report == null)
    <div class="text-muted">Cliquez sur "Lancer l'audit" pour analyser la cohérence entre le système de fichiers et la base de données.</div>

    @elseif(!report.hasAnomalies())
    <div class="alert alert-success">
        Aucune anomalie détectée. ${report.filesScanned()} fichier(s) analysé(s), ${report.dbRecords()} enregistrement(s) en base.
    </div>

    @else
    <div class="text-muted small mb-3">
        ${report.filesScanned()} fichier(s) · ${report.dbRecords()} enregistrement(s) DB · ${report.anomalies().size()} anomalie(s) · analysé le ${report.scannedAt().toString().replace("T", " ").substring(0, 19)}
    </div>

    !{Map<AnomalyType, List<AuditEntry>> byType = report.byType();}

    <%-- UNTRACKED_WITH_SIDECAR : fichier + sidecar présents, absents de la DB (reconstruction) --%>
    @if(byType.containsKey(AnomalyType.UNTRACKED_WITH_SIDECAR))
    !{List<AuditEntry> entries = byType.get(AnomalyType.UNTRACKED_WITH_SIDECAR);}
    <div class="card mb-3">
        <div class="card-header d-flex justify-content-between align-items-center">
            <span class="fw-semibold">Non indexés avec sidecar <span class="badge bg-warning text-dark ms-1">${entries.size()}</span></span>
            <div class="d-flex align-items-center gap-2">
                <span class="text-muted small">Fichier ✓ · Sidecar ✓ · DB ✗</span>
                <form method="post" action="audit/repair/import-all-sidecars">
                    <button type="submit" class="btn btn-warning btn-sm">Tout importer</button>
                </form>
            </div>
        </div>
        <div class="list-group list-group-flush small">
            @for(AuditEntry e : entries)
            <div class="list-group-item d-flex justify-content-between align-items-center">
                <code class="text-truncate me-2">${e.relPath()}</code>
                <form method="post" action="audit/repair/import-sidecar" class="flex-shrink-0">
                    <input type="hidden" name="relPath" value="${e.relPath()}">
                    <button type="submit" class="btn btn-outline-warning btn-sm">Importer</button>
                </form>
            </div>
            @endfor
        </div>
    </div>
    @endif

    <%-- GHOST_RECORD : enregistrement DB sans fichier ni sidecar --%>
    @if(byType.containsKey(AnomalyType.GHOST_RECORD))
    !{List<AuditEntry> entries = byType.get(AnomalyType.GHOST_RECORD);}
    <div class="card mb-3">
        <div class="card-header d-flex justify-content-between align-items-center">
            <span class="fw-semibold">Enregistrements fantômes <span class="badge bg-danger ms-1">${entries.size()}</span></span>
            <div class="d-flex align-items-center gap-2">
                <span class="text-muted small">DB ✓ · Fichier ✗ · Sidecar ✗</span>
                <form method="post" action="audit/repair/delete-all-ghosts"
                      onsubmit="return confirm('Supprimer les ${entries.size()} enregistrement(s) fantôme(s) ?')">
                    <button type="submit" class="btn btn-danger btn-sm">Tout supprimer</button>
                </form>
            </div>
        </div>
        <div class="list-group list-group-flush small">
            @for(AuditEntry e : entries)
            <div class="list-group-item d-flex justify-content-between align-items-center">
                <div class="text-truncate me-2">
                    <div>${e.dbRecord().getTitle() != null ? e.dbRecord().getTitle() : e.dbRecord().getOriginalFilename()}</div>
                    <code class="text-muted">${e.relPath()}</code>
                </div>
                <form method="post" action="audit/repair/delete-record/${e.dbRecord().getId()}" class="flex-shrink-0">
                    <button type="submit" class="btn btn-outline-danger btn-sm">Supprimer</button>
                </form>
            </div>
            @endfor
        </div>
    </div>
    @endif

    <%-- MISSING_FILE : DB + sidecar présents, fichier manquant --%>
    @if(byType.containsKey(AnomalyType.MISSING_FILE))
    !{List<AuditEntry> entries = byType.get(AnomalyType.MISSING_FILE);}
    <div class="card mb-3">
        <div class="card-header d-flex justify-content-between align-items-center">
            <span class="fw-semibold">Fichiers manquants <span class="badge bg-danger ms-1">${entries.size()}</span></span>
            <div class="d-flex align-items-center gap-2">
                <span class="text-muted small">DB ✓ · Sidecar ✓ · Fichier ✗</span>
                <form method="post" action="audit/repair/delete-all-missing"
                      onsubmit="return confirm('Supprimer les ${entries.size()} enregistrement(s) et sidecar(s) ?')">
                    <button type="submit" class="btn btn-danger btn-sm">Tout supprimer</button>
                </form>
            </div>
        </div>
        <div class="list-group list-group-flush small">
            @for(AuditEntry e : entries)
            <div class="list-group-item d-flex justify-content-between align-items-center">
                <div class="text-truncate me-2">
                    <div>${e.dbRecord().getTitle() != null ? e.dbRecord().getTitle() : e.dbRecord().getOriginalFilename()}</div>
                    <code class="text-muted">${e.relPath()}</code>
                </div>
                <form method="post" action="audit/repair/delete-record/${e.dbRecord().getId()}" class="flex-shrink-0">
                    <button type="submit" class="btn btn-outline-danger btn-sm">Supprimer</button>
                </form>
            </div>
            @endfor
        </div>
    </div>
    @endif

    <%-- FILE_WITHOUT_SIDECAR : fichier + DB présents, sidecar manquant --%>
    @if(byType.containsKey(AnomalyType.FILE_WITHOUT_SIDECAR))
    !{List<AuditEntry> entries = byType.get(AnomalyType.FILE_WITHOUT_SIDECAR);}
    <div class="card mb-3">
        <div class="card-header d-flex justify-content-between align-items-center">
            <span class="fw-semibold">Sidecars manquants <span class="badge bg-secondary ms-1">${entries.size()}</span></span>
            <div class="d-flex align-items-center gap-2">
                <span class="text-muted small">Fichier ✓ · DB ✓ · Sidecar ✗</span>
                <form method="post" action="audit/repair/regenerate-all-sidecars">
                    <button type="submit" class="btn btn-outline-secondary btn-sm">Tout régénérer</button>
                </form>
            </div>
        </div>
        <div class="list-group list-group-flush small">
            @for(AuditEntry e : entries)
            <div class="list-group-item d-flex justify-content-between align-items-center">
                <div class="text-truncate me-2">
                    <div>${e.dbRecord().getTitle() != null ? e.dbRecord().getTitle() : e.dbRecord().getOriginalFilename()}</div>
                    <code class="text-muted">${e.relPath()}</code>
                </div>
                <form method="post" action="audit/repair/regenerate-sidecar/${e.dbRecord().getId()}" class="flex-shrink-0">
                    <button type="submit" class="btn btn-outline-secondary btn-sm">Régénérer</button>
                </form>
            </div>
            @endfor
        </div>
    </div>
    @endif

    <%-- UNTRACKED_NO_SIDECAR : fichier dans archive sans sidecar ni DB — ré-analyse --%>
    @if(byType.containsKey(AnomalyType.UNTRACKED_NO_SIDECAR))
    !{List<AuditEntry> entries = byType.get(AnomalyType.UNTRACKED_NO_SIDECAR);}
    <div class="card mb-3">
        <div class="card-header d-flex justify-content-between align-items-center">
            <span class="fw-semibold">Non indexés sans sidecar <span class="badge bg-secondary ms-1">${entries.size()}</span></span>
            <div class="d-flex align-items-center gap-2">
                <span class="text-muted small">Fichier ✓ · DB ✗ · Sidecar ✗</span>
                <form method="post" action="audit/repair/reanalyze-all-untracked">
                    <button type="submit" class="btn btn-outline-secondary btn-sm">Tout ré-analyser</button>
                </form>
            </div>
        </div>
        <div class="list-group list-group-flush small">
            @for(AuditEntry e : entries)
            <div class="list-group-item d-flex justify-content-between align-items-center">
                <code class="text-truncate me-2">${e.relPath()}</code>
                <form method="post" action="audit/repair/reanalyze-archive-file" class="flex-shrink-0">
                    <input type="hidden" name="relPath" value="${e.relPath()}">
                    <button type="submit" class="btn btn-outline-secondary btn-sm">Ré-analyser</button>
                </form>
            </div>
            @endfor
        </div>
    </div>
    @endif

    <%-- INBOX_ORPHAN : fichier en inbox sans enregistrement DB --%>
    @if(byType.containsKey(AnomalyType.INBOX_ORPHAN))
    !{List<AuditEntry> entries = byType.get(AnomalyType.INBOX_ORPHAN);}
    <div class="card mb-3">
        <div class="card-header d-flex justify-content-between align-items-center">
            <span class="fw-semibold">Inbox non indexés <span class="badge bg-info text-dark ms-1">${entries.size()}</span></span>
            <div class="d-flex align-items-center gap-2">
                <span class="text-muted small">Inbox ✓ · DB ✗</span>
                <form method="post" action="audit/repair/analyze-all-inbox-orphans">
                    <button type="submit" class="btn btn-outline-info btn-sm">Tout analyser</button>
                </form>
            </div>
        </div>
        <div class="list-group list-group-flush small">
            @for(AuditEntry e : entries)
            <div class="list-group-item d-flex justify-content-between align-items-center">
                <code class="text-truncate me-2">${e.relPath()}</code>
                <form method="post" action="audit/repair/analyze-inbox-orphan" class="flex-shrink-0">
                    <input type="hidden" name="relPath" value="${e.relPath()}">
                    <button type="submit" class="btn btn-outline-info btn-sm">Analyser</button>
                </form>
            </div>
            @endfor
        </div>
    </div>
    @endif

    <%-- ORPHAN_SIDECAR : sidecar sans fichier ni DB --%>
    @if(byType.containsKey(AnomalyType.ORPHAN_SIDECAR))
    !{List<AuditEntry> entries = byType.get(AnomalyType.ORPHAN_SIDECAR);}
    <div class="card mb-3">
        <div class="card-header d-flex justify-content-between align-items-center">
            <span class="fw-semibold">Sidecars orphelins <span class="badge bg-secondary ms-1">${entries.size()}</span></span>
            <div class="d-flex align-items-center gap-2">
                <span class="text-muted small">Sidecar ✓ · Fichier ✗ · DB ✗</span>
                <form method="post" action="audit/repair/delete-all-orphan-sidecars"
                      onsubmit="return confirm('Supprimer les ${entries.size()} sidecar(s) orphelin(s) ?')">
                    <button type="submit" class="btn btn-outline-danger btn-sm">Tout supprimer</button>
                </form>
            </div>
        </div>
        <div class="list-group list-group-flush small">
            @for(AuditEntry e : entries)
            <div class="list-group-item d-flex justify-content-between align-items-center">
                <code class="text-truncate me-2">${e.relPath()}</code>
                <form method="post" action="audit/repair/delete-sidecar" class="flex-shrink-0">
                    <input type="hidden" name="relPath" value="${e.relPath()}">
                    <button type="submit" class="btn btn-outline-danger btn-sm">Supprimer</button>
                </form>
            </div>
            @endfor
        </div>
    </div>
    @endif

    @endif

</div>

`)
