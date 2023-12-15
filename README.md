# l2-contracts

### Simple bridge for swapping tokens from Aztec L2 on any L1 

#### Prerequisites:

`Node.js >= v18 (recommend installing with nvm)`

`Docker and Docker Compose (Docker Desktop under WSL2 on windows)`

`Aztec Sandbox/cli: /bin/bash -c "$(curl -fsSL 'https://sandbox.aztec.network')"`

#### To build smart contract:

`sudo aztec-cli compile --typescript ./../../test/fixtures contracts/bridge`

#### To test smart contract:

`npm ci` (--force may be needed)

`yarn test`
