# Archive Register

The findable-in-five-years record of every git ref Threadline has retired.

**Convention (D-31).** A branch is never deleted without first being pinned by an **annotated** tag
named `archive/<original-branch-name>`, whose message carries the SHA, the merge base, the ancestry
verification output, the diffstat, the archive date and requirement, the merge-or-archive
recommendation, the rationale, the restore command, and a pointer back to this file. This register
carries one row per archived ref so the set is discoverable without knowing the tag names.

Inspect any entry without restoring it:

```bash
git cat-file -p archive/<original-branch-name>      # the full archive message
git log --oneline main..archive/<original-branch-name>
git diff main...archive/<original-branch-name>
```

---

## Archived refs

| ref | SHA | date | reason | recommendation | restore command |
|---|---|---|---|---|---|
| `gsd/phase-166-unfreeze-token-lane-mechanism` | `dd5b48be6f4c175f5dd7cecee19dbeb2f9a2934a` | 2026-08-27 | GREEN-12 repository hygiene. Phase-166 operator-surface light-token-lane draft, **not** an ancestor of `main` (`git merge-base --is-ancestor` exited 1) — real unmerged work, so it was pinned before removal. v1.36 shipped the same mechanism to `main` through a different lineage, as a strict superset. | **Archive** — no unique unshipped value (`main` carries the router `:theme` option, `normalize_theme/1`, and the light token block, plus a session-backed theme route the branch lacks), and its one material difference — nine per-LiveView `data-tl-theme` attributes — was deliberately factored into the shared shell on `main`. It also touches operator-surface routing and the style contract, which Phases 201/204 rewrite. Full reasoning: `.planning/audits/198-phase166-diff.md`. | `git branch gsd/phase-166-unfreeze-token-lane-mechanism dd5b48be6f4c175f5dd7cecee19dbeb2f9a2934a` |
| `backup/pre-release-cleanup-2026-05-08` | `50374eb71111f464154e99f1b6eb92d0067d5e97` | 2026-08-27 | GREEN-12 repository hygiene. A **strict ancestor** of `main` (`git merge-base --is-ancestor` exited 0) with an empty diff against it — already merged, so nothing was at risk. Retired because a long-lived mutable branch named "backup" is the wrong container for a point-in-time snapshot: a tag is. | **Archive as provenance, not preservation.** This tag rescues nothing; it records what the ref pointed at and why it was retired. Stated explicitly so a future reader does not mistake it for recovered work. | `git branch backup/pre-release-cleanup-2026-05-08 50374eb71111f464154e99f1b6eb92d0067d5e97` |
| `ci/198-gap-closure` (`local` subject) | `ffcff0d1613381950cfb6baad93e90aee19dcece` | 2026-09-09 | GREEN-12 round-11 preservation. Annotated tag `archive/ci/198-gap-closure/local-ffcff0d16133`; merge bases against task baseline and local `main` equal the subject SHA; ancestor checks true; ahead 0; unique commits and diffstats empty. Evidence: `.planning/audits/198-round11-ref-disposition.json`. | **Retire.** The local divergent tip is fully ancestral with no unique commit or diffstat; preserved independently because the origin tip differs. | `git branch ci/198-gap-closure ffcff0d1613381950cfb6baad93e90aee19dcece` |
<!-- archive-subject: local:ci/198-gap-closure@ffcff0d1613381950cfb6baad93e90aee19dcece|archive/ci/198-gap-closure/local-ffcff0d16133|ffcff0d1613381950cfb6baad93e90aee19dcece|git branch ci/198-gap-closure ffcff0d1613381950cfb6baad93e90aee19dcece -->
| `ci/198-gap-closure` (`origin` subject) | `f748e43d7e4c1e63a0142569a55f57c7187e5cb1` | 2026-09-09 | GREEN-12 round-11 preservation. Annotated tag `archive/ci/198-gap-closure/origin-f748e43d7e4c`; merge bases against task baseline and local `main` equal the subject SHA; ancestor checks true; ahead 0; unique commits and diffstats empty. Evidence: `.planning/audits/198-round11-ref-disposition.json`. | **Retire.** The origin divergent tip is fully ancestral with no unique commit or diffstat; preserved independently because the local tip differs. | `git branch ci/198-gap-closure f748e43d7e4c1e63a0142569a55f57c7187e5cb1` |
<!-- archive-subject: origin:ci/198-gap-closure@f748e43d7e4c1e63a0142569a55f57c7187e5cb1|archive/ci/198-gap-closure/origin-f748e43d7e4c|f748e43d7e4c1e63a0142569a55f57c7187e5cb1|git branch ci/198-gap-closure f748e43d7e4c1e63a0142569a55f57c7187e5cb1 -->

**Rows: 4.** This register is not empty. Had there been no stale branches at execution time, this
section would say so explicitly rather than being absent — an absent register is indistinguishable
from a forgotten one.

---

## Durability

Archive tags are pushed to `origin` (D-32). Until that push lands, a tag exists only on the
maintainer's laptop, and a laptop loss destroys the only copy of whatever it pins — precisely what
GREEN-12 exists to prevent. The tags above were created in Plan 198-06; the push to `origin` is
Plan 198-07 step 5, gated behind the credential audit. **Between those two plans these tags are
single-copy, and that is a known, time-boxed exposure rather than an oversight.**

The "milestone tags stay local" rule does not apply here. That rule existed solely because pushing
would have published `.planning/` history, and that rationale is void once `.planning/` goes public
on `main` in this same phase. Whether *milestone* tags stay local is a separate, deferred question.
