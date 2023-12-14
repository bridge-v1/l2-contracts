use dep::aztec::{
  context::{PublicContext, PrivateContext},
  selector::compute_selector,
  types::address::{AztecAddress},
};

struct Token {
  address: Field,
}

impl Token {
    pub fn at(address: Field) -> Self {
        Self { address }
    }

    pub fn transfer_public(self: Self, context: PublicContext, from: Field, to: Field, amount: Field, nonce: Field) {
        let _transfer_return_values = context.call_public_function(
          self.address,
          compute_selector("transfer_public((Field),(Field),Field,Field)"),
          [from, to, amount, nonce]
        );
    }

    pub fn burn_public(self: Self, context: PublicContext, from: Field, amount: Field, nonce: Field) {
        let _return_values = context.call_public_function(
            self.address,
            compute_selector("burn_public((Field),Field,Field)"),
            [from, amount, nonce]
        );
    }

    pub fn mint_public(self: Self, context: PublicContext, to: Field, amount: Field) {
        let _transfer_return_values = context.call_public_function(
          self.address,
          compute_selector("mint_public((Field),Field)"),
          [to, amount]
        );
    }
}