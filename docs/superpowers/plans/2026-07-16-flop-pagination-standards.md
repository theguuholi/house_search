# Flop Pagination Standards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace manual broker pagination with validated Flop queries, URL-driven LiveView state, reusable sortable table and pagination components, and durable project standards.

**Architecture:** `HouseSearch.Accounts.Invitation` defines the only allowed sort and page behavior through `Flop.Schema`; `HouseSearch.Accounts.list_brokers/1` owns friendly search plus validated query execution and returns rows with `Flop.Meta`. The broker LiveView treats URL parameters as state in `handle_params/3`, while `CoreComponents.table/1` and `pagination/1` remain stateless wrappers around Flop Phoenix.

**Tech Stack:** Elixir 1.14, Phoenix 1.7.24, LiveView 1.0.18, Ecto 3.10+, Flop 0.26.4, Flop Phoenix 0.26.1, ExUnit, Floki, Heroicons.

## Global Constraints

- Preserve the locked Phoenix 1.7.24 and LiveView 1.0.18 baseline; do not use LiveView 1.1-only APIs.
- Use page pagination only, with a default page size of 25 and maximum page size of 100.
- Expose sorting controls only for `name`, `email`, `status`, and `inserted_at`; allowlist `id` only as Flop's required deterministic tie-breaker.
- Default to `inserted_at desc`, `email asc`, then `id asc` for deterministic results.
- Keep the friendly public search parameter as `q`; do not emit duplicate nested Flop filter parameters.
- Contexts own Ecto queries and Flop execution; LiveViews and components never parse pagination values, calculate offsets, or call `Repo`.
- `mount/3` initializes stable state; `handle_params/3` is the sole URL-driven list loader.
- Extend the existing table component and add one stateless pagination component; do not add a parallel sortable-table component or JavaScript hooks.
- Implement production behavior test-first and capture focused RED evidence before each production change.

---

### Task 1: Flop Pagination Skill and Rule Contract

**Files:**
- Create: `.agents/skills/flop-pagination-standards/SKILL.md`
- Create: `.agents/skills/flop-pagination-standards/agents/openai.yaml`
- Create: `.agents/rules/flop-pagination.md`

**Interfaces:**
- Consumes: the approved design at `docs/superpowers/specs/2026-07-16-flop-pagination-standards-design.md`.
- Produces: the required `flop-pagination-standards` routing skill and concise project gate used by all later tasks.

- [ ] **Step 1: Run the skill RED baseline without exposing the new skill**

  Spawn a fresh subagent with only this pressure scenario and ask it to return a proposed implementation outline without editing files:

  ```text
  A Phoenix 1.7 / LiveView 1.0 application manually parses page and per_page,
  calculates offsets in a context, reloads a broker list from mount and events,
  and has a plain shared table. The team wants Flop sorting and pagination today.
  Propose the schema, context, LiveView, shared component, and test changes. Keep
  q as the public name/email search parameter. Delivery is urgent, existing
  behavior must not break, and the solution must be reusable across the app.
  ```

  Record whether the baseline omits any of: explicit schema allowlists, maximum page size, unique order tie-breaker, `replace_invalid_params: true`, context-owned `q` handling, `handle_params/3`, page reset on search, stateless components, query preservation, accessibility, or focused tests.

- [ ] **Step 2: Initialize the local skill with official tooling**

  Read `/Users/gustavooliveira/.codex/skills/.system/skill-creator/references/openai_yaml.md`, then run:

  ```bash
  /Users/gustavooliveira/.codex/skills/.system/skill-creator/scripts/init_skill.py flop-pagination-standards \
    --path .agents/skills \
    --interface display_name="Flop Pagination Standards" \
    --interface short_description="Apply HouseSearch Flop list standards" \
    --interface default_prompt="Use $flop-pagination-standards to design or change a HouseSearch filtered, sorted, or paginated list."
  ```

  Expected: the skill directory contains `SKILL.md` and `agents/openai.yaml` with no extra resource directories.

- [ ] **Step 3: Replace the generated skill with the minimal standards workflow**

  The skill must use this contract:

  ```markdown
  ---
  name: flop-pagination-standards
  description: Use when creating or materially changing HouseSearch Flop schemas, filtered or sorted context lists, URL-driven pagination, sortable tables, pagination components, or their tests.
  ---

  # Flop Pagination Standards

  ## Core contract

  Treat the URL as list state, the context as query owner, the schema as the
  allowlist, and shared function components as stateless renderers.

  ## Required workflow

  1. Read `.agents/rules/flop-pagination.md` and the applicable Ecto, LiveView,
     and LiveView testing standards.
  2. Derive `Flop.Schema` with explicit `filterable`, `sortable`, pagination,
     limit, and deterministic default-order options.
  3. Accept URL parameter maps at the context boundary. Apply friendly domain
     filters such as `q` to the base query, remove them before Flop validation,
     and call `Flop.validate_and_run/3` with `for: Schema`, the project Repo,
     and `replace_invalid_params: true`.
  4. Load route-backed list state only in `handle_params/3`; patch the URL for
     search, sort, and pagination and remove `page` when search changes.
  5. Render through the shared stateless table and pagination components.
  6. Add focused context, component, and LiveView RED/GREEN coverage.

  ## Quick reference

  | Layer | Owns | Must not own |
  |---|---|---|
  | Schema | allowlists, limits, pagination type, stable default order | public URL parsing |
  | Context | friendly filters, validation, query, Repo execution | socket state |
  | LiveView | URL patching, forms, assigns, mutations | Ecto queries or offsets |
  | Component | links, icons, semantic and ARIA markup | fetching, parsing, events |

  ## Common mistakes

  - Do not derive Flop with broad field lists or convert client strings to atoms.
  - Do not keep `q` in Flop params when the public contract is a friendly filter.
  - Do not load URL state in `mount/3` or reload lists directly from events.
  - Do not make sorting or pagination stateful components.
  - Do not omit a unique final order field when preceding fields can tie.
  - Do not expose interactive disabled controls or icon-only sort state.

  ## Completion gate

  Confirm invalid inputs fall back safely, links preserve unrelated query
  parameters, search resets the page, shared components remain plain-table
  compatible, and focused plus project verification passes.
  ```

- [ ] **Step 4: Add the concise project rule**

  `.agents/rules/flop-pagination.md` must state the same enforceable gates without duplicating explanatory material: explicit schema allowlists and limits; deterministic order; context-owned `q` and `Flop.validate_and_run/3`; URL state in `handle_params/3`; stateless accessible shared components; RED/GREEN context, component, and route tests.

- [ ] **Step 5: Validate and run the skill GREEN scenario**

  Run:

  ```bash
  /Users/gustavooliveira/.codex/skills/.system/skill-creator/scripts/quick_validate.py .agents/skills/flop-pagination-standards
  ```

  Expected: `Skill is valid!`

  Spawn a fresh subagent with the same scenario from Step 1 plus:

  ```text
  Use $flop-pagination-standards at
  .agents/skills/flop-pagination-standards to solve this request.
  ```

  Expected: the response includes every contract item omitted by the baseline. If it finds a new loophole, tighten the smallest relevant section and rerun validation and the scenario.

- [ ] **Step 6: Commit the verified skill and rule**

  ```bash
  git add .agents/skills/flop-pagination-standards .agents/rules/flop-pagination.md
  git commit -m "docs: add Flop pagination standards"
  ```

---

### Task 2: Flop Dependencies, Schema Contract, and Broker Context Query

**Files:**
- Modify: `mix.exs`
- Modify: `mix.lock`
- Modify: `lib/house_search/accounts/invitation.ex`
- Modify: `lib/house_search/accounts.ex`
- Modify: `test/house_search/accounts/invitation_test.exs`
- Create: `test/house_search/accounts/broker_listing_test.exs`

**Interfaces:**
- Consumes: `Flop.Schema`, `Flop.validate_and_run/3`, `HouseSearch.Repo`.
- Produces: `Accounts.list_brokers(params :: map()) :: {[Invitation.t()], Flop.Meta.t()}`.

- [ ] **Step 1: Add dependency declarations and fetch them**

  Add to `deps/0`:

  ```elixir
  {:flop, "~> 0.26.4"},
  {:flop_phoenix, "~> 0.26.1"},
  ```

  Run `mix deps.get` and `mix compile --warnings-as-errors`.
  Expected: dependencies resolve with Elixir 1.14, Phoenix 1.7, LiveView 1.0, and Ecto 3.10+.

- [ ] **Step 2: Write schema-contract and context RED tests**

  Extend `invitation_test.exs` with direct protocol assertions:

  ```elixir
  test "Flop schema exposes only approved broker list behavior" do
    assert Flop.Schema.filterable(%Invitation{}) == []
    assert Flop.Schema.sortable(%Invitation{}) == [:name, :email, :status, :inserted_at, :id]
    assert Flop.Schema.default_limit(%Invitation{}) == 25
    assert Flop.Schema.max_limit(%Invitation{}) == 100
    assert Flop.Schema.pagination_types(%Invitation{}) == [:page]
    assert Flop.Schema.default_pagination_type(%Invitation{}) == :page
    assert Flop.Schema.default_order(%Invitation{}) == %{
             order_by: [:inserted_at, :email, :id],
             order_directions: [:desc, :asc, :asc]
           }
  end
  ```

  In `broker_listing_test.exs`, create invitations through `invitation_fixture/1` and cover separate tests for: 25-row defaults and metadata; `page_size=100` maximum with oversized values falling back safely; stable default order; `q` matching name or email; approved ascending/descending order; requested page contents and metadata; invalid `page`, `page_size`, `order_by`, and `order_directions` falling back without raising.

- [ ] **Step 3: Run focused tests and capture correct RED evidence**

  Run:

  ```bash
  mix test test/house_search/accounts/invitation_test.exs test/house_search/accounts/broker_listing_test.exs
  ```

  Expected: assertions fail because `Invitation` does not implement `Flop.Schema` and `list_brokers/1` does not return `{rows, meta}` from URL maps. Fix only test setup errors until these are the failures.

- [ ] **Step 4: Derive the explicit schema contract**

  Place before `schema "invitations"`:

  ```elixir
  @derive {
    Flop.Schema,
    filterable: [],
    sortable: [:name, :email, :status, :inserted_at, :id],
    default_limit: 25,
    max_limit: 100,
    pagination_types: [:page],
    default_pagination_type: :page,
    default_order: %{
      order_by: [:inserted_at, :email, :id],
      order_directions: [:desc, :asc, :asc]
    }
  }
  ```

- [ ] **Step 5: Replace manual parsing with validated Flop execution**

  Implement this boundary in `Accounts`:

  ```elixir
  @spec list_brokers(map()) :: {[Invitation.t()], Flop.Meta.t()}
  def list_brokers(params \\ %{}) when is_map(params) do
    {q, flop_params} = Map.pop(params, "q", "")

    query = from invitation in Invitation
    query = search_brokers(query, q)

    {:ok, result} =
      Flop.validate_and_run(query, flop_params,
        for: Invitation,
        repo: Repo,
        replace_invalid_params: true
      )

    result
  end

  defp search_brokers(query, q) when is_binary(q) do
    case String.trim(q) do
      "" -> query
      q ->
        term = "%#{q}%"
        where(query, [invitation], ilike(invitation.email, ^term) or ilike(invitation.name, ^term))
    end
  end

  defp search_brokers(query, _q), do: query
  ```

- [ ] **Step 6: Run focused GREEN tests and format**

  Run:

  ```bash
  mix test test/house_search/accounts/invitation_test.exs test/house_search/accounts/broker_listing_test.exs
  mix format mix.exs lib/house_search/accounts.ex lib/house_search/accounts/invitation.ex test/house_search/accounts/invitation_test.exs test/house_search/accounts/broker_listing_test.exs
  ```

  Expected: all focused tests pass and formatted files remain green on rerun.

- [ ] **Step 7: Commit the context slice**

  ```bash
  git add mix.exs mix.lock lib/house_search/accounts.ex lib/house_search/accounts/invitation.ex test/house_search/accounts/invitation_test.exs test/house_search/accounts/broker_listing_test.exs
  git commit -m "feat: paginate broker queries with Flop"
  ```

---

### Task 3: Reusable Sortable Table and Pagination Components

**Files:**
- Modify: `lib/house_search_web/components/core_components.ex`
- Create: `test/house_search_web/components/core_components_test.exs`

**Interfaces:**
- Consumes: `rows`, optional `Flop.Meta`, a verified `path`, sortable column `field`, and optional pagination `target`.
- Produces: backward-compatible `table/1` and stateless `pagination/1` function components.

- [ ] **Step 1: Write component RED tests**

  Use `render_component/2` and Floki to prove independently:

  - `table/1` still renders a plain header and rows with only `id`, `rows`, and columns.
  - A sortable column renders a patch link whose `href` preserves `q` and whose accessible label names the field and next direction.
  - Active ascending and descending columns expose `aria-sort` and the matching Heroicon class; unsorted sortable columns use the unsorted Heroicon.
  - `pagination/1` renders a labeled `nav`, `aria-current="page"`, previous/next/page/ellipsis states, and non-interactive disabled controls.
  - Pagination URLs preserve `q`, current order fields, and directions.

- [ ] **Step 2: Run component tests and capture RED**

  Run `mix test test/house_search_web/components/core_components_test.exs`.
  Expected: failures show `table/1` lacks `meta`, `path`, and `field`, and `pagination/1` is undefined; plain-table coverage should already pass.

- [ ] **Step 3: Delegate sortable rendering to Flop Phoenix while preserving the table API**

  Add optional table attrs and column field:

  ```elixir
  attr :meta, Flop.Meta, default: nil
  attr :path, :any, default: nil

  slot :col, required: true do
    attr :label, :string
    attr :field, :atom
  end
  ```

  Keep the current plain-table branch for `nil` metadata/path. For the sortable branch, call `Flop.Phoenix.table/1` with the existing row slots and styling options. Pass Heroicon HEEx fragments as `symbol_asc`, `symbol_desc`, and `symbol_unsorted`, retain the existing `id`, row IDs/click/item mapping, table semantics, and action slot, and add `aria-sort`/accessible link text if Flop Phoenix does not emit them itself.

- [ ] **Step 4: Add the stateless pagination wrapper**

  Define attrs:

  ```elixir
  attr :meta, Flop.Meta, required: true
  attr :path, :any, required: true
  attr :label, :string, default: "Pagination"
  attr :target, :any, default: nil
  ```

  Render a semantic `<nav aria-label={@label}>` and delegate state/link generation to `Flop.Phoenix.pagination/1`, passing application Tailwind classes and `target`. Ensure disabled previous/next output is not a link and current page carries `aria-current="page"`.

- [ ] **Step 5: Run component GREEN tests and existing component callers**

  Run:

  ```bash
  mix test test/house_search_web/components/core_components_test.exs
  mix test test/house_search_web
  mix format lib/house_search_web/components/core_components.ex test/house_search_web/components/core_components_test.exs
  ```

  Expected: focused component tests and existing web tests pass.

- [ ] **Step 6: Commit the reusable components**

  ```bash
  git add lib/house_search_web/components/core_components.ex test/house_search_web/components/core_components_test.exs
  git commit -m "feat: add sortable table pagination components"
  ```

---

### Task 4: URL-Driven Broker LiveView Reference Implementation

**Files:**
- Modify: `lib/house_search_web/live/admin/broker_live/index.ex`
- Modify: `lib/house_search_web/live/admin/broker_live/index.html.heex`
- Modify: `test/house_search_web/live/admin/broker_live/index_test.exs`

**Interfaces:**
- Consumes: `Accounts.list_brokers/1`, `CoreComponents.table/1`, `CoreComponents.pagination/1`.
- Produces: route-reproducible search, sort, and page state loaded only through `handle_params/3`.

- [ ] **Step 1: Expand route-level RED coverage**

  Add focused tests that mount through `~p"/admin/brokers"` and prove:

  - Initial `q`, `page`, `page_size`, `order_by`, and `order_directions` parameters select and order visible rows.
  - Submitting `#search_form` trims `q`, patches to a URL without `page`, and displays filtered rows.
  - Sort header clicks patch the URL and reorder rows.
  - Pagination link clicks patch the URL and display the requested page.
  - A direct `live(conn, patched_path)` reproduces the same list state.
  - Successful invite and revoke retain `q` and ordering in the current patched URL and visible list.
  - Unauthorized users render neither `#invitations` nor pagination metadata, including when hostile list params are supplied.

- [ ] **Step 2: Run the LiveView test and capture RED**

  Run `mix test test/house_search_web/live/admin/broker_live/index_test.exs`.
  Expected: URL patch, sort links, pagination links, and preserved-state assertions fail because mount/events currently load lists directly.

- [ ] **Step 3: Move all list loading into `handle_params/3`**

  Refactor callbacks to this shape:

  ```elixir
  @impl true
  def mount(_params, _session, socket) do
    admin? = match?(%User{system_role: :admin, status: :active}, socket.assigns.current_user)

    {:ok,
     assign(socket,
       admin?: admin?,
       form: to_form(%{}, as: "invitation"),
       search_form: to_form(%{"q" => ""}, as: "search"),
       invitations: [],
       meta: nil,
       list_path: ~p"/admin/brokers"
     )}
  end

  @impl true
  def handle_params(params, _uri, %{assigns: %{admin?: true}} = socket) do
    {invitations, meta} = Accounts.list_brokers(params)
    q = params |> Map.get("q", "") |> normalize_q()

    {:noreply,
     assign(socket,
       invitations: invitations,
       meta: meta,
       search_form: to_form(%{"q" => q}, as: "search"),
       list_path: ~p"/admin/brokers?#{[q: blank_to_nil(q)]}"
     )}
  end

  def handle_params(_params, _uri, socket), do: {:noreply, socket}
  ```

  Implement `normalize_q/1` as trim-for-binaries with an empty fallback. Build the verified path so blank `q` is omitted rather than serialized as an empty value.

- [ ] **Step 4: Patch URLs from events and route mutation refreshes through parameters**

  Replace the search event with:

  ```elixir
  def handle_event("search", %{"search" => %{"q" => q}}, socket) do
    q = normalize_q(q)
    {:noreply, push_patch(socket, to: ~p"/admin/brokers?#{[q: blank_to_nil(q)]}")}
  end
  ```

  On successful invite/revoke, clear the invite form, put the flash, then call `push_patch(socket, to: socket.assigns.list_path)` so `handle_params/3` remains the only reload path. Preserve sort/page parameters by storing the current URI-derived path or by rebuilding it from `meta.flop` plus `q`; do not call `Accounts.list_brokers/1` inside events.

- [ ] **Step 5: Wire reusable components in HEEx**

  Use:

  ```heex
  <.table id="invitations" rows={@invitations} meta={@meta} path={@list_path}>
    <:col :let={invitation} label="Broker" field={:name}>{invitation.name}</:col>
    <:col :let={invitation} label="Email" field={:email}>{invitation.email}</:col>
    <:col :let={invitation} label="Status" field={:status}>{invitation.status}</:col>
    <:action :let={invitation}>
      <.button phx-click="revoke" phx-value-id={invitation.id}>Revoke</.button>
    </:action>
  </.table>

  <.pagination :if={@meta && @meta.total_pages > 1} meta={@meta} path={@list_path} label="Broker invitations pages" />
  ```

  Keep the existing empty state and admin authorization boundary.

- [ ] **Step 6: Run focused and related GREEN tests**

  Run:

  ```bash
  mix test test/house_search_web/live/admin/broker_live/index_test.exs
  mix test test/house_search/accounts/broker_listing_test.exs test/house_search_web/components/core_components_test.exs test/house_search_web/live/admin/broker_live/index_test.exs
  mix format lib/house_search_web/live/admin/broker_live/index.ex lib/house_search_web/live/admin/broker_live/index.html.heex test/house_search_web/live/admin/broker_live/index_test.exs
  ```

  Expected: all broker context, component, and route tests pass.

- [ ] **Step 7: Commit the reference LiveView**

  ```bash
  git add lib/house_search_web/live/admin/broker_live/index.ex lib/house_search_web/live/admin/broker_live/index.html.heex test/house_search_web/live/admin/broker_live/index_test.exs
  git commit -m "refactor: drive broker lists from URL params"
  ```

---

### Task 5: Standards Routing and Cross-References

**Files:**
- Modify: `AGENTS.md`
- Modify: `.agents/rules/liveview.md`
- Modify: `.agents/rules/liveview-tests.md`
- Modify: `.agents/rules/ecto-schema.md`
- Modify: `.agents/skills/phoenix-liveview-standards/SKILL.md`
- Modify: `.agents/skills/liveview-testing-standards/SKILL.md`
- Modify: `.agents/skills/ecto-schema-standards/SKILL.md`

**Interfaces:**
- Consumes: `.agents/rules/flop-pagination.md` and `flop-pagination-standards`.
- Produces: discoverable routing without copying the full Flop standard into adjacent documents.

- [ ] **Step 1: Run a routing baseline before editing existing skills**

  Spawn a fresh subagent with: `Which HouseSearch skills and rules must be read before changing a paginated sortable LiveView backed by an Ecto schema?` Do not mention the new skill. Record whether it discovers `flop-pagination-standards`; this is the RED result for cross-reference edits.

- [ ] **Step 2: Add concise routing references**

  - Add `.agents/rules/flop-pagination.md` under Local Rules in `AGENTS.md`.
  - Add a routing row: `Flop schema, filtered/sorted list, pagination, or sortable table | flop-pagination-standards`.
  - Add the new skill path under Local Skills.
  - Add one sentence/link in each touched rule and skill: when Flop, URL list filtering, sorting, or pagination is involved, `flop-pagination-standards` and `.agents/rules/flop-pagination.md` are also required.
  - Do not duplicate the Flop workflow, option lists, or examples in these files.

- [ ] **Step 3: Validate changed skills and rerun routing GREEN**

  Run `quick_validate.py` for all four changed/local skills. Repeat the Step 1 subagent question with the updated repository. Expected: it identifies the Flop skill plus LiveView, testing, and Ecto standards.

- [ ] **Step 4: Commit standards routing**

  ```bash
  git add AGENTS.md .agents/rules/liveview.md .agents/rules/liveview-tests.md .agents/rules/ecto-schema.md .agents/skills/phoenix-liveview-standards/SKILL.md .agents/skills/liveview-testing-standards/SKILL.md .agents/skills/ecto-schema-standards/SKILL.md
  git commit -m "docs: route Flop list changes through standards"
  ```

---

### Task 6: Standards Review and Final Verification

**Files:**
- Review: all files changed since commit `5b6f160`

**Interfaces:**
- Consumes: completed implementation and standards contract.
- Produces: fresh evidence that the implementation is formatted, tested, version-compatible, and ready to hand off.

- [ ] **Step 1: Review the complete diff against the approved design**

  Run `git diff 5b6f160...HEAD` and check every design section: dependencies, schema, context, URL flow, stateless table, pagination, standards package, tests, and out-of-scope limits. Confirm there is no manual `parse_int`, `limit`, or `offset` logic in `list_brokers/1`, no list load outside `handle_params/3`, and no duplicated sortable-table component.

- [ ] **Step 2: Run the project’s diff-scoped LiveView reviewer**

  Use `.codex/agents/house-search-liveview-reviewer.toml` read-only against the diff. Fix actionable findings test-first when behavior changes; rerun focused tests after every fix.

- [ ] **Step 3: Run fresh verification under `cy-final-verify`**

  Run in order:

  ```bash
  mix test test/house_search/accounts/invitation_test.exs test/house_search/accounts/broker_listing_test.exs test/house_search_web/components/core_components_test.exs test/house_search_web/live/admin/broker_live/index_test.exs
  mix format --check-formatted
  mix precommit
  ```

  Expected: zero failures, zero formatting differences, and successful compile, dependency, Credo, Sobelow, Dialyzer, and coverage checks.

- [ ] **Step 4: Commit any verification-only fixes**

  If verification required changes, stage only those understood files and commit with a narrow conventional message. If no changes were required, do not create an empty commit.

- [ ] **Step 5: Report the completed behavior and evidence**

  Summarize the context return contract, URL-driven LiveView flow, shared component API, standards routing, focused test results, and `mix precommit` result. Link the design and implementation plan and note any unrelated pre-existing failures separately.
