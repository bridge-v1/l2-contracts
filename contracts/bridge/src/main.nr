mod swap;
mod interfaces;

contract bridge {
    use dep::aztec::{
        context::{PrivateContext, PublicContext, Context},
        state_vars::{
            map::Map,
            public_state::PublicState
        },
        types::type_serialization::field_serialization::{
            FieldSerializationMethods, FIELD_SERIALIZED_LEN,
        },
        types::type_serialization::aztec_address_serialization::{
            AztecAddressSerializationMethods, AZTEC_ADDRESS_SERIALIZED_LEN
        },
        types::address::{AztecAddress},
        selector::compute_selector,
    };
    use crate::swap::{SWAP_SERIALIZED_LEN, Swap, SwapSerializationMethods};
    use crate::interfaces::Token;

    struct Storage {
        owner: PublicState<AztecAddress, AZTEC_ADDRESS_SERIALIZED_LEN>,
        operator: PublicState<AztecAddress, AZTEC_ADDRESS_SERIALIZED_LEN>,

        token1: PublicState<AztecAddress, AZTEC_ADDRESS_SERIALIZED_LEN>,
        token2: PublicState<AztecAddress, AZTEC_ADDRESS_SERIALIZED_LEN>,

        swaps: Map<PublicState<Swap, SWAP_SERIALIZED_LEN>>,
        counter: PublicState<Field, FIELD_SERIALIZED_LEN>,
    }

    impl Storage {
        fn init(context: Context) -> Self {
            Storage {
                owner: PublicState::new(
                    context,
                    1,
                    AztecAddressSerializationMethods,
                ),
                operator: PublicState::new(
                    context,
                    2,
                    AztecAddressSerializationMethods,
                ),
                token1: PublicState::new(
                    context,
                    3,
                    AztecAddressSerializationMethods,
                ),
                token2: PublicState::new(
                    context,
                    4,
                    AztecAddressSerializationMethods,
                ),
                swaps: Map::new(
                   context,
                   5,
                   |context, slot| {
                       PublicState::new(
                           context,
                           slot,
                           SwapSerializationMethods,
                       )
                   },
               ),
               counter: PublicState::new(
                   context,
                   6,
                   FieldSerializationMethods,
               ),
            }
        }
    }

    #[aztec(private)]
    fn constructor(owner: AztecAddress) {
        let selector = compute_selector("_initialize(Field)");
        context.call_public_function(context.this_address(), selector, [owner.address]);
    }

    #[aztec(public)]
    internal fn _initialize(owner: Field) {
        storage.owner.write(AztecAddress::new(owner));
    }

    #[aztec(public)]
    fn set_operator(operator: Field) {
        assert(context.msg_sender() == storage.owner.read().address, "You are not the owner!");
        storage.operator.write(AztecAddress::new(operator));
    }

    #[aztec(public)]
    fn add_token(
        token_id: Field,
        token: AztecAddress,
        amount: Field,
        nonce_for_transfer: Field
    ) {
         Token::at(token.address).transfer_public(
           context,
           context.msg_sender(),
           context.this_address(),
           amount,
           nonce_for_transfer,
        );
        if (token_id == 1) {
            storage.token1.write(token);
        } else {
            storage.token2.write(token);
        }
    }

    #[aztec(public)]
    fn swap_public(
        token_id: Field,
        amount: Field,
        nonce_for_transfer: Field
    ) {
        let mut token = AztecAddress::new(0);
        if (token_id == 1) {
            token = storage.token1.read();
        } else {
            token = storage.token2.read();
        }

        Token::at(token.address).transfer_public(
            context,
            context.msg_sender(),
            context.this_address(),
            amount,
            nonce_for_transfer,
        );

        let counter = storage.counter.read();
        let swap = storage.swaps.at(counter);
        swap.write(Swap {token_id: token_id, amount: amount, address: context.msg_sender(), executed: 0});

        storage.counter.write(counter + 1);
    }

    #[aztec(public)]
    fn execute_swap_public(
        swap_id: Field,
        token_id: Field,
        amount: Field,
    ) {
        let swap = storage.swaps.at(swap_id);
        let info = swap.read();

        assert(context.msg_sender() == storage.operator.read().address, "You are not the operator!");
        assert(info.executed == 0, "Swap has been executed!");

        let mut token = AztecAddress::new(0);
        if (token_id == 1) {
            token = storage.token1.read();
        } else {
            token = storage.token2.read();
        }

        Token::at(token.address).transfer_public(
            context,
            context.this_address(),
            info.address,
            amount,
            0
        );

        swap.write(Swap {token_id: info.token_id, amount: info.amount, address: info.address, executed: 1});
    }

    unconstrained fn get_counter() -> Field {
       storage.counter.read()
    }

    unconstrained fn get_swap(swap_id: Field) -> Swap {
       storage.swaps.at(swap_id).read()
    }

    unconstrained fn get_storage() -> [AztecAddress; 4] {
       [storage.owner.read(), storage.operator.read(), storage.token1.read(), storage.token2.read()]
    }

    unconstrained fn compute_note_hash_and_nullifier(
        contract_address: Field,
        nonce: Field,
        storage_slot: Field,
        serialized_note: [Field; 0]) -> [Field; 4] {
        [0, 0, 0, 0]
    }
}