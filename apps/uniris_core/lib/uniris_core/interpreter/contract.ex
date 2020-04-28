defmodule UnirisCore.Interpreter.Contract do
  @moduledoc """
  Represents parsed smart contract instance as long running process.

  Triggers and action mechanism are sent to the contract as message passing.
  """

  alias UnirisCore.ContractRegistry
  alias UnirisCore.Transaction

  use GenServer

  defstruct triggers: [],
            conditions: [
              response: Macro.escape(true),
              inherit: Macro.escape(true),
              origin_family: :all
            ],
            actions: {:__block__, [], []},
            constants: []

  @typedoc """
  Origin family is the category of device originating transactions
  """
  @type origin_family :: :all | :biometric | :software | :usb

  @typedoc """
  Uniris Smart Contract is defined by three main components:
  - Triggers: Nodes are able to self trigger smart contract based on the extraction of
  these elements and stored locally.
    - Datetime: Timestamp when the action will be executed
  - Conditions: Requirements to be true before execute the contract
    - Response: Define the rules to accept the incoming transaction response
    - Origin Family: Define the accepted family of devices originating the transactions
    - Post Paid Fee: Define the address will be in charge to pay the fees for the transactions
    - Inherit: Inherited constraints ruling the next transactions on the contract chain
  - Actions: Contract logic executed against a transaction response and condition interacting
  with the smart contract

  Additional information as constants are extracted from the AST to be used
  inside triggers, conditions or actions
  """
  @type t :: %__MODULE__{
          triggers: [] | [datetime: integer()],
          conditions: [
            response: Macro.t(),
            origin_family: origin_family(),
            post_paid_fee: binary(),
            inherit: Macro.t()
          ],
          actions: Macro.t(),
          constants: Keyword.t()
        }

  def start_link(opts) do
    %Transaction{address: tx_address} = Keyword.get(opts, :transaction)
    GenServer.start_link(__MODULE__, opts, name: via_tuple(tx_address))
  end

  def init(opts) do
    ast = Keyword.get(opts, :ast)
    tx = Keyword.get(opts, :transaction)

    contract = create(ast, tx)

    Enum.each(contract.triggers, fn {trigger_type, value} ->
      case trigger_type do
        :datetime ->
          now = DateTime.utc_now() |> DateTime.to_unix()
          Process.send_after(self(), :time_trigger, abs(now - value))

        _ ->
          :ok
      end
    end)

    {:ok, contract}
  end

  @spec create({:actions, [], [[do: Macro.t()]]}, Transaction.t()) :: __MODULE__.t()
  defp create({:actions, _, [[do: actions]]} = _ast, tx = %Transaction{}),
    do: %__MODULE__{
      actions: actions,
      constants: [
        keys: tx.data.keys,
        ledger: tx.data.ledger
      ]
    }

  @spec create(
          {:__block__, [],
           [
             {:@, [], [{atom(), [], [term()]}]}
             | {:trigger, [], Keyword.t()}
             | {:condition, [], Keyword.t()}
             | {:actions, [], [[do: Macro.t()]]}
           ]},
          Transaction.t()
        ) :: __MODULE__.t()
  defp create({:__block__, [], elems} = _ast, tx = %Transaction{}) do
    elems
    |> Enum.reduce(
      %__MODULE__{
        constants: [
          keys: tx.data.keys,
          ledger: tx.data.ledger
        ]
      },
      fn elem, contract ->
        do_build_contract(elem, contract)
      end
    )
  end

  defp do_build_contract({:@, _, [{token, _, [value]}]}, contract = %__MODULE__{}) do
    %{contract | constants: Keyword.put(contract.constants, token, value)}
  end

  defp do_build_contract({:trigger, _, [props]}, contract = %__MODULE__{}) do
    Map.update!(contract, :triggers, &Keyword.merge(&1, props))
  end

  defp do_build_contract({:condition, _, [props]}, contract = %__MODULE__{}) do
    Map.update!(contract, :conditions, &Keyword.merge(&1, props))
  end

  defp do_build_contract(
         {:actions, _, [[do: {:__block__, _, _} = actions]]},
         contract = %__MODULE__{}
       ) do
    %{contract | actions: actions}
  end

  defp do_build_contract({:actions, _, [[do: elems]]}, contract = %__MODULE__{}) do
    %{contract | actions: elems}
  end

  def handle_call(
        {:execute, incoming_tx = %Transaction{}},
        _from,
        state = %__MODULE__{actions: actions, conditions: conditions, constants: constants}
      ) do
    context = constants ++ [response: incoming_tx]

    case Keyword.get(conditions, :response) do
      nil ->
        with {output, _} <- Code.eval_quoted(actions, context) do
          {:ok, output}
        end

      condition ->
        with {true, _} <- Code.eval_quoted(condition, context),
             {_output, _} <- Code.eval_quoted(actions, context) do
          # TODO: do something with the output
          {:reply, :ok, state}
        else
          _ ->
            {:reply, {:error, :condition_not_respected}}
        end
    end
  end

  def handle_info(:time, state = %__MODULE__{actions: actions, constants: constants}) do
    case Code.eval_quoted(actions, constants) do
      {_output, _} ->
        # TODO: do someting with the output
        {:noreply, state}

      _ ->
        {:noreply, state}
    end
  end

  @spec execute(binary(), Transaction.validated()) :: :ok | {:error, :condition_not_respected}
  def execute(address, tx = %Transaction{}) do
    GenServer.call(via_tuple(address), {:execute, tx})
  end

  defp via_tuple(address) do
    {:via, Registry, {ContractRegistry, address}}
  end
end