// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DEX Template
 * @author stevepham.eth and m00npapi.eth
 * @notice Empty DEX.sol that just outlines what features could be part of the challenge (up to you!)
 * @dev We want to create an automatic market where our contract will hold reserves of both ETH and 🎈 Balloons. These reserves will provide liquidity that allows anyone to swap between the assets.
 * NOTE: functions outlined here are what work with the front end of this challenge. Also return variable names need to be specified exactly may be referenced (It may be helpful to cross reference with front-end code function calls).
 */
contract DEX {
    /* ========== GLOBAL VARIABLES ========== */
    IERC20 token; //instantiates the imported contract
    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidity;

    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when ethToToken() swap transacted
     */
    event EthToTokenSwap(address swapper, uint256 tokenOutput, uint256 ethInput);

    /**
     * @notice Emitted when tokenToEth() swap transacted
     */
    event TokenToEthSwap(address swapper, uint256 tokensInput, uint256 ethOutput);

    /**
     * @notice Emitted when liquidity provided to DEX and mints LPTs.
     */
    event LiquidityProvided(address liquidityProvider, uint256 liquidityMinted, uint256 ethInput, uint256 tokensInput);

    /**
     * @notice Emitted when liquidity removed from DEX and decreases LPT count within DEX.
     */
    event LiquidityRemoved(
        address liquidityRemover,
        uint256 liquidityWithdrawn,
        uint256 tokensOutput,
        uint256 ethOutput
    );

    /* ========== CONSTRUCTOR ========== */

    constructor(address tokenAddr) {
        token = IERC20(tokenAddr); //specifies the token address that will hook into the interface and be used through the variable 'token'
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice initializes amount of tokens that will be transferred to the DEX itself from the erc20 contract mintee (and only them based on how Balloons.sol is written). Loads contract up with both ETH and Balloons.
     * @param tokens amount to be transferred to DEX
     * @return totalLiquidity is the number of LPTs minting as a result of deposits made to DEX contract
     * NOTE: since ratio is 1:1, this is fine to initialize the totalLiquidity (wrt to balloons) as equal to eth balance of contract.
     */
    function init(uint256 tokens) external payable returns (uint256) {
        require(totalLiquidity == 0, "DEX already has liquidity");
        require(token.transferFrom(msg.sender, address(this), tokens), "Token Transfer failed.");
        totalLiquidity = msg.value;
        liquidity[msg.sender] = msg.value;
        emit LiquidityProvided(msg.sender, totalLiquidity, msg.value, tokens);
        return totalLiquidity;
    }

    /**
     * @notice returns yOutput, or yDelta for xInput (or xDelta)
     * @dev NOTE: This is the core function of the DEX contract, also called AMM(Automated Market Maker)
     * 1. Pricing model: (x + dx)(y - dy) = xy = k, like Uniswap V2
     *    Thus, dy = y - xy / (x + dx) = y * dx / (x + dx)
     * 2. Since there are no floating-point numbers in Solidty, we should use some math tricks to calculate the 0.3% fee for the LP(Liquidity Provider)
     *    dx = xInput * 997 / 1000, and we should operate `the division` in the last to make the result as precise as possible
     */
    function price(uint256 xInput, uint256 xReserves, uint256 yReserves) public pure returns (uint256 yOutput) {
        uint256 xInputWithoutFee = xInput * 997;
        return (yReserves * xInputWithoutFee) / (1000 * xReserves + xInputWithoutFee);
    }

    /**
     * @notice returns liquidity for a user.
     * NOTE: this is not needed typically due to the `liquidity()` mapping variable being public and having a getter as a result. This is left though as it is used within the front end code (App.jsx).
     * NOTE: if you are using a mapping liquidity, then you can use `return liquidity[lp]` to get the liquidity for a user.
     * NOTE: if you will be submitting the challenge make sure to implement this function as it is used in the tests.
     */
    function getLiquidity(address lp) external view returns (uint256) {
        return liquidity[lp];
    }

    /**
     * @notice sends Ether to DEX in exchange for $BAL
     */
    function ethToToken() external payable returns (uint256 tokenOutput) {
        // 1. Calculate
        require(msg.value > 0, "cannot swap 0 ETH");
        uint256 tokenReserves = token.balanceOf(address(this));
        // IMPORTANT: in payable functions, the paid ETH has already been added to the contract balance
        uint256 ethReserves = address(this).balance - msg.value;
        // NOTE: in Solidity, the "named return variable" is initialized before the function execution
        tokenOutput = price(msg.value, ethReserves, tokenReserves);

        // 2. Transfer
        require(token.transfer(msg.sender, tokenOutput), "ethToToken(): reverted swap");
        emit EthToTokenSwap(msg.sender, tokenOutput, msg.value);
        return tokenOutput;
    }

    /**
     * @notice sends $BAL tokens to DEX in exchange for Ether
     */
    function tokenToEth(uint256 tokenInput) external returns (uint256 ethOutput) {
        // 1. Calculate
        require(tokenInput > 0, "cannot swap 0 tokens");
        uint256 tokenReserves = token.balanceOf(address(this));
        // NOTE: in Solidity, the "named return variable" is initialized before the function execution
        ethOutput = price(tokenInput, tokenReserves, address(this).balance);

        // 2. Transfer
        require(token.transferFrom(msg.sender, address(this), tokenInput), "tokenToEth(): reverted swap");
        (bool success, ) = msg.sender.call{value: ethOutput}("");
        require(success, "tokenToEth(): transfer ETH failed");
        emit TokenToEthSwap(msg.sender, tokenInput, ethOutput);
        return ethOutput;
    }

    /**
     * @notice allows deposits of $BAL and $ETH to liquidity pool
     * NOTE: We want the ratio of $BAL and ETH be unchanged!
     * NOTE: parameter is the msg.value sent with this function call. That amount is used to determine the amount of $BAL needed as well and taken from the depositor.
     * NOTE: user has to make sure to give DEX approval to spend their tokens on their behalf by calling approve function prior to this function call.
     * NOTE: Equal parts of both assets will be removed from the user's wallet with respect to the price outlined by the AMM.
     */
    function deposit() external payable returns (uint256 tokensDeposited) {
        // 1. Calculate
        require(msg.value > 0, "cannot deposit 0 ETH");
        uint256 tokenReserves = token.balanceOf(address(this));
        // IMPORTANT: in payable functions, the paid ETH has already been added to the contract balance
        uint256 ethReserves = address(this).balance - msg.value;
        tokensDeposited = msg.value * tokenReserves / ethReserves;

        // 2. Transfer
        require(token.transferFrom(msg.sender, address(this), tokensDeposited), "deposit tokens failed");
        // In this DEX contract, the liquidity only depends on the ETH amount
        uint256 liquidityMinted = totalLiquidity * msg.value / ethReserves;
        totalLiquidity += liquidityMinted;
        liquidity[msg.sender] += liquidityMinted;
        emit LiquidityProvided(msg.sender, liquidityMinted, msg.value, tokensDeposited);
        return tokensDeposited;
    }

    /**
     * @notice allows withdrawal of $BAL and ETH from liquidity pool
     * @dev The withdraw() function lets a user take his LPT out, withdrawing both ETH and $BAL tokens out at the correct ratio.
     * The actual amount of ETH and $BAL a LP withdraws could be higher than what they deposited because of the 0.3% fees collected from each trade.
     * It also could be lower depending on the price fluctuations of $BAL to ETH and vice versa (from token swaps taking place using the AMM).
     * The 0.3% fee incentivizes third parties to provide liquidity, but they must be cautious of Impermanent Loss(IL).
     * See also: https://www.youtube.com/watch?v=8XJ1MSTEuU0
     */
    function withdraw(uint256 liquidityAmount) external returns (uint256 ethAmount, uint256 tokenAmount) {
        // 1. Calculate
        require(liquidity[msg.sender] >= liquidityAmount, "not enough liquidity to withdraw");
        totalLiquidity -= liquidityAmount;
        liquidity[msg.sender] -= liquidityAmount;
        ethAmount = address(this).balance * liquidityAmount / totalLiquidity;
        tokenAmount = token.balanceOf(address(this)) * liquidityAmount / totalLiquidity;

        // 2. Transfer
        (bool success, ) = msg.sender.call{value: ethAmount}("");
        require(success, "withdraw(): transfer ETH failed");
        require(token.transfer(msg.sender, tokenAmount), "withdraw(): transfer tokens failed");
        emit LiquidityRemoved(msg.sender, liquidityAmount, tokenAmount, ethAmount);
        return (ethAmount, tokenAmount);
    }
}
