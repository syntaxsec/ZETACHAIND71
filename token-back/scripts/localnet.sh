#!/bin/bash

set -e
set -o pipefail

# npx hardhat localnet --exit-on-error & sleep 15

function balance() {
  echo -e "\n🖼️  Balance"
  echo "---------------------------------------------"
  local ZETACHAIN=$(cast call "$CONTRACT_ZETACHAIN" "balanceOf(address)(uint256)" "$SENDER")
  local ETHEREUM=$(cast call "$CONTRACT_ETHEREUM" "balanceOf(address)(uint256)" "$SENDER")
  local BNB=$(cast call "$CONTRACT_BNB" "balanceOf(address)(uint256)" "$SENDER")
  echo "🟢 ZetaChain: $ZETACHAIN"
  echo "🔵 EVM Chain: $ETHEREUM"
  echo "🟡 BNB Chain: $BNB"
  echo "---------------------------------------------"
}

echo -e "\n🚀 Compiling contracts..."
npx hardhat compile --force --quiet

ZRC20_ETHEREUM=$(jq -r '.addresses[] | select(.type=="ZRC-20 ETH on 5") | .address' localnet.json)
ZRC20_BNB=$(jq -r '.addresses[] | select(.type=="ZRC-20 BNB on 97") | .address' localnet.json)
GATEWAY_ZETACHAIN=$(jq -r '.addresses[] | select(.type=="gatewayZEVM" and .chain=="zetachain") | .address' localnet.json)
GATEWAY_ETHEREUM=$(jq -r '.addresses[] | select(.type=="gatewayEVM" and .chain=="ethereum") | .address' localnet.json)
GATEWAY_BNB=$(jq -r '.addresses[] | select(.type=="gatewayEVM" and .chain=="bnb") | .address' localnet.json)
UNISWAP_ROUTER=$(jq -r '.addresses[] | select(.type=="uniswapRouterInstance" and .chain=="zetachain") | .address' localnet.json)
SENDER=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

CONTRACT_ZETACHAIN=$(npx hardhat msg-back:deploy --name ZetaChainUniversal --network localhost --gateway "$GATEWAY_ZETACHAIN" --uniswap-router "$UNISWAP_ROUTER" --json | jq -r '.contractAddress')
echo -e "\n🚀 Deployed contract on ZetaChain: $CONTRACT_ZETACHAIN"

CONTRACT_ETHEREUM=$(npx hardhat msg-back:deploy --name EVMConnectedNFT --json --network localhost --gateway "$GATEWAY_ETHEREUM" | jq -r '.contractAddress')
echo -e "🚀 Deployed contract on EVM chain: $CONTRACT_ETHEREUM"

CONTRACT_BNB=$(npx hardhat msg-back:deploy --name EVMConnectedNFT --json --network localhost --gateway "$GATEWAY_BNB" | jq -r '.contractAddress')
echo -e "🚀 Deployed contract on BNB chain: $CONTRACT_BNB"

echo -e "\n📮 User Address: $SENDER"

echo -e "\n🔗 Setting universal and connected contracts..."
npx hardhat msg-back:set-universal --network localhost --contract "$CONTRACT_ETHEREUM" --universal "$CONTRACT_ZETACHAIN" --json &>/dev/null
npx hardhat msg-back:set-universal --network localhost --contract "$CONTRACT_BNB" --universal "$CONTRACT_ZETACHAIN" --json &>/dev/null
npx hardhat msg-back:set-connected --network localhost --contract "$CONTRACT_ZETACHAIN" --connected "$CONTRACT_ETHEREUM" --zrc20 "$ZRC20_ETHEREUM" --json &>/dev/null
npx hardhat msg-back:set-connected --network localhost --contract "$CONTRACT_ZETACHAIN" --connected "$CONTRACT_BNB" --zrc20 "$ZRC20_BNB" --json &>/dev/null

npx hardhat localnet-check

echo -e "\nTransferring message from: Ethereum → BNB (which sends the result back to Ethereum). Input is 10."
npx hardhat msg-back:transfer --network localhost --json --amount 10 --from "$CONTRACT_ETHEREUM" --to "$ZRC20_BNB" --gas-amount 1

npx hardhat localnet-check
