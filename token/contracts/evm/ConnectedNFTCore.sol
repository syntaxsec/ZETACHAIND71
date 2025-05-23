// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@zetachain/protocol-contracts/contracts/evm/GatewayEVM.sol";
import {RevertOptions} from "@zetachain/protocol-contracts/contracts/evm/GatewayEVM.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {console} from "hardhat/console.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import "../shared/CrossChainMessageEvents.sol";

/**
 * @title UniversalNFTCore
 * @dev This abstract contract provides the core logic for Connected NFT Tokens. It is designed
 *      to be imported into an OpenZeppelin-based ERC721 implementation, extending its
 *      functionality with cross-chain token transfer capabilities via GatewayEVM. This
 *      contract facilitates cross-chain message transfers to and from EVM-based networks, and
 *      minting of NFTs based on the transferred message. It's important to set the universal 
 *      contract address before making cross-chain transfers.
 */
abstract contract ConnectedNFTCore is
    // ERC20Upgradeable,
    ERC721Upgradeable,

    OwnableUpgradeable,
    CrossChainMessageEvents
{
    // Address of the EVM gateway contract
    GatewayEVM public gateway;

    // The address of the Universal contract on ZetaChain. This contract serves
    // as a key component for handling all cross-chain transfers.
    address public universal;
    uint256 public nextTokenId;

    // The amount of gas used when making cross-chain transfers
    uint256 public gasLimitAmount;

    error InvalidAddress();
    error Unauthorized();
    error InvalidGasLimit();
    error GasTokenTransferFailed();
    error GasTokenRefundFailed();
    error TransferToZetaChainRequiresNoGas();

    /**
     * @dev Ensures that the function can only be called by the Gateway contract.
     */
    modifier onlyGateway() {
        if (msg.sender != address(gateway)) revert Unauthorized();
        _;
    }

    /**
     * @notice Sets the gas limit for cross-chain transfers.
     * @dev Can only be called by the contract owner.
     * @param gas New gas limit value.
     */
    function setGasLimit(uint256 gas) external 
    onlyOwner 
    {
        if (gas == 0) revert InvalidGasLimit();
        gasLimitAmount = gas;
    }

    /**
     * @notice Sets the universal contract address.
     * @dev Can only be called by the contract owner.
     * @param contractAddress The address of the universal contract.
     */
    function setUniversal(address contractAddress) external 
    onlyOwner 
    {
        if (contractAddress == address(0)) revert InvalidAddress();
        universal = contractAddress;
        emit SetUniversal(contractAddress);
    }

    /**
     * @notice Sets the EVM gateway contract address.
     * @dev Can only be called by the contract owner.
     * @param gatewayAddress The address of the gateway contract.
     */
    function setGateway(address gatewayAddress) external 
    onlyOwner 
    {
        if (gatewayAddress == address(0)) revert InvalidAddress();
        gateway = GatewayEVM(gatewayAddress);
    }

    /**
     * @notice Initializes the contract with gateway, universal, and gas limit settings.
     * @dev To be called during contract deployment.
     * @param gatewayAddress The address of the gateway contract.
     * @param universalAddress The address of the universal contract.
     * @param gasLimit The gas limit to set.
     */
    function __UniversalCore_init(
        address gatewayAddress,
        address universalAddress,
        uint256 gasLimit
    ) internal {
        if (gatewayAddress == address(0)) revert InvalidAddress();
        if (universalAddress == address(0)) revert InvalidAddress();
        if (gasLimit == 0) revert InvalidGasLimit();
        gateway = GatewayEVM(gatewayAddress);
        universal = universalAddress;
        gasLimitAmount = gasLimit;
        nextTokenId = 1;
    }

    /**
     * @notice Transfers message to another chain.
     * @dev Does a costly computation and pass the result to zetachain.
     * @param destination The ZRC-20 address of the gas token of the destination chain.
     * @param receiver The address on the destination chain that will receive the tokens.
     * @param amount Our input.
     */
    function transferCrossChain(
        address destination,
        address receiver,
        uint256 amount
    ) external payable {
        if (receiver == address(0)) revert InvalidAddress();

        console.log("!!!!!! Preparing to send message cross chain.");
        console.log("!!!!!! Here are the arguments (destination, receiver, amount)", destination, receiver, amount);
        console.log("!!!!!! We will be doing a costly computation. This is represented by running a for loop.");
        console.log("!!!!!! btw: (tx.origin, msg.sender) = ", tx.origin, msg.sender);

        uint256 x = 0;
        for (uint256 i = 0; i < 1000; i++) {
            x += i;
        }

        bytes memory message = abi.encode(
            destination,
            receiver,
            amount,
            msg.sender
        );

        emit MessageTransfer(destination, receiver, amount);

        if (destination == address(0)) {
            console.log("destination doesnt make sense, it's 0...");
        } else {
            console.log("!!!!!! Preparing to deposit this amount of gas fee ", msg.value, ", and do a call to zetachain.");

            gateway.depositAndCall{value: msg.value}(
                universal,
                message,
                RevertOptions(
                    address(this),
                    true,
                    universal,
                    abi.encode(amount, msg.sender),
                    gasLimitAmount
                )
            );
        }
    }

    /**
     * @notice Mints NFTs in response to an incoming cross-chain message.
     * @dev Called by the Gateway upon receiving a message.
     * @param context The message context.
     * @param message The encoded message containing information about the tokens.
     * @return A constant indicating the function was successfully handled.
     */
    function onCall(
        MessageContext calldata context,
        bytes calldata message
    ) external payable onlyGateway returns (bytes4) {
        if (context.sender != universal) revert Unauthorized();
        (
            address receiver,
            uint256 amount,
            uint256 gasAmount,
            address sender
        ) = abi.decode(message, (address, uint256, uint256, address));
        console.log("!!!!!! On destination chain, btw (tx.origin, msg.sender, sender) = ", tx.origin, msg.sender, sender);
        if (amount <= 100) {
            console.log("!!!! minted because 100 >= ", amount);
            _safeMint(receiver, nextTokenId++);
        } else {
            console.log("!!!! not minted because 100 <", amount);
        }

        console.log("!!!!! Send left over gas back to sender. This is being paid in the current chain's token. gasAmount = ", gasAmount);
        if (gasAmount > 0) {
            if (sender == address(0)) revert InvalidAddress();
            (bool success, ) = payable(sender).call{value: gasAmount}("");
            if (!success) revert GasTokenTransferFailed();
        }
        emit MessageTransferReceived(receiver, amount);
        return "";
    }

    /**
     * @notice Emits an event when a cross-chain transfer is reverted.
     * @dev Called by the Gateway if a call fails.
     * @param context The revert context containing metadata and revert message.
     */
    function onRevert(RevertContext calldata context) external onlyGateway {
        (uint256 amount, address sender) = abi.decode(
            context.revertMessage,
            (uint256, address)
        );

        emit MessageTransferReverted(
            sender,
            amount,
            address(0), // gas token
            context.amount
        );
    }

    receive() external payable {}
}
