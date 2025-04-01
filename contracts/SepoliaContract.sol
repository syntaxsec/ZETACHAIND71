// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {RevertContext} from "@zetachain/protocol-contracts/contracts/Revert.sol";
import "@zetachain/protocol-contracts/contracts/evm/GatewayEVM.sol";
import "hardhat/console.sol";


contract SepoliaContract is ERC721 {
    
    GatewayEVM public immutable gateway;
    address public admin;
    
    uint32 private _tokenIdCounter;
    mapping(address => uint256[]) public mintedTokens;
    
    event NFTMinted(address indexed to, uint256 tokenId);
    event MessageReceived(string origin, address recipient, bool result);
    event RevertEvent(string message, RevertContext context);
    
    error Unauthorized();
    
    modifier onlyGateway() {
        if (msg.sender != address(gateway)) revert Unauthorized();
        _;
    }
    
    constructor(
        address payable gatewayAddress
    ) ERC721("CrossChainNFT", "CCNFT") {
        gateway = GatewayEVM(gatewayAddress);
        admin = msg.sender;
    }
    
    // Receive message from ZetaChain
    function onCall(
        MessageContext calldata context,
        bytes calldata message
    ) external payable onlyGateway returns (bytes4) {
        (bool result, address nftRecipient) = abi.decode(message, (bool, address));
        
        emit MessageReceived(string(abi.encodePacked(msg.sender)), nftRecipient, result);
        
        console.log("message successfully sent");
        console.log(result);
        // if (result) {
        //     mintNFT(nftRecipient);
        // }
        
        return "";
    }
    
    // Mint a new NFT to the recipient
    function mintNFT(address recipient) internal {
        uint256 tokenId = _tokenIdCounter++;
        
        _mint(recipient, tokenId);
        mintedTokens[recipient].push(tokenId);
        
        emit NFTMinted(recipient, tokenId);
    }
    
    // Get all tokens owned by an address
    function getTokensByOwner(address owner) external view returns (uint256[] memory) {
        return mintedTokens[owner];
    }
    
    function onRevert(
        RevertContext calldata revertContext
    ) external onlyGateway {
        emit RevertEvent("Revert on Sepolia", revertContext);
    }
    
    // copied from Connected.sol
    receive() external payable {}
    fallback() external payable {}
}