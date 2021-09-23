import Config

# Do not print debug messages in production
config :logger, level: System.get_env("ARCHETHIC_LOGGER_LEVEL", "info") |> String.to_atom()

config :archethic, :mut_dir, System.get_env("ARCHETHIC_MUT_DIR", "data")

config :archethic, ArchEthic.Bootstrap,
  reward_address: System.get_env("ARCHETHIC_REWARD_ADDRESS", "") |> Base.decode16!(case: :mixed)

config :archethic, ArchEthic.Bootstrap.NetworkInit,
  genesis_pools:
    [
      %{
        address:
          Base.decode16!("002CA95C90A4D75DEEC973D251F5B59CD8EBC787FEC265B9CAC1F6C56A8D9BFCCA",
            case: :mixed
          ),
        amount: 3.82e9
      },
      %{
        address:
          Base.decode16!("00AD6EEC49FED0A936FEF4BD3301FF933FFFE9BA63BE2F6E948DFEC4C2D4543917",
            case: :mixed
          ),
        amount: 2.36e9
      },
      %{
        address:
          Base.decode16!("00D23C33B9B75A272B1E8BCA6F252179A144E0A66A396CCF989C4A6D353CFF3849",
            case: :mixed
          ),
        amount: 9.0e8
      },
      %{
        address:
          Base.decode16!("006FDE9B6EDF98E682561634B814A5FA2127B327D50AF38428AB06B447A4CF8345",
            case: :mixed
          ),
        amount: 5.6e8
      },
      %{
        address:
          Base.decode16!("000F1DFC550CB0492C7BEA2DCFABC6F2E2378A5D1D8AA8B5058FC2F30B62DD5DDC",
            case: :mixed
          ),
        amount: 3.4e8
      },
      %{
        address:
          Base.decode16!("006098E77BA4C675DA94F57091E73797BF2E11B3FAB20867101AB20FBE21ED862A",
            case: :mixed
          ),
        amount: 3.4e8
      },
      %{
        address:
          Base.decode16!("009BD34BB544A9A71536806E52E9E9F4F41FF81751848FD0B1E0E465D2FB95C36C",
            case: :mixed
          ),
        amount: 2.2e8
      },
      if(System.get_env("ARCHETHIC_NETWORK_TYPE") == "testnet",
        do: %{
          address:
            "00EC64107CA604A6B954037CFA91ED18315A77A94FBAFD91275CEE07FA45EAF893"
            |> Base.decode16!(case: :mixed),
          amount: 1.0e7
        }
      )
    ]
    |> Enum.filter(& &1)

config :archethic, ArchEthic.Bootstrap.Sync,
  # 15 days
  out_of_sync_date_threshold:
    System.get_env("ARCHETHIC_BOOTSTRAP_OUT_OF_SYNC_THRESHOLD", "54000") |> String.to_integer()

# TODO: provide the true addresses for the genesis UCO distribution
# config :archethic, ArchEthic.Bootstrap.NetworkInit, genesis_pools: []

config :archethic, ArchEthic.BeaconChain.SlotTimer,
  # Every 10 minutes
  interval: System.get_env("ARCHETHIC_BEACON_CHAIN_SLOT_TIMER_INTERVAL", "0 */10 * * * * *")

config :archethic, ArchEthic.BeaconChain.SummaryTimer,
  # Every day at midnight
  interval: System.get_env("ARCHETHIC_BEACON_CHAIN_SUMMARY_TIMER_INTERVAL", "0 0 0 * * * *")

config :archethic, ArchEthic.Crypto,
  root_ca_public_keys: [
    tpm:
      System.get_env(
        "ARCHETHIC_CRYPTO_ROOT_CA_TPM_PUBKEY",
        "3059301306072a8648ce3d020106082a8648ce3d03010703420004f0fe701a03ce375a6e57adbe0255808812036571c1424db2779c77e8b4a9ba80a15b118e8e7465ee2e94094e59c4b3f7177e99063af1b19bfcc4d7e1ac3f89dd"
      )
      |> Base.decode16!(case: :mixed)
  ],
  key_certificates_dir: System.get_env("ARCHETHIC_CRYPTO_CERT_DIR", "~/aebot/key_certificates")

config :archethic,
       ArchEthic.Crypto.NodeKeystore,
       (case(System.get_env("ARCHETHIC_CRYPTO_NODE_KEYSTORE_IMPL", "TPM")) do
          "TPM" ->
            ArchEthic.Crypto.NodeKeystore.TPMImpl

          "SOFTWARE" ->
            ArchEthic.Crypto.NodeKeystore.SoftwareImpl
        end)

# TODO: to remove when the implementation will be detected
config :archethic,
       ArchEthic.Crypto.SharedSecretsKeystore,
       ArchEthic.Crypto.SharedSecretsKeystore.SoftwareImpl

config :archethic, ArchEthic.DB.CassandraImpl,
  host: System.get_env("ARCHETHIC_DB_HOST", "127.0.0.1:9042")

config :archethic, ArchEthic.Governance.Pools,
  # TODO: provide the true addresses of the members
  initial_members: [
    technical_council: [],
    ethical_council: [],
    foundation: [],
    uniris: []
  ]

config :archethic,
       ArchEthic.Networking.IPLookup,
       (case(System.get_env("ARCHETHIC_NETWORKING_IMPL", "NAT")) do
          "NAT" ->
            ArchEthic.Networking.IPLookup.NAT

          "STATIC" ->
            ArchEthic.Networking.IPLookup.Static

          "IPFY" ->
            ArchEthic.Networking.IPLookup.IPIFY
        end)

config :archethic, ArchEthic.Networking.PortForwarding,
  enabled:
    (case(System.get_env("ARCHETHIC_NETWORKING_PORT_FORWARDING", "true")) do
       "true" ->
         true

       _ ->
         false
     end)

config :archethic, ArchEthic.Networking.IPLookup.Static,
  hostname: System.get_env("ARCHETHIC_STATIC_IP")

config :archethic, ArchEthic.Networking.Scheduler,
  interval: System.get_env("ARCHETHIC_NETWORKING_UPDATE_SCHEDULER", "0 0 * * * * *")

config :archethic, ArchEthic.OracleChain.Scheduler,
  # Poll new changes every minute
  polling_interval: System.get_env("ARCHETHIC_ORACLE_CHAIN_POLLING_INTERVAL", "0 * * * * *"),
  # Aggregate chain every day at midnight
  summary_interval: System.get_env("ARCHETHIC_ORACLE_CHAIN_SUMMARY_INTERVAL", "0 0 0 * * * *")

config :archethic, ArchEthic.Reward.NetworkPoolScheduler,
  # Every month
  interval: System.get_env("ARCHETHIC_REWARD_SCHEDULER_INTERVAL", "0 0 0 1 * * *")

config :archethic,
       ArchEthic.Crypto.SharedSecretsKeystore,
       ArchEthic.Crypto.SharedSecretsKeystore.SoftwareImpl

config :archethic, ArchEthic.SharedSecrets.NodeRenewalScheduler,
  # Every day at 23:50:00
  interval:
    System.get_env("ARCHETHIC_SHARED_SECRETS_RENEWAL_SCHEDULER_INTERVAL", "0 50 0 * * * *"),
  # Every day at midnight
  application_interval:
    System.get_env("ARCHETHIC_SHARED_SECRETS_APPLICATION_INTERVAL", "0 0 0 * * * *")

config :archethic, ArchEthic.SelfRepair.Scheduler,
  # Every day at 00:05:00
  # To give time for the beacon chain to produce summary
  interval: System.get_env("ARCHETHIC_SELF_REPAIR_SCHEDULER_INTRERVAL", "0 5 0 * * * *")

config :archethic, ArchEthic.P2P.Endpoint,
  port: System.get_env("ARCHETHIC_P2P_PORT", "30002") |> String.to_integer()

config :archethic, ArchEthic.P2P.BootstrappingSeeds,
  backup_file: System.get_env("ARCHETHIC_P2P_BOOTSTRAPPING_SEEDS_FILE", "p2p/seeds"),
  # TODO: define the default list of P2P seeds once the network will be more open to new miners
  genesis_seeds: System.get_env("ARCHETHIC_P2P_BOOTSTRAPPING_SEEDS")

config :archethic, ArchEthicWeb.FaucetController,
  enabled: System.get_env("ARCHETHIC_NETWORK_TYPE") == "testnet"

# For production, don't forget to configure the url host
# to something meaningful, Phoenix uses this information
# when generating URLs.
#
# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix phx.digest` task,
# which you should run after static files are built and
# before starting your production server.
config :archethic, ArchEthicWeb.Endpoint,
  http: [:inet6, port: System.get_env("ARCHETHIC_HTTP_PORT", "40000") |> String.to_integer()],
  url: [host: "*", port: System.get_env("ARCHETHIC_HTTP_PORT", "40000") |> String.to_integer()],
  cache_static_manifest: "priv/static/cache_manifest.json",
  server: true,
  root: ".",
  version: Application.spec(:archethic, :vsn),
  check_origin: false
