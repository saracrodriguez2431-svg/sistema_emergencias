# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

import Config

config :web,
  generators: [timestamp_type: :utc_datetime]

# Configure the endpoint
config :web, WebWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: WebWeb.ErrorHTML, json: WebWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Web.PubSub,
  live_view: [signing_salt: "H2N/8uRp"]

# Configure LiveView
config :phoenix_live_view,
  root_tag_attribute: "phx-r"

# Configure the mailer
config :web, Web.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild
config :esbuild,
  version: "0.25.4",
  web: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind
config :tailwind,
  version: "4.3.3",
  web: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
import_config "#{config_env()}.exs"
