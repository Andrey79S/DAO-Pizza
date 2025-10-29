// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Treasury
 * Holds stablecoins (USDT/USDC) and pays out rewards on request by authorized contract.
 */
contract Treasury is Ownable {
    IERC20 public stable; // USDC or USDT
    address public distributor; // authorized to trigger payouts

    event Deposited(address indexed from, uint256 amount);
    event Paid(address indexed to, uint256 amount);

    constructor(IERC20 _stable) {
        stable = _stable;
    }

    function setDistributor(address _distributor) external onlyOwner {
        distributor = _distributor;
    }

    function deposit(uint256 amount) external {
        require(stable.transferFrom(msg.sender, address(this), amount), "deposit failed");
        emit Deposited(msg.sender, amount);
    }

    /// only distributor can call to pay users when pizza tokens are burned
    function pay(address to, uint256 amount) external {
        require(msg.sender == distributor, "Only distributor");
        require(stable.balanceOf(address(this)) >= amount, "Insufficient funds");
        require(stable.transfer(to, amount), "transfer failed");
        emit Paid(to, amount);
    }

    // admin withdraw in case of emergencies
    function adminWithdraw(address to, uint256 amount) external onlyOwner {
        require(stable.transfer(to, amount), "withdraw failed");
    }
}
