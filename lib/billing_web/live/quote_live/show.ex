defmodule BillingWeb.QuoteLive.Show do
  use BillingWeb, :live_view

  alias Billing.Quotes
  # alias Billing.InvoicingWorker
  alias Phoenix.PubSub
  alias Billing.InvoiceHandler
  alias Phoenix.LiveView.AsyncResult
  alias Billing.ElectronicInvoices
  alias BillingWeb.ElectronicInvoiceComponents

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <.header>
        Invoice {@quote.id}
        <:subtitle>This is a quote record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/quotes"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/quotes/#{@quote}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit quote
          </.button>

          <.sign_electronic_invoice_button sign_result={@sign_result} />
        </:actions>
      </.header>

      <.list>
        <:item title="Issued at">{@quote.issued_at}</:item>
        <:item title="Customer">{@quote.customer.full_name}</:item>
      </.list>

      <div class="divider"></div>

      <h2 class="font-semibold">
        Electronic Quotes
      </h2>

      <.table
        id="electronic_invoices"
        rows={@streams.electronic_invoices}
        row_click={
          fn {_id, electronic_invoice} ->
            JS.navigate(~p"/electronic_invoices/#{electronic_invoice}")
          end
        }
      >
        <:col :let={{_id, electronic_invoice}} label="Id">{electronic_invoice.id}</:col>
        <:col :let={{_id, electronic_invoice}} label="Access Key">
          {electronic_invoice.access_key}
        </:col>
        <:col :let={{_id, electronic_invoice}} label="State">
          <ElectronicInvoiceComponents.state electronic_invoice={electronic_invoice} />
        </:col>
      </.table>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    PubSub.subscribe(Billing.PubSub, "quote:#{id}")

    socket = assign(socket, :quote, Quotes.get_quote!(id))

    {:ok,
     socket
     |> assign(:page_title, "Show Invoice")
     |> assign(:sign_result, %AsyncResult{})
     |> assign_electronic_invoices()}
  end

  @impl true
  def handle_event("sign_electronic_invoice", _params, socket) do
    quote_id = socket.assigns.quote.id

    {:noreply,
     socket
     |> assign(:sign_result, AsyncResult.loading())
     |> start_async(:sign_electronic_invoice, fn ->
       InvoiceHandler.sign_electronic_invoice(quote_id)
     end)}
  end

  @impl true
  def handle_async(:sign_electronic_invoice, {:ok, {:ok, electronic_invoice}}, socket) do
    InvoiceHandler.start_send_worker(electronic_invoice)

    {:noreply,
     socket
     |> assign(:sign_result, AsyncResult.ok(electronic_invoice))
     |> assign_electronic_invoices()
     |> put_flash(:info, "Electronic quote signed")}
  end

  def handle_async(:sign_electronic_invoice, {:ok, {:error, error}}, socket) do
    {:noreply,
     socket
     |> assign(:sign_result, AsyncResult.failed(%AsyncResult{}, {:error, error}))
     |> assign_electronic_invoices()
     |> put_flash(:error, "Error: #{inspect(error)}")}
  end

  def handle_async(:sign_electronic_invoice, {:exit, reason}, socket) do
    {:noreply,
     socket
     |> assign(:sign_result, AsyncResult.failed(%AsyncResult{}, {:exit, reason}))
     |> assign_electronic_invoices()
     |> put_flash(:error, "Error: #{inspect(reason)}")}
  end

  @impl true
  def handle_info(
        {:electronic_invoice_updated, %{electronic_invoice_id: _electronic_invoice_id}},
        socket
      ) do
    {:noreply, assign_electronic_invoices(socket)}
  end

  @impl true
  def handle_info(
        {:electronic_invoice_error,
         %{electronic_invoice_id: _electronic_invoice_id, error: error}},
        socket
      ) do
    {:noreply,
     socket
     |> assign_electronic_invoices()
     |> put_flash(:error, "Error en la facturación: #{error}")}
  end

  attr :sign_result, AsyncResult, required: true

  defp sign_electronic_invoice_button(assigns) do
    ~H"""
    <.button variant="primary" phx-click="sign_electronic_invoice" disabled={@sign_result.loading}>
      <span :if={@sign_result.loading} class="loading loading-spinner loading-md"></span>
      <.icon :if={!@sign_result.loading} name="hero-finger-print" /> Sign electronic quote
    </.button>
    """
  end

  defp assign_electronic_invoices(socket) do
    stream(
      socket,
      :electronic_invoices,
      ElectronicInvoices.list_electronic_invoices_by_invoice_id(socket.assigns.quote.id)
    )
  end
end
