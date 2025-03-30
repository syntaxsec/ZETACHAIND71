# ZETACHAIND71

## Steps to run the hello example
- Prerequisites: You should have some Zeta and SepoliaETH. Copy your private key into the .env file. You can check your private key by clicking metamask -> three dots -> account details -> show private key. It'll look something like this:![image](https://github.com/user-attachments/assets/d1d0a78d-a494-4576-b1ec-bd1142199337)

- First clone the repo and run yarn:
```
git clone https://github.com/zeta-chain/example-contracts
cd example-contracts/examples/hello
yarn
```
- Deploy on zeta_testnet: `npx hardhat deploy --network zeta_testnet --gateway 0x6c533f7fe93fae114d0954697069df33c9b74fd7`
- Copy the Contract address.
- Then run the below. You should see a transaction hash. You can check the status of the transaction hash via https://sepolia.etherscan.io/ on sepolia's side, or https://athens.explorer.zetachain.com/cc/tx/transaction_hash_here on zetachain's side (eg. https://athens.explorer.zetachain.com/cc/tx/0xa399e4874af7e2b5a0fce1d87dbb02362e82988401da07642942fb2bf4ad7d06)
```
npx hardhat evm-call \
  --network sepolia_testnet \
  --gateway-evm 0x0c487a766110c85d301d96e33579c5b317fa4995 \
  --receiver copied_contract_address \
  --types '["string"]' alice
```
