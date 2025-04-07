// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@zetachain/protocol-contracts/contracts/evm/GatewayEVM.sol";
import {RevertOptions} from "@zetachain/protocol-contracts/contracts/evm/GatewayEVM.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {console} from "hardhat/console.sol";
import {ERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";

import "../shared/UniversalTokenEvents.sol";

/**
 * @title UniversalTokenCore
 * @dev This abstract contract provides the core logic for Universal Tokens. It is designed
 *      to be imported into an OpenZeppelin-based ERC20 implementation, extending its
 *      functionality with cross-chain token transfer capabilities via GatewayEVM. This
 *      contract facilitates cross-chain token transfers to and from EVM-based networks.
 *      It's important to set the universal contract address before making cross-chain transfers.
 */
abstract contract ConnectedNFTCore is
    // ERC20Upgradeable,
    ERC721Upgradeable,

    OwnableUpgradeable,
    UniversalTokenEvents
{
    // Address of the EVM gateway contract
    GatewayEVM public gateway;

    // The address of the Universal Token contract on ZetaChain. This contract serves
    // as a key component for handling all cross-chain transfers while also functioning
    // as an ERC-20 Universal Token.
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
    // onlyOwner 
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
    // onlyOwner 
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
    // onlyOwner 
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
    function __UniversalTokenCore_init(
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

    struct Msg {
        uint16 amount;
        bool isResult;
    }

    /**
     * @notice Transfers tokens to another chain.
     * @dev Burns the tokens locally, then uses the Gateway to send a message to
     *      mint the same tokens on the destination chain. If the destination is the zero
     *      address, transfers the tokens to ZetaChain.
     * @param destination The ZRC-20 address of the gas token of the destination chain.
     * @param receiver The address on the destination chain that will receive the tokens.
     * @param amount The amount of tokens to transfer.
     */
    function transferCrossChain(
        address destination,
        address receiver,
        uint256 amount
    ) external payable {
        if (receiver == address(0)) revert InvalidAddress();

        console.log("!!!!!! Prepare: Connected -> ZetaChain");
        // console.log("!!!!!! Here are the arguments (destination, receiver, amount)", destination, receiver, amount);
        console.log("!!!!!! We will be doing a costly computation. This is represented by running a for loop.");
        // console.log("!!!!!! btw: (tx.origin, msg.sender) = ", tx.origin, msg.sender);

        uint256 x = 0;
        for (uint256 i = 0; i < 1000; i++) {
            x += i;
        }

        console.log("!!!!!! Here instead of sending the amount, we send a struct that contains amount and a boolean isResult. It's default to false and only true when we are sending back the result.");
        bytes memory message = abi.encode(
            destination,
            receiver,
            Msg(uint16(amount), false),
            msg.sender
        );

        emit TokenTransfer(destination, receiver, amount);

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

    function transferCrossChain2(
        address destination,
        address receiver,
        uint256 amount
    ) external payable {
        if (receiver == address(0)) revert InvalidAddress();

        console.log("!!!!!! Preparing to send message cross chain, the second time.");

        bytes memory message = abi.encode(
            destination,
            receiver,
            Msg(uint16(0), true),
            msg.sender
        );

        emit TokenTransfer(destination, receiver, amount);

        if (destination == address(0)) {
            console.log("destination doesnt make sense, it's 0...");
        } else {
            console.log("!!!!!! Preparing to deposit this amount of gas fee ", amount, ", and do a call to zetachain.");

            gateway.depositAndCall{value: amount}(
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
     * @notice Mints tokens in response to an incoming cross-chain transfer.
     * @dev Called by the Gateway upon receiving a message.
     * @param context The message context.
     * @param message The encoded message containing information about the tokens.
     * @return A constant indicating the function was successfully handled.
     */
    function onCall(
        MessageContext calldata context,
        bytes calldata message
    ) external payable onlyGateway returns (bytes4) {
        console.log("!!!!!! On destination chain");
        // console.log("!!!!!! btw (tx.origin, msg.sender) = ", tx.origin, msg.sender);
        if (context.sender != universal) revert Unauthorized();
        (
            address receiver,
            Msg memory mymsg,
            uint256 gasAmount,
            address sender
        ) = abi.decode(message, (address, Msg, uint256, address));
        
        if (!mymsg.isResult) {
            if (mymsg.amount <= 100) {
                console.log("!!!!! minted because 100 >= ", mymsg.amount);
                _safeMint(receiver, nextTokenId++);
            } else {
                console.log("!!!!! not minted because 100 < ", mymsg.amount);
            }
            mymsg.isResult = true;
            // console.log("sending with arguments (tx.origin, sender) = ", tx.origin, sender);
            console.log("!!!!! Connected -> Zetachain. Instead of transferring the remaining gas fees to the sender, we use this as the gas fee to send the result back.");

            this.transferCrossChain2(
                0x91d18e54DAf4F677cB28167158d6dd21F6aB3921,
                tx.origin,
                gasAmount
            );
            return "";
            
        } else {
            console.log("!!!!! We arrived on the Connected chain with the result. This is the end of our trip :)");
        }
        
        console.log("!!!!! Send left over gas back to sender. This is being paid in the current chain's token. gasAmount = ", gasAmount);
        if (gasAmount > 0) {
            if (sender == address(0)) revert InvalidAddress();
            (bool success, ) = payable(sender).call{value: gasAmount}("");
            if (!success) revert GasTokenTransferFailed();
        }
        // emit TokenTransferReceived(receiver, amount);
        return "";
    }

    /**
     * @notice Mints tokens and sends them back to the sender if a cross-chain transfer fails.
     * @dev Called by the Gateway if a call fails.
     * @param context The revert context containing metadata and revert message.
     */
    function onRevert(RevertContext calldata context) external onlyGateway {
        (uint256 amount, address sender) = abi.decode(
            context.revertMessage,
            (uint256, address)
        );
        // _mint(sender, amount);
        // if (context.amount > 0) {
        //     (bool success, ) = payable(sender).call{value: context.amount}("");
        //     if (!success) revert GasTokenRefundFailed();
        // }
        emit TokenTransferReverted(
            sender,
            amount,
            address(0), // gas token
            context.amount
        );
    }

    receive() external payable {}
}
