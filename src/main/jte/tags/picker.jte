@import com.github.lafarer.archiver.model.TagDef
@import java.util.List

@param List<TagDef> allTagDefs
@param List<String> selectedTags
@param String returnTo

<div>
    <label class="form-label">Tags</label>
    <input type="hidden" name="tags" id="tags-hidden" value="${selectedTags.isEmpty() ? "" : String.join(", ", selectedTags)}">
    @if(!allTagDefs.isEmpty())
        <div class="d-flex flex-wrap gap-1 align-items-center">
            @for(TagDef tag : allTagDefs)
                !{boolean selected = selectedTags.contains(tag.getSlug());}
                <button type="button"
                        class="btn btn-sm ${selected ? "btn-secondary" : "btn-outline-secondary"} tag-picker-btn"
                        data-slug="${tag.getSlug()}"
                        title="${tag.getDescription() != null ? tag.getDescription() : ""}">
                    ${tag.getLabel()}
                </button>
            @endfor
            <button type="button" class="btn btn-sm btn-link text-decoration-none p-0 ms-1"
                    data-bs-toggle="modal" data-bs-target="#newTagModal">
                + Nouveau
            </button>
        </div>
    @else
        <div class="d-flex align-items-center gap-2">
            <span class="text-muted small">Aucun tag défini.</span>
            <button type="button" class="btn btn-sm btn-link text-decoration-none p-0"
                    data-bs-toggle="modal" data-bs-target="#newTagModal">
                + Créer un tag
            </button>
        </div>
    @endif
</div>

<div class="modal fade" id="newTagModal" tabindex="-1" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <form method="post" action="/tags">
                <div class="modal-header">
                    <h5 class="modal-title">Nouveau tag</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body d-flex flex-column gap-3">
                    <input type="hidden" name="returnTo" value="${returnTo}">
                    <div>
                        <label class="form-label" for="new-tag-label">Label</label>
                        <input type="text" name="label" id="new-tag-label" class="form-control" required
                               autocomplete="off">
                    </div>
                    <div>
                        <label class="form-label" for="new-tag-slug">Slug</label>
                        <input type="text" name="slug" id="new-tag-slug" class="form-control"
                               pattern="[a-z0-9\\-]+" required autocomplete="off">
                        <div class="form-text">Lettres minuscules, chiffres et tirets uniquement.</div>
                    </div>
                    <div>
                        <label class="form-label" for="new-tag-desc">
                            Description <span class="text-muted small">(contexte pour l'IA)</span>
                        </label>
                        <textarea name="description" id="new-tag-desc" class="form-control" rows="2"></textarea>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-outline-secondary btn-sm" data-bs-dismiss="modal">Annuler</button>
                    <button type="submit" class="btn btn-primary btn-sm">Créer</button>
                </div>
            </form>
        </div>
    </div>
</div>

<script>
(function () {
    document.querySelectorAll('.tag-picker-btn').forEach(function (btn) {
        btn.addEventListener('click', function () {
            this.classList.toggle('btn-secondary');
            this.classList.toggle('btn-outline-secondary');
            syncTags();
        });
    });

    document.getElementById('new-tag-label').addEventListener('input', function () {
        document.getElementById('new-tag-slug').value = this.value
            .toLowerCase()
            .normalize('NFD').replace(/[̀-ͯ]/g, '')
            .replace(/\s+/g, '-')
            .replace(/[^a-z0-9-]/g, '');
    });

    function syncTags() {
        var slugs = Array.from(document.querySelectorAll('.tag-picker-btn.btn-secondary'))
            .map(function (b) { return b.dataset.slug; });
        document.getElementById('tags-hidden').value = slugs.join(', ');
    }
}());
</script>
