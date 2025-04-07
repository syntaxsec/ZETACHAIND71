// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@zetachain/protocol-contracts/contracts/zevm/interfaces/UniversalContract.sol";
import "@zetachain/protocol-contracts/contracts/zevm/interfaces/IGatewayZEVM.sol";
import "@zetachain/protocol-contracts/contracts/zevm/interfaces/IWZETA.sol";
import "@zetachain/protocol-contracts/contracts/zevm/GatewayZEVM.sol";
import {SwapHelperLib} from "@zetachain/toolkit/contracts/SwapHelperLib.sol";
import {console} from "hardhat/console.sol";

import "../shared/CrossChainMessageEvents.sol";

/**
 * @title UniversalCore
 * @dev This contract facilitates cross-chain message transfers to and from ZetaChain and other
 *      connected EVM-based networks.
 */
abstract contract UniversalCore is
    UniversalContract,
    OwnableUpgradeable,
    CrossChainMessageEvents
{
    // Indicates this contract implements a Universal Contract
    bool public constant isUniversal = true;

    // Address of the ZetaChain Gateway contract
    GatewayZEVM public gateway;

    // Address of the Uniswap Router for token swaps
    address public uniswapRouter;

    // Gas limit for cross-chain operations
    uint256 public gasLimitAmount;

    // Mapping of connected ZRC20 tokens to their respective contracts
    mapping(address => address) public connected;

    error TransferFailed();
    error Unauthorized();
    error InvalidAddress();
    error InvalidGasLimit();
    error ApproveFailed();
    error ZeroMsgValue();
    error TokenRefundFailed();

    modifier onlyGateway() {
        if (msg.sender != address(gateway)) revert Unauthorized();
        _;
    }

    /**
     * @notice Sets the ZetaChain gateway contract address.
     * @dev Can only be called by the contract owner.
     * @param gatewayAddress The address of the gateway contract.
     */
    function setGateway(address gatewayAddress) external onlyOwner {
        if (gatewayAddress == address(0)) revert InvalidAddress();
        gateway = GatewayZEVM(payable(gatewayAddress));
    }

    /**
     * @notice Initializes the contract.
     * @dev Should be called during contract deployment.
     * @param gatewayAddress Address of the Gateway contract.
     * @param gasLimit Gas limit for cross-chain calls.
     * @param uniswapRouterAddress Address of the Uniswap router contract.
     */
    function __UniversalCore_init(
        address gatewayAddress,
        uint256 gasLimit,
        address uniswapRouterAddress
    ) internal {
        if (gatewayAddress == address(0) || uniswapRouterAddress == address(0))
            revert InvalidAddress();
        if (gasLimit == 0) revert InvalidGasLimit();
        gateway = GatewayZEVM(payable(gatewayAddress));
        uniswapRouter = uniswapRouterAddress;
        gasLimitAmount = gasLimit;
    }

    /**
     * @notice Sets the gas limit for cross-chain transfers.
     * @dev Can only be called by the contract owner.
     * @param gas New gas limit value.
     */
    function setGasLimit(uint256 gas) external onlyOwner {
        if (gas == 0) revert InvalidGasLimit();
        gasLimitAmount = gas;
    }

    /**
     * @notice Links a ZRC20 gas token address to a contract on the corresponding chain.
     * @dev Can only be called by the contract owner.
     * @param zrc20 Address of the ZRC20 token.
     * @param contractAddress Address of the corresponding contract.
     */
    function setConnected(
        address zrc20,
        address contractAddress
    ) external onlyOwner {
        if (zrc20 == address(0)) revert InvalidAddress();
        if (contractAddress == address(0)) revert InvalidAddress();
        connected[zrc20] = contractAddress;
        emit SetConnected(zrc20, contractAddress);
    }

    /**
     * @notice Handles cross-chain message transfers.
     * @dev This function is called by the Gateway contract upon receiving a message.
     *      If the destination is ZetaChain, do nothing.
     *      If the destination is another chain, swap the gas token for the corresponding
     *      ZRC20 token and use the Gateway to send a message to the destination chain.
     * @param context Message context metadata.
     * @param zrc20 ZRC20 token address.
     * @param amount We aren't using this
     * @param message Encoded payload containing token transfer metadata.
     */
    function onCall(
        MessageContext calldata context,
        address zrc20,
        uint256 amount,
        bytes calldata message
    ) external override onlyGateway {
        console.log("!!!!!! Received on zetachain!");
        if (context.sender != connected[zrc20]) revert Unauthorized();
        (
            address destination,
            address receiver,
            uint256 tokenAmount,
            address sender
        ) = abi.decode(message, (address, address, uint256, address));
        console.log("!!!!!! Arguments are: (receiver, tokenAmount, sender) = ", receiver, tokenAmount, sender);
        console.log("!!!!!! btw: (tx.origin, msg.sender) = ", tx.origin, msg.sender);


        if (destination == address(0)) {
            console.log("!!!!!! We're on the destination chain (zetachain). This isn't intended for forwarding purposes");
        } else {
            console.log("!!!!!! Prepare to get gas fees");
            (address gasZRC20, uint256 gasFee) = IZRC20(destination)
                .withdrawGasFeeWithGasLimit(gasLimitAmount);
            console.log("!!!!!! what we get: (gasZRC20, gasFee) = ", gasZRC20, gasFee, " (gasZRC20 is our destination zrc20 token address)");
            
            if (destination != gasZRC20) revert InvalidAddress();

            console.log("!!!!!! preparing to uniswap");
            console.log("!!!!!! we're swapping 'amount' of 'zrc20' to 'targetZRC20', where (zrc20, amount, targetZRC20) = ", zrc20, amount, destination);
            uint256 out = SwapHelperLib.swapExactTokensForTokens(
                uniswapRouter,
                zrc20,
                amount,
                destination,
                0
            );
            console.log("!!!!!! Got 'targetZRC20' amount ", out);
            console.log("!!!!!! approving the gateway to spend the tokens on our behalf");

            if (!IZRC20(destination).approve(address(gateway), out)) {
                revert ApproveFailed();
            }
            console.log("!!!!!! Preparing to withdraw and call. This will call the connected chain.");

            gateway.withdrawAndCall(
                abi.encodePacked(connected[destination]),
                out - gasFee,
                destination,
                abi.encode(receiver, tokenAmount, out - gasFee, sender),
                CallOptions(gasLimitAmount, false),
                RevertOptions(
                    address(this),
                    true,
                    address(0),
                    abi.encode(receiver, tokenAmount, sender),
                    0
                )
            );
        }
        emit MessageTransferToDestination(destination, receiver, amount);
    }

    /**
     * @notice Handles a cross-chain call failure and reverts the token transfer.
     * @param context Metadata about the failed call.
     */
    function onRevert(RevertContext calldata context) external onlyGateway {
        (, uint256 amount, address sender) = abi.decode(
            context.revertMessage,
            (address, uint256, address)
        );
        // _mint(sender, amount);
        emit MessageTransferReverted(
            sender,
            amount,
            context.asset,
            context.amount
        );
    }

    function onAbort(AbortContext calldata context) external onlyGateway {
        (, uint256 amount, address sender) = abi.decode(
            context.revertMessage,
            (address, uint256, address)
        );
        // _mint(sender, amount);
        emit MessageTransferAborted(
            sender,
            amount,
            context.asset,
            context.amount
        );

    }
}
