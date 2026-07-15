---
schema_version: "compozy.tasks/v2"
workflow: house-search-mvp
graph:
  nodes:
    - id: task_01
      file: task_01.md
    - id: task_02
      file: task_02.md
    - id: task_03
      file: task_03.md
    - id: task_04
      file: task_04.md
    - id: task_05
      file: task_05.md
    - id: task_06
      file: task_06.md
    - id: task_07
      file: task_07.md
  edges:
    - from: task_01
      to: task_02
    - from: task_01
      to: task_03
    - from: task_02
      to: task_04
    - from: task_03
      to: task_05
    - from: task_04
      to: task_05
    - from: task_05
      to: task_06
    - from: task_06
      to: task_07
---

# HouseSearch MVP Task List

Seven vertical slices implement the MVP in dependency order. Tasks 02 and 03 may proceed in parallel after the account boundary is established; the remaining slices converge through case lifecycle, recommendation behavior, AI, and durable orchestration.

## Tasks

1. `task_01.md` — Establish invite-only accounts and broker access
2. `task_02.md` — Build usage plans and immutable ledger
3. `task_03.md` — Deliver governed source ingestion and listing evidence
4. `task_04.md` — Implement request, criteria, and case lifecycle
5. `task_05.md` — Build ranking and broker-controlled recommendations
6. `task_06.md` — Add provider-neutral conversational AI
7. `task_07.md` — Orchestrate durable progressive research

