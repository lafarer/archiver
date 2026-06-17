@import com.github.lafarer.archiver.config.ArchiverProperties
@import com.github.lafarer.archiver.service.SettingService

@param SettingService settings
@param ArchiverProperties props
@param boolean watchdogRunning
@param String page

@template.layout.base(page = page, title = "Réglages", watchdogRunning = watchdogRunning, content = @`

<div class="page-header">
    <h1>Réglages</h1>
</div>

<div class="page-body">
<form method="post" action="/settings">
<div style="max-width: 560px" class="d-flex flex-column gap-4">

    <div class="card">
        <div class="card-header fw-semibold">Dossiers <small class="text-muted">(lecture seule)</small></div>
        <div class="card-body">
            <dl class="row mb-0">
                <dt class="col-sm-4">Dossier d'archivage</dt>
                <dd class="col-sm-8"><code>${props.getArchivePath().toString()}</code></dd>
                <dt class="col-sm-4">Dossier inbox</dt>
                <dd class="col-sm-8 mb-0"><code>${props.getInboxPath().toString()}</code></dd>
            </dl>
        </div>
    </div>

    <div class="card">
        <div class="card-header fw-semibold">Surveillance automatique</div>
        <div class="card-body d-flex flex-column gap-3">
            <div class="form-check form-switch">
                <input class="form-check-input" type="checkbox" name="watchdog_enabled"
                       value="true" id="watchdog"
                       checked="${settings.getBoolean("watchdog_enabled")}">
                <label class="form-check-label" for="watchdog">
                    Watchdog inbox
                    <span class="badge ${watchdogRunning ? "bg-success" : "bg-secondary"} ms-1">
                        ${watchdogRunning ? "actif" : "inactif"}
                    </span>
                </label>
            </div>
            <div>
                <label class="form-label" for="debounceMs">Délai anti-rebond (ms)</label>
                <input type="number" class="form-control form-control-sm" id="debounceMs"
                       name="watchdog_debounce_ms" min="200" max="10000" step="100"
                       value="${settings.get("watchdog_debounce_ms")}">
                <div class="form-text">
                    Délai d'attente avant de traiter un nouveau fichier détecté.
                    Absorbe les événements filesystem multiples générés par un seul dépôt
                    (notamment sur les volumes Docker). Valeur par défaut : 1500 ms.
                </div>
            </div>
        </div>
    </div>

    <div class="card">
        <div class="card-header fw-semibold">Import manuel</div>
        <div class="card-body">
            <label class="form-label">Action sur le fichier source</label>
            <div>
                <div class="form-check form-check-inline">
                    <input class="form-check-input" type="radio" name="import_mode"
                           value="copy" id="modeCopy"
                           checked="${"copy".equals(settings.get("import_mode"))}">
                    <label class="form-check-label" for="modeCopy">Copier</label>
                </div>
                <div class="form-check form-check-inline">
                    <input class="form-check-input" type="radio" name="import_mode"
                           value="move" id="modeMove"
                           checked="${"move".equals(settings.get("import_mode"))}">
                    <label class="form-check-label" for="modeMove">Déplacer</label>
                </div>
            </div>
        </div>
    </div>

    <div class="card">
        <div class="card-header fw-semibold">Intelligence artificielle</div>
        <div class="card-body d-flex flex-column gap-3">
            <div>
                <label class="form-label" for="aiModel">Modèle</label>
                <select name="ai_model" id="aiModel" class="form-select">
                    <option value="claude-sonnet-4-6" selected="${"claude-sonnet-4-6".equals(settings.get("ai_model"))}">claude-sonnet-4-6</option>
                    <option value="claude-opus-4-7"   selected="${"claude-opus-4-7".equals(settings.get("ai_model"))}">claude-opus-4-7</option>
                    <option value="claude-haiku-4-5" selected="${"claude-haiku-4-5".equals(settings.get("ai_model"))}">claude-haiku-4-5</option>
                </select>
            </div>
            <div class="form-check form-switch">
                <input class="form-check-input" type="checkbox" name="auto_archive_enabled"
                       value="true" id="autoArchive"
                       checked="${settings.getBoolean("auto_archive_enabled")}"
                       onchange="document.getElementById('thresholdSection').style.display = this.checked ? '' : 'none'">
                <label class="form-check-label" for="autoArchive">Archivage automatique</label>
                <div class="form-text">Si activé, les documents dont la confiance dépasse le seuil sont archivés sans validation manuelle.</div>
            </div>
            <div id="thresholdSection" style="${settings.getBoolean("auto_archive_enabled") ? "" : "display:none"}">
                <label class="form-label" for="confThreshold">
                    Seuil de confiance minimum
                    <strong id="thresholdVal">${settings.get("confidence_threshold")}</strong>
                </label>
                <input type="range" class="form-range" id="confThreshold"
                       name="confidence_threshold" min="0" max="1" step="0.05"
                       value="${settings.get("confidence_threshold")}"
                       oninput="document.getElementById('thresholdVal').textContent = this.value">
                <div class="form-text">En-dessous du seuil, le document reste en attente de validation manuelle.</div>
            </div>
        </div>
    </div>

    <div>
        <button type="submit" class="btn btn-primary">Enregistrer</button>
    </div>

</div>
</form>
</div>

`)
