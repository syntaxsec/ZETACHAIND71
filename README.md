# Overview
We provide 2 PoCs for Zetachain:
- `token`: a one-way transfer of a message from a cheap chain to an expensive chain.        
- `token-back`: a back-and-forth transfer of a message from an expensive chain to a cheap chain, which sends some result back to the expensive chain.       

Notice in all of our examples, the `BNB` chain is the cheap chain where we conduct the costly operation, and `Ethereum` is the expensive chain where we mint an NFT.

# Setup and Run
To run a PoC, first `cd` into the PoC directory. Then do the following:        
- run `yarn` to install required packages        
- on one terminal, run `npx hardhat localnet`. Localnet is a local testnet that allows us to test cross chain contracts.        
- on another, run `./scripts/localnet.sh`        
- Observe the logs on both windows. Our logs on the localnet start with "!!!!!".        

# What we're passing around
```solidity
// This is what we are actually sending
abi.encode(
  address zrc20Dest, // The ZRC-20 address of the gas token of the destination chain
  struct Msg { 
    uint16 amount;  // Our input
    bool isResult;  // A boolean that indicates if this is sending from the cheap chain back to the expensive chain
  },
  uint256 gasAmount, //The remaining gas Amount
  address sender  // The original Sender
);
```

```solidity
// These below are for demonstration purposes but 
// There is no reason it should not be possible to send the function we want to run
// And switch to it in onCall in the receiving contract via a conditional
struct Request { 
  address zrc20Dest,
  uint256 gasAmount, 
  address sender,
  bytes arguments,
  string function
}

struct Response {
  address zrc20Dest,
  uint256 gasAmount, 
  address sender,
  bytes result
}
```

# PoC 1: Token
This PoC shows that it's possible to transfer message cross chain via the help of a Universal contract deployed on Zetachain. The data flow is `B -> Z -> E`, where `B` is `BNB`, `Z` is `ZetaChain`, `E` is `Ethereum`.
- We invoke `transferCrossChain` on the `EVMConnectedNFT` contract on the `BNB chain`, with an input of `10`.
- The `EVMConnectedNFT` contract on `BNB` does a costly computation and sends the result and some estimated gas fee to the `ZetaChainUniversal` contract on `Zetachain`.
- The`onCall` function of the `ZetaChainUniversal` contract on `Zetachain` will be called. Here we swap the estimated gas fee with the targeting zrc tokens. Then, we approve the gateway to use our swapped zrc tokens. Lastly, we invoke `gateway.withdrawAndCall`, which sends parts of our funds there with a call command and arguments. (For the parts of our funds that we didn't send, these are the gas fee for Zetachain.)
- The `onCall` function of the `EVMConnectedNFT` contract on the `Ethereum Chain` will get invoked. It will either mint an NFT or do nothing based on the forwarded result we got from `ZetachainUniversal`. Lastly, we send the remaining gas back to the sender in the target token in the destination chain. In our case, it's `ZRC20_ETHEREUM`.


# PoC 2: Token-Back
This PoC shows that it's possible to transfer messages cross chain back and forth. This allows the User to only connect to the expensive chain, acheiving our goal of computational arbitrage. The data flow is `E -> Z -> B -> Z -> E`, where `B` is `BNB`, `Z` is `ZetaChain`, `E` is `Ethereum`.
- We invoke `transferCrossChain` on the `EVMConnectedNFT` contract on the `Ethereum chain`, with an input of `10`.
- The `EVMConnectedNFT` contract on `Ethereum` sends a request to `BNB` via the `ZetaChainUniversal` contract on `Zetachain`. 
- The `EVMConnectedNFT` contract on `BNB` conducts a costly computation and sends the result back to the `EVMConnectedNFT` contract on `Ethereum`, potentially triggering a mint. 

Notice that in both examples, whenever we invoke a cross chain call, we pass on the remaining gas fees. In PoC 2, after potentially triggering a mint on `Ethereum`, we send the remaining gas fees to the sender in `ZRC20_ETH`.

# Top 3 Resources
[Gateway EVM and ZEVM protocol contracts](https://github.com/zeta-chain/protocol-contracts)

[Sample Universal Apps and Contracts to be deployed in External Chain](https://github.com/zeta-chain/example-contracts)

[Validator Node Docs](https://github.com/zeta-chain/node/tree/develop/docs)
