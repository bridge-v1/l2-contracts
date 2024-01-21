# l2-contracts

### Simple bridge for swapping tokens from Aztec L2 on any L1 

#### Prerequisites:

`Node.js >= v18 (recommend installing with nvm)`

`Docker and Docker Compose (Docker Desktop under WSL2 on windows)`

`Aztec Sandbox/cli: bash -i <(curl -s install.aztec.network)"`

#### To build smart contract:

`cd contracts/bridge`
`aztec-nargo compile --silence-warnings`
`aztec-cli codegen target -o ../../test/fixtures --ts`

#### To test smart contract:

`npm ci` (--force may be needed)

`yarn test`
