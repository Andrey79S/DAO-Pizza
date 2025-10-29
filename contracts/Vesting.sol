// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title SimpleVesting
 * Hold tokens for beneficiary and allow periodic release.
 */
contract SimpleVesting {
    IERC20 public token;
    address public beneficiary;
    uint256 public start;
    uint256 public duration; // seconds
    uint256 public totalAmount;
    uint256 public released;

    constructor(IERC20 _token, address _beneficiary, uint256 _start, uint256 _duration, uint256 _totalAmount) {
        token = _token;
        beneficiary = _beneficiary;
        start = _start;
        duration = _duration;
        totalAmount = _totalAmount;
    }

    function releasable() public view returns (uint256) {
        if (block.timestamp < start) return 0;
        uint256 elapsed = block.timestamp - start;
        if (elapsed > duration) elapsed = duration;
        uint256 vested = (totalAmount * elapsed) / duration;
        return vested - released;
    }

    function release() external {
        uint256 amount = releasable();
        require(amount > 0, "Nothing to release");
        released += amount;
        require(token.transfer(beneficiary, amount), "Transfer failed");
    }
}
