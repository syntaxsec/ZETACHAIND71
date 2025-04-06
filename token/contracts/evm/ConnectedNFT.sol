// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {ERC20BurnableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import {ERC20PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PausableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

// Import the Universal Token core contract
import "./ConnectedNFTCore.sol";

contract ConnectedNFT is
    Initializable,
    // ERC20Upgradeable,
    // ERC20BurnableUpgradeable,
    // ERC20PausableUpgradeable,
    // PausableUpgradeable,
    OwnableUpgradeable,
    // UUPSUpgradeable,
    // ERC721Upgradeable,
    ConnectedNFTCore // Inherit the Universal Token core contract
{
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address initialOwner,
        string memory name,
        string memory symbol,
        address payable gatewayAddress, // Include EVM gateway address
        uint256 gas // Set gas limit for universal Token transfers
    ) public 
    initializer 
    {
        // __ERC20_init(name, symbol);
        // __ERC20Burnable_init();
        // __ERC20Pausable_init();
        __ERC721_init(name, symbol);
        __Ownable_init(initialOwner);
        // __UUPSUpgradeable_init();
        __UniversalTokenCore_init(gatewayAddress, address(this), gas); // Initialize the Universal Token core contract
    }

    // function safeMint(
    //     address to,
    //     string memory uri
    // ) public onlyOwner whenNotPaused {
    //     // Generate globally unique token ID, feel free to supply your own logic
    //     uint256 hash = uint256(
    //         keccak256(
    //             abi.encodePacked(address(this), block.number, _nextTokenId++)
    //         )
    //     );

    //     uint256 tokenId = hash & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    //     _safeMint(to, tokenId);
    //     // _setTokenURI(tokenId, uri);
    // }

    // function pause() public onlyOwner {
    //     _pause();
    // }

    // function unpause() public onlyOwner {
    //     _unpause();
    // }

    // function mint(address to, uint256 amount) public onlyOwner {
    //     _mint(to, amount);
    // }

    // function _authorizeUpgrade(
    //     address newImplementation
    // ) internal override onlyOwner {}

    // // The following functions are overrides required by Solidity.

    // function _update(
    //     address from,
    //     address to,
    //     uint256 value
    // ) internal override(ERC20Upgradeable, ERC20PausableUpgradeable) {
    //     super._update(from, to, value);
    // }
}
