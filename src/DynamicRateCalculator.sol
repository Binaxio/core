// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "openzeppelin/access/Ownable.sol";
import "./interfaces/IDynamicRateCalculator.sol";

contract DynamicRateCalculator is IDynamicRateCalculator, Ownable {
    int256 public epsilon = 0;
    int256 public theta = 0;
    uint256 public base;

    /**
     * @dev normalized factor
     */
    int256 constant factor = 1e4;

    constructor(int256 _epsilon, int256 _theta, address _governor) {
        _transferOwnership(_governor);
        _setParameters(_epsilon, _theta, 1e4);
    }

    /**
     * calculate the maximum odds
     * @return odds:int256 belongs to [10000,+oo]
     * normalized: result / 10000
     */
    function maxOdds() public view returns (int256) {
        return factor + (theta * epsilon) / factor;
    }

    /**
     * calculate the minimum odds
     * @return odds:int256 belongs to [0,10000]
     * normalized: result / 10000
     */
    function minOdds() public view returns (int256) {
        return factor - epsilon;
    }

    /**
     * calculate the odds for buying long
     * @param betc: The total statistics of long odds before the i-th block
     * @param betp: The total statistics of short odds before the i-th block
     * @return odds:int256
     * normalized: result / 10000
     */
    function oddsC(uint256 betc, uint256 betp) public view returns (uint128) {
        require(
            betc <= (1 << 128) && betp <= (1 << 128),
            "parameters overflow"
        );
        int256 ibetc = int256(betc + base);
        int256 ibetp = int256(betp + base);
        return
            uint128(
                uint256(
                    (-epsilon * theta * (ibetc - ibetp)) /
                        (theta * ibetc + ibetp) +
                        factor
                )
            );
    }

    /**
     * calculate the odds for buying short
     * @param betc: The total statistics of long odds before the i-th block
     * @param betp: The total statistics of short odds before the i-th block
     * @return odds:int256
     * normalized: result / 10000
     */
    function oddsP(uint256 betc, uint256 betp) public view returns (uint128) {
        require(
            betc <= (1 << 128) && betp <= (1 << 128),
            "parameters overflow"
        );
        int256 ibetc = int256(betc + base);
        int256 ibetp = int256(betp + base);
        return
            uint128(
                uint256(
                    (-epsilon * theta * (ibetp - ibetc)) /
                        (theta * ibetp + ibetc) +
                        factor
                )
            );
    }

    function setParameters(
        int256 _epsilon,
        int256 _theta,
        uint256 _base
    ) public onlyOwner {
        _setParameters(_epsilon, _theta, _base);
    }

    function _setParameters(
        int256 _epsilon,
        int256 _theta,
        uint256 _base
    ) internal {
        require(_epsilon >= 0 && _epsilon <= factor, "invalid epsilon");
        require(_base > 0, "invalid base");
        epsilon = _epsilon;
        theta = _theta;
        base = _base;
        emit ParamsChanged(_epsilon, _theta, _base);
    }

    event ParamsChanged(int256 epsilon, int256 theta, uint256 base);
}
