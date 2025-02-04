defmodule ArchEthic.SelfRepair.Sync.BeaconSummaryHandler.TransactionHandlerTest do
  use ArchEthicCase

  alias ArchEthic.BeaconChain
  alias ArchEthic.BeaconChain.SlotTimer, as: BeaconSlotTimer
  alias ArchEthic.BeaconChain.Subset, as: BeaconSubset

  alias ArchEthic.Crypto

  alias ArchEthic.P2P
  alias ArchEthic.P2P.Message.GetTransaction
  alias ArchEthic.P2P.Message.GetTransactionChain
  alias ArchEthic.P2P.Message.GetTransactionInputs
  alias ArchEthic.P2P.Message.GetUnspentOutputs
  alias ArchEthic.P2P.Message.TransactionInputList
  alias ArchEthic.P2P.Message.TransactionList
  alias ArchEthic.P2P.Message.UnspentOutputList
  alias ArchEthic.P2P.Node

  alias ArchEthic.SelfRepair.Sync.BeaconSummaryHandler.TransactionHandler
  alias ArchEthic.SharedSecrets.MemTables.NetworkLookup

  alias ArchEthic.TransactionFactory

  alias ArchEthic.TransactionChain.TransactionInput
  alias ArchEthic.TransactionChain.TransactionSummary

  doctest TransactionHandler

  import Mox

  setup do
    start_supervised!({BeaconSlotTimer, interval: "0 * * * * * *"})
    Enum.each(BeaconChain.list_subsets(), &BeaconSubset.start_link(subset: &1))

    welcome_node = %Node{
      first_public_key: "key1",
      last_public_key: "key1",
      available?: true,
      geo_patch: "BBB",
      network_patch: "BBB",
      reward_address: :crypto.strong_rand_bytes(32),
      enrollment_date: DateTime.utc_now()
    }

    coordinator_node = %Node{
      first_public_key: Crypto.first_node_public_key(),
      last_public_key: Crypto.last_node_public_key(),
      authorized?: true,
      available?: true,
      authorization_date: DateTime.utc_now() |> DateTime.add(-10),
      geo_patch: "AAA",
      network_patch: "AAA",
      reward_address: :crypto.strong_rand_bytes(32),
      enrollment_date: DateTime.utc_now()
    }

    storage_nodes = [
      %Node{
        ip: {127, 0, 0, 1},
        port: 3000,
        first_public_key: "key3",
        last_public_key: "key3",
        available?: true,
        geo_patch: "BBB",
        network_patch: "BBB",
        reward_address: :crypto.strong_rand_bytes(32),
        authorized?: true,
        authorization_date: DateTime.utc_now()
      }
    ]

    Enum.each(storage_nodes, &P2P.add_and_connect_node(&1))

    P2P.add_and_connect_node(welcome_node)
    P2P.add_and_connect_node(coordinator_node)

    Crypto.generate_deterministic_keypair("daily_nonce_seed")
    |> elem(0)
    |> NetworkLookup.set_daily_nonce_public_key(DateTime.utc_now() |> DateTime.add(-10))

    {:ok,
     %{
       welcome_node: welcome_node,
       coordinator_node: coordinator_node,
       storage_nodes: storage_nodes
     }}
  end

  test "download_transaction?/1 should return true when the node is a chain storage node" do
    assert true =
             TransactionHandler.download_transaction?(%TransactionSummary{
               address: "@Alice2"
             })
  end

  test "download_transaction/2 should download the transaction", context do
    inputs = [
      %TransactionInput{
        from: "@Alice2",
        amount: 1_000_000_000,
        type: :UCO,
        timestamp: DateTime.utc_now()
      }
    ]

    tx = TransactionFactory.create_valid_transaction(context, inputs)

    MockClient
    |> stub(:send_message, fn
      _, %GetTransaction{}, _ ->
        {:ok, tx}
    end)

    tx_summary = %TransactionSummary{address: "@Alice2", timestamp: DateTime.utc_now()}
    assert ^tx = TransactionHandler.download_transaction(tx_summary, "AAA")
  end

  test "process_transaction/1 should handle the transaction and replicate it", context do
    me = self()

    inputs = [
      %TransactionInput{
        from: "@Alice2",
        amount: 1_000_000_000,
        type: :UCO,
        timestamp: DateTime.utc_now()
      }
    ]

    tx = TransactionFactory.create_valid_transaction(context, inputs)

    MockClient
    |> stub(:send_message, fn
      _, %GetTransaction{}, _ ->
        {:ok, tx}

      _, %GetTransactionInputs{}, _ ->
        {:ok, %TransactionInputList{inputs: inputs}}

      _, %GetUnspentOutputs{}, _ ->
        {:ok, %UnspentOutputList{unspent_outputs: inputs}}

      _, %GetTransactionChain{}, _ ->
        {:ok, %TransactionList{transactions: []}}
    end)

    MockDB
    |> stub(:write_transaction_chain, fn _ ->
      send(me, :transaction_replicated)
      :ok
    end)

    assert :ok = TransactionHandler.process_transaction(tx)

    assert_received :transaction_replicated
  end
end
