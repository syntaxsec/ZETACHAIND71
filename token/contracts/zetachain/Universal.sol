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

// Import the Universal NFT core contract
import "./UniversalCore.sol";

contract UniversalToken is
    Initializable,
    OwnableUpgradeable,
    UniversalCore // Inherit theUniversal NFT core contract
{

    function initialize(
        address initialOwner,
        string memory name, // we're using the same deploy task for Universal.sol and ConnectedNFT.sol so we'll keep this here.
        string memory symbol,
        address payable gatewayAddress, // Include EVM gateway address
        uint256 gas, // Set gas limit forUniversal NFT transfers
        address uniswapRouterAddress // Uniswap v2 router address for gas token swaps
    ) public 
    initializer 
    {
        __Ownable_init(initialOwner);
        __UniversalCore_init(gatewayAddress, gas, uniswapRouterAddress); // Initialize theUniversal NFT core contract
    }

    receive() external payable {}
}
