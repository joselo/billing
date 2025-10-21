defmodule BillingWeb.Router do
  use BillingWeb, :router

  import BillingWeb.UserAuth

  alias BillingWeb.Plugs.CartPlug
  alias BillingWeb.LiveSessions.CartSession

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {BillingWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
    plug CartPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BillingWeb do
    pipe_through :browser

    live_session :init_assings, on_mount: [{CartSession, :mount_session}] do
      live "/", CatalogLive.Index, :index
      live "/cart", CartLive.Index, :index
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", BillingWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:billing, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: BillingWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", BillingWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{BillingWeb.UserAuth, :require_authenticated}] do
      live "/users/settings", UserLive.Settings, :edit
      live "/users/settings/confirm-email/:token", UserLive.Settings, :confirm_email

      live "/customers", CustomerLive.Index, :index
      live "/customers/new", CustomerLive.Form, :new
      live "/customers/:id", CustomerLive.Show, :show
      live "/customers/:id/edit", CustomerLive.Form, :edit

      live "/invoices", InvoiceLive.Index, :index
      live "/invoices/new/:order_id", InvoiceLive.Form, :new
      live "/invoices/new", InvoiceLive.Form, :new
      live "/invoices/:id", InvoiceLive.Show, :show
      live "/invoices/:id/edit", InvoiceLive.Form, :edit

      live "/certificates", CertificateLive.Index, :index
      live "/certificates/new", CertificateLive.Form, :new
      live "/certificates/:id", CertificateLive.Show, :show
      live "/certificates/:id/edit", CertificateLive.Form, :edit

      live "/companies", CompanyLive.Index, :index
      live "/companies/new", CompanyLive.Form, :new
      live "/companies/:id", CompanyLive.Show, :show
      live "/companies/:id/edit", CompanyLive.Form, :edit

      live "/emission_profiles", EmissionProfileLive.Index, :index
      live "/emission_profiles/new", EmissionProfileLive.Form, :new
      live "/emission_profiles/:id", EmissionProfileLive.Show, :show
      live "/emission_profiles/:id/edit", EmissionProfileLive.Form, :edit

      get "/electronic_invoice/:id/pdf", ElectronicInvoiceController, :pdf
      get "/electronic_invoice/:id/xml", ElectronicInvoiceController, :xml

      live "/products", ProductLive.Index, :index
      live "/products/new", ProductLive.Form, :new
      live "/products/:id", ProductLive.Show, :show
      live "/products/:id/edit", ProductLive.Form, :edit

      live "/agent_chat", AgentChatLive.Index, :index

      live "/orders", OrderLive.Index, :index
      live "/orders/:id", OrderLive.Show, :show
    end

    post "/users/update-password", UserSessionController, :update_password
  end

  scope "/", BillingWeb do
    pipe_through [:browser]

    live_session :current_user,
      on_mount: [{BillingWeb.UserAuth, :mount_current_scope}] do
      live "/users/register", UserLive.Registration, :new
      live "/users/log-in", UserLive.Login, :new
      live "/users/log-in/:token", UserLive.Confirmation, :new
    end

    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
