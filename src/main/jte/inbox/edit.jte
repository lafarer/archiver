@import com.github.lafarer.archiver.model.Document
@import com.github.lafarer.archiver.model.CustomFieldDef
@import com.github.lafarer.archiver.model.DocumentTypeDef
@import com.github.lafarer.archiver.model.TagDef
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
@param String page
@param String message = null
@param boolean watchdogRunning = false
@param String contextPath = ""

!{String pageTitle = "Éditer - " + (document.getTitle() != null ? document.getTitle() : document.getOriginalFilename());}
@template.layout.base(page = page, title = pageTitle, watchdogRunning = watchdogRunning, contextPath = contextPath, content = @`

!{boolean previewable = document.getMimeType() != null && (document.getMimeType().startsWith("image/") || document.getMimeType().equals("application/pdf"));}
!{String previewTitle = document.getTitle() != null ? document.getTitle() : document.getOriginalFilename();}
<div class="page-header">
    <h1>
        <a href="inbox" class="text-decoration-none text-muted me-2">←</a>
        Vérification du document
    </h1>
    @if(previewable)
        <button type="button" class="btn btn-outline-primary btn-sm"
                onclick="openPreviewDrawer('documents/${document.getId()}/file', '${document.getMimeType()}', '${previewTitle}')">
            Aperçu
        </button>
    @endif
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

<div class="page-body">

    @if(message != null)
    <div class="alert alert-success alert-dismissible fade show" role="alert">
        ${message}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
    @endif


    !{String docSize = ArchiveController.formatSize(document.getFileSizeBytes());}
    !{DateTimeFormatter dtf = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm").withZone(ZoneId.systemDefault());}
    <div class="mb-3 text-muted small">
        Fichier : <strong>${document.getOriginalFilename()}</strong>
        &nbsp;·&nbsp; ${docSize}
        @if(document.getFilesystemMtime() != null)
            &nbsp;·&nbsp; ${dtf.format(document.getFilesystemMtime())}
        @endif
        <br>
        @if(proposedPath.full() != null)
            → <code><span class="opacity-50">${proposedPath.existing()}</span><strong>${proposedPath.newPart()}</strong></code>
            @if(proposedPath.pathTemplate() != null)
                <div class="mt-1">
                    Règle : <span class="text-body-secondary">${proposedPath.ruleLabel()}</span>
                    &nbsp;·&nbsp;
                    <code class="opacity-75">${proposedPath.pathTemplate()}</code>
                </div>
            @endif
        @else
            <div class="alert alert-warning mt-2 mb-0 py-2">
                Aucune règle de stockage disponible. <a href="rules">Configurez une règle par défaut</a> pour archiver ce document.
            </div>
        @endif
    </div>

    <form id="editForm" method="post" action="inbox/${document.getId()}">

        <div class="d-flex flex-column gap-3" style="max-width: 700px">

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
                <%-- Hidden input carries the slug that gets submitted --%>
                <input type="hidden" id="documentType" name="documentType" value="${currentSlug}">
                <script>
                (function() {
                    var search = document.getElementById('documentTypeSearch');
                    var slug   = document.getElementById('documentType');
                    function sync() {
                        // Look for a datalist option whose label matches the typed text
                        var opts = document.querySelectorAll('#doc-types-list option');
                        for (var i = 0; i < opts.length; i++) {
                            if (opts[i].value.toLowerCase() === search.value.toLowerCase()) {
                                slug.value = opts[i].dataset.slug;
                                return;
                            }
                        }
                        // No known match - fall back to the typed value as slug
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

            @template.tags.picker(allTagDefs = allTagDefs, selectedTags = document.getTags(), returnTo = "/inbox/" + document.getId() + "/edit")

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
                <a href="inbox" class="btn btn-link text-muted">Annuler</a>
            </div>

        </div>

    </form>

    @if(document.getAiReasoning() != null)
    <details class="mt-3" style="max-width: 700px">
        <summary class="text-muted small fw-semibold" style="cursor: pointer">Raisonnement IA</summary>
        <div class="mt-2 p-2 bg-light rounded small text-muted" style="white-space: pre-wrap">${document.getAiReasoning()}</div>
        @if(document.getAiModel() != null)
            <div class="text-muted small mt-1 fst-italic">Modèle : ${document.getAiModel()}</div>
        @endif
    </details>
    @endif

    <hr class="my-4" style="max-width: 700px">

    <div style="max-width: 700px" class="mb-4">
        <button class="btn btn-outline-secondary btn-sm" type="button"
                data-bs-toggle="collapse" data-bs-target="#reanalyzePanel">
            Ré-analyser avec un hint…
        </button>
        <div class="collapse mt-3 ${message != null ? "show" : ""}" id="reanalyzePanel">
            <form method="post" action="inbox/${document.getId()}/reanalyze" id="reanalyzeForm">
                <div class="mb-2">
                    <label class="form-label small fw-semibold" for="hint">Hint pour l'IA</label>
                    <textarea id="hint" name="hint" class="form-control form-control-sm" rows="3"
                              placeholder="ex: Ce document est un certificat PEB, pas une facture de travaux. L'émetteur est CERGA."></textarea>
                    <div class="form-text">Le hint est transmis à l'IA uniquement pour cette ré-analyse. Tous les champs seront recalculés.</div>
                </div>
                <button type="submit" id="reanalyzeBtn" class="btn btn-warning btn-sm">
                    <span id="reanalyzeSpinner" class="spinner-border spinner-border-sm me-1 d-none" role="status"></span>
                    Ré-analyser
                </button>
            </form>
        </div>
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

    <div style="max-width: 700px">
        <form method="post" action="inbox/${document.getId()}/validate">
            <button type="submit" class="btn btn-success" disabled="${proposedPath.full() == null}">Valider et archiver ✓</button>
        </form>
    </div>

</div>

`)
