use dep::aztec::{
  context::{PublicContext, PrivateContext},
  protocol_types::{
    abis::function_selector::FunctionSelector,
    address::{AztecAddress}
  }
};

struct Token {
  address: AztecAddress,
}

impl Token {
    pub fn at(address: AztecAddress) -> Self {
        Self { address }
    }

    pub fn transfer_public(self: Self, context: PublicContext, from: Field, to: Field, amount: Field, nonce: Field) {
        let _transfer_return_values = context.call_public_function(
          self.address,
          FunctionSelector::from_signature("transfer_public((Field),(Field),Field,Field)"),
          [from, to, amount, nonce]
        );
    }

    pub fn burn(self: Self, context: &mut PrivateContext, from: Field, amount: Field, nonce: Field) {
        let _return_values = context.call_private_function(
            self.address,
            FunctionSelector::from_signature("burn((Field),Field,Field)"),
            [from, amount, nonce]
        );
    }

    pub fn burn_public(self: Self, context: PublicContext, from: Field, amount: Field, nonce: Field) {
        let _return_values = context.call_public_function(
            self.address,
            FunctionSelector::from_signature("burn_public((Field),Field,Field)"),
            [from, amount, nonce]
        );
    }

    pub fn mint_public(self: Self, context: PublicContext, to: Field, amount: Field) {
        let _transfer_return_values = context.call_public_function(
          self.address,
          FunctionSelector::from_signature("mint_public((Field),Field)"),
          [to, amount]
        );
    }

    pub fn mint_private(self: Self, context: PublicContext, amount: Field, secret_hash: Field) {
        let _return_values = context.call_public_function(
            self.address,
            FunctionSelector::from_signature("mint_private(Field,Field)"),
            [amount, secret_hash]
        );
    }
}