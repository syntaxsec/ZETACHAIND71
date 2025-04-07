// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

contract CrossChainMessagingEvents {
    event SetUniversal(address indexed universalAddress);
    event SetConnected(address indexed zrc20, address contractAddress);
    event MessageTransfer(
        address indexed destination,
        address indexed receiver,
        uint256 amount
    );
    event MessageTransferReceived(address indexed receiver, uint256 amount);
    event MessageTransferReverted(
        address indexed sender,
        uint256 amount,
        address refundAsset,
        uint256 refundAmount
    );
    event MessageTransferAborted(
        address indexed sender,
        uint256 amount,
        address refundAsset,
        uint256 refundAmount
    );
    event MessageTransferToDestination(
        address indexed destination,
        address indexed sender,
        uint256 amount
    );
}
