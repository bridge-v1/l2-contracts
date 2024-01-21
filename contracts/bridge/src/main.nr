mod swap;
mod interfaces;

contract bridge {
    use dep::aztec::{
        context::{PrivateContext, PublicContext, Context},
        state_vars::{
            map::Map,
            public_state::PublicState
        },
        types::type_serialization::field_serialization::FieldSerializationMethods,
        types::type_serialization::address_serialization::AddressSerializationMethods,
        protocol_types::{
            address::{AztecAddress},
            abis::function_selector::FunctionSelector
        },
    };
    use crate::swap::{SWAP_SERIALIZED_LEN, Swap, SwapSerializationMethods};
    use crate::interfaces::Token;

    struct Storage {
        owner: PublicState<AztecAddress, 1>,
        operator: PublicState<AztecAddress, 1>,

        token1: PublicState<AztecAddress, 1>,
        token2: PublicState<AztecAddress, 1>,

        swaps: Map<Field, PublicState<Swap, SWAP_SERIALIZED_LEN>>,
        counter: PublicState<Field, 1>,
    }

    impl Storage {
        fn init(context: Context) -> Self {
            Storage {
                owner: PublicState::new(
                    context,
                    1,
                    AddressSerializationMethods,
                ),
                operator: PublicState::new(
                    context,
                    2,
                    AddressSerializationMethods,
                ),
                token1: PublicState::new(
                    context,
                    3,
                    AddressSerializationMethods,
                ),
                token2: PublicState::new(
                    context,
                    4,
                    AddressSerializationMethods,
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
        let selector = FunctionSelector::from_signature("_initialize(Field)");
        context.call_public_function(context.this_address(), selector, [owner.to_field()]);
    }

    #[aztec(public)]
    internal fn _initialize(owner: Field) {
        storage.owner.write(AztecAddress::from_field(owner));
    }

    #[aztec(public)]
    fn set_operator(operator: AztecAddress) {
        assert(context.msg_sender() == storage.owner.read(), "You are not the owner!");
        storage.operator.write(operator);
    }

    #[aztec(public)]
    fn set_tokens(token1: AztecAddress, token2: AztecAddress) {
        assert(context.msg_sender() == storage.owner.read(), "You are not the owner!");
        storage.token1.write(token1);
        storage.token2.write(token2);
    }

    #[aztec(public)]
    internal fn _save_swap(
        in_token_id: Field,
        out_token_id: Field,
        in_token_amount: Field,
        l2_secret_hash: Field
    ) {
        let counter = storage.counter.read();
        let swap = storage.swaps.at(counter);

        swap.write(Swap {
            is_private: 1,
            in_token_id: in_token_id,
            out_token_id: out_token_id,
            in_token_amount: in_token_amount,
            out_token_amount: 0,
            l2_address: 0,
            l2_secret_hash: l2_secret_hash,
            is_executed: 0
        });

        storage.counter.write(counter + 1);
    }

    #[aztec(public)]
    internal fn _update_swap(
        swap_id: Field,
        out_token_amount: Field,
    ) {
        let swap = storage.swaps.at(swap_id);
        let info = swap.read();

        swap.write(Swap {
            is_private: 1,
            in_token_id: info.in_token_id,
            out_token_id: info.out_token_id,
            in_token_amount: info.in_token_amount,
            out_token_amount: out_token_amount,
            l2_address: 0,
            l2_secret_hash: info.l2_secret_hash,
            is_executed: 1
        });
    }

    #[aztec(public)]
    internal fn _assert_token_is_same(in_token_id: Field, in_token_address: Field) {
        let mut token = AztecAddress::from_field(0);
        if (in_token_id == 1) {
            token = storage.token1.read();
        } else {
            token = storage.token2.read();
        }

        assert(token == AztecAddress::from_field(in_token_address), "Token is not same!");
    }

    #[aztec(public)]
    internal fn _assert_swap_params(swap_id: Field, secret_hash_for_redeeming: Field) {
        let swap = storage.swaps.at(swap_id);
        let info = swap.read();

        assert(info.is_executed == 0, "Swap has been executed!");
        assert(info.is_private == 1, "Swap is not private!");
        assert(info.l2_secret_hash == secret_hash_for_redeeming, "Secret hash is not same!");
    }

    #[aztec(public)]
    internal fn _assert_operator(address: AztecAddress) {
       assert(address == storage.operator.read(), "You are not the operator!");
    }

    #[aztec(public)]
    internal fn _mint_private(out_token_address: AztecAddress, amount: Field, secret_hash: Field) {
        Token::at(out_token_address).mint_private(context, amount, secret_hash);
    }

    #[aztec(public)]
    fn swap_public(
        in_token_id: Field,
        out_token_id: Field,
        in_token_amount: Field,
        nonce_for_burn: Field
    ) {
        let mut token = AztecAddress::from_field(0);
        if (in_token_id == 1) {
            token = storage.token1.read();
        } else {
            token = storage.token2.read();
        }

        Token::at(token).burn_public(
            context,
            context.msg_sender().to_field(),
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
            l2_address: context.msg_sender().to_field(),
            l2_secret_hash: 0,
            is_executed: 0
        });

        storage.counter.write(counter + 1);
    }

    #[aztec(private)]
    fn swap_private(
        in_token_id: Field,
        in_token_address: AztecAddress,
        out_token_id: Field,
        in_token_amount: Field,
        nonce_for_burn: Field,
        secret_hash_for_redeeming: Field
    ) -> pub Field {
        let mut selector = FunctionSelector::from_signature("_assert_token_is_same(Field,Field)");
        context.call_public_function(context.this_address(), selector, [in_token_id, in_token_address.to_field()]);

        Token::at(in_token_address).burn(
            &mut context,
            context.msg_sender().to_field(),
            in_token_amount,
            nonce_for_burn,
        );

        selector = FunctionSelector::from_signature("_save_swap(Field,Field,Field,Field)");
        context.call_public_function(context.this_address(), selector, [in_token_id, out_token_id, in_token_amount, secret_hash_for_redeeming]);
    }

    #[aztec(public)]
    fn execute_swap_public(
        swap_id: Field,
        out_token_amount: Field,
    ) {
        let swap = storage.swaps.at(swap_id);
        let info = swap.read();

        assert(context.msg_sender() == storage.operator.read(), "You are not the operator!");
        assert(info.is_executed == 0, "Swap has been executed!");
        assert(info.is_private == 0, "Swap is private!");

        let mut token = AztecAddress::from_field(0);
        if (info.out_token_id == 1) {
            token = storage.token1.read();
        } else {
            token = storage.token2.read();
        }

        Token::at(token).mint_public(
            context,
            info.l2_address,
            out_token_amount
        );

        swap.write(Swap {
            is_private: 0,
            in_token_id: info.in_token_id,
            out_token_id: info.out_token_id,
            in_token_amount: info.in_token_amount,
            out_token_amount: out_token_amount,
            l2_address: info.l2_address,
            l2_secret_hash: 0,
            is_executed: 1
        });
    }

    #[aztec(public)]
    fn execute_swap_private(
        swap_id: Field,
        out_token_amount: Field,
    ) {
        assert(context.msg_sender() == storage.operator.read(), "You are not the operator!");

        let swap = storage.swaps.at(swap_id);
        let info = swap.read();

        assert(info.is_executed == 0, "Swap has been executed!");
        assert(info.is_private == 1, "Swap is not private!");

        let mut token = AztecAddress::from_field(0);
        if (info.out_token_id == 1) {
            token = storage.token1.read();
        } else {
            token = storage.token2.read();
        }

        Token::at(token).mint_private(context, out_token_amount, info.l2_secret_hash);

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

    unconstrained fn get_counter() -> pub Field {
       storage.counter.read()
    }

    unconstrained fn get_swap(swap_id: Field) -> pub Swap {
       storage.swaps.at(swap_id).read()
    }

    unconstrained fn get_storage() -> pub [AztecAddress; 4] {
       [storage.owner.read(), storage.operator.read(), storage.token1.read(), storage.token2.read()]
    }

    unconstrained fn compute_note_hash_and_nullifier(
            contract_address: AztecAddress,
            nonce: Field,
            storage_slot: Field,
            serialized_note: [Field; 3]
    ) -> pub [Field; 4] {
        [0, 0, 0, 0]
    }
}