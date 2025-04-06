// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {RevertContext, RevertOptions} from "@zetachain/protocol-contracts/contracts/Revert.sol";
import "@zetachain/protocol-contracts/contracts/zevm/interfaces/UniversalContract.sol";
import "@zetachain/protocol-contracts/contracts/zevm/interfaces/IGatewayZEVM.sol";
import "@zetachain/protocol-contracts/contracts/zevm/GatewayZEVM.sol";
import {SwapHelperLib} from "@zetachain/toolkit/contracts/SwapHelperLib.sol";
import {ERC20BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

// Import the Universal Token core contract
import "./UniversalCore.sol";

contract UniversalToken is
    Initializable,
    // ERC20Upgradeable,
    // ERC20BurnableUpgradeable,
    // ERC20PausableUpgradeable,
    // PausableUpgradeable,
    OwnableUpgradeable,
    // UUPSUpgradeable,
    UniversalCore // Inherit the Universal Token core contract
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    // constructor() {
    //     _disableInitializers();
    // }

    function initialize(
        address initialOwner,
        string memory name,
        string memory symbol,
        address payable gatewayAddress, // Include EVM gateway address
        uint256 gas, // Set gas limit for universal Token transfers
        address uniswapRouterAddress // Uniswap v2 router address for gas token swaps
    ) public 
    initializer 
    {
        __Ownable_init(initialOwner);
        __UniversalCore_init(gatewayAddress, gas, uniswapRouterAddress); // Initialize the Universal Token core contract
    }

    receive() external payable {}
}
