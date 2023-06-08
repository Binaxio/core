// SPDX-License-Identifier: None
pragma solidity ^0.8.13;

import "./IOracle.sol";

interface IBinaryOptions {
    struct UserInfo {
        address user;
        int256 amount;
        uint128 ratio;
        uint128 blockNumber;
    }

    struct RoundInfo {
        uint256 totalBear;
        uint256 pendingBear;
        uint256 totalBull;
        uint256 pendingBull;
        uint256 lastBetBlock;
    }

    event ButBull(
        address user,
        uint256 amount,
        uint256 blockNumber,
        uint256 ratio
    );
    event ButBear(
        address user,
        uint256 amount,
        uint256 blockNumber,
        uint256 ratio
    );

    function roundInfo(
        uint256 epoch
    )
        external
        view
        returns (
            uint256 totalBear,
            uint256 pendingBear,
            uint256 totalBull,
            uint256 pendingBull,
            uint256 lastBetBlock
        );

    function getUserEpochInfo(
        address user,
        uint256 epoch
    ) external view returns (UserInfo[] memory infos);

    function getEpochInfo(
        uint256 epoch
    ) external view returns (UserInfo[] memory infos);

    function getUserEpochResult(
        address user,
        uint256 epoch
    ) external view returns (uint256 totalWin);

    function getEpochResult(
        uint256 epoch
    )
        external
        view
        returns (uint256 totalBet, uint256 bullWin, uint256 bearWin);

    function getEpochEnd(uint256 epoch) external view returns (uint256 end);

    function currentEpoch() external view returns (uint256 epoch);

    function epochPeriod() external view returns (uint256 period);

    function epochStopBetBlockCount() external view returns (uint256 count);

    function oracle() external view returns (IOracle oracle);

    // function submitPrice(uint256[] calldata price, uint256 epoch) external;

    function betBull(uint256 amount) external;

    function betBear(uint256 amount) external;

    function addLiquidity(
        address token,
        uint256 amountIn,
        uint256 minUtOut,
        address to
    ) external;

    function removeLiquidity(
        address token,
        uint256 utIn,
        uint256 minAmountOut,
        address to
    ) external;
}
