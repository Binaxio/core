// SPDX-License-Identifier: None
pragma solidity ^0.8.13;

interface IDynamicRateCalculator {
    function maxOdds() external view returns (int256);

    /**
     * calculate the minimum odds
     * @return odds:int256 belongs to [0,10000]
     * normalized: result / 10000
     */
    function minOdds() external view returns (int256);

    /**
     * calculate the odds for buying long
     * @param betc: The total statistics of long odds before the i-th block
     * @param betp: The total statistics of short odds before the i-th block
     * @return odds:int256
     * normalized: result / 10000
     */
    function oddsC(uint256 betc, uint256 betp) external view returns (uint128);

    /**
     * calculate the odds for buying short
     * @param betc: The total statistics of long odds before the i-th block
     * @param betp: The total statistics of short odds before the i-th block
     * @return odds:int256
     * normalized: result / 10000
     */
    function oddsP(uint256 betc, uint256 betp) external view returns (uint128);

    function setParameters(
        int256 _epsilon,
        int256 _theta,
        uint256 _base
    ) external;
}
