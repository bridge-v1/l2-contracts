mod types;
mod interfaces;

contract bridge {
    use dep::aztec::{
        context::{PrivateContext, PublicContext, Context},
        state_vars::{public_state::PublicState},
        types::type_serialization::field_serialization::{
            FieldSerializationMethods, FIELD_SERIALIZED_LEN,
        },
        types::type_serialization::aztec_address_serialization::{
            AztecAddressSerializationMethods, AZTEC_ADDRESS_SERIALIZED_LEN
        },
        types::address::{AztecAddress},
        selector::compute_selector,
        log::emit_unencrypted_log,
    };
    use dep::safe_math::SafeU120;
    use crate::interfaces::Token;
    use crate::types::{
            safe_u120_serialization::{SafeU120SerializationMethods, SAFE_U120_SERIALIZED_LEN}
        };

    struct Storage {
        owner: PublicState<AztecAddress, AZTEC_ADDRESS_SERIALIZED_LEN>,
        operator: PublicState<AztecAddress, AZTEC_ADDRESS_SERIALIZED_LEN>,

        token1: PublicState<AztecAddress, AZTEC_ADDRESS_SERIALIZED_LEN>,
        token2: PublicState<AztecAddress, AZTEC_ADDRESS_SERIALIZED_LEN>,
    }

    impl Storage {
        fn init(context: Context) -> pub Self {
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
            }
        }
    }

    #[aztec(private)]
    fn constructor(owner: AztecAddress, operator: AztecAddress) {
        let selector = compute_selector("_initialize(Field)");
        context.call_public_function(context.this_address(), selector, [owner.address]);
    }

    #[aztec(public)]
    internal fn _initialize(
        owner: Field,
    ) {
        storage.owner.write(AztecAddress::new(owner));
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
        } else if (token_id == 2) {
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
        emit_unencrypted_log(&mut context, 1234567);
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