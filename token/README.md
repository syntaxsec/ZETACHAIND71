# Steps to setup and run
- run `yarn` to install required packages
- on one terminal, run `npx hardhat localnet`. Localnet is a local testnet that allows us to test cross chain contracts.
- on another, run `./scripts/localnet.sh`
- Observe the logs on both windows. Our logs on the localnet start with "!!!!".

# What is our PoC?
This PoC shows that it's possible to transfer message cross chain via the help of a Universal contract deployed on Zetachain. This is the data flow:
- We invoke `transferCrossChain` on the `EVMConnectedNFT` contract on the `BNB chain`, with an input of `10`.
- The `EVMConnectedNFT` contract on `BNB` does a costly computation and sends the result and some estimated gas fee to the `ZetaChainUniversal` contract on `Zetachain`.
- The`onCall` function of the `ZetaChainUniversal` contract on `Zetachain` will be called. Here we swap the estimated gas fee with the targeting zrc tokens. Then, we approve the gateway to use our swapped zrc tokens. Lastly, we invoke `gateway.withdrawAndCall`, which sends parts of our funds there with a call command and arguments. (For the parts of our funds that we didn't send, these are the gas fee for Zetachain.)
- The `onCall` function of the `EVMConnectedNFT` contract on the `Ethereum Chain` will get invoked. It will either mint an NFT or do nothing based on the forwarded result we got from `ZetachainUniversal`. Lastly, we send the remaining gas back to the sender in the target token in the destination chain. In our case, it's `ZRC20_ETHEREUM`.
