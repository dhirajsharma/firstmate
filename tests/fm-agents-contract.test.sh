#!/usr/bin/env bash
# tests/fm-agents-contract.test.sh - guard the always-loaded supervisor contract.
#
# AGENTS.md is the agent's prompt interface: every harness injects it whole
# before any work, so its visible text is the behavior under test, the same
# stance tests/fm-harness-adapter-references.test.sh takes for the harness
# router. Skill files and bin/ script headers are part of that interface too:
# AGENTS.md section 2 orders every agent to read a script's header before its
# first use, and scripts such as fm-brief.sh and fm-tasks-axi.sh print theirs
# through --help. This test holds four properties of that interface:
#
#   1. Reachability ledger. Every line of the pre-slim contract (BASELINE_COMMIT)
#      is still present verbatim, or a LEDGER row names where its rule now lives:
#      kept rows point at the reworded rule in AGENTS.md, and moved rows point at
#      an owner file plus the visible AGENTS.md trigger that leads there (directly,
#      or through one named intermediate that itself names the owner). A trim that
#      drops a rule, an owner edit that deletes a moved rule, or a trigger edit that
#      strands an owner fails here. When you move a rule out of AGENTS.md, add its
#      row; when you delete a baseline line, cover it.
#   2. Skill index. Every agent-only skill has a section 13 trigger.
#   3. Codex delivery. AGENTS.md stays within Codex's default 32 KiB
#      project_doc_max_bytes; beyond it Codex silently truncates the contract.
#   4. Composed startup budget. For every supported primary harness, the real
#      locked empty-home bin/fm-session-start.sh digest plus AGENTS.md, CLAUDE.md
#      for Claude, and every skill's frontmatter (the always-listed skill
#      descriptions) stays within its reviewed cap, so moving text into another
#      always-loaded surface is not a saving.
#
# Planted-regression self-tests prove each check fails when its property breaks.
# The harness render needs real `ps` ancestry; a sandbox that hides other
# processes from `ps` makes every harness read as unknown and read-only.
set -u

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
# shellcheck source=bin/fm-startup-memory-budget-lib.sh
. "$ROOT/bin/fm-startup-memory-budget-lib.sh"

TMP_ROOT=$(fm_test_tmproot fm-agents-contract)
FM_TEST_CLEANUP_DIRS+=("$TMP_ROOT")
trap fm_test_cleanup EXIT
BASE_PATH=${FM_TEST_BASE_PATH:-/usr/bin:/bin:/usr/sbin:/sbin}

BASELINE_COMMIT=76d44055
CODEX_PROJECT_DOC_MAX_BYTES=32768
PRIMARY_HARNESSES="claude codex opencode grok pi pi-signed omp cursor"

# Reviewed composed-startup caps in estimated tokens (ceil(bytes / 3)), set at
# the measured empty-home floor plus a small margin when the contract was slimmed.
# Raise one only with a stated reason in the PR that needs it.
cap_for() {
  case "$1" in
    claude) printf '%s\n' 17650 ;;
    codex) printf '%s\n' 17050 ;;
    opencode) printf '%s\n' 17150 ;;
    grok) printf '%s\n' 17650 ;;
    pi) printf '%s\n' 19000 ;;
    pi-signed) printf '%s\n' 19000 ;;
    omp) printf '%s\n' 18550 ;;
    cursor) printf '%s\n' 17800 ;;
    *) return 1 ;;
  esac
}

# --- ledger ------------------------------------------------------------------
# Row: <baseline lines> @@ <owner> @@ <anchor> @@ <AGENTS.md trigger> [@@ <via>]
# Owner AGENTS.md means the rule is kept, reworded, in the slim contract.
# Anchor =verbatim means each listed baseline line appears unchanged in the owner.
# Anchors and triggers match case-insensitively after whitespace collapses; a
# shell owner is read with its comment markers removed.
LEDGER="$TMP_ROOT/ledger.txt"
cat > "$LEDGER" <<'LEDGER'
# Preamble
3-4 @@ AGENTS.md @@ does not select the worker role @@ -
6-8 @@ AGENTS.md @@ this file is your entire job description @@ -
10-12 @@ AGENTS.md @@ into a non-chat artifact @@ -
13 @@ AGENTS.md @@ section 9's parent-channel rule is the only way the captain is reached @@ -
14 @@ AGENTS.md @@ light nautical seasoning @@ -
15 @@ AGENTS.md @@ ## 9. escalation and captain etiquette @@ -
# 1. Identity and prime directives
20-21 @@ AGENTS.md @@ delegate coding, investigation, planning, bug reproduction, and audits @@ -
32 @@ AGENTS.md @@ is the only standing relaxation for merge authority @@ -
38-39 @@ AGENTS.md @@ treat direct captain intervention in a crewmate window as authoritative @@ -
44-45 @@ AGENTS.md @@ change it directly only when the fleet is empty @@ -
48 @@ .agents/skills/firstmate-coding-guidelines/SKILL.md @@ never add an agent name as a commit co-author @@ `firstmate-coding-guidelines` - before changing section 1's shared tracked material
# 2. Layout and state
52 @@ docs/configuration.md @@ this section is the single owner of the top-level operational-home layout @@ (docs/configuration.md) "operational home layout and state" owns the file inventory and configuration schemas
53-55 @@ AGENTS.md @@ refuses to run without an explicit `fm_home` @@ -
57 @@ AGENTS.md @@ `state/` (runtime records and append-only status events) @@ -
60 @@ docs/configuration.md @@ the always-loaded supervisor contract (claude.md is a real @agents.md pointer to it) @@ (docs/configuration.md) "operational home layout and state" owns the file inventory and configuration schemas
61-153 @@ docs/configuration.md @@ =verbatim @@ (docs/configuration.md) "operational home layout and state" owns the file inventory and configuration schemas
157 @@ AGENTS.md @@ are canonical regardless of harness memory @@ -
# 3. Session start
161-162 @@ AGENTS.md @@ exactly once per session, never its lock, bootstrap, wake-drain, or network components separately @@ -
164 @@ AGENTS.md @@ never its lock, bootstrap, wake-drain, or network components separately @@ -
163 @@ bin/fm-session-start.sh @@ supervision-instructions - the one emitted operating block for the detected primary harness @@ `bin/fm-session-start.sh` exactly once per session, never its lock, bootstrap, wake-drain, or network components separately; its header owns what it composes and prints
165 @@ AGENTS.md @@ so run it yourself when this session has no digest @@ -
167-169 @@ AGENTS.md @@ only as its read-once contract allows @@ -
170 @@ AGENTS.md @@ rebuild an absent or stale project registry from the clones before dispatch @@ -
172-173 @@ AGENTS.md @@ no spawning, steering, merging, wake-queue draining, supervision or checkout repair @@ -
175 @@ bin/fm-session-start.sh @@ no network on the blocking path @@ `bin/fm-session-start.sh` exactly once per session, never its lock, bootstrap, wake-drain, or network components separately; its header owns what it composes and prints
176 @@ bin/fm-startup-network.sh @@ every external-network call a session start makes used to run @@ until `bin/fm-startup-network.sh report` returns the finished result
177 @@ bin/fm-startup-network.sh @@ inactive-outcome scan also runs here @@ until `bin/fm-startup-network.sh report` returns the finished result
178 @@ AGENTS.md @@ `bin/fm-startup-network.sh report` returns the finished result @@ -
180 @@ bin/fm-session-start.sh @@ acquire the per-home session lock first, before any mutating step runs @@ `bin/fm-session-start.sh` exactly once per session, never its lock, bootstrap, wake-drain, or network components separately; its header owns what it composes and prints
181 @@ bin/fm-session-start.sh @@ detect-only diagnostics always run @@ `bin/fm-session-start.sh` exactly once per session, never its lock, bootstrap, wake-drain, or network components separately; its header owns what it composes and prints
182 @@ AGENTS.md @@ no spawning, steering, merging, wake-queue draining, supervision or checkout repair @@ -
183 @@ bin/fm-session-start.sh @@ only projection cleanup, the six bootstrap mutating sweeps, and wake-queue @@ `bin/fm-session-start.sh` exactly once per session, never its lock, bootstrap, wake-drain, or network components separately; its header owns what it composes and prints
184 @@ bin/fm-bootstrap.sh @@ recovery-grade state owned by bin/fm-backend.sh's @@ `bin/fm-session-start.sh` exactly once per session, never its lock, bootstrap, wake-drain, or network components separately; its header owns what it composes and prints @@ bin/fm-session-start.sh
185 @@ bin/fm-session-start.sh @@ wake-drain - presents durable wakes @@ `bin/fm-session-start.sh` exactly once per session, never its lock, bootstrap, wake-drain, or network components separately; its header owns what it composes and prints
186 @@ AGENTS.md @@ printed as `wake_ack_required` @@ -
187 @@ AGENTS.md @@ `open decisions` entries are actionable @@ -
188 @@ AGENTS.md @@ a `status outcome backstop` is a recovered wake @@ -
189 @@ AGENTS.md @@ `unread status` lines print only once @@ -
190 @@ AGENTS.md @@ never that the captain ruled @@ -
191 @@ AGENTS.md @@ wake-queue draining @@ -
192-193 @@ AGENTS.md @@ owns the wait and wake mechanism @@ -
194 @@ bin/fm-session-start.sh @@ cheap per-task endpoint-liveness read @@ `bin/fm-session-start.sh` exactly once per session, never its lock, bootstrap, wake-drain, or network components separately; its header owns what it composes and prints
195 @@ AGENTS.md @@ `bin/fm-crew-state.sh` owns current-state reconciliation @@ -
196 @@ bin/fm-session-start.sh @@ network checks - the result of the deferred network stage @@ `bin/fm-session-start.sh` exactly once per session, never its lock, bootstrap, wake-drain, or network components separately; its header owns what it composes and prints
197 @@ AGENTS.md @@ or other fleet mutation @@ -
198 @@ bin/fm-session-start.sh @@ context digest - data/projects.md, data/secondmates.md, data/captain.md @@ `bin/fm-session-start.sh` exactly once per session, never its lock, bootstrap, wake-drain, or network components separately; its header owns what it composes and prints
199 @@ AGENTS.md @@ means built-in defaults @@ -
200 @@ bin/fm-session-start.sh @@ closing reminder - prints the context-specific watcher next step @@ `bin/fm-session-start.sh` exactly once per session, never its lock, bootstrap, wake-drain, or network components separately; its header owns what it composes and prints
202 @@ AGENTS.md @@ bootstrap detects, asks consent, and installs only after the captain approves in this session @@ -
203 @@ AGENTS.md @@ do not dispatch until essential launch tools are present and github authentication is good @@ -
204 @@ AGENTS.md @@ consulting current help rather than memorized flags @@ -
205-206 @@ .agents/skills/bootstrap-diagnostics/SKILL.md @@ missing_manual, presentation_unavailable, backend_invalid @@ `bootstrap-diagnostics` - when the digest's bootstrap or network-checks section prints a diagnostic line other than `bootstrap_info:`
207 @@ AGENTS.md @@ owns startup secondmate sync, liveness, and inherited local material @@ -
# 4. Harness and runtime dispatch
211 @@ .agents/skills/harness-adapters/SKILL.md @@ use before spawning or recovering a crewmate or secondmate @@ `harness-adapters` - before spawning or recovering a crewmate or secondmate
212 @@ AGENTS.md @@ never dispatch on an unverified adapter @@ -
213 @@ AGENTS.md @@ fall back only to a verified adapter @@ -
215 @@ docs/configuration.md @@ ## crew dispatch profiles (config/crew-dispatch.json) @@ (docs/configuration.md) "operational home layout and state" owns the file inventory and configuration schemas
215 @@ docs/configuration.md @@ ## runtime backend (config/backend / fm_backend) @@ (docs/configuration.md) "operational home layout and state" owns the file inventory and configuration schemas
215 @@ bin/fm-harness.sh @@ config/crew-harness (a bare adapter name) wins @@ spawn only through `bin/fm-spawn.sh` @@ bin/fm-spawn.sh
215 @@ AGENTS.md @@ dispatch only on a backend `fm-spawn` validates as spawn-capable @@ -
216 @@ AGENTS.md @@ consult them at every crewmate or scout intake @@ -
217 @@ AGENTS.md @@ by precedence of explicit per-task captain override @@ -
218 @@ .agents/skills/quota-array-dispatch/SKILL.md @@ start each intake by running `quota-axi` once with no `--json` @@ through `quota-array-dispatch`, which owns every-candidate accounting
219 @@ .agents/skills/quota-array-dispatch/SKILL.md @@ account for every candidate visibly @@ through `quota-array-dispatch`, which owns every-candidate accounting
220 @@ .agents/skills/quota-array-dispatch/SKILL.md @@ confirm the catalog lists the candidate's model @@ through `quota-array-dispatch`, which owns every-candidate accounting
221 @@ .agents/skills/quota-array-dispatch/SKILL.md @@ is disclosed uncertainty @@ through `quota-array-dispatch`, which owns every-candidate accounting
222 @@ .agents/skills/quota-array-dispatch/SKILL.md @@ only concrete contradictory evidence blocks @@ through `quota-array-dispatch`, which owns every-candidate accounting
223 @@ AGENTS.md @@ malformed configuration is an actionable error @@ -
224 @@ .agents/skills/quota-array-dispatch/SKILL.md @@ dispatch inside the strongest-reasoning class @@ through `quota-array-dispatch`, which owns every-candidate accounting
225 @@ .agents/skills/quota-array-dispatch/SKILL.md @@ do not select by array order, harness name @@ through `quota-array-dispatch`, which owns every-candidate accounting
226 @@ .agents/skills/quota-array-dispatch/SKILL.md @@ `quota-axi` remains data-only @@ through `quota-array-dispatch`, which owns every-candidate accounting
227 @@ .agents/skills/quota-array-dispatch/SKILL.md @@ single owner of the completion-aware profile-array selection procedure @@ through `quota-array-dispatch`, which owns every-candidate accounting
228 @@ .agents/skills/harness-adapters/references/common/model-and-effort.md @@ never select `max` through this fallback @@ `harness-adapters` owns the effort fallback
229 @@ .agents/skills/harness-adapters/references/common/model-and-effort.md @@ do not add model-specific versions of this fallback policy @@ `harness-adapters` owns the effort fallback
231 @@ AGENTS.md @@ `secondmate-provisioning` owns secondmate harness pins @@ -
232 @@ AGENTS.md @@ passing an explicit `--backend` only under that exact task's own authority @@ -
233 @@ AGENTS.md @@ never a silent retry on another backend @@ -
# 5. Recovery
237-238 @@ AGENTS.md @@ honoring read-only mode @@ -
239 @@ AGENTS.md @@ a `state/<id>.status` line is a wake event @@ -
241 @@ AGENTS.md @@ never sweeping a shared endpoint namespace @@ -
242 @@ AGENTS.md @@ recover a dead or windowless ordinary direct report through `stuck-crewmate-recovery` @@ -
243 @@ AGENTS.md @@ the main home never reconstructs or supervises its child tree @@ -
244 @@ AGENTS.md @@ after restart it reconciles its own work and waits silently @@ -
246 @@ AGENTS.md @@ while `state/.afk` exists the daemon owns supervision @@ -
247 @@ AGENTS.md @@ surface only captain-relevant decisions @@ -
248 @@ AGENTS.md @@ make a restart a non-event @@ -
# 6. Project and knowledge management
252-253 @@ AGENTS.md @@ at the intake of every request for project work, and before adding, cloning, registering, creating, removing, or initializing a project @@ -
254 @@ .agents/skills/project-management/SKILL.md @@ use the registry format and parser contract @@ `project-management` - at the intake of every request for project work
254 @@ .agents/skills/project-management/SKILL.md @@ obtain the captain's explicit consent for those exact values @@ `project-management` - at the intake of every request for project work
254 @@ .agents/skills/project-management/SKILL.md @@ first obtain the captain's explicit removal decision @@ `project-management` - at the intake of every request for project work
255 @@ AGENTS.md @@ creating a project never authorizes an unmentioned remote @@ -
257 @@ AGENTS.md @@ `secondmate-provisioning` - before creating, seeding @@ -
258 @@ AGENTS.md @@ its project list is non-exclusive provisioning data @@ -
259 @@ .agents/skills/project-management/SKILL.md @@ keep `local-only` work in the main home @@ load `project-management` at the intake of every request for project work
261-263 @@ AGENTS.md @@ a secondmate is idle by default and acts only on work the main firstmate routes @@ -
265-272 @@ AGENTS.md @@ route durable knowledge to its most specific owner @@ -
274-276 @@ AGENTS.md @@ firstmate never writes a project's `agents.md` @@ -
277 @@ .agents/skills/stow/SKILL.md @@ it is not a reconciliation of durable records against repository or forge reality @@ when the captain invokes `/stow`, load the `stow` skill
# 7. Task lifecycle
281 @@ AGENTS.md @@ read each `bin/` script's header before its first use @@ -
285-287 @@ .agents/skills/project-management/SKILL.md @@ resolve the project independently for every request @@ load `project-management` at the intake of every request for project work
289-292 @@ .agents/skills/project-management/SKILL.md @@ route by the nature of the work against each registered secondmate scope @@ load `project-management` at the intake of every request for project work
293-294 @@ AGENTS.md @@ take the simplest direct end-to-end path for one-off or infrequent operational work @@ -
296-297 @@ AGENTS.md @@ before commissioning an investigation, consult existing reports and evidence @@ -
299-300 @@ AGENTS.md @@ **ship** is the default @@ -
302 @@ AGENTS.md @@ relay an answer they already hold @@ -
303 @@ AGENTS.md @@ never launch a parallel design exercise @@ -
304 @@ AGENTS.md @@ evidence, not authorization to change code @@ -
305 @@ .agents/skills/diagnostic-reasoning/SKILL.md @@ use before scoping a reported bug @@ `diagnostic-reasoning` - before scoping a reported bug
307-308 @@ .agents/skills/project-management/SKILL.md @@ resolve every ship task's concrete delivery mode and `yolo` merge posture at intake @@ load `project-management` at the intake of every request for project work
309 @@ .agents/skills/project-management/SKILL.md @@ dropping below its rigor needs a reason you can state @@ load `project-management` at the intake of every request for project work
310 @@ .agents/skills/project-management/SKILL.md @@ never infer internal-only from file location or project name @@ load `project-management` at the intake of every request for project work
311 @@ .agents/skills/project-management/SKILL.md @@ an unregistered project or absent registry resolves to `no-mistakes` with yolo off @@ load `project-management` at the intake of every request for project work
312 @@ .agents/skills/project-management/SKILL.md @@ record the resulting mode, `yolo` merge posture @@ load `project-management` at the intake of every request for project work
314-315 @@ AGENTS.md @@ file or subsystem overlap is a risk signal, not a reason to wait @@ -
316-317 @@ AGENTS.md @@ write the brief under section 11 @@ -
319 @@ AGENTS.md @@ ### dispatch and steering @@ -
321-322 @@ AGENTS.md @@ must resolve an isolated task worktree distinct from the primary checkout @@ -
323 @@ AGENTS.md @@ under the tasks-axi backlog gate moves the item to in flight @@ -
324 @@ AGENTS.md @@ confirm the worker is processing the brief @@ -
325 @@ AGENTS.md @@ never the backlog @@ -
327 @@ bin/fm-send.sh @@ the task's steering inbox (newlines are legal) @@ `bin/fm-send.sh`, whose header owns the durable inbox, remote delivery, and safe resend
328 @@ bin/fm-send.sh @@ fm_pending_reply_existing_corr=<corr> @@ `bin/fm-send.sh`, whose header owns the durable inbox, remote delivery, and safe resend
329 @@ AGENTS.md @@ passing `--resolve-key` when a steer answers an open keyed decision or blocker @@ -
330 @@ .agents/skills/harness-adapters/SKILL.md @@ routing-marked lifecycle text becomes chat @@ `harness-adapters` - before spawning or recovering a crewmate or secondmate
331 @@ bin/fm-control.sh @@ deliver the harness's verified interrupt sequence @@ use `bin/fm-control.sh <task-id> interrupt|exit|relaunch`
332 @@ .agents/skills/project-management/SKILL.md @@ do not read the secondmate's chat because marked routed replies return through its status @@ load `project-management` at the intake of every request for project work
333 @@ AGENTS.md @@ `bin/fm-pending-reply-lib.sh` owns marked secondmate request correlation @@ -
334 @@ AGENTS.md @@ ## 8. supervision protocol @@ -
336 @@ AGENTS.md @@ ### delivery path and merge authority @@ -
338-339 @@ AGENTS.md @@ no-mistakes alone owns review, fixes, tests, docs, push, pr, and ci @@ -
340 @@ AGENTS.md @@ never hold work for a manual clean verdict @@ -
341 @@ AGENTS.md @@ a separate review needs an explicit captain request or a knowledge-only task @@ -
342 @@ AGENTS.md @@ escalated as a choice to use no-mistakes @@ -
343 @@ AGENTS.md @@ `yolo` governs merge authority only @@ -
345 @@ .agents/skills/project-management/SKILL.md @@ `no-mistakes` runs the full validation pipeline before a pr @@ load `project-management` at the intake of every request for project work
346 @@ .agents/skills/project-management/SKILL.md @@ `direct-pr` pushes and opens a pr without the no-mistakes pipeline @@ load `project-management` at the intake of every request for project work
347 @@ .agents/skills/project-management/SKILL.md @@ lands only through the approved local fast-forward path @@ load `project-management` at the intake of every request for project work
349-350 @@ AGENTS.md @@ `yolo` governs merge authority only @@ -
351 @@ AGENTS.md @@ never merge a red pr unless a current explicit captain instruction names the single github check @@ -
352 @@ AGENTS.md @@ destructive, irreversible, and security-sensitive merges still escalate @@ -
353 @@ AGENTS.md @@ standing `yolo` never authorizes a red merge @@ -
354 @@ AGENTS.md @@ the worker never answers its own finding @@ -
355 @@ AGENTS.md @@ merge only through `bin/fm-pr-merge.sh` @@ -
356 @@ AGENTS.md @@ report an autonomous merge as a one-line full-url or local-main outcome @@ -
360 @@ AGENTS.md @@ trigger validation on the same worker after its implementation commit @@ -
361-362 @@ AGENTS.md @@ firstmate never invokes `no-mistakes axi respond` for a crew-owned run @@ -
363 @@ .agents/skills/captain-hold-lifecycle/SKILL.md @@ append the captain's words to that brief's `## captain's intent` @@ goes through `captain-hold-lifecycle`, which owns the brief update, follow-up routing, and the supersession sequence
364 @@ .agents/skills/captain-hold-lifecycle/SKILL.md @@ `bin/fm-dod-lib.sh` owns the worker-side `--intent` contract @@ goes through `captain-hold-lifecycle`, which owns the brief update, follow-up routing, and the supersession sequence
365 @@ .agents/skills/captain-hold-lifecycle/SKILL.md @@ prefer routing new requirements to follow-up work @@ goes through `captain-hold-lifecycle`, which owns the brief update, follow-up routing, and the supersession sequence
365 @@ .agents/skills/captain-hold-lifecycle/SKILL.md @@ corrections required to satisfy already accepted intent are not new requirements @@ goes through `captain-hold-lifecycle`, which owns the brief update, follow-up routing, and the supersession sequence
367 @@ .agents/skills/captain-hold-lifecycle/SKILL.md @@ completely invalidates the work being validated keeps the task with the same worker @@ goes through `captain-hold-lifecycle`, which owns the brief update, follow-up routing, and the supersession sequence
368 @@ .agents/skills/captain-hold-lifecycle/SKILL.md @@ cancel the active run through no-mistakes axi's supported abort command @@ goes through `captain-hold-lifecycle`, which owns the brief update, follow-up routing, and the supersession sequence
369 @@ .agents/skills/captain-hold-lifecycle/SKILL.md @@ only when its code is `recover_custody` @@ goes through `captain-hold-lifecycle`, which owns the brief update, follow-up routing, and the supersession sequence
370 @@ .agents/skills/captain-hold-lifecycle/SKILL.md @@ custody recovery settles branch ownership, not content @@ goes through `captain-hold-lifecycle`, which owns the brief update, follow-up routing, and the supersession sequence
371 @@ .agents/skills/captain-hold-lifecycle/SKILL.md @@ apart from that single supported abort @@ goes through `captain-hold-lifecycle`, which owns the brief update, follow-up routing, and the supersession sequence
372 @@ .agents/skills/captain-hold-lifecycle/SKILL.md @@ validate exactly once against that final head @@ goes through `captain-hold-lifecycle`, which owns the brief update, follow-up routing, and the supersession sequence
374 @@ AGENTS.md @@ an ask-user finding returns as `needs-decision` @@ -
375 @@ .agents/skills/ask-user-authority/SKILL.md @@ send the same worker one exact decision naming the decision key @@ goes through `ask-user-authority`, which owns deciding, escalating, and delivering the decision
376 @@ .agents/skills/ask-user-authority/SKILL.md @@ require the matching `resolved` event, forbid `--yes` @@ goes through `ask-user-authority`, which owns deciding, escalating, and delivering the decision
377 @@ .agents/skills/ask-user-authority/SKILL.md @@ resume fleet supervision immediately after the decision lands @@ goes through `ask-user-authority`, which owns deciding, escalating, and delivering the decision
379 @@ AGENTS.md @@ judge validation by `bin/fm-crew-state.sh`'s printed state line @@ -
380 @@ AGENTS.md @@ a parked approval or fix-review state means the worker follows the active gate help @@ -
380 @@ bin/fm-crew-state.sh @@ passed/checks-passed -> done, failed/cancelled -> failed @@ judge validation by `bin/fm-crew-state.sh`'s printed state line
381 @@ AGENTS.md @@ the worker never hand-edits, commits, aborts, or restarts outside the gate response flow @@ -
382 @@ bin/fm-dod-lib.sh @@ the ci-ready return point @@ scaffold every brief with `bin/fm-brief.sh`, whose header and `--help` own the scaffold, the fill contract, definitions of done @@ bin/fm-brief.sh
384 @@ AGENTS.md @@ ### ready, landing, and cleanup @@ -
386 @@ AGENTS.md @@ `done: pr <url> checks green` for no-mistakes or `done: pr <url>` for direct-pr @@ -
386 @@ bin/fm-dod-lib.sh @@ done: pr {url} checks green @@ scaffold every brief with `bin/fm-brief.sh`, whose header and `--help` own the scaffold, the fill contract, definitions of done @@ bin/fm-brief.sh
387 @@ bin/fm-pr-check.sh @@ then atomically arm a static merge poll @@ run `bin/fm-pr-check.sh <id> <pr url>`
388 @@ AGENTS.md @@ then report the full url, a concise outcome, and any no-mistakes risk level @@ -
389 @@ AGENTS.md @@ is the only standing relaxation for merge authority @@ -
390 @@ bin/fm-check-register.sh @@ keep it an ordinary single-link mode-0700 file, print one line only when firstmate should wake @@ bound and retired only through `bin/fm-check-register.sh`
391 @@ AGENTS.md @@ never a hand-composed `rm` @@ -
393 @@ AGENTS.md @@ tear down a ship task only after landing is confirmed @@ -
394-395 @@ AGENTS.md @@ never bypass a refusal or use `--force` @@ -
396 @@ AGENTS.md @@ spawn and teardown move items themselves @@ -
398 @@ AGENTS.md @@ a secondmate's idle endpoint is healthy @@ -
399 @@ .agents/skills/secondmate-provisioning/SKILL.md @@ explicitly decides to retire that persistent second mate @@ `secondmate-provisioning` - before creating, seeding, validating, launching, handing backlog to, recovering, pushing inherited local material into, or retiring a secondmate home
399 @@ .agents/skills/secondmate-provisioning/SKILL.md @@ teardown refuses while its `state/*.meta` contains in-flight work @@ `secondmate-provisioning` - before creating, seeding, validating, launching, handing backlog to, recovering, pushing inherited local material into, or retiring a secondmate home
401 @@ AGENTS.md @@ promote an authorized scout through `bin/fm-promote.sh` @@ -
403 @@ AGENTS.md @@ a scout only after its self-contained report exists and its findings are relayed @@ -
404 @@ AGENTS.md @@ evidence, not authorization to change code @@ -
405 @@ AGENTS.md @@ `captain-hold-lifecycle` - before completing an investigation or visual review @@ -
406 @@ .agents/skills/captain-hold-lifecycle/SKILL.md @@ prefer keeping that scout alive to host its own lavish loop @@ `captain-hold-lifecycle` - before completing an investigation or visual review
407 @@ AGENTS.md @@ rather than creating a duplicate task @@ -
408 @@ bin/fm-promote.sh @@ carry over only the intended fix changes @@ promote an authorized scout through `bin/fm-promote.sh`, whose header owns the promoted worker's clean-base carry-over
408 @@ bin/fm-promote.sh @@ turn that reproduction into a regression test @@ promote an authorized scout through `bin/fm-promote.sh`, whose header owns the promoted worker's clean-base carry-over
408 @@ bin/fm-promote.sh @@ inventory this worktree's scratch state @@ promote an authorized scout through `bin/fm-promote.sh`, whose header owns the promoted worker's clean-base carry-over
# 8. Supervision protocol
412 @@ AGENTS.md @@ owns the wait and wake mechanism @@ -
414 @@ AGENTS.md @@ keep exactly one live supervision cycle @@ -
415 @@ AGENTS.md @@ relay may require that cycle with no fleet work @@ -
416 @@ AGENTS.md @@ or start a second cycle beside a healthy one @@ -
417 @@ AGENTS.md @@ using its repair action only for a missing or failed cycle @@ -
418 @@ AGENTS.md @@ no turn ends blind while work is under way @@ -
420 @@ AGENTS.md @@ every wake-handling turn first drains the durable wake queue @@ -
421 @@ AGENTS.md @@ session start is exempt because its digest already presented the queue @@ -
422 @@ AGENTS.md @@ `open decisions` entries are actionable @@ -
423 @@ AGENTS.md @@ `unread status` lines print only once @@ -
424 @@ AGENTS.md @@ never that the captain ruled @@ -
425 @@ AGENTS.md @@ interruption before it leaves the work durable for idempotent re-handling @@ -
426 @@ AGENTS.md @@ re-read current state before re-escalating an old decision, blocker, or pause @@ -
427 @@ AGENTS.md @@ `paused:` is a bounded external wait expected to clear on its own @@ -
429 @@ AGENTS.md @@ `signal:` - read the listed event lines first @@ -
431 @@ AGENTS.md @@ `signal:` - read the listed event lines first @@ -
432 @@ AGENTS.md @@ a deep-inspection reason also requires current-state and validation-log inspection @@ -
433 @@ AGENTS.md @@ or it stays pending @@ -
434 @@ AGENTS.md @@ never report an unchanged fleet as progress @@ -
436 @@ AGENTS.md @@ refresh a clone in this home through the guarded fleet-sync path @@ -
437 @@ .agents/skills/fmx-respond/SKILL.md @@ clears the link regardless of how many follow-ups remain @@ `fmx-respond` - when relay is on: on an `x-mention <request_id>`
439 @@ AGENTS.md @@ a secondmate's idle endpoint is healthy @@ -
440 @@ AGENTS.md @@ empty polls, elapsed time, and no-change updates are not captain-facing progress @@ -
441 @@ AGENTS.md @@ especially never `pkill -f bin/fm-watch.sh` @@ -
442 @@ AGENTS.md @@ a forced repair uses only the home-scoped path the emitted block names @@ -
444-445 @@ AGENTS.md @@ every wake-handling turn first drains the durable wake queue @@ -
446 @@ AGENTS.md @@ never the primary checkout @@ -
447 @@ AGENTS.md @@ turn-end guards are backstops, not permission to omit the cycle @@ -
451 @@ AGENTS.md @@ invoke the `/afk` skill when the captain says `/afk` @@ -
452 @@ AGENTS.md @@ the skill owns the procedure @@ -
454 @@ .agents/skills/afk/SKILL.md @@ constructs every current injection as the `away-supervisor` kind @@ invoke the `/afk` skill when the captain says `/afk`
455 @@ .agents/skills/afk/SKILL.md @@ written only by `bin/fm-afk-contract.sh` after the captain confirms a read-back @@ invoke the `/afk` skill when the captain says `/afk`
455 @@ .agents/skills/afk/SKILL.md @@ recorded clauses are not executed by this release @@ invoke the `/afk` skill when the captain says `/afk`
456-457 @@ AGENTS.md @@ pi runs no daemon and keeps its ordinary supervision session @@ -
458-459 @@ AGENTS.md @@ is internal escalation that never exits away mode @@ -
460 @@ AGENTS.md @@ any other unmarked message means the captain returned @@ -
461 @@ AGENTS.md @@ away mode never expands approval authority @@ -
462 @@ AGENTS.md @@ biasing ambiguous input toward exit @@ -
464-466 @@ AGENTS.md @@ when a live worker reports its no-mistakes pipeline dead, unreachable, or timed out @@ -
# 9. Escalation and captain etiquette
471 @@ AGENTS.md @@ translates internal state into the project outcome, consequence, and next decision @@ -
472 @@ AGENTS.md @@ in the captain's nouns @@ -
473 @@ AGENTS.md @@ never expose internal terms @@ -
474 @@ AGENTS.md @@ scout and second mate are accepted house vocabulary @@ -
475 @@ AGENTS.md @@ rewrite internal labels before sending @@ -
477 @@ AGENTS.md @@ worktree, checkout, primary checkout, or local-main -> local copy @@ -
478 @@ AGENTS.md @@ teardown -> cleanup @@ -
482 @@ AGENTS.md @@ brief -> instructions @@ -
483 @@ AGENTS.md @@ crewmate -> worker, only when naming the helper matters @@ -
484 @@ AGENTS.md @@ harness, backend, runtime, or adapter -> worker runtime or tool @@ -
485 @@ AGENTS.md @@ status file, metadata, state, task id, or raw path -> durable record @@ -
486 @@ AGENTS.md @@ fail-closed, fails closed, fail loudly, or refuses loudly -> stops safely @@ -
487 @@ AGENTS.md @@ fail-open, fails open, passive fail-open, or degraded-open -> steps aside @@ -
489-490 @@ AGENTS.md @@ decision records verbatim into captain chat @@ -
491 @@ AGENTS.md @@ even when a private report you point to keeps exact identifiers @@ -
493-495 @@ AGENTS.md @@ every escalation stands alone and stays concise @@ -
497-504 @@ AGENTS.md @@ reach the captain immediately for work ready for review @@ -
506 @@ AGENTS.md @@ appending the outcome to the parent channel your charter names @@ -
507 @@ AGENTS.md @@ do not surface automatic fixes, retries, routine progress, or supervision mechanics @@ -
508 @@ AGENTS.md @@ reply exactly `captain, shipshape.` @@ -
509 @@ AGENTS.md @@ batch non-urgent updates into the next natural reply @@ -
511 @@ AGENTS.md @@ mention a pr with its full `https://...` url copied verbatim @@ -
# 10. Backlog contract
516-518 @@ AGENTS.md @@ it tracks work items, never agents @@ -
519-520 @@ AGENTS.md @@ filing any main-side thread worth tracking the same way @@ -
521 @@ .agents/skills/captain-hold-lifecycle/SKILL.md @@ must be carried by a captain-held task in the authoritative backlog @@ `captain-hold-lifecycle` - before completing an investigation or visual review
522-523 @@ AGENTS.md @@ spawn and teardown move items themselves @@ -
525-526 @@ AGENTS.md @@ used only through `bin/fm-tasks-axi.sh` or the documented manual path @@ -
527 @@ AGENTS.md @@ owns cross-home handoff @@ -
529 @@ bin/fm-tasks-axi.sh @@ keep free-form notes free of temporary paths, moving versions, ephemeral identifiers @@ write and act on task notes under the durable-note rules in `bin/fm-tasks-axi.sh`'s header
530 @@ bin/fm-tasks-axi.sh @@ archive the superseded body when recoverability matters @@ write and act on task notes under the durable-note rules in `bin/fm-tasks-axi.sh`'s header
531 @@ bin/fm-tasks-axi.sh @@ verify volatile details in a note against their authoritative config @@ write and act on task notes under the durable-note rules in `bin/fm-tasks-axi.sh`'s header
532 @@ bin/fm-tasks-axi.sh @@ preserve durable structured identifiers, dependencies, and completion artifact links @@ write and act on task notes under the durable-note rules in `bin/fm-tasks-axi.sh`'s header
# 11. Crewmate briefs
536 @@ AGENTS.md @@ scaffold every brief with `bin/fm-brief.sh` @@ -
537 @@ bin/fm-brief.sh @@ never widen `## captain's intent` into a general goal or an enumerated coverage list @@ scaffold every brief with `bin/fm-brief.sh`, whose header and `--help` own the scaffold, the fill contract, definitions of done
538 @@ bin/fm-brief.sh @@ naming what stays out of scope when the ask is narrow @@ scaffold every brief with `bin/fm-brief.sh`, whose header and `--help` own the scaffold, the fill contract, definitions of done
539 @@ bin/fm-brief.sh @@ owns the no-mistakes `--intent` contract @@ scaffold every brief with `bin/fm-brief.sh`, whose header and `--help` own the scaffold, the fill contract, definitions of done
540 @@ bin/fm-brief.sh @@ keep additions task-specific rather than repeating lifecycle instructions @@ scaffold every brief with `bin/fm-brief.sh`, whose header and `--help` own the scaffold, the fill contract, definitions of done
542 @@ AGENTS.md @@ every ship brief keeps its worktree-isolation assertion @@ -
543 @@ AGENTS.md @@ requires `firstmate-coding-guidelines` @@ -
544 @@ AGENTS.md @@ regenerating rather than hand-adding commands @@ -
545 @@ bin/fm-brief.sh @@ a named non-`default` session plus a trailing `--session <name>` on every call @@ scaffold every brief with `bin/fm-brief.sh`, whose header and `--help` own the scaffold, the fill contract, definitions of done
547 @@ .agents/skills/secondmate-provisioning/SKILL.md @@ sole owner of boilerplate idle-by-default behavior @@ charter briefs follow `secondmate-provisioning`
548 @@ AGENTS.md @@ status appends are sparse supervisor-actionable events @@ -
549 @@ AGENTS.md @@ the scaffold is a safety contract @@ -
# 12. Self-update
553 @@ AGENTS.md @@ shared instructions reach running homes only after landing on the default branch @@ -
554 @@ AGENTS.md @@ a running firstmate loads only `agents.md`, `bin/`, and `.agents/skills/` @@ -
555 @@ AGENTS.md @@ on `/updatefirstmate` or a request to update firstmate, load that skill @@ -
556 @@ .agents/skills/updatefirstmate/SKILL.md @@ guarded update path @@ on `/updatefirstmate` or a request to update firstmate, load that skill
# 13. Agent-only reference skills
560 @@ AGENTS.md @@ none of these skills is captain-invocable @@ -
562 @@ AGENTS.md @@ `bootstrap-diagnostics` - when the digest's bootstrap or network-checks section prints a diagnostic line @@ -
563 @@ AGENTS.md @@ `diagnostic-reasoning` - before scoping a reported bug @@ -
564 @@ AGENTS.md @@ `ask-user-authority` - before deciding any ask-user finding @@ -
565 @@ AGENTS.md @@ `quota-array-dispatch` - before choosing among a matched crew-dispatch profile array @@ -
566 @@ AGENTS.md @@ `harness-adapters` - before spawning or recovering a crewmate or secondmate @@ -
567 @@ AGENTS.md @@ `firstmate-orca` - before switching to orca @@ -
568-569 @@ AGENTS.md @@ `project-management` - at the intake of every request for project work @@ -
570 @@ AGENTS.md @@ `stuck-crewmate-recovery` - when the digest reports @@ -
571 @@ AGENTS.md @@ `secondmate-provisioning` - before creating, seeding @@ -
572 @@ AGENTS.md @@ `captain-hold-lifecycle` - before completing an investigation or visual review @@ -
573-574 @@ AGENTS.md @@ never run a registered source's blocking command yourself @@ -
575 @@ AGENTS.md @@ `fmx-respond` - when relay is on @@ -
576 @@ AGENTS.md @@ `firstmate-codexapp` - before coordinating a visible codex desktop thread @@ -
577 @@ AGENTS.md @@ `firstmate-coding-guidelines` - before changing section 1's shared tracked material @@ -
# 14. Relay
581 @@ AGENTS.md @@ called "x mode" in older docs @@ -
582 @@ AGENTS.md @@ is inert until the home places `fmx_pairing_token` in its gitignored `.env` @@ -
583 @@ AGENTS.md @@ which still requires trusted-channel confirmation @@ -
584 @@ docs/configuration.md @@ it is off unless the firstmate home's gitignored `.env` contains a non-empty `fmx_pairing_token` @@ (docs/configuration.md) "operational home layout and state" owns the file inventory and configuration schemas
586 @@ AGENTS.md @@ a relay-only home still keeps the live supervision cycle @@ -
587 @@ AGENTS.md @@ `fmx-respond` - when relay is on: on an `x-mention <request_id>` @@ -
588 @@ .agents/skills/fmx-respond/SKILL.md @@ clears the link regardless of how many follow-ups remain @@ `fmx-respond` owns the rest, including durable promised final replies that only this home posts
590 @@ .agents/skills/fmx-respond/SKILL.md @@ turn it into durable state @@ `fmx-respond` owns the rest, including durable promised final replies that only this home posts
591 @@ AGENTS.md @@ when the digest lists a public commitment awaiting delivery or an open public loop @@ -
592 @@ .agents/skills/fmx-respond/SKILL.md @@ only this home holds the relay consent and the thread binding @@ `fmx-respond` owns the rest, including durable promised final replies that only this home posts
592 @@ .agents/skills/fmx-respond/SKILL.md @@ never recover a terminal result by reading a worker's `done:` sentence @@ `fmx-respond` owns the rest, including durable promised final replies that only this home posts
# Captain instruction precedence
596-597 @@ AGENTS.md @@ overrides any conflicting standing rule above @@ -
598 @@ AGENTS.md @@ never infer an override, broaden its scope, apply it by analogy @@ -
599 @@ AGENTS.md @@ ambiguous scope or conflict needs one concise clarification first @@ -
600 @@ AGENTS.md @@ a conflicting firstmate-written rule must not rigidly block it @@ -
601 @@ AGENTS.md @@ standing `yolo` merge authority never substitutes @@ -
# Maintaining this file
605-607 @@ .agents/skills/firstmate-coding-guidelines/SKILL.md @@ patch, replace, or prune the owner's existing language @@ `firstmate-coding-guidelines` owns this file's size discipline
608 @@ AGENTS.md @@ a rule it cannot place stays here @@ -
LEDGER

CHECKER="$TMP_ROOT/check-contract.py"
cat > "$CHECKER" <<'PY'
"""Check the AGENTS.md reachability ledger, baseline coverage, and skill index."""
import json
import os
import re
import sys
from pathlib import Path

root, agents_path, ledger_path, baseline_path = sys.argv[1:5]
overrides = json.loads(os.environ.get("FM_CONTRACT_OWNER_OVERRIDES", "{}"))
errors = []
cache = {}


def read(rel):
    if rel not in cache:
        path = Path(agents_path) if rel == "AGENTS.md" else Path(overrides.get(rel, os.path.join(root, rel)))
        try:
            cache[rel] = path.read_text(encoding="utf-8")
        except OSError:
            errors.append(f"owner unreadable: {rel}")
            cache[rel] = ""
    return cache[rel]


def norm(text, rel=""):
    if rel.endswith(".sh"):
        text = "\n".join(re.sub(r"^\s*#\s?", "", line) for line in text.splitlines())
        text = text.replace("\\`", "`")
    return re.sub(r"\s+", " ", text).strip().lower()


def tokens(rel):
    match = re.match(r"\.agents/skills/([^/]+)/", rel)
    if match:
        return [f"`{match.group(1)}`", f"`/{match.group(1)}`"]
    return [rel.lower()]


baseline = Path(baseline_path).read_text(encoding="utf-8").splitlines() if baseline_path else []
agents_raw = read("AGENTS.md")
agents = norm(agents_raw)
covered = set()
rows = 0
for number, raw in enumerate(Path(ledger_path).read_text(encoding="utf-8").splitlines(), 1):
    if not raw.strip() or raw.startswith("#"):
        continue
    rows += 1
    parts = [part.strip() for part in raw.split(" @@ ")]
    if len(parts) not in (4, 5):
        errors.append(f"ledger line {number}: expected 4 or 5 fields")
        continue
    spec, owner, anchor, trigger = parts[:4]
    via = parts[4] if len(parts) == 5 else ""
    lines = set()
    for chunk in spec.split(","):
        first, _, last = chunk.partition("-")
        lines.update(range(int(first), int(last or first) + 1))
    covered |= lines
    if anchor == "=verbatim":
        if baseline:
            owner_lines = set(read(owner).splitlines())
            for line in sorted(lines):
                text = baseline[line - 1]
                if text.strip() and text not in owner_lines:
                    errors.append(f"ledger line {number}: {owner} lost baseline line {line} verbatim: {text[:80]}")
    elif norm(anchor) not in norm(read(owner), owner):
        errors.append(f"ledger line {number}: {owner} no longer states: {anchor}")
    if owner == "AGENTS.md":
        continue
    if trigger == "-":
        errors.append(f"ledger line {number}: a rule moved to {owner} needs an AGENTS.md trigger")
        continue
    if norm(trigger) not in agents:
        errors.append(f"ledger line {number}: AGENTS.md lost the trigger for {owner}: {trigger}")
    target = via or owner
    if not any(token in norm(trigger) for token in tokens(target)):
        errors.append(f"ledger line {number}: trigger does not name {target}: {trigger}")
    if via:
        via_text = norm(read(via), via)
        if not any(token.strip("`/") in via_text for token in tokens(owner)) and os.path.basename(owner).lower() not in via_text:
            errors.append(f"ledger line {number}: {via} does not lead to {owner}")

if baseline:
    current = set(agents_raw.splitlines())
    missing = [
        index for index, text in enumerate(baseline, 1)
        if text.strip() and text != "```" and text not in current and index not in covered
    ]
    if missing:
        errors.append("baseline lines with no ledger row: " + ",".join(str(index) for index in missing))

for skill in sorted(Path(root, ".agents/skills").glob("*/SKILL.md")):
    front = skill.read_text(encoding="utf-8").split("---")[1]
    name = re.search(r"^name:\s*(\S+)", front, re.M).group(1)
    if re.search(r"^user-invocable:\s*false", front, re.M) and name != "decision-hold-lifecycle":
        if f"- `{name}` - " not in agents_raw:
            errors.append(f"skill index: agent-only skill {name} has no section 13 trigger")

for error in errors:
    print(error)
print(f"rows={rows} covered={len(covered)} errors={len(errors)}")
sys.exit(1 if errors else 0)
PY

BASELINE_FILE="$TMP_ROOT/AGENTS.baseline.md"
if ! git -C "$ROOT" show "$BASELINE_COMMIT:AGENTS.md" > "$BASELINE_FILE" 2>/dev/null; then
  [ -z "${CI:-}" ] || fail "baseline $BASELINE_COMMIT is unreachable; the ledger cannot prove coverage (fetch full history)"
  printf 'note: baseline %s unreachable locally; coverage and verbatim checks skipped\n' "$BASELINE_COMMIT"
  BASELINE_FILE=""
fi

run_checker() {  # <agents> <ledger> -> prints output, returns checker status
  python3 "$CHECKER" "$ROOT" "$1" "$2" "$BASELINE_FILE" 2>&1
}

expect_checker_failure() {  # <label> <expected text> <agents> <ledger>
  local out rc
  out=$(run_checker "$3" "$4")
  rc=$?
  [ "$rc" -ne 0 ] || fail "$1: checker passed a planted regression"
  assert_contains "$out" "$2" "$1: checker did not report the planted regression"
}

out=$(run_checker "$ROOT/AGENTS.md" "$LEDGER") || fail "contract ledger check failed:
$out"
pass "every baseline rule is kept or reachable through a visible trigger ($(printf '%s\n' "$out" | tail -1))"

planted="$TMP_ROOT/agents-no-trigger.md"
grep -v 'captain-hold-lifecycle' "$ROOT/AGENTS.md" > "$planted"
expect_checker_failure "dropped trigger" "AGENTS.md lost the trigger for .agents/skills/captain-hold-lifecycle/SKILL.md" "$planted" "$LEDGER"
pass "a trim that strands a moved rule's owner is caught"

owner_copy="$TMP_ROOT/captain-hold-lifecycle.md"
grep -v 'recover_custody' "$ROOT/.agents/skills/captain-hold-lifecycle/SKILL.md" > "$owner_copy"
if out=$(FM_CONTRACT_OWNER_OVERRIDES="{\".agents/skills/captain-hold-lifecycle/SKILL.md\": \"$owner_copy\"}" run_checker "$ROOT/AGENTS.md" "$LEDGER"); then
  fail "owner edit: checker passed an owner that dropped a moved rule"
fi
assert_contains "$out" "no longer states: only when its code is \`recover_custody\`" "owner edit: dropped rule not named"
pass "an owner edit that deletes a moved rule is caught"

if [ -n "$BASELINE_FILE" ]; then
  planted_ledger="$TMP_ROOT/ledger-missing-row.txt"
  grep -v '^48 @@ ' "$LEDGER" > "$planted_ledger"
  expect_checker_failure "uncovered baseline line" "baseline lines with no ledger row: 48" "$ROOT/AGENTS.md" "$planted_ledger"
  pass "a removed baseline line with no ledger row is caught"
fi

planted_index="$TMP_ROOT/agents-no-index.md"
grep -v "^- \`fmx-respond\` - " "$ROOT/AGENTS.md" > "$planted_index"
expect_checker_failure "skill index" "skill index: agent-only skill fmx-respond has no section 13 trigger" "$planted_index" "$LEDGER"
pass "an agent-only skill without a section 13 trigger is caught"

# --- Codex delivery ------------------------------------------------------------
agents_bytes=$(LC_ALL=C wc -c < "$ROOT/AGENTS.md" | tr -d '[:space:]')
[ "$agents_bytes" -le "$CODEX_PROJECT_DOC_MAX_BYTES" ] \
  || fail "AGENTS.md is $agents_bytes bytes; Codex's default project_doc_max_bytes ($CODEX_PROJECT_DOC_MAX_BYTES) silently truncates it"
pass "AGENTS.md ($agents_bytes bytes) fits Codex's default project_doc_max_bytes"

# --- composed startup budget -----------------------------------------------------
FAKEBIN="$TMP_ROOT/fakebin"
mkdir -p "$FAKEBIN"
fm_fake_exit0 "$FAKEBIN" tmux node chrome-devtools-axi gh
fm_fake_version_tool "$FAKEBIN" lavish-axi FM_FAKE_LAVISH_AXI_VERSION 0.1.46
fm_fake_version_tool "$FAKEBIN" gh-axi FM_FAKE_GH_AXI_VERSION 0.1.29
fm_fake_version_tool "$FAKEBIN" quota-axi FM_FAKE_QUOTA_AXI_VERSION 0.1.29
cat > "$FAKEBIN/treehouse" <<'SH'
#!/usr/bin/env bash
[ "${1:-}" = get ] && [ "${2:-}" = --help ] && printf '%s\n' 'Usage: treehouse get [--lease]'
exit 0
SH
cat > "$FAKEBIN/no-mistakes" <<'SH'
#!/usr/bin/env bash
[ "${1:-}" = --version ] && printf '%s\n' 'no-mistakes version v1.46.0 (fake) 2026-06-27T00:02:18Z'
exit 0
SH
cat > "$FAKEBIN/tasks-axi" <<'SH'
#!/usr/bin/env bash
case "${1:-} ${2:-}" in
  "--version "*) printf '%s\n' 0.2.4 ;;
  "update --help") printf '%s\n' 'usage: tasks-axi update <id> [--archive-body]' ;;
  "mv --help") printf '%s\n' 'usage: tasks-axi mv <id> [<id>...] <state>' ;;
esac
exit 0
SH
# A fake ps names this test's own pid as the harness process, so fm-harness.sh and
# the session lock both see a real ancestry edge without any vendor binary.
cat > "$FAKEBIN/ps" <<'SH'
#!/usr/bin/env bash
pid=
previous=
for argument in "$@"; do
  [ "$previous" = -p ] && pid=$argument
  previous=$argument
done
case "$*" in
  *"comm="*)
    if [ "$pid" = "$FM_FAKE_HARNESS_PID" ]; then printf '/usr/local/bin/%s\n' "$FM_FAKE_HARNESS"; else printf '/bin/bash\n'; fi
    exit 0
    ;;
  *"args="*)
    if [ "$pid" = "$FM_FAKE_HARNESS_PID" ]; then printf '%s\n' "$FM_FAKE_HARNESS"; else printf 'bash\n'; fi
    exit 0
    ;;
  *"ppid="*)
    /bin/ps -o ppid= -p "$pid"
    ;;
esac
exit 1
SH
chmod +x "$FAKEBIN"/*

render_digest() {  # <harness> <output file>
  local harness=$1 out=$2 world fake=$1
  local -a markers=(FM_CONTRACT_RENDER=1)
  case "$harness" in
    pi|pi-signed) markers=(PI_CODING_AGENT=true "FM_PI_HARNESS=$harness"); fake=pi ;;
    omp) markers=(FM_OMP_HARNESS=omp) ;;
    cursor) markers=(CURSOR_AGENT=1); fake=cursor-agent ;;
  esac
  world=$(mktemp -d "$TMP_ROOT/render.XXXXXX")
  mkdir -p "$world/home/state" "$world/home/data" "$world/home/config"
  git init -q -b main "$world/root"
  git -C "$world/root" -c user.email=contract@example.invalid -c user.name=contract commit -q --allow-empty -m init
  env -u CLAUDECODE -u PI_CODING_AGENT -u FM_PI_HARNESS -u GROK_AGENT -u CURSOR_AGENT -u CURSOR_INVOKED_AS \
    -u FM_OMP_HARNESS -u GEMINI_CLI -u ATLASSIAN_AGENT_TYPE -u ROVODEV_CLI \
    "${markers[@]}" FM_FAKE_HARNESS="$fake" FM_FAKE_HARNESS_PID=$$ \
    FM_HOME="$world/home" FM_ROOT_OVERRIDE="$world/root" PATH="$FAKEBIN:$BASE_PATH" \
    "$ROOT/bin/fm-session-start.sh" > "$out" 2>&1 < /dev/null
}

skill_frontmatter_bytes() {  # <skills dir>
  local skill total=0 bytes
  for skill in "$1"/*/SKILL.md; do
    bytes=$(awk '/^---$/ { count++; print; if (count == 2) exit; next } count == 1 { print }' "$skill" | LC_ALL=C wc -c | tr -d '[:space:]')
    total=$((total + bytes))
  done
  printf '%s\n' "$total"
}

composed_tokens() {  # <harness> <digest file> <skills dir>
  local bytes
  bytes=$(( $(LC_ALL=C wc -c < "$ROOT/AGENTS.md") + $(LC_ALL=C wc -c < "$2") + $(skill_frontmatter_bytes "$3") ))
  [ "$1" != claude ] || bytes=$(( bytes + $(LC_ALL=C wc -c < "$ROOT/CLAUDE.md") ))
  fm_startup_memory_estimated_tokens_for_bytes "$bytes"
}

pids=()
for harness in $PRIMARY_HARNESSES; do
  render_digest "$harness" "$TMP_ROOT/digest-$harness.out" &
  pids+=("$!")
done
index=0
for harness in $PRIMARY_HARNESSES; do
  wait "${pids[$index]}" || fail "$harness: fm-session-start.sh exited non-zero:
$(cat "$TMP_ROOT/digest-$harness.out")"
  index=$((index + 1))
done

printf '%-10s %8s %8s\n' harness tokens cap
for harness in $PRIMARY_HARNESSES; do
  digest="$TMP_ROOT/digest-$harness.out"
  assert_grep "SUPERVISION OPERATING INSTRUCTIONS - primary harness: $harness" "$digest" \
    "$harness: the render did not detect the harness, so the measurement is not that harness's startup"
  assert_no_grep "READ-ONLY SESSION" "$digest" "$harness: the render lost the session lock, so it measured the read-only digest"
  [ "$(awk '/^BOOTSTRAP$/ { getline; getline; print; exit }' "$digest")" = "(silent - all good)" ] \
    || fail "$harness: bootstrap was not silent, so the digest is not the empty-home floor:
$(awk '/^BOOTSTRAP$/,/^WAKE QUEUE$/' "$digest")"
  tokens=$(composed_tokens "$harness" "$digest" "$ROOT/.agents/skills")
  cap=$(cap_for "$harness")
  printf '%-10s %8s %8s\n' "$harness" "$tokens" "$cap"
  [ "$tokens" -le "$cap" ] || fail "$harness: composed empty-home startup is $tokens estimated tokens, over its reviewed cap of $cap"
done
pass "every primary harness's composed empty-home startup is within its reviewed cap"

padded_skills="$TMP_ROOT/padded-skills"
cp -R "$ROOT/.agents/skills" "$padded_skills"
filler=$(printf 'moved rule text %.0s' $(seq 1 4000))
python3 - "$padded_skills/stow/SKILL.md" "$filler" <<'PY'
import sys
from pathlib import Path
path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
path.write_text(text.replace("description: ", "description: " + sys.argv[2] + " ", 1), encoding="utf-8")
PY
tokens=$(composed_tokens claude "$TMP_ROOT/digest-claude.out" "$padded_skills")
[ "$tokens" -gt "$(cap_for claude)" ] || fail "moving text into an always-listed skill description stayed under the claude cap"
padded_digest="$TMP_ROOT/digest-padded.out"
{ cat "$TMP_ROOT/digest-codex.out"; printf '%s\n' "$filler"; } > "$padded_digest"
tokens=$(composed_tokens codex "$padded_digest" "$ROOT/.agents/skills")
[ "$tokens" -gt "$(cap_for codex)" ] || fail "moving text into the emitted digest stayed under the codex cap"
pass "moving contract text into a skill description or the emitted digest breaks the budget"
