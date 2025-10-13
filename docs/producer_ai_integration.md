# Producer.ai Codex Integration Strategy

This document operationalizes the Producer.ai-focused Codex integration plan. It aligns
Codex CLI, Codex Web, and local infrastructure across the Rust, Python, C++/ASM, and
TypeScript/React stack maintained in this repository.

## 1. Architecture Integration Overview

### 1.1 Environment Integration
- **VS Code, Cursor, Windsurf**: configure the Codex IDE extension and ensure it
  shares the same authentication profile as the CLI.
- **Terminal-first workflows**: install the Codex CLI globally and configure
  project-specific prompts in `AGENTS.md` files. Recommended aliases:
  - `alias cx="codex --config ./codex.toml"`
  - `alias cxr="codex run"` for scripted executions.
- **Context persistence**: use `codex exec` with prompt templates stored inside
  `scripts/prompts/` to keep long-running Rust/Python/DSP conversations coherent.

### 1.2 Orchestration Layer
- **Local CLI** handles low-latency development feedback loops, Git automation,
  and snapshot testing flows for `codex-rs`.
- **Codex Web** is reserved for parallel batch generation (e.g., scaffolding
  multiple React micro-frontends or DSP kernels). Use GitHub-issued tokens to
  push AI-generated branches and open PRs through the Codex automation features.
- **Review integration**: configure Codex to generate PR descriptions that follow
  this repository’s AGENTS.md conventions and automatically request reviewers for
  performance-sensitive modules (`codex-rs/core`, `codex-rs/common`).

### 1.3 Code Generation Engine Targets
- **Rust DSP**: generate SIMD-aware filters, lock-free ring buffers, and
  JUCE-compatible wrappers. Validate with `cargo bench` profiles and the
  audio-focused test harness below.
- **Python automation**: scaffold FastAPI endpoints, Producer.ai sample-library
  orchestration scripts, and Terraform IaC hooks for platform services.
- **React/TypeScript**: generate TypeScript-first components with Vite
  integration, ensuring `eslint` and `tsc` clean runs before commit.

## 2. Producer.ai Optimizations

### 2.1 DSP Workflow Enhancements
- Provide Codex with DSP-specific prompts describing sample rates (44.1–192 kHz)
  and latency budgets (<5 ms) to guide algorithm synthesis.
- Maintain a repository of FAUST snippets and conversion scripts in
  `codex-rs/dsp/faust/` to accelerate Rust/JUCE interoperability.
- Integrate JUCE-based UIs by pairing Rust DSP crates with generated C++
  components via cbindgen headers.

### 2.2 Plugin Development
- Scaffold VST3/AU projects using Codex-generated CMake presets and ensure they
  load the Rust DSP dynamic libraries with deterministic initialization order.
- Use Codex to draft parameter mappings, automation curves, and UI bindings,
  then validate thread safety with the provided checklists in §3.2.

### 2.3 Performance-Sensitive Code
- Adopt Codex-assisted SIMD reviews that compare intrinsics against reference
  scalar implementations.
- Add Codex prompts that insist on no heap allocations in audio callbacks and
  enforce lock-free data structures.
- Document accepted optimization patterns in `docs/dsp/optimization-patterns.md`.

## 3. CI/CD and DevOps Automation

### 3.1 Automated Code Review
- Configure Codex GitHub Action to run on pull requests touching
  `codex-rs/**`, `sdk/**`, or `codex-cli/**`.
- Enable AI suggestions for:
  - Performance regressions (using `cargo bench -- --baseline` comparisons).
  - Security scanning for Python/Terraform assets.
  - Adherence to AGENTS.md coding standards (Rust clippy hints, Stylize usage).

### 3.2 Performance Monitoring
- Extend CI with nightly audio benchmarks that emit latency and CPU usage
  metrics; Codex analyzes trends and comments when regressions exceed 5%.
- Store benchmark baselines in `benchmarks/audio/` with metadata consumed by
  Codex prompts to reason about acceptable thresholds.

### 3.3 Infrastructure as Code
- Use Codex templates for Terraform modules covering:
  - GPU-enabled inference clusters.
  - Artifact storage for rendered audio and presets.
  - Observability stacks (Prometheus, Grafana, OpenTelemetry collectors).
- Maintain IaC prompt libraries in `infrastructure/prompts/` so Codex can repeat
  deployments consistently.

## 4. Implementation Roadmap

### Phase 1: Foundation (Weeks 1–2)
1. Install Codex CLI, authenticate, and sync IDE integrations.
2. Standardize `AGENTS.md` templates across all packages (see Appendix A).
3. Establish prompt libraries for CLI and Web workflows.
4. Define benchmarking baselines and create the `benchmarks/audio/` directory.

### Phase 2: DSP Integration (Weeks 3–4)
1. Generate JUCE plugin skeletons and integrate with Rust DSP crates.
2. Implement FAUST-to-Rust conversion scripts and tests.
3. Add automated impulse/frequency-response regression tests.
4. Wire Codex prompts into DSP benchmarking workflows.

### Phase 3: Backend Automation (Weeks 5–6)
1. Scaffold FastAPI or Django services for Producer.ai metadata APIs.
2. Generate Terraform modules for deployment targets.
3. Automate CI pipelines for backend services (lint, test, deploy).
4. Integrate Codex review bots for backend pull requests.

### Phase 4: Advanced Automation (Weeks 7–8)
1. Create multi-language templates bundling Rust/Python/React components.
2. Enable Codex-driven performance coaching with continuous learning loops.
3. Expand Codex Web jobs for batch DSP code synthesis and plugin QA.
4. Measure success metrics weekly and refine prompts accordingly.

## 5. Success Metrics
- **Velocity**: target 40% faster feature delivery measured via cycle time.
- **Quality**: keep DSP regression failures below 5% per release.
- **Coverage**: maintain ≥90% automated test coverage for DSP crates.
- **Cost**: monitor Codex token usage per project and enforce budgets.

## Appendix A – AGENTS.md Template

```
# Producer.ai Audio Stack Guidelines

- Sample rates: support 44.1 kHz, 48 kHz, 88.2 kHz, 96 kHz, and 192 kHz.
- Latency budget: keep end-to-end processing under 5 ms.
- Audio callbacks must be allocation-free and avoid locks.
- Prefer SIMD optimizations; provide scalar fallbacks for testing.
- Validate with impulse, noise, and sweep tests; update snapshots when outputs
  change intentionally.
- Document new DSP blocks in docs/dsp/ with diagrams and benchmark numbers.
```

Embed this template (customized per package) to keep Codex-generated code aligned
with Producer.ai expectations.
