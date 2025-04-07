// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {ERC20PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

// Import the Universal NFT core contract
import "./ConnectedNFTCore.sol";

contract ConnectedNFT is
    Initializable,
    OwnableUpgradeable,
    ConnectedNFTCore // Inherit theUniversal NFT core contract
{

    function initialize(
        address initialOwner,
        string memory name,
        string memory symbol,
        address payable gatewayAddress, // Include EVM gateway address
        uint256 gas // Set gas limit forUniversal NFT transfers
    ) public 
    initializer 
    {
        __ERC721_init(name, symbol);
        __Ownable_init(initialOwner);
        __UniversalCore_init(gatewayAddress, address(this), gas); // Initialize theUniversal NFT core contract
    }
}
