// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@zetachain/protocol-contracts/contracts/evm/GatewayEVM.sol";
import "@zetachain/protocol-contracts/contracts/Revert.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BaseSepoliaContract {
    using SafeERC20 for IERC20;
    
    GatewayEVM public immutable gateway;
    address public zetaChainContractAddress;
    uint256 public threshold = 100; // example
    
    event ConditionResult(bool result, address recipient);
    event MessageSent(address indexed to, bool result, address recipient);
    
    constructor(address payable gatewayAddress, address _zetaChainContractAddress) {
        gateway = GatewayEVM(gatewayAddress);
        zetaChainContractAddress = _zetaChainContractAddress;
    }
    
    function checkConditionAndSend(uint256 value, address nftRecipient) external payable {
        bool result = value >= threshold;
        
        emit ConditionResult(result, nftRecipient);

        bytes memory message = abi.encode(result, nftRecipient);

        
        RevertOptions memory revertOptions = RevertOptions({
            revertAddress: msg.sender,
            callOnRevert: false,
            abortAddress: address(0x2ca7d64A7EFE2D62A725E2B35Cf7230D6677FfEe),
            revertMessage: message,
            onRevertGasLimit: 500000
        });
        
        // Send message to ZetaChain
        gateway.call(
            zetaChainContractAddress,
            message,
            revertOptions
        );
        
        emit MessageSent(zetaChainContractAddress, result, nftRecipient);
    }
}