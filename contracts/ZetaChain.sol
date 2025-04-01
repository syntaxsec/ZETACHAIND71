// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {RevertContext, RevertOptions} from "@zetachain/protocol-contracts/contracts/Revert.sol";
import "@zetachain/protocol-contracts/contracts/zevm/interfaces/UniversalContract.sol";
import "@zetachain/protocol-contracts/contracts/zevm/interfaces/IGatewayZEVM.sol";
import "@zetachain/protocol-contracts/contracts/zevm/GatewayZEVM.sol";

import "hardhat/console.sol";


contract ZetaChainContract is UniversalContract {
    GatewayZEVM public immutable gateway;
    address public sepoliaContractAddress;
    
    event MessageReceived(string origin, bool result, address recipient);
    event MessageForwarded(address indexed to, bool result, address recipient);
    event RevertEvent(string message, RevertContext context);
    
    error TransferFailed();
    error Unauthorized();
    
    modifier onlyGateway() {
        if (msg.sender != address(gateway)) revert Unauthorized();
        _;
    }
    
    constructor(address payable gatewayAddress, address _sepoliaContractAddress) {
        gateway = GatewayZEVM(gatewayAddress); // zetachain gateway
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
        console.log(result, nftRecipient); // success
        
        // Forward to Sepolia
        forwardToSepolia(result, nftRecipient, zrc20);
    }
    
    // Forward message to Sepolia
    // To be honest I'm not sure if the zrc20 conversion is correct
    function forwardToSepolia(bool result, address recipient, address zrc20) internal {
        bytes memory message = abi.encode(result, recipient);
        
        CallOptions memory callOptions = CallOptions({
            gasLimit: 1000000,
            isArbitraryCall: false
        });
        
        RevertOptions memory revertOptions = RevertOptions({
            revertAddress: address(this),
            callOnRevert: true,
            abortAddress: address(0), // this is the default
            revertMessage: message, 
            onRevertGasLimit: 50000  // these are arbitrary
        });
        
        // for sepolia https://www.zetachain.com/docs/developers/tokens/zrc20/
        // not sure if this is the right way. 
        // address zrc20 = address(0x2ca7d64A7EFE2D62A725E2B35Cf7230D6677FfEe);
        
        // Convert contract address to bytes
        bytes memory receiver = abi.encodePacked(sepoliaContractAddress);

        // These are copied from the Universal.sol contract
        (, uint256 gasFee) = IZRC20(zrc20).withdrawGasFeeWithGasLimit(callOptions.gasLimit);
        if (!IZRC20(zrc20).transferFrom(tx.origin, address(this), gasFee)) {
            revert TransferFailed();
        }
        IZRC20(zrc20).approve(address(gateway), gasFee);
        gateway.call(
            receiver,
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