# Lifecycle and Context Boundaries

## Route-backed lifecycle

Register pages with `live/4` inside the appropriate existing scope or `live_session`. Use `mount/3` for one-time assign setup and connected-process setup. Use `handle_params/3` for state encoded in the URL and live navigation. Events validate payloads and call context APIs; they do not contain queries or persistence logic.

```elixir
defmodule HouseSearchWeb.PropertyLive.Index do
  use HouseSearchWeb, :live_view

  alias HouseSearch.Properties

  @impl true
  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user

    if connected?(socket), do: Properties.subscribe(current_user)

    {:ok,
     socket
     |> assign(:page_title, "Properties")
     |> assign(:properties, Properties.list_properties(current_user))}
  end

  @impl true
  def handle_event("archive", %{"id" => id}, socket) do
    case Properties.archive_property(socket.assigns.current_user, id) do
      {:ok, property} -> {:noreply, update_property(socket, property)}
      {:error, reason} -> {:noreply, put_flash(socket, :error, error_message(reason))}
    end
  end
end
```

## Context boundary

The web layer may pass scope/current-user data and plain parameters. The context authorizes, queries, preloads, changes, and broadcasts domain data. It returns explicit success/error results for the LiveView to render.

Forbidden in LiveViews and LiveComponents:

- `alias HouseSearch.Repo` or any `Repo.*` call, including `Repo.preload/2`.
- `Ecto.Query` composition for application data.
- Passing `%Phoenix.LiveView.Socket{}` to a context.
- Trusting client IDs without a scope-aware context lookup.

If the required context API does not exist, add the smallest domain function and test it at the context boundary.

## Callback responsibilities

- `mount/3`: stable initial assigns; subscriptions and process-only work behind `connected?/1`.
- `handle_params/3`: URL-driven filtering, pagination, selection, or mode.
- `handle_event/3`: UI input normalization, context call, socket response; cover success and failure.
- `handle_info/2`: PubSub and parent/component messages; validate message scope before assigning.
- `terminate/2`: not a reliability mechanism; processes can exit without it.

Do not perform writes or irreversible side effects in `mount/3`; disconnected and connected mounts both run.

## PubSub contract

Contexts own topic names and broadcast shapes through public subscribe/broadcast functions. Topics must be scoped narrowly enough to prevent cross-account/user leakage.

```elixir
if connected?(socket), do: Properties.subscribe(socket.assigns.current_user)

@impl true
def handle_info({:property_updated, property}, socket) do
  if Properties.visible_to?(socket.assigns.current_user, property) do
    {:noreply, update_property(socket, property)}
  else
    {:noreply, socket}
  end
end
```

Prefer message-driven synchronization in tests; never use `Process.sleep/1` to wait for PubSub.
