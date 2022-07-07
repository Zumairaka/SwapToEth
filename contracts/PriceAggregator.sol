// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @notice creating a contract for retrieving the latest price
 * of the token
 */

contract PriceAggregator {
    /**
     * @dev using the function latestRoundData from AggregatorV3Interface
     * @param priceFeed address of the pricefeed from where we need
     * to fetch the latest data
     * @return price the price of the token in USD
     */

    function getLatestPrice(address priceFeed) external view returns (int256) {
        (, int256 price, , , ) = AggregatorV3Interface(priceFeed).latestRoundData();
        return price;
    }

    /**
     * @notice to return the decimals of the token
     * @dev use the decimals function in the aggregator contract
     * @param priceFeed address of the pricefeed of which we need
     * to fetch the decimals
     * @return decimals uint8
     */

    function decimals(address priceFeed) external view returns (uint8) {
        return AggregatorV3Interface(priceFeed).decimals();
    }
}
