// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@zetachain/protocol-contracts/contracts/zevm/interfaces/UniversalContract.sol";
import "@zetachain/protocol-contracts/contracts/zevm/interfaces/IGatewayZEVM.sol";
import "@zetachain/protocol-contracts/contracts/zevm/GatewayZEVM.sol";
import {SwapHelperLib} from "@zetachain/toolkit/contracts/SwapHelperLib.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

// Import the Universal core contract
import "./UniversalCore.sol";

contract Universal is
    Initializable,
    OwnableUpgradeable,
    UniversalCore // Inherit the Universal Token core contract
{

    function initialize(
        address initialOwner,
        string memory name, // we're using the same deploy task for Universal.sol and ConnectedNFT.sol so we'll keep this here.
        string memory symbol,
        address payable gatewayAddress, // Include EVM gateway address
        uint256 gas, // Set gas limit
        address uniswapRouterAddress // Uniswap v2 router address for gas token swaps
    ) public 
    initializer 
    {
        __Ownable_init(initialOwner);
        __UniversalCore_init(gatewayAddress, gas, uniswapRouterAddress); // Initialize the Universal Token core contract
    }

    receive() external payable {}
}
