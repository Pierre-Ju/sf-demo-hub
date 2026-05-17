---
name: create-demo
description: Bootstrap a Salesforce scratch-org demo environment for one of the supported industries (manufacturing / retail / healthcare / finance). Use when the user asks to create / spin up / bring up / 拉起 / 新建 a demo org, or invokes /create-demo. Orchestrates create-demo.sh, the post-create UI checklist, and seed verification.
---

# create-demo

End-to-end orchestrator for `sf-demo-hub` demo environments. Wraps `create-demo.sh` and adds the things the shell script can't do: arg parsing from natural language, pre-flight validation, the UI-only post-create checklist (email deliverability, Pipeline Inspection), and verification.

## Inputs

Parse from user's message:

- **industry** (required): one of `manufacturing | retail | healthcare | finance`. Reject anything else — do NOT silently pick a default.
- **duration-days** (optional, default 7, max 30)
- **skip-checklist** (optional): if the user says "just create it" / "只创建别管 checklist", skip step 3.

If industry is ambiguous or missing, ask via AskUserQuestion before doing anything else.

## Flow

### 1. Pre-flight checks

Run these in parallel before touching any org:

- `sf org list` → confirm a Dev Hub is set as default. If not, stop and tell the user to `sf org login web --set-default-dev-hub --alias devhub`.
- `sf org display --target-org demo-<industry>` → if it succeeds, alias is already taken. Ask the user: reset and recreate (`scripts/reset.sh demo-<industry>`), or abort.
- Read `config/<industry>-scratch-def.json` and check if `features` includes an industry-cloud feature (e.g. `ManufacturingCloud`). Cross-reference [[project_devhub_entitlements]] in user memory — if the current Dev Hub doesn't have it, warn the user and offer to proceed with a degraded config (the seed script only uses standard objects, so degrade is safe).

### 2. Create the org

Run `./create-demo.sh <industry> <duration>`. The script handles:

- scratch org create with `--set-default --wait 15`
- seed apex run
- `sf org open`

If it fails on "feature not allowed", drop the offending feature from `features[]` in the scratch-def, commit nothing, and retry once. Surface the failure to the user before retrying.

### 3. Post-create UI checklist (Metadata API can't touch these)

These steps require the user to click in Setup — Claude can only guide. Print a numbered checklist and wait for confirmation before declaring done:

1. **Email Deliverability** (Setup → Email → Deliverability):
   - Dropdown `Access to Send Email (All Email Services)` → **All email**
   - Checkbox `Use a substitute email address for unverified domains` → **checked**
   - Both required. Default `System email only` silently drops Apex/Flow email.
2. **Pipeline Inspection** (Setup → Pipeline Inspection): toggle on. No Metadata API support.
3. **Language / Locale** (Setup → Company Information): verify `zh_CN` / `CN`.
4. **List View permissions**: try creating a List View on any standard object. If "New" button is missing, add `Manage Public List Views` + `Customize Application` to System Administrator profile.

See [Scratch org demo gotchas](../../../CLAUDE.md) for the full reasoning behind each step.

### 4. Verify seed data

After the checklist, confirm seed ran:

```
sf data query --target-org demo-<industry> --query "SELECT COUNT() FROM Account WHERE Industry != null"
```

Expect 5–10 rows (per the per-industry seed). If 0, re-run `sf apex run -o demo-<industry> -f scripts/apex/seed-<industry>.apex` — it's idempotent.

### 5. Final summary

Report to user:

- Alias, org URL, expiration date
- Which checklist items are pending manual action (if any)
- Teardown command: `./scripts/reset.sh demo-<industry>`

## Failure / resume modes

If the user re-invokes the skill and `demo-<industry>` already exists:

- Detect via `sf org display`
- Ask: **(a)** skip create, jump to checklist + seed verify; **(b)** reset and start over; **(c)** abort.

This makes the skill safe to re-run after a partial failure without forcing a full teardown.

## Notes for the implementer

- The bash script is the source of truth for create + seed. Don't reimplement its logic in the skill — call it.
- The UI checklist is the real value-add of this skill. Don't shortcut it.
- Windows: `create-demo.sh` runs under Git Bash / WSL. If the user is on plain PowerShell, fall back to invoking the underlying `sf` commands directly.
- Keep idempotency: seed scripts already guard with `SELECT ... LIMIT 1`; the skill should too at every step.
