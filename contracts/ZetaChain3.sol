// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {RevertContext, RevertOptions} from "@zetachain/protocol-contracts/contracts/Revert.sol";
import "@zetachain/protocol-contracts/contracts/zevm/interfaces/UniversalContract.sol";
import "@zetachain/protocol-contracts/contracts/zevm/interfaces/IGatewayZEVM.sol";
import "@zetachain/protocol-contracts/contracts/zevm/interfaces/IZRC20.sol";
import "@zetachain/protocol-contracts/contracts/zevm/GatewayZEVM.sol";
import "hardhat/console.sol";

contract ZetaChainContract3 is UniversalContract {
    GatewayZEVM public immutable gateway;
    address public sepoliaContractAddress;
    
    event MessageReceived(string origin, bool result, address recipient);
    event MessageForwarded(address indexed to, bool result, address recipient);
    event RevertEvent(string message, RevertContext context);
    event DebugLog(string message, uint256 value);
    event DebugAddr(string message, address addr);
    
    error InvalidAddress();
    error Unauthorized();
    error TransferFailed();
    error ApprovalFailed();
    
    modifier onlyGateway() {
        if (msg.sender != address(gateway)) revert Unauthorized();
        _;
    }
    
    constructor(address payable gatewayAddress, address _sepoliaContractAddress) {
        if (gatewayAddress == address(0) || _sepoliaContractAddress == address(0)) 
            revert InvalidAddress();
        gateway = GatewayZEVM(gatewayAddress);
        sepoliaContractAddress = _sepoliaContractAddress;
    }
    
    function onCall(
        MessageContext calldata context,
        address zrc20,
        uint256 amount,
        bytes calldata message
    ) external override onlyGateway {
        (bool result, address nftRecipient) = abi.decode(message, (bool, address));
        
        emit MessageReceived(string(context.origin), result, nftRecipient);
        emit DebugLog("Received amount", amount);
        emit DebugAddr("ZRC20 token", zrc20);
        emit DebugAddr("Original sender", context.sender);
        
        // Forward the message to Sepolia
        forwardToSepolia(result, nftRecipient, context.sender, zrc20);
    }
    
    // Forward message to Sepolia
    function forwardToSepolia(bool result, address recipient, address originalSender, address zrc20) internal {
        bytes memory message = abi.encode(result, recipient);
        
        // If no ZRC20 token was provided, use the default Sepolia ZRC20
        if (zrc20 == address(0)) {
            zrc20 = address(0x2ca7d64A7EFE2D62A725E2B35Cf7230D6677FfEe);
        }
        
        // Convert contract address to bytes
        bytes memory receiverAddress = abi.encodePacked(sepoliaContractAddress);
        
        // Set up call options
        CallOptions memory callOptions = CallOptions({
            gasLimit: 300000,
            isArbitraryCall: false
        });
        
        // Set up revert options
        RevertOptions memory revertOptions = RevertOptions({
            revertAddress: originalSender, // Send revert back to original sender
            callOnRevert: false,
            abortAddress: address(0),
            revertMessage: message,
            onRevertGasLimit: 100000
        });
        
        // Send the message to Sepolia
        gateway.call(
            receiverAddress,
            zrc20,
            message,
            callOptions,
            revertOptions
        );
        
        emit MessageForwarded(sepoliaContractAddress, result, recipient);
    }
    
    function onRevert(
        RevertContext calldata revertContext
    ) external onlyGateway {
        emit RevertEvent("Revert on ZetaChain", revertContext);
    }
}