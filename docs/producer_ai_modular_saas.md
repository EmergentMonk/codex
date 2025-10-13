# Producer.ai Modular SaaS Build Playbook

This playbook adapts the "Deep Research" specification into an actionable
multi-agent plan using the Codex toolchain that ships with this repository. It
focuses on orchestrating Codex CLI, Codex Web, and MCP-capable extensions to
construct the dual-purpose Producer.ai + medical cannabis platform.

## 1. Agent Topology

| Agent | Responsibilities | Key Prompts & Scripts |
| --- | --- | --- |
| **Codex CLI (local)** | Rust core engine, addon runtime, CI automation | `scripts/prompts/rust/core_engine.prompt`, `scripts/prompts/ci/coverage.prompt` |
| **Codex Web (cloud)** | Parallel UI scaffolding, documentation drafts, addon marketplace assets | `scripts/prompts/web/ui_shell.prompt`, `scripts/prompts/docs/adr.prompt` |
| **MCP Servers** | Secure credential storage, quantum backends, compliance knowledge bases | Configure in `~/.codex/config.toml` with entries for `producer-ai-secret-vault` and `quantum-sim` |
| **CI Bot (codex-action)** | Enforces AGENTS.md checks, gathers benchmarks, prepares release notes | GitHub workflow `ci/codex.yml` |

> **Tip:** Reuse the environment integrations listed in
> [`docs/producer_ai_integration.md`](./producer_ai_integration.md) so each agent
> shares the same authentication profile and prompt libraries.

## 2. Workstream Breakdown

### 2.1 Rust Core & Addon Microkernel

1. **Bootstrap crates**
   - Use `codex run scripts/prompts/rust/core_engine.prompt` to scaffold
     `codex-rs/producer_core` (microkernel) and `codex-rs/addons/*` (sandbox API).
   - Apply AGENTS.md conventions: inline `format!` args, collapse `if`, prefer
     method references.
2. **Audio pipeline**
   - Generate Demucs-equivalent stem separation harness via `scripts/prompts/rust/dsp_pipeline.prompt`.
   - Add WASM target tasks to `codex-rs/producer_core/Cargo.toml` (Codex CLI will
     inject `wasm32-unknown-unknown` configs).
3. **Addon SDK**
   - Create `sdk/rust-addon/` with hot-reload traits and permission manifest
     schema. Drive CLI agent with `scripts/prompts/rust/addon_sdk.prompt`.
4. **Quality gates**
   - After each feature, run `just fmt` and `just fix -p codex-producer-core` as
     mandated by repository instructions.

### 2.2 Quantum & Python Interop

1. Provision PyO3 bindings inside `codex-rs/quantum_bridge/` using Codex CLI
   prompt `scripts/prompts/rust/pyo3_bridge.prompt`.
2. Use MCP secret vault to hand Codex Web the necessary Python environment
   variables (`VIRTUAL_ENV`, `PYTHONPATH`).
3. Scaffold NumPy data transfer tests with Codex Web for broader coverage while
   the CLI focuses on compiling Rust artifacts locally.

### 2.3 Medical Cannabis Services

1. **FastAPI service**: With Codex Web, run `codex exec` against
   `scripts/prompts/python/prescription_api.prompt` to generate endpoints aligned
   with Australian compliance workflows.
2. **EHR connectors**: Task the CLI agent to produce gRPC clients inside
   `sdk/typescript/medical-ehr/` ensuring TypeScript strict mode.
3. **Compliance automation**: Attach MCP knowledge base `aus-health-regs` so
   Codex can cross-check Schedule 4/8 rules when drafting validation logic.

### 2.4 Frontend & Collaboration UX

1. Use Codex Web to parallelize React dashboard generation via Vite + Tailwind
   templates in `apps/producer-dashboard/`.
2. Configure shared component library `apps/ui-kit/` with Storybook stories and
   automated visual regression prompts.
3. Integrate WebSocket collaboration layer by directing Codex CLI at
   `scripts/prompts/typescript/realtime.prompt` once backend events exist.

### 2.5 Infrastructure & DevOps

1. **Terraform/IaC**: Employ Codex CLI prompts in `scripts/prompts/iac/*` to
   scaffold GPU inference clusters, storage buckets, and observability stacks.
2. **CI/CD**: Extend `.github/workflows/ci.yml` with Codex action jobs that run
   `cargo test`, `pnpm test`, and compliance linting.
3. **Monitoring**: Ask Codex Web to draft OpenTelemetry collector configs and
   Grafana dashboards stored under `infrastructure/observability/`.

## 3. Milestone Schedule

| Phase | Duration | Key Deliverables |
| --- | --- | --- |
| **Phase 1 – Foundation** | Weeks 1–2 | Microkernel crate, baseline REST API, addon manifest schema |
| **Phase 2 – Advanced Audio** | Weeks 3–5 | Real-time stem separation, WASM audio worklets, SIMD benchmarks |
| **Phase 3 – Healthcare Expansion** | Weeks 6–8 | Prescription workflows, EHR integrations, compliance automation |
| **Phase 4 – Ecosystem & Marketplace** | Weeks 9–12 | Addon marketplace MVP, quantum modules, CI/CD hardening |

Each phase should close with Codex-generated ADRs stored in
`docs/adr/producer_ai/` and benchmark snapshots under `benchmarks/audio/`.

## 4. Governance & Review Loops

- **Weekly planning**: Run Codex CLI stand-up prompt `scripts/prompts/ops/weekly_sync.prompt` to summarize progress and open issues.
- **Code review**: Enable Codex Action reviewers on PRs touching `codex-rs/**`
  and `apps/**`. Require green status checks from `just fix` and integration
  suites.
- **Security**: Schedule Codex Web audits monthly using
  `scripts/prompts/security/threat_model.prompt` to assess RBAC, OAuth, and data
  encryption coverage.

## 5. Success Metrics Dashboard

Track metrics in `docs/producer_ai_metrics.md` (to be generated) via automated
Codex Web jobs:

- Audio processing latency ≤ 5 ms for 48 kHz workloads.
- ≥ 95% test coverage for core Rust crates.
- Mean time to recovery < 30 minutes for infrastructure incidents.
- Compliance automation detects ≥ 99% invalid prescriptions in staging.

## 6. Next Steps

1. Duplicate the prompt templates referenced above (many are placeholders) into
   `scripts/prompts/` with concrete instructions for Codex agents.
2. Initialize new workspaces (`apps/`, `codex-rs/producer_core/`, etc.) following
   the repository’s contribution guide.
3. Open an ADR describing deviations from this playbook so future follow-up
   tasks can iterate collaboratively with Codex.

This document provides a cohesive blueprint for orchestrating Codex agents
across the entire Producer.ai + medical cannabis initiative while staying aligned
with repository tooling and AGENTS.md policies.
