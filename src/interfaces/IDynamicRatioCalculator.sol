// SPDX-License-Identifier: None
pragma solidity ^0.8.13;

interface IDynamicRatioCalculator {
    function getBullRatio(
        uint256 totalBull,
        uint256 totalBear
    ) external view returns (uint128 ratio);

    function getBearRatio(
        uint256 totalBull,
        uint256 totalBear
    ) external view returns (uint128 ratio);
}
