use dep::aztec::types::type_serialization::TypeSerializationInterface;
use dep::aztec::types::address::AztecAddress;

struct Swap {
    token_id: Field,
    amount: Field,
    address: Field,
    executed: Field,
}

global SWAP_SERIALIZED_LEN: Field = 4;

fn deserializeSwap(fields: [Field; SWAP_SERIALIZED_LEN]) -> Swap {
    Swap {
        token_id: fields[0] as Field,
        amount: fields[1] as Field,
        address: fields[2] as Field,
        executed: fields[3] as Field,
    }
}

fn serializeSwap(swap: Swap) -> [Field; SWAP_SERIALIZED_LEN] {
    [swap.token_id as Field, swap.amount as Field, swap.address as Field, swap.executed as Field]
}

impl Swap {
    fn serialize(self: Self) -> [Field; SWAP_SERIALIZED_LEN] {
        serializeSwap(self)
    }
}

global SwapSerializationMethods = TypeSerializationInterface {
    deserialize: deserializeSwap,
    serialize: serializeSwap,
};