# HEEx and Accessibility

## Semantic structure

Choose elements for meaning before styling:

- One page `<main>` and one descriptive `<h1>` reflecting `page_title`.
- `<nav>` for navigation, `<section>` with an accessible name for grouped content, `<article>` for standalone items.
- `<ul>`/`<ol>` and `<li>` for lists; real `<table>` structure for tabular data.
- `<button>` for actions; `<.link navigate={...}>` or `<.link patch={...}>` for navigation.
- `<label>`/`<fieldset>`/`<legend>` for form semantics and `<time datetime={...}>` for dates.

Generic `<div>`/`<span>` elements are acceptable for layout only when no semantic element fits.

## Accessible names and state

- Controls have a programmatic accessible name. Icon-only buttons require `aria-label`.
- Images require meaningful `alt`, or `alt=""` when decorative.
- Do not encode status with color alone; include text or a programmatic label.
- Preserve keyboard operation and visible focus.
- Use `aria-expanded`, `aria-controls`, `aria-current`, live regions, and dialog attributes when the interaction requires them.
- Stable IDs and meaningful ARIA/data attributes are valid DOM/test contracts; visible text is not required when copy is not the behavior under test.

## Forms and errors

Build forms with `to_form/2`, `<.form>`, and `<.input>` so labels, names, and errors follow CoreComponents. Set changeset action for validation feedback. Handle both success and error returns from context mutations.

```heex
<.form for={@form} id="search-form" phx-change="filter">
  <.input field={@form[:query]} type="search" label="Search properties" />
</.form>
```

Do not replace a form control with clickable generic markup. Do not manually duplicate validation errors already rendered by `<.input>`.

## Stable DOM contracts

Give IDs to forms, hook roots, stream containers, dialogs, and controls targeted by tests or accessibility relationships. Use deterministic domain IDs for repeated items. Selectors should express role/structure/state, not CSS utility classes or the entire rendered HTML.

## HEEx conventions

Use HEEx attribute interpolation and component attributes, not string-built HTML. Prefer tag-level `:if` and `:for` where they keep the structure clear. Keep branching/domain computation in `.ex` helpers or contexts; templates render already-shaped assigns.
