#!/usr/bin/env bash
# collect-ci-runs.sh — READ-ONLY collector for the Phase 214 CI baseline (BASE-01).
#
# Lists GitHub Actions runs with `gh run list` and fetches each run's jobs with a
# default-GET `gh api .../actions/runs/<id>/jobs` call (latest attempt only).
# Writes trimmed per-run JSON to raw/ci/runs/<run id>.json and records the
# selection in raw/ci/manifest.json. It never writes to GitHub: no dispatch,
# re-run, cancel, push, PR/issue comment, and no HTTP method override.
#
# Usage (from the repo root):
#   bash .planning/phases/218-ci-economy-remove-waste/tools/collect-ci-runs.sh \
#     --workflow ci.yml --event pull_request [--target 20] [--min 10]
#   ... --workflow flake-detection.yml --event schedule --status any --since 2026-08-27 --target 200 --min 1
#   ... --head-sha <sha> [--min 1]
#   ... --release-tag v0.11.0
#
# Flags:
#   --workflow <file>   workflow file name (e.g. ci.yml)
#   --event <e>         pull_request | push | schedule | workflow_dispatch
#   --target N          keep the most recent N runs (default 20; 0 = all;
#                       default 0 with --head-sha)
#   --min N             exit non-zero if fewer than N runs were found (default 10)
#   --status <s>        success (default) | any (every completed run, any conclusion)
#   --since YYYY-MM-DD  only runs created on/after this date (manifest key gets a suffix)
#   --head-sha <sha>    alternative selector: every completed run for one SHA, any workflow
#   --release-tag <tag> derive a release cycle's SHA set (release-please PR commits,
#                       the release merge commit, the distribution-sync PR commits)
#                       with read-only gh release list / gh pr list / gh pr view,
#                       collect every run on those SHAs, write raw/ci/release-<tag>.json
#   --refresh           re-fetch run JSON even if raw/ci/runs/<id>.json exists
set -euo pipefail

REPO="szTheory/threadline"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PHASE_DIR="$(dirname "$SCRIPT_DIR")"
RAW_DIR="$PHASE_DIR/raw/ci"
RUNS_DIR="$RAW_DIR/runs"
MANIFEST="$RAW_DIR/manifest.json"

WORKFLOW=""
EVENT=""
TARGET=""
MIN=10
STATUS="success"
SINCE=""
HEAD_SHA=""
REFRESH=0
RELEASE_TAG=""

die() { echo "collect-ci-runs: $*" >&2; exit 1; }

while [ $# -gt 0 ]; do
  case "$1" in
    --workflow) WORKFLOW="${2:?}"; shift 2 ;;
    --event) EVENT="${2:?}"; shift 2 ;;
    --target) TARGET="${2:?}"; shift 2 ;;
    --min) MIN="${2:?}"; shift 2 ;;
    --status) STATUS="${2:?}"; shift 2 ;;
    --since) SINCE="${2:?}"; shift 2 ;;
    --head-sha) HEAD_SHA="${2:?}"; shift 2 ;;
    --release-tag) RELEASE_TAG="${2:?}"; shift 2 ;;
    --refresh) REFRESH=1; shift ;;
    -h|--help) sed -n '2,30p' "$0"; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

if [ -n "$RELEASE_TAG" ]; then
  [[ "$RELEASE_TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || die "--release-tag must look like v0.11.0"
  VERSION="${RELEASE_TAG#v}"
  mkdir -p "$RAW_DIR"
  PUBLISHED="$(gh release list --repo "$REPO" --limit 100 --json tagName,publishedAt \
    | jq -r --arg t "$RELEASE_TAG" '.[] | select(.tagName == $t) | .publishedAt')"
  [ -n "$PUBLISHED" ] || die "no GitHub release named $RELEASE_TAG"
  pr_number() {
    gh pr list --repo "$REPO" --state merged --search "\"$1\" in:title" --json number,title \
      | jq -r --arg t "$1" '[.[] | select(.title | endswith($t))] | .[0].number // empty'
  }
  REL_PR="$(pr_number "release $VERSION")"
  SYNC_PR="$(pr_number "sync distribution docs for $VERSION")"
  [ -n "$REL_PR" ] || die "no merged release-please PR titled 'release $VERSION'"
  REL_JSON="$(gh pr view "$REL_PR" --repo "$REPO" --json number,commits,mergeCommit)"
  SYNC_JSON='null'
  [ -n "$SYNC_PR" ] && SYNC_JSON="$(gh pr view "$SYNC_PR" --repo "$REPO" --json number,commits,mergeCommit)"
  SHAS_JSON="$(jq -n --argjson r "$REL_JSON" --argjson s "$SYNC_JSON" '
    [($r.commits[] | {sha: .oid, role: "release-please PR commit", pr: $r.number}),
     {sha: $r.mergeCommit.oid, role: "release merge commit on main", pr: $r.number}]
    + (if $s == null then [] else [$s.commits[] | {sha: .oid, role: "distribution-sync PR commit", pr: $s.number}] end)')"
  for sha in $(jq -r '.[].sha' <<<"$SHAS_JSON"); do
    "$0" --head-sha "$sha" --min 1 $( [ "$REFRESH" -eq 1 ] && echo --refresh )
  done
  RUN_IDS="$(for sha in $(jq -r '.[].sha' <<<"$SHAS_JSON"); do
      jq -c --arg k "sha:$sha" '.entries[$k].run_ids' "$MANIFEST"; done | jq -s 'add | unique')"
  jq -n --arg tag "$RELEASE_TAG" --arg published "$PUBLISHED" --argjson shas "$SHAS_JSON" \
     --argjson runs "$RUN_IDS" --arg fetched "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     --arg rel "$REL_PR" --arg sync "${SYNC_PR:-}" '{
       tag: $tag, published_at: $published,
       release_pr: ($rel | tonumber), sync_pr: (if $sync == "" then null else ($sync | tonumber) end),
       head_shas: [$shas[] | .sha], sha_roles: $shas, run_ids: $runs,
       derivation: [
         "gh release list --repo szTheory/threadline --limit 100 --json tagName,publishedAt",
         ("gh pr list --repo szTheory/threadline --state merged --search \"release " + ($tag | ltrimstr("v")) + " in:title\""),
         ("gh pr list --repo szTheory/threadline --state merged --search \"sync distribution docs for " + ($tag | ltrimstr("v")) + " in:title\""),
         "gh pr view <n> --repo szTheory/threadline --json number,commits,mergeCommit",
         "gh run list --repo szTheory/threadline --commit <sha> --status completed (per SHA, via --head-sha)"
       ],
       fetched_at_utc: $fetched
     }' > "$RAW_DIR/release-$RELEASE_TAG.json"
  echo "collect-ci-runs: release $RELEASE_TAG -> $(jq '.head_shas | length' "$RAW_DIR/release-$RELEASE_TAG.json") SHA(s), $(jq '.run_ids | length' "$RAW_DIR/release-$RELEASE_TAG.json") run(s)" >&2
  exit 0
fi

# Default: 20 most recent runs; with --head-sha every run for that SHA (0 = no cap),
# because the push-event runs are the oldest for a SHA and a cap would drop them.
if [ -z "$TARGET" ]; then
  if [ -n "$HEAD_SHA" ]; then TARGET=0; else TARGET=20; fi
fi
case "$TARGET" in *[!0-9]*) die "--target must be an integer" ;; esac
case "$MIN" in ''|*[!0-9]*) die "--min must be an integer" ;; esac
case "$STATUS" in success|any) ;; *) die "--status must be success or any" ;; esac
if [ -n "$SINCE" ] && ! [[ "$SINCE" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then die "--since must be YYYY-MM-DD"; fi

FIELDS="databaseId,headSha,createdAt,event,attempt,conclusion,status,workflowName,displayTitle"
LIST_ARGS=(run list --repo "$REPO" --limit 200 --json "$FIELDS")

if [ -n "$HEAD_SHA" ]; then
  [[ "$HEAD_SHA" =~ ^[0-9a-f]{7,40}$ ]] || die "--head-sha must be a hex SHA"
  LIST_ARGS+=(--commit "$HEAD_SHA" --status completed)
  KEY="sha:$HEAD_SHA"
else
  [ -n "$WORKFLOW" ] || die "--workflow is required (or use --head-sha)"
  [ -n "$EVENT" ] || die "--event is required (or use --head-sha)"
  case "$EVENT" in pull_request|push|schedule|workflow_dispatch) ;; *) die "unsupported --event: $EVENT" ;; esac
  LIST_ARGS+=(--workflow "$WORKFLOW" --event "$EVENT")
  if [ "$STATUS" = "success" ]; then
    LIST_ARGS+=(--status success)
  else
    LIST_ARGS+=(--status completed)
  fi
  KEY="$WORKFLOW:$EVENT"
  [ "$STATUS" = "any" ] && KEY="$KEY:any"
fi
if [ -n "$SINCE" ]; then
  LIST_ARGS+=(--created ">=$SINCE")
  KEY="$KEY:since-$SINCE"
fi

mkdir -p "$RUNS_DIR"
[ -f "$MANIFEST" ] || echo '{"repo":"szTheory/threadline","entries":{}}' > "$MANIFEST"

LIST_JSON="$(gh "${LIST_ARGS[@]}")"
# Newest first, one entry per run (gh reports the latest attempt), keep --target.
SELECTED="$(jq -c --argjson t "$TARGET" \
  'unique_by(.databaseId) | sort_by(.createdAt, .databaseId) | reverse | (if $t > 0 then .[:$t] else . end)' \
  <<<"$LIST_JSON")"
COUNT="$(jq 'length' <<<"$SELECTED")"

while IFS= read -r meta; do
  [ -n "$meta" ] || continue
  id="$(jq -r '.databaseId' <<<"$meta")"
  [[ "$id" =~ ^[0-9]+$ ]] || die "non-numeric run id from gh: $id"
  out="$RUNS_DIR/$id.json"
  if [ -f "$out" ] && [ "$REFRESH" -eq 0 ]; then continue; fi
  gh api --paginate "repos/$REPO/actions/runs/$id/jobs?per_page=100" \
    | jq -s --argjson meta "$meta" '{
        run_id: $meta.databaseId,
        attempt: $meta.attempt,
        head_sha: $meta.headSha,
        event: $meta.event,
        created_at: $meta.createdAt,
        conclusion: $meta.conclusion,
        workflow: $meta.workflowName,
        jobs: ([.[].jobs[]] | map({
          id, name, status, conclusion, started_at, completed_at, labels,
          steps: [(.steps // [])[] | {name, conclusion, started_at, completed_at}]
        }) | sort_by(.id))
      }' > "$out.tmp"
  mv "$out.tmp" "$out"
done < <(jq -c '.[]' <<<"$SELECTED")

# Record the exact list command (repo-relative, no machine paths).
CMD="gh"
for a in "${LIST_ARGS[@]}"; do
  case "$a" in *[[:space:]\>]*) CMD="$CMD '$a'" ;; *) CMD="$CMD $a" ;; esac
done
FETCHED="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

jq --arg key "$KEY" --arg wf "$WORKFLOW" --arg ev "$EVENT" --arg sha "$HEAD_SHA" \
   --arg status "$STATUS" --arg since "$SINCE" --arg cmd "$CMD" --arg fetched "$FETCHED" \
   --argjson target "$TARGET" --argjson sel "$SELECTED" '
  .entries[$key] = {
    workflow: (if $wf == "" then null else $wf end),
    event: (if $ev == "" then null else $ev end),
    head_sha: (if $sha == "" then null else $sha end),
    status: $status,
    since: (if $since == "" then null else $since end),
    target: $target,
    run_ids: [$sel[] | .databaseId],
    list_command: $cmd,
    fetched_at_utc: $fetched
  }' "$MANIFEST" > "$MANIFEST.tmp"
mv "$MANIFEST.tmp" "$MANIFEST"

echo "collect-ci-runs: $KEY -> $COUNT run(s)" >&2
if [ "$COUNT" -lt "$MIN" ]; then
  die "only $COUNT run(s) found for $KEY, fewer than --min $MIN"
fi
