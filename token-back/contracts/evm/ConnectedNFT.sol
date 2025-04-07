// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

// Import the Universal Token core contract
import "./ConnectedNFTCore.sol";

contract ConnectedNFT is
    Initializable,
    OwnableUpgradeable,
    ConnectedNFTCore // Inherit the Universal Token core contract
{

    function initialize(
        address initialOwner,
        string memory name,
        string memory symbol,
        address payable gatewayAddress, // Include EVM gateway address
        uint256 gas // Set gas limit for universal Token transfers
    ) public 
    initializer 
    {
        __ERC721_init(name, symbol);
        __Ownable_init(initialOwner);
        __UniversalCore_init(gatewayAddress, address(this), gas); // Initialize the Universal Token core contract
    }
}
