@import com.github.lafarer.archiver.service.StorageAuditService.AuditReport
@import com.github.lafarer.archiver.service.StorageAuditService.AuditEntry
@import com.github.lafarer.archiver.service.StorageAuditService.AnomalyType
@import java.util.List
@import java.util.Map

@param AuditReport report = null
@param String page
@param String message = null

@template.layout.base(page = page, title = "Audit", content = @`

<div class="page-header">
    <h1>Audit de stockage</h1>
    <a href="/audit?run=true" class="btn btn-outline-primary btn-sm">
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

    @if(byType.containsKey(AnomalyType.UNTRACKED_WITH_SIDECAR))
    !{List<AuditEntry> entries = byType.get(AnomalyType.UNTRACKED_WITH_SIDECAR);}
    <div class="card mb-3">
        <div class="card-header d-flex justify-content-between align-items-center">
            <span class="fw-semibold">Non indexés avec sidecar <span class="badge bg-warning text-dark ms-1">${entries.size()}</span></span>
            <span class="text-muted small">Fichier ✓ · Sidecar ✓ · DB ✗ — peuvent être reconstruits</span>
        </div>
        <div class="list-group list-group-flush small">
            @for(AuditEntry e : entries)
            <div class="list-group-item d-flex justify-content-between align-items-center">
                <code class="text-truncate me-2">${e.relPath()}</code>
            </div>
            @endfor
        </div>
    </div>
    @endif

    @if(byType.containsKey(AnomalyType.GHOST_RECORD))
    !{List<AuditEntry> entries = byType.get(AnomalyType.GHOST_RECORD);}
    <div class="card mb-3">
        <div class="card-header d-flex justify-content-between align-items-center">
            <span class="fw-semibold">Enregistrements fantômes <span class="badge bg-danger ms-1">${entries.size()}</span></span>
            <span class="text-muted small">DB ✓ · Fichier ✗ · Sidecar ✗</span>
        </div>
        <div class="list-group list-group-flush small">
            @for(AuditEntry e : entries)
            <div class="list-group-item d-flex justify-content-between align-items-center">
                <div class="text-truncate me-2">
                    <div>${e.dbRecord().getTitle() != null ? e.dbRecord().getTitle() : e.dbRecord().getOriginalFilename()}</div>
                    <code class="text-muted">${e.relPath()}</code>
                </div>
            </div>
            @endfor
        </div>
    </div>
    @endif

    @if(byType.containsKey(AnomalyType.MISSING_FILE))
    !{List<AuditEntry> entries = byType.get(AnomalyType.MISSING_FILE);}
    <div class="card mb-3">
        <div class="card-header d-flex justify-content-between align-items-center">
            <span class="fw-semibold">Fichiers manquants <span class="badge bg-danger ms-1">${entries.size()}</span></span>
            <span class="text-muted small">DB ✓ · Sidecar ✓ · Fichier ✗</span>
        </div>
        <div class="list-group list-group-flush small">
            @for(AuditEntry e : entries)
            <div class="list-group-item d-flex justify-content-between align-items-center">
                <div class="text-truncate me-2">
                    <div>${e.dbRecord().getTitle() != null ? e.dbRecord().getTitle() : e.dbRecord().getOriginalFilename()}</div>
                    <code class="text-muted">${e.relPath()}</code>
                </div>
            </div>
            @endfor
        </div>
    </div>
    @endif

    @if(byType.containsKey(AnomalyType.FILE_WITHOUT_SIDECAR))
    !{List<AuditEntry> entries = byType.get(AnomalyType.FILE_WITHOUT_SIDECAR);}
    <div class="card mb-3">
        <div class="card-header d-flex justify-content-between align-items-center">
            <span class="fw-semibold">Sidecars manquants <span class="badge bg-secondary ms-1">${entries.size()}</span></span>
            <span class="text-muted small">Fichier ✓ · DB ✓ · Sidecar ✗</span>
        </div>
        <div class="list-group list-group-flush small">
            @for(AuditEntry e : entries)
            <div class="list-group-item d-flex justify-content-between align-items-center">
                <div class="text-truncate me-2">
                    <div>${e.dbRecord().getTitle() != null ? e.dbRecord().getTitle() : e.dbRecord().getOriginalFilename()}</div>
                    <code class="text-muted">${e.relPath()}</code>
                </div>
            </div>
            @endfor
        </div>
    </div>
    @endif

    @if(byType.containsKey(AnomalyType.UNTRACKED_NO_SIDECAR))
    !{List<AuditEntry> entries = byType.get(AnomalyType.UNTRACKED_NO_SIDECAR);}
    <div class="card mb-3">
        <div class="card-header d-flex justify-content-between align-items-center">
            <span class="fw-semibold">Non indexés sans sidecar <span class="badge bg-secondary ms-1">${entries.size()}</span></span>
            <span class="text-muted small">Fichier ✓ · DB ✗ · Sidecar ✗ — nécessitent une ré-analyse</span>
        </div>
        <div class="list-group list-group-flush small">
            @for(AuditEntry e : entries)
            <div class="list-group-item d-flex justify-content-between align-items-center">
                <code class="text-truncate me-2">${e.relPath()}</code>
            </div>
            @endfor
        </div>
    </div>
    @endif

    @if(byType.containsKey(AnomalyType.ORPHAN_SIDECAR))
    !{List<AuditEntry> entries = byType.get(AnomalyType.ORPHAN_SIDECAR);}
    <div class="card mb-3">
        <div class="card-header d-flex justify-content-between align-items-center">
            <span class="fw-semibold">Sidecars orphelins <span class="badge bg-secondary ms-1">${entries.size()}</span></span>
            <span class="text-muted small">Sidecar ✓ · Fichier ✗ · DB ✗</span>
        </div>
        <div class="list-group list-group-flush small">
            @for(AuditEntry e : entries)
            <div class="list-group-item d-flex justify-content-between align-items-center">
                <code class="text-truncate me-2">${e.relPath()}</code>
            </div>
            @endfor
        </div>
    </div>
    @endif

    @endif

</div>

`)
