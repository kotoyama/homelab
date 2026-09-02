# AGENTS.md

Behavioral rules for AI agents in this homelab repo.

## Workflow

Verify every change in this order:

1. Lint: `ansible-lint`
2. Dry run: `ansible-playbook playbooks/site.yml --check --diff`
3. Deploy: `ansible-playbook playbooks/site.yml`
4. Re-run: must report `changed=0`

To operate on a single service, append `--tags <role>` to any playbook invocation above (e.g. `--tags pihole`).

## Rules

- **Single source of truth**: any configuration change goes through roles and a playbook deploy. Never edit configs directly on the Pi (exception: a live hotfix to state the next run wouldn't touch anyway).
- **Simplicity first**: a variable earns its place only if overridden elsewhere or used in 2+ places; otherwise inline the value. No speculative abstractions.
- **Claim labeling**: every factual statement is `verified` / `assumption` / `unverified`. Never present assumptions or doc examples as facts. Verify via the cheapest authoritative source first (version-matched official docs, man pages, etc.); escalate to source inspection only if docs are ambiguous, and stop after one dead end — report `unverified` and let the user decide instead of digging deeper.
- **Consistency**: never invent new patterns — follow the conventions of existing roles.
- **Idempotency**: describe state with modules, restart only through handlers on actual change; no `shell`/`command` tasks.
- **Pinned images**: exact versions unless an upstream stable tag exists.
- **Secrets**: live in vault only. No secrets in code, logs, or chat history. When quoting output that contains one, mask the value with asterisks (e.g. `vault_become_password: ****`).
- **Healthcheck**: every role deploying a compose service ends with a healthcheck task.
- **Variable placement**: service-scoped variables live in `roles/<service>/defaults/main.yml`; `inventory/group_vars/all/main.yml` holds only host-wide values or variables reused across roles.
- **No default values**: before writing any config, consult version-matched upstream docs (installed package docs on the Pi, e.g. `zcat /usr/share/doc/unattended-upgrades/README.md.gz`, man pages, image docs) and commit only overrides or required values — never copies of default/sample files. Verify effective state after deploy where possible (e.g. `apt-config dump`).
- **No dead code**: after deleting anything, grep the whole repo (no extension filters) for leftovers.
