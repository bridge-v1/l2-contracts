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
    fn set_tokens(token1: AztecAddress, token2: AztecAddress) {
        assert(context.msg_sender() == storage.owner.read().address, "You are not the owner!");
        storage.token1.write(token1);
        storage.token2.write(token2);
    }

    #[aztec(public)]
    fn swap_public(
        in_token_id: Field,
        out_token_id: Field,
        in_token_amount: Field,
        nonce_for_burn: Field
    ) {
        let mut token = AztecAddress::new(0);
        if (in_token_id == 1) {
            token = storage.token1.read();
        } else {
            token = storage.token2.read();
        }

        Token::at(token.address).burn_public(
            context,
            context.msg_sender(),
            in_token_amount,
            nonce_for_burn,
        );

        let counter = storage.counter.read();
        let swap = storage.swaps.at(counter);

        swap.write(Swap {
            is_private: 0,
            in_token_id: in_token_id,
            out_token_id: out_token_id,
            in_token_amount: in_token_amount,
            out_token_amount: 0,
            l2_address: context.msg_sender(),
            l2_secret_hash: 0,
            is_executed: 0
        });

        storage.counter.write(counter + 1);
    }

    #[aztec(public)]
    fn execute_swap_public(
        swap_id: Field,
        out_token_id: Field,
        out_token_amount: Field,
    ) {
        let swap = storage.swaps.at(swap_id);
        let info = swap.read();

        assert(context.msg_sender() == storage.operator.read().address, "You are not the operator!");
        assert(info.is_executed == 0, "Swap has been executed!");
        assert(info.is_private == 0, "Swap is private!");

        let mut token = AztecAddress::new(0);
        if (out_token_id == 1) {
            token = storage.token1.read();
        } else {
            token = storage.token2.read();
        }

        Token::at(token.address).mint_public(
            context,
            info.l2_address,
            out_token_amount
        );

        swap.write(Swap {
            is_private: info.is_private,
            in_token_id: info.in_token_id,
            out_token_id: info.out_token_id,
            in_token_amount: info.in_token_amount,
            out_token_amount: out_token_amount,
            l2_address: info.l2_address,
            l2_secret_hash: info.l2_secret_hash,
            is_executed: 1
        });
    }

    #[aztec(public)]
    fn swap_private(
        token_id: Field,
        amount: Field,
        nonce_for_transfer: Field,
        secret_hash_for_redeeming: Field
    ) {
        let mut token = AztecAddress::new(0);
        if (token_id == 1) {
            token = storage.token1.read();
        } else {
            token = storage.token2.read();
        }

        // TODO: burn instead of transfer
        // Token::at(token.address).transfer(
        //     context,
        //     context.msg_sender(),
        //     context.this_address(),
        //     amount,
        //     nonce_for_transfer,
        // );

        let counter = storage.counter.read();
        let swap = storage.swaps.at(counter);
        // swap.write(Swap {token_id: token_id, amount: amount, address: secret_hash_for_redeeming, executed: 0});

        storage.counter.write(counter + 1);
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