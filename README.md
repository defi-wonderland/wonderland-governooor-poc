# Wonderland Governor

⚠️ The code has not been audited yet, tread with caution.

## Overview

Wonderland Governor is a DAO governance solution designed to address the current limitations in delegation within governance protocols. Unlike old systems where users give all their voting power to one delegate, it offers a flexible solution, introducing innovative features to empower users and enhance governance processes in decentralized organizations.

Key Features:

Proposal Types:

Wonderland Governor lets organizations set different types of proposals for specific needs like legal or technical matters.
Every proposal now has a required type, making it clear which category it falls into.

Better Delegation:

Users can now spread their voting power across different categories.
Users can choose multiple delegates for each proposal type, assigning a percentage of their voting power to each.
Users can still delegate 100% of their voting power to one person if they prefer.

Wonderland Governor is founded on the OpenZeppelin contracts and enhances their functionalities to achieve the described features.

## Setup

This project uses [Foundry](https://book.getfoundry.sh/). To build it locally, run:

```sh
git clone git@github.com:defi-wonderland/wonderland-governooor-poc.git
cd wonderland-governooor-poc
yarn install
yarn build
```

### Available Commands

Make sure to set `OPTIMISM_RPC` environment variable before running end-to-end tests.

| Yarn Command            | Description                                                |
| ----------------------- | ---------------------------------------------------------- |
| `yarn build`            | Compile all contracts.                                     |
| `yarn coverage`         | See `forge coverage` report.                               |
| `yarn deploy:local`     | Deploy the contracts to a local fork.                      |
| `yarn deploy:goerli`    | Deploy the contracts to Goerli testnet.                    |
| `yarn deploy:optimism`  | Deploy the contracts to Optimism mainnet.                  |
| `yarn deploy:mainnet`   | Deploy the contracts to Ethereum mainnet.                  |
| `yarn test`             | Run all unit and integration tests.                        |
| `yarn test:unit`        | Run unit tests.                                            |
| `yarn test:integration` | Run integration tests.                                     |
| `yarn test:gas`         | Run all unit and integration tests, and make a gas report. |

## Idea and Narrative
The original idea was crafted by [Particle](https://twitter.com/0xParticle), [Mono](https://twitter.com/0x_mono) and [Joxes](https://twitter.com/0xJoxes) from the Research team. 
You can find more information on why we built this on the site: [https://governance.sucks/](https://governance.sucks/)

## Licensing

The primary license for Wonderland Governor contracts is MIT, see [`LICENSE`](./LICENSE).

## Contributors

Wonderland Governor was built with ❤️ by [Wonderland](https://defi.sucks).

Wonderland is a team of top Web3 researchers, developers, and operators who believe that the future needs to be open-source, permissionless, and decentralized.

[DeFi sucks](https://defi.sucks), but Wonderland is here to make it better.
