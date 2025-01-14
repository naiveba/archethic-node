defmodule ArchEthic.TransactionChain.TransactionSummary do
  @moduledoc """
  Represents transaction header or extract to summarize it
  """
  defstruct [:timestamp, :address, :type, movements_addresses: []]

  alias ArchEthic.TransactionChain.Transaction
  alias ArchEthic.TransactionChain.Transaction.ValidationStamp
  alias ArchEthic.TransactionChain.Transaction.ValidationStamp.LedgerOperations

  alias ArchEthic.Utils

  @type t :: %__MODULE__{
          timestamp: DateTime.t(),
          address: binary(),
          movements_addresses: list(binary()),
          type: Transaction.transaction_type()
        }

  @doc """
  Convert a transaction into transaction info
  """
  @spec from_transaction(Transaction.t()) :: t()
  def from_transaction(%Transaction{
        address: address,
        type: type,
        validation_stamp: %ValidationStamp{
          timestamp: timestamp,
          ledger_operations: operations
        }
      }) do
    %__MODULE__{
      address: address,
      timestamp: timestamp,
      movements_addresses: LedgerOperations.movement_addresses(operations),
      type: type
    }
  end

  @doc """
  Serialize into binary format

  ## Examples

        iex> %TransactionSummary{
        ...>   address:  <<0, 0, 11, 4, 226, 118, 242, 59, 165, 128, 69, 40, 228, 121, 127, 37, 154, 199,
        ...>     168, 212, 53, 82, 220, 22, 56, 222, 223, 127, 16, 172, 142, 218, 41, 247>>,
        ...>   timestamp: ~U[2020-06-25 15:11:53Z],
        ...>   type: :transfer,
        ...>   movements_addresses: [
        ...>      <<0, 0, 234, 233, 156, 155, 114, 241, 116, 246, 27, 130, 162, 205, 249, 65, 232, 166,
        ...>        99, 207, 133, 252, 112, 223, 41, 12, 206, 162, 233, 28, 49, 204, 255, 12>>
        ...>   ]
        ...> }
        ...> |> TransactionSummary.serialize()
        <<
        # Address
        0, 0, 11, 4, 226, 118, 242, 59, 165, 128, 69, 40, 228, 121, 127, 37, 154, 199,
        168, 212, 53, 82, 220, 22, 56, 222, 223, 127, 16, 172, 142, 218, 41, 247,
        # Timestamp
        0, 0, 1, 114, 236, 9, 2, 168,
        # Type
        253,
        # Nb movements addresses
        0, 1,
        # Movement address
        0, 0, 234, 233, 156, 155, 114, 241, 116, 246, 27, 130, 162, 205, 249, 65, 232, 166,
        99, 207, 133, 252, 112, 223, 41, 12, 206, 162, 233, 28, 49, 204, 255, 12
        >>
  """
  @spec serialize(t()) :: binary()
  def serialize(%__MODULE__{
        address: address,
        timestamp: timestamp,
        type: type,
        movements_addresses: movements_addresses
      }) do
    <<address::binary, DateTime.to_unix(timestamp, :millisecond)::64,
      Transaction.serialize_type(type), length(movements_addresses)::16,
      :erlang.list_to_binary(movements_addresses)::binary>>
  end

  @doc """
  Deserialize an encoded TransactionSummary

  ## Example

      iex> <<0, 0, 11, 4, 226, 118, 242, 59, 165, 128, 69, 40, 228, 121, 127, 37, 154, 199,
      ...> 168, 212, 53, 82, 220, 22, 56, 222, 223, 127, 16, 172, 142, 218, 41, 247, 0, 0, 1, 114, 236, 9, 2, 168,
      ...> 253, 0, 1, 0, 0, 234, 233, 156, 155, 114, 241, 116, 246, 27, 130, 162, 205, 249, 65, 232, 166,
      ...> 99, 207, 133, 252, 112, 223, 41, 12, 206, 162, 233, 28, 49, 204, 255, 12>>
      ...> |> TransactionSummary.deserialize()
      {
        %TransactionSummary{
          address:  <<0, 0, 11, 4, 226, 118, 242, 59, 165, 128, 69, 40, 228, 121, 127, 37, 154, 199,
              168, 212, 53, 82, 220, 22, 56, 222, 223, 127, 16, 172, 142, 218, 41, 247>>,
            timestamp: ~U[2020-06-25 15:11:53.000Z],
            type: :transfer,
            movements_addresses: [
              <<0, 0, 234, 233, 156, 155, 114, 241, 116, 246, 27, 130, 162, 205, 249, 65, 232, 166,
                99, 207, 133, 252, 112, 223, 41, 12, 206, 162, 233, 28, 49, 204, 255, 12>>
            ]
        },
        ""
      }
  """
  @spec deserialize(bitstring()) :: {t(), bitstring()}
  def deserialize(data) when is_bitstring(data) do
    {address, <<timestamp::64, type::8, nb_movements::16, rest::bitstring>>} =
      Utils.deserialize_address(data)

    {addresses, rest} = Utils.deserialize_addresses(rest, nb_movements, [])

    {
      %__MODULE__{
        address: address,
        timestamp: DateTime.from_unix!(timestamp, :millisecond),
        type: Transaction.parse_type(type),
        movements_addresses: addresses
      },
      rest
    }
  end

  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{
        address: address,
        timestamp: timestamp,
        type: type,
        movements_addresses: movements_addresses
      }) do
    %{
      address: address,
      timestamp: timestamp,
      type: Atom.to_string(type),
      movements_addresses: movements_addresses
    }
  end

  @spec from_map(map()) :: t()
  def from_map(%{
        address: address,
        timestamp: timestamp,
        type: type,
        movements_addresses: movements_addresses
      }) do
    %__MODULE__{
      address: address,
      timestamp: timestamp,
      type: String.to_atom(type),
      movements_addresses: movements_addresses
    }
  end
end
