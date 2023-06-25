// SPDX-License-Identifier: None
pragma solidity ^0.8.13;

import "./interfaces/IBinaryOptions.sol";
import "./interfaces/IDynamicRateCalculator.sol";

contract BinaryOptions is IBinaryOptions {
    mapping(uint256 => RoundInfo) public roundInfo;
    mapping(uint256 => uint256[]) public userEpochInfo;
    mapping(address => uint256) public userLastBetEpoch;
    mapping(address => uint256[]) public userTotalBetEpochs;
    UserInfo[] public userInfo;
    // Standard_Token public immutable ut;
    uint256 public immutable epochPeriod;
    uint256 public immutable epochStopBetBlockCount;
    IOracle public immutable oracle;
    IDynamicRateCalculator public calculator;
    uint256 public constant RATE_DIVIDER = 1000000;

    constructor(
        uint256 _epochPeriod,
        uint256 _stopBetBlockCount,
        address _oracle,
        address _calculator
    ) {
        epochPeriod = _epochPeriod;
        epochStopBetBlockCount = _stopBetBlockCount;
        oracle = IOracle(_oracle);
        calculator = IDynamicRateCalculator(_calculator);
        // ut = new Standard_Token(0, "UT", 18, "UT");
    }

    function getUserInfo(
        address user
    ) public view returns (UserInfo[] memory infos) {
        uint256[] memory indexes = userTotalBetEpochs[user];
        infos = new UserInfo[](indexes.length);
        for (uint i = 0; i < indexes.length; i++) {
            infos[i] = userInfo[indexes[i]];
        }
    }

    function getEpochInfo(
        uint256 epoch
    ) public view returns (UserInfo[] memory epochInfos) {
        uint256[] memory infos = userEpochInfo[epoch];
        epochInfos = new UserInfo[](infos.length);
        for (uint i = 0; i < infos.length; i++) {
            epochInfos[i] = userInfo[infos[i]];
        }
    }

    function getUserEpochInfo(
        address user,
        uint256 epoch
    ) public view returns (UserInfo[] memory userEpochInfos) {
        uint256[] memory infos = userEpochInfo[epoch];
        uint256 userEopchInfosCount = 0;
        for (uint i = 0; i < infos.length; i++) {
            UserInfo memory info = userInfo[infos[i]];
            if (info.user == user) {
                userEopchInfosCount++;
            }
        }
        userEpochInfos = new UserInfo[](userEopchInfosCount);
        uint256 index = 0;
        for (uint i = 0; i < infos.length; i++) {
            UserInfo memory info = userInfo[infos[i]];
            if (info.user == user) {
                userEpochInfos[index++] = userInfo[infos[i]];
            }
        }
    }

    function getEpochResult(
        uint256 epoch
    ) public view returns (uint256 totalBet, uint256 bullWin, uint256 bearWin) {
        require(epoch % epochPeriod == 0);
        UserInfo[] memory infos = getEpochInfo(epoch);

        uint256 end = getEpochEnd(epoch);
        (bool succeed, uint256 price) = oracle.peek(abi.encode(end));

        if (succeed) {
            for (uint i = 0; i < infos.length; i++) {
                UserInfo memory info = infos[i];
                int256 amount = info.amount;
                (bool s, uint256 p) = oracle.peek(abi.encode(info.blockNumber));
                if (s) {
                    uint256 rate = info.rate;
                    if (p == price) {
                        continue;
                    }
                    if (p > price && amount > 0) {
                        //bull win
                        bullWin += (uint256(amount) * rate) / RATE_DIVIDER;
                    } else if (amount < 0) {
                        //bear win
                        bearWin += (uint256(-amount) * rate) / RATE_DIVIDER;
                    }
                }
                totalBet += uint256(amount > 0 ? amount : -amount);
            }
        }
    }

    function getUserEpochResult(
        address user,
        uint256 epoch
    ) public view override returns (uint256 totalWin) {
        UserInfo[] memory infos = getUserEpochInfo(user, epoch);
        uint256 end = getEpochEnd(epoch);
        (bool succeed, uint256 price) = oracle.peek(abi.encode(end));
        if (succeed) {
            for (uint i = 0; i < infos.length; i++) {
                UserInfo memory info = infos[i];
                (bool s, uint256 p) = oracle.peek(abi.encode(info.blockNumber));
                if (s) {
                    int256 amount = info.amount;
                    uint256 rate = info.rate;
                    if (p == price) {
                        continue;
                    }
                    if (p > price && amount > 0) {
                        //bull win
                        totalWin += (uint256(amount) * rate) / RATE_DIVIDER;
                    } else if (amount < 0) {
                        //bear win
                        totalWin += (uint256(-amount) * rate) / RATE_DIVIDER;
                    }
                }
            }
        }
    }

    function getEpochEnd(uint256 epoch) public view returns (uint256 end) {
        return epoch + epochPeriod;
    }

    function currentEpoch() external view returns (uint256 epoch) {
        return block.number - (block.number % epochPeriod);
    }

    function handleBet(uint256 epoch, int256 amount, uint128 rate) private {
        //TODO: transfer asset or auto compound
        // ut.transferFrom(msg.sender, address(this), amount);
        address user = msg.sender;
        UserInfo memory detail = UserInfo({
            user: user,
            amount: amount,
            rate: rate,
            blockNumber: uint128(block.number)
        });
        uint256 index = userInfo.length;
        //TODO: use bitMap to storage the bet info for optimizing gas
        userEpochInfo[epoch].push(index);
        userTotalBetEpochs[user].push(index);
        userInfo.push(detail);
    }

    function betC(uint256 amount) external override {
        uint256 currentBlockNumber = block.number;
        uint epoch = currentBlockNumber - (currentBlockNumber % epochPeriod);
        if (currentBlockNumber >= epoch + epochStopBetBlockCount) {
            epoch += epochPeriod;
        }
        RoundInfo storage info = roundInfo[epoch];
        require(info.lastBetBlock <= currentBlockNumber, "this is impossible");

        handleBet(
            epoch,
            int256(amount),
            calculator.oddsC(info.totalBull, info.totalBear)
        );
        if (info.lastBetBlock < currentBlockNumber) {
            info.lastBetBlock = currentBlockNumber;
            info.totalBull += info.pendingBull;
            info.pendingBull = 0;
        }
        info.pendingBull += amount;
    }

    function betP(uint256 amount) external override {
        uint256 currentBlockNumber = block.number;
        uint epoch = currentBlockNumber - (currentBlockNumber % epochPeriod);
        if (currentBlockNumber >= epoch + epochStopBetBlockCount) {
            epoch += epochPeriod;
        }
        RoundInfo storage info = roundInfo[epoch];
        require(info.lastBetBlock <= currentBlockNumber, "this is impossible");

        handleBet(
            epoch,
            -int256(amount),
            calculator.oddsP(info.totalBull, info.totalBear)
        );
        if (info.lastBetBlock < currentBlockNumber) {
            info.lastBetBlock = currentBlockNumber;
            info.totalBear += info.pendingBear;
            info.pendingBear = 0;
        }
        info.pendingBear += amount;
    }

    function claimWin(uint256 epoch) external override {}
}
