// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import './PriceAggregator.sol';

contract SwapToEth {

    ISwapRouter public swapRouter;
    PriceAggregator priceAggregator;

    // address public constant DAI = 0xaD6D458402F60fD3Bd25163575031ACDce07538D;
    address public constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address public constant WETHPricefeed = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    // set the pool fee to 0.3%.
    uint24 public constant poolFee = 3000;

    // mapping for storing the WETH balance of an address
    mapping(address => uint256) ethBalance;

    constructor(ISwapRouter _swapRouter, address _priceAggregator) {
        swapRouter = _swapRouter;
        priceAggregator = PriceAggregator(_priceAggregator);
    }

    /** @notice swapExactInputSingle swaps a fixed amount of token for a maximum possible amount of WETH
    * using the token/WETH9 0.3% pool by calling `exactInputSingle` in the swap router.
    * @dev The calling address must approve this contract to spend at least `amountIn` worth of its token for this function to succeed.
    * @param amountIn The exact amount of DAI that will be swapped for WETH.
    * @param token address of the token that has to be swapped for WETH
    * @param priceFeed chainlink pricefeed for fetching the current rate
    * @return amountOut The amount of WETH received.
    */
    function swapExactInputSingle(uint256 amountIn, address token, address priceFeed) external returns (uint256 amountOut) {
        // msg.sender must approve this contract

        // Transfer the specified amount of token to this contract.
        TransferHelper.safeTransferFrom(token, msg.sender, address(this), amountIn);

        // Approve the router to spend token.
        TransferHelper.safeApprove(token, address(swapRouter), amountIn);

        // Using oracle to fetch the current rate to set amountOutMinimum.
        uint256 amountOutMinimum = getCurrentRate(amountIn, priceFeed);
        
        // We also set the sqrtPriceLimitx96 to be 0 to ensure we swap our exact input amount.
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: token,
                tokenOut: WETH,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        amountOut = swapRouter.exactInputSingle(params);
        ethBalance[msg.sender] += amountOut;
    }

    /**
    * @notice function for retrieving the accumulated eth
    * @dev this function will trasnfer the accumualted eth of particular user
    * @dev check the balance; if zero revert
     */
     function claimEth() external {
        uint256 balance = ethBalance[msg.sender];
        require(balance > 0, "SwapToEth: no balance to transfer");
        // transfer the accumulated balance
        ethBalance[msg.sender] = 0;
        TransferHelper.safeTransfer(WETH, msg.sender, balance);
     }

    /**
    * @notice function for fetching the current usd rate from oracle
    * @dev this function will compute the minmium output amount
    * @param amountIn token amount
    * @param priceFeed chailink pricefeed for the token
    * @return amountMinOut return the minimum WETH amount
     */
     function getCurrentRate(uint256 amountIn, address priceFeed) internal view returns (uint256 amountMinOut) {
         uint256 tokenPrice = uint256(priceAggregator.getLatestPrice(priceFeed));
         uint256 WETHPrice = uint256(priceAggregator.getLatestPrice(WETHPricefeed));
         amountMinOut = (amountIn * tokenPrice * priceAggregator.decimals(WETHPricefeed))/(WETHPrice * priceAggregator.decimals(priceFeed));
     }
}