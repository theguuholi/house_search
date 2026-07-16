# LiveView 1.0 Hooks

## When a hook is justified

Use LiveView-native events, `Phoenix.LiveView.JS`, and server-rendered state first. Add a hook only for a browser API or third-party widget that HEEx and LiveView cannot express directly. JavaScript lifecycle automation is outside this package; this reference defines the server/DOM contract.

## Required contract

Every hook must have:

1. A unique, stable DOM `id` on the same element as `phx-hook`.
2. A named hook module registered in the `hooks:` option passed to `LiveSocket`.
3. Minimal DOM ownership: LiveView owns server-rendered DOM; the hook owns only its documented subtree or external instance.
4. Cleanup in `destroyed()` for listeners, observers, timers, subscriptions, and third-party instances created by the hook.
5. A documented event/payload contract. Hook-to-server events have `render_hook/3` coverage.

```javascript
// assets/js/hooks/property_map.js
export default {
  mounted() {
    this.onBoundsChanged = event => this.pushEvent("bounds_changed", event.detail)
    this.el.addEventListener("bounds-changed", this.onBoundsChanged)
  },

  destroyed() {
    this.el.removeEventListener("bounds-changed", this.onBoundsChanged)
  }
}
```

```javascript
import PropertyMap from "./hooks/property_map"

let liveSocket = new LiveSocket("/live", Socket, {
  hooks: {PropertyMap},
  params: {_csrf_token: csrfToken}
})
```

```heex
<section id="property-map" phx-hook="PropertyMap" aria-label="Property map">
  ...
</section>
```

Keep payloads small, explicit, and validated in `handle_event/3`. If a hook event belongs to a LiveComponent, target the component from the hooked element and test through that element.

`render_hook/3` exercises the server event contract only. It does not execute `mounted()`, `updated()`, or `destroyed()` and is not a JavaScript lifecycle test.

## DOM ownership

Do not let both LiveView and a third-party library rewrite the same nodes. Place widget-managed DOM under the smallest possible hook root and use the LiveView 1.0-supported boundary appropriate to the widget, commonly `phx-update="ignore"` on the widget-owned element. Keep status, labels, and actions server-rendered outside that ignored subtree when possible.

Do not add a JavaScript package or runner solely for these standards.
