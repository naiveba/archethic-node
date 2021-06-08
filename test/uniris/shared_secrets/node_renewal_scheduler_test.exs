defmodule Uniris.SharedSecrets.NodeRenewalSchedulerTest do
  use UnirisCase, async: false

  alias Uniris.BeaconChain
  alias Uniris.BeaconChain.SlotTimer, as: BeaconSlotTimer
  alias Uniris.BeaconChain.SubsetRegistry

  alias Uniris.Crypto

  alias Uniris.P2P
  alias Uniris.P2P.Message.Ok
  alias Uniris.P2P.Message.StartMining
  alias Uniris.P2P.Node

  alias Uniris.SharedSecrets.NodeRenewalScheduler, as: Scheduler

  import Mox

  setup do
    start_supervised!({BeaconSlotTimer, interval: "* * * * * *"})
    Enum.each(BeaconChain.list_subsets(), &Registry.register(SubsetRegistry, &1, []))
    :ok
  end

  describe "start_link/1" do
    test "should initiate the node renewal scheduler and trigger node renewal every each seconds" do
      P2P.add_and_connect_node(%Node{
        first_public_key: Crypto.last_node_public_key(),
        last_public_key: Crypto.last_node_public_key(),
        geo_patch: "AAA",
        available?: true,
        authorized?: true,
        authorization_date: DateTime.utc_now(),
        average_availability: 1.0
      })

      me = self()

      MockClient
      |> stub(:send_message, fn _, %StartMining{} ->
        send(me, :renewal_processed)
        {:ok, %Ok{}}
      end)

      MockDB
      |> expect(:get_latest_tps, fn -> 10.0 end)

      assert {:ok, pid} = Scheduler.start_link([interval: "*/2 * * * * *"], [])

      assert %{interval: "*/2 * * * * *"} = :sys.get_state(pid)

      send(
        pid,
        {:node_update, %Node{authorized?: true, first_public_key: Crypto.first_node_public_key()}}
      )

      assert_receive :renewal_processed, 3_000
    end
  end
end
