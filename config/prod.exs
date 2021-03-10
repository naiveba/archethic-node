import Config

# Do not print debug messages in production
config :logger, level: :info

config :uniris, :mut_dir, System.get_env("UNIRIS_MUT_DIR", "/opt/data")

config :uniris, Uniris.Bootstrap.Sync,
  # 15 days
  out_of_sync_date_threshold: 54_000

# TODO: provide the true addresses for the genesis UCO distribution
# config :uniris, Uniris.Bootstrap.NetworkInit, genesis_pools: []

config :uniris, Uniris.BeaconChain.SlotTimer,
  # Every 10 minutes at the 50th second
  interval: "50 */10 * * * * *"

config :uniris, Uniris.BeaconChain.SummaryTimer,
  # Every day at midnight at the 50th second
  interval: "50 0 0 * * * *"

# TODO: specify the crypto implementation using hardware when developed
config :uniris, Uniris.Crypto.Keystore, impl: Uniris.Crypto.SoftwareKeystore

config :uniris, Uniris.DB, impl: Uniris.DB.CassandraImpl

config :uniris, Uniris.DB.KeyValueImpl, root_dir: "priv/storage"

config :uniris, Uniris.Governance.Pools,
  # TODO: provide the true addresses of the members
  initial_members: [
    technical_council: [],
    ethical_council: [],
    foundation: [],
    uniris: []
  ]

config :uniris, Uniris.Networking.IPLookup, impl: Uniris.Networking.IPLookup.NAT

config :uniris, Uniris.OracleChain.Scheduler,
  # Poll new changes every minute
  polling_interval: "0 * * * * *",
  # Aggregate chain every day at midnight
  summary_interval: "0 0 0 * * *"

config :uniris, Uniris.SharedSecrets.NodeRenewalScheduler,
  # Every day at midnight at the 50th second
  interval: "50 0 0 * * * *"

config :uniris, Uniris.SelfRepair.Sync, last_sync_file: "priv/p2p/last_sync"

config :uniris, Uniris.SelfRepair.Sync.BeaconSummaryHandler.NetworkStatistics,
  dump_dir: "priv/p2p/network_stats"

config :uniris, Uniris.SelfRepair.Scheduler,
  # Every day at midnight
  interval: "0 0 0 * * * *"

config :uniris, Uniris.P2P.Endpoint,
  port: System.get_env("UNIRIS_P2P_PORT", "3002") |> String.to_integer()

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
config :uniris, UnirisWeb.Endpoint,
  http: [:inet6, port: System.get_env("UNIRIS_HTTP_PORT", "80") |> String.to_integer()],
  url: [host: "*", port: 443],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  root: ".",
  version: Application.spec(:uniris, :vsn),
  check_origin: false,
  https: [
    port: 443,
    cipher_suite: :strong,
    keyfile: System.get_env("UNIRIS_WEB_SSL_KEY_PATH"),
    certfile: System.get_env("UNIRIS_WEB_SSL_CERT_PATH"),
    transport_options: [socket_opts: [:inet6]]
  ]

# force_ssl: [hsts: true]
