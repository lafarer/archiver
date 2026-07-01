@import com.github.lafarer.archiver.model.Document
@import com.github.lafarer.archiver.model.CustomFieldDef
@import com.github.lafarer.archiver.model.DocumentTypeDef
@import com.github.lafarer.archiver.model.TagDef
@import com.github.lafarer.archiver.model.ClassificationHistory
@import com.github.lafarer.archiver.model.enums.ClassificationTrigger
@import com.github.lafarer.archiver.service.DocumentPipelineService.ProposedPathParts
@import com.github.lafarer.archiver.web.ArchiveController
@import java.time.ZoneId
@import java.time.format.DateTimeFormatter
@import java.util.List
@import java.util.Map

@param Document document
@param List<CustomFieldDef> customFieldDefs
@param List<DocumentTypeDef> documentTypeDefs
@param List<TagDef> allTagDefs
@param List<String> issuerSuggestions
@param Map<String, List<String>> fieldSuggestions
@param Map<String, String> cfProvenance
@param ProposedPathParts proposedPath
@param List<ClassificationHistory> history
@param String prevUrl = null
@param String nextUrl = null
@param String backUrl = null
@param String page
@param String message = null
@param boolean watchdogRunning = false
@param String contextPath = ""

!{String pageTitle = document.getTitle() != null ? document.getTitle() : document.getOriginalFilename();}
!{boolean previewable = document.getMimeType() != null && (document.getMimeType().startsWith("image/") || document.getMimeType().equals("application/pdf"));}
@template.layout.base(page = page, title = pageTitle, watchdogRunning = watchdogRunning, contextPath = contextPath, content = @`

!{String previewTitle = document.getTitle() != null ? document.getTitle() : document.getOriginalFilename();}
<div class="page-header">
    <h1>
        <a href="${backUrl != null ? backUrl : "archive"}" class="text-decoration-none text-muted me-2">←</a>
        ${pageTitle}
    </h1>
    <div class="d-flex gap-2 align-items-center">
        @if(prevUrl != null)
            <a href="${prevUrl}" class="btn btn-sm btn-outline-secondary" title="Document précédent">‹</a>
        @else
            <button class="btn btn-sm btn-outline-secondary" disabled>‹</button>
        @endif
        @if(nextUrl != null)
            <a href="${nextUrl}" class="btn btn-sm btn-outline-secondary" title="Document suivant">›</a>
        @else
            <button class="btn btn-sm btn-outline-secondary" disabled>›</button>
        @endif
        @if(previewable)
            <button type="button" class="btn btn-outline-primary btn-sm"
                    onclick="openPreviewDrawer('documents/${document.getId()}/file', '${document.getMimeType()}', '${previewTitle}')">
                Aperçu
            </button>
        @endif
    </div>
</div>

<div class="page-body">

    @if(message != null)
    <div class="alert alert-success alert-dismissible fade show" role="alert">
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
    @endif

    !{boolean pathChanged = proposedPath.full() != null && document.getResolvedPath() != null && !document.getResolvedPath().equals(proposedPath.full());}
    !{String docSize = ArchiveController.formatSize(document.getFileSizeBytes());}
    !{DateTimeFormatter dtf = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm").withZone(ZoneId.systemDefault());}
    <div class="mb-3 text-muted small">
        Fichier : <strong>${document.getOriginalFilename()}</strong>
        &nbsp;·&nbsp; ${docSize}
        @if(document.getFilesystemMtime() != null)
            &nbsp;·&nbsp; ${dtf.format(document.getFilesystemMtime())}
        @endif
        <br>
        <code>${document.getResolvedPath()}</code>
        @if(proposedPath.full() != null && proposedPath.pathTemplate() != null)
            <div class="mt-1">
                Règle : <span class="text-body-secondary">${proposedPath.ruleLabel()}</span>
                &nbsp;·&nbsp;
                <code class="opacity-75">${proposedPath.pathTemplate()}</code>
            </div>
        @endif
        @if(proposedPath.full() == null)
            <div class="mt-1 text-warning">
                ⚠ Aucune règle de stockage disponible. <a href="rules">Configurez une règle par défaut</a>.
            </div>
        @elseif(pathChanged)
            <div class="mt-1 text-warning">
                ⚠ La règle a changé. Nouveau chemin :
                <code><span class="opacity-50">${proposedPath.existing()}</span><strong>${proposedPath.newPart()}</strong></code>
                <form method="post" action="archive/${document.getId()}/reclassify" class="d-inline ms-2">
                    <button type="submit" class="btn btn-warning btn-sm">Reclassifier et déplacer</button>
                </form>
            </div>
        @endif
    </div>

    <div style="max-width: 700px">

        <ul class="nav nav-tabs" id="detailTabs">
            <li class="nav-item">
                <button class="nav-link active" type="button"
                        data-bs-toggle="tab" data-bs-target="#tab-meta">Métadonnées</button>
            </li>
            <li class="nav-item">
                <button class="nav-link" type="button"
                        data-bs-toggle="tab" data-bs-target="#tab-history">
                    Historique
                    @if(!history.isEmpty())
                        <span class="badge bg-secondary ms-1">${history.size()}</span>
                    @endif
                </button>
            </li>
        </ul>

        <div class="tab-content border border-top-0 rounded-bottom p-3 mb-3">

            <div class="tab-pane fade show active" id="tab-meta">
                <form method="post" action="archive/${document.getId()}">
                    <div class="d-flex flex-column gap-3">

                        <div>
                            <label class="form-label" for="documentTypeSearch">Type de document</label>
                            !{String currentSlug = document.getDocumentType() != null ? document.getDocumentType() : "";}
                            !{String currentLabel = documentTypeDefs.stream().filter(dt -> dt.getSlug().equals(currentSlug)).map(dt -> dt.getLabel()).findFirst().orElse(currentSlug);}
                            <input type="text" id="documentTypeSearch" list="doc-types-list"
                                   class="form-control" autocomplete="off"
                                   placeholder="Rechercher un type de document…"
                                   value="${currentLabel}">
                            <datalist id="doc-types-list">
                                @for(DocumentTypeDef dt : documentTypeDefs)
                                    <option value="${dt.getLabel()}" data-slug="${dt.getSlug()}"></option>
                                @endfor
                            </datalist>
                            <input type="hidden" id="documentType" name="documentType" value="${currentSlug}">
                            <script>
                            (function() {
                                var search = document.getElementById('documentTypeSearch');
                                var slug   = document.getElementById('documentType');
                                function sync() {
                                    var opts = document.querySelectorAll('#doc-types-list option');
                                    for (var i = 0; i < opts.length; i++) {
                                        if (opts[i].value.toLowerCase() === search.value.toLowerCase()) {
                                            slug.value = opts[i].dataset.slug;
                                            return;
                                        }
                                    }
                                    slug.value = search.value;
                                }
                                search.addEventListener('input',  sync);
                                search.addEventListener('change', sync);
                            })();
                            </script>
                        </div>

                        <div>
                            !{Double titleConf = document.getTitleConfidence();}
                            <label class="form-label d-flex justify-content-between" for="title">
                                <span>Titre</span>
                                @if(titleConf != null)
                                    <span class="text-muted small">confiance : ${String.format("%.0f%%", titleConf * 100)}</span>
                                @endif
                            </label>
                            <input type="text" id="title" name="title" class="form-control"
                                   value="${document.getTitle() != null ? document.getTitle() : ""}">
                        </div>

                        <div>
                            !{Double dateConf = document.getDocumentDateConfidence();}
                            <label class="form-label d-flex justify-content-between" for="documentDate">
                                <span>Date <span class="text-muted small">(AAAA, AAAA-MM ou AAAA-MM-JJ)</span></span>
                                @if(dateConf != null)
                                    <span class="text-muted small">confiance : ${String.format("%.0f%%", dateConf * 100)}</span>
                                @endif
                            </label>
                            <input type="text" id="documentDate" name="documentDate" class="form-control"
                                   value="${document.getDocumentDate() != null ? document.getDocumentDate() : ""}"
                                   pattern="\d{4}(-\d{2}(-\d{2})?)?" placeholder="ex: 2024-03-15">
                        </div>

                        <div>
                            !{Double issuerConf = document.getIssuerConfidence();}
                            <label class="form-label d-flex justify-content-between" for="issuer">
                                <span>Émetteur</span>
                                @if(issuerConf != null)
                                    <span class="text-muted small">confiance : ${String.format("%.0f%%", issuerConf * 100)}</span>
                                @endif
                            </label>
                            <input type="text" id="issuer" name="issuer" class="form-control"
                                   value="${document.getIssuer() != null ? document.getIssuer() : ""}"
                                   list="issuer-list" autocomplete="off">
                            <datalist id="issuer-list">
                                @for(String s : issuerSuggestions)
                                    <option value="${s}"></option>
                                @endfor
                            </datalist>
                        </div>

                        <div>
                            <label class="form-label" for="description">Description</label>
                            <textarea id="description" name="description" class="form-control" rows="2">${document.getDescription() != null ? document.getDescription() : ""}</textarea>
                        </div>

                        @template.tags.picker(allTagDefs = allTagDefs, selectedTags = document.getTags(), returnTo = "/archive/" + document.getId())

                        @if(!customFieldDefs.isEmpty())
                            <hr class="my-1">
                            <div class="text-muted small fw-semibold mb-1">Champs personnalisés</div>
                            !{long cfEmptyCount = customFieldDefs.stream().filter(cf -> document.getCustomFields().getOrDefault(cf.getSlug(), "").isBlank()).count();}
                            !{boolean cfCollapse = cfEmptyCount > 0 && cfEmptyCount < customFieldDefs.size();}
                            @for(CustomFieldDef cf : customFieldDefs)
                                !{String cfValue = document.getCustomFields().getOrDefault(cf.getSlug(), "");}
                                !{List<String> suggestions = fieldSuggestions.getOrDefault(cf.getSlug(), List.of());}
                                !{String listId = "cf-list-" + cf.getSlug();}
                                @if(!cfValue.isBlank() || !cfCollapse)
                                <div>
                                    <label class="form-label" for="cf_${cf.getSlug()}">${cf.getLabel()}</label>
                                    <input type="text" id="cf_${cf.getSlug()}" name="cf_${cf.getSlug()}"
                                           class="form-control" value="${cfValue}"
                                           list="${listId}" autocomplete="off">
                                    <datalist id="${listId}">
                                        @for(String s : suggestions)
                                            <option value="${s}"></option>
                                        @endfor
                                    </datalist>
                                    @if(cfProvenance.containsKey(cf.getSlug()))
                                        <div class="form-text text-muted">${cfProvenance.get(cf.getSlug())}</div>
                                    @endif
                                    @if(cf.getDescription() != null && !cf.getDescription().isEmpty())
                                        <details class="cf-help">
                                            <summary>Instructions</summary>
                                            <div>${cf.getDescription()}</div>
                                        </details>
                                    @endif
                                </div>
                                @endif
                            @endfor
                            @if(cfCollapse)
                            <details class="mt-2">
                                <summary class="text-muted small" style="cursor: pointer">Autres champs (${cfEmptyCount})</summary>
                                <div class="d-flex flex-column gap-3 mt-2">
                                @for(CustomFieldDef cf : customFieldDefs)
                                    !{String cfValue2 = document.getCustomFields().getOrDefault(cf.getSlug(), "");}
                                    !{List<String> suggestions2 = fieldSuggestions.getOrDefault(cf.getSlug(), List.of());}
                                    !{String listId2 = "cf-list2-" + cf.getSlug();}
                                    @if(cfValue2.isBlank())
                                    <div>
                                        <label class="form-label" for="cf_${cf.getSlug()}">${cf.getLabel()}</label>
                                        <input type="text" id="cf_${cf.getSlug()}" name="cf_${cf.getSlug()}"
                                               class="form-control" value=""
                                               list="${listId2}" autocomplete="off">
                                        <datalist id="${listId2}">
                                            @for(String s : suggestions2)
                                                <option value="${s}"></option>
                                            @endfor
                                        </datalist>
                                        @if(cfProvenance.containsKey(cf.getSlug()))
                                            <div class="form-text text-muted">${cfProvenance.get(cf.getSlug())}</div>
                                        @endif
                                        @if(cf.getDescription() != null && !cf.getDescription().isEmpty())
                                            <details class="cf-help">
                                                <summary>Instructions</summary>
                                                <div>${cf.getDescription()}</div>
                                            </details>
                                        @endif
                                    </div>
                                    @endif
                                @endfor
                                </div>
                            </details>
                            @endif
                        @endif

                        <div class="d-flex gap-2 mt-2">
                            <button type="submit" class="btn btn-outline-secondary">Enregistrer</button>
                            <a href="archive" class="btn btn-link text-muted">Annuler</a>
                        </div>

                    </div>
                </form>
                @if(document.getAiReasoning() != null)
                <details class="mt-3">
                    <summary class="text-muted small fw-semibold" style="cursor: pointer">Raisonnement IA</summary>
                    <div class="mt-2 p-2 bg-light rounded small text-muted" style="white-space: pre-wrap">${document.getAiReasoning()}</div>
                    @if(document.getAiModel() != null)
                        <div class="text-muted small mt-1 fst-italic">Modèle : ${document.getAiModel()}</div>
                    @endif
                </details>
                @endif
            </div>

            <div class="tab-pane fade" id="tab-history">
                @if(history.isEmpty())
                    <div class="text-muted small">Aucun historique disponible.</div>
                @else
                    <div class="d-flex flex-column gap-3">
                        @for(ClassificationHistory h : history)
                        <div class="d-flex gap-3">
                            <div class="text-muted small text-nowrap" style="min-width: 130px">
                                ${h.getCreatedAt().toString().replace("T", " ").substring(0, 16)}
                            </div>
                            <div>
                                @if(h.getOldPath() == null)
                                    <span class="badge bg-success mb-1">Archivage initial</span>
                                @elseif(h.getTrigger() == ClassificationTrigger.RULE_CHANGE)
                                    <span class="badge bg-info text-dark mb-1">Changement de règle</span>
                                @else
                                    <span class="badge bg-secondary mb-1">Manuel</span>
                                @endif
                                <div><code class="small">${h.getNewPath()}</code></div>
                                @if(h.getOldPath() != null)
                                    <div class="text-muted small">← <code>${h.getOldPath()}</code></div>
                                @endif
                                @if(h.getNewRule() != null)
                                    <div class="text-muted small">Règle : ${h.getNewRule().getLabel()}</div>
                                @endif
                            </div>
                        </div>
                        @endfor
                    </div>
                @endif
            </div>

        </div>

    </div>

    <hr class="my-4" style="max-width: 700px">

    <div style="max-width: 700px">
        <div class="text-muted small fw-semibold mb-2">Ré-analyse IA</div>
        <form id="reanalyzeForm" method="post" action="archive/${document.getId()}/reanalyze">
            <div class="mb-2">
                <textarea name="hint" class="form-control form-control-sm" rows="2"
                          placeholder="Indice optionnel (ex : c'est une facture EDF, l'émetteur est EDF…)"></textarea>
            </div>
            <button type="submit" id="reanalyzeBtn" class="btn btn-outline-primary btn-sm">
                <span id="reanalyzeSpinner" class="spinner-border spinner-border-sm me-1 d-none" role="status"></span>
                Ré-analyser avec l'IA
            </button>
        </form>
    </div>

    <script>
    document.getElementById('reanalyzeForm').addEventListener('submit', function() {
        const btn = document.getElementById('reanalyzeBtn');
        const spinner = document.getElementById('reanalyzeSpinner');
        btn.disabled = true;
        spinner.classList.remove('d-none');
        btn.childNodes[btn.childNodes.length - 1].textContent = ' Analyse en cours…';
        document.querySelectorAll('input, textarea, select, button')
            .forEach(el => el.disabled = true);
    });
    </script>

    <hr class="my-4" style="max-width: 700px">

    <div style="max-width: 700px">
        <form method="post" action="archive/${document.getId()}/delete"
              onsubmit="return confirm('Supprimer définitivement ce document et son fichier ?')">
            <button type="submit" class="btn btn-outline-danger btn-sm">Supprimer le document</button>
        </form>
    </div>

</div>

@if(previewable)
    <script>
        document.addEventListener('DOMContentLoaded', function() {
            openPreviewDrawer(
                'documents/${document.getId()}/file',
                '${document.getMimeType()}',
                '${previewTitle}'
            );
        });
    </script>
@endif

`)
