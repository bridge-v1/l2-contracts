use dep::aztec::types::type_serialization::TypeSerializationInterface;
use dep::aztec::types::address::AztecAddress;

struct Swap {
    is_private: Field,
    in_token_id: Field,
    out_token_id: Field,
    in_token_amount: Field,
    out_token_amount: Field,
    l2_address: Field,
    l2_secret_hash: Field,
    is_executed: Field,
}

global SWAP_SERIALIZED_LEN: Field = 8;

fn deserializeSwap(fields: [Field; SWAP_SERIALIZED_LEN]) -> Swap {
    Swap {
        is_private: fields[0] as Field,
        in_token_id: fields[1] as Field,
        out_token_id: fields[2] as Field,
        in_token_amount: fields[3] as Field,
        out_token_amount: fields[4] as Field,
        l2_address: fields[5] as Field,
        l2_secret_hash: fields[6] as Field,
        is_executed: fields[7] as Field,
    }
}

fn serializeSwap(swap: Swap) -> [Field; SWAP_SERIALIZED_LEN] {
    [swap.is_private as Field, swap.in_token_id as Field, swap.out_token_id as Field, swap.in_token_amount as Field, swap.out_token_amount as Field, swap.l2_address as Field, swap.l2_secret_hash as Field, swap.is_executed as Field]
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