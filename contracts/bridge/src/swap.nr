use dep::aztec::types::type_serialization::TypeSerializationInterface;
use dep::aztec::types::address::AztecAddress;

struct Swap {
    token_id: Field,
    amount: Field,
    address: Field,
}

global SWAP_SERIALIZED_LEN: Field = 3;

fn deserializeSwap(fields: [Field; SWAP_SERIALIZED_LEN]) -> Swap {
    Swap {
        token_id: fields[0] as u120,
        amount: fields[1] as u120,
        address: fields[2] as Field,
    }
}

fn serializeSwap(swap: Swap) -> [Field; SWAP_SERIALIZED_LEN] {
    [swap.token_id as Field, swap.amount as Field, swap.address as Field]
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