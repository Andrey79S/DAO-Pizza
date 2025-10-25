// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title DAOPIZZA — ERC20 with simple lock mechanism for purchased tokens
contract DAOPIZZA is ERC20, Ownable {
    // amount locked per account (cannot be transferred until unlocked)
    mapping(address => uint256) public lockedAmount;

    constructor(uint256 initialSupply) ERC20("DAO Pizza Token", "DAOPIZZA") {
        _mint(msg.sender, initialSupply);
    }

    /// @notice Lock tokens of account (only owner: sale contract or admin)
    function lockTokens(address account, uint256 amount) external onlyOwner {
        require(balanceOf(account) >= amount, "Not enough balance to lock");
        lockedAmount[account] += amount;
    }

    /// @notice Unlock tokens of account (only owner)
    function unlockTokens(address account, uint256 amount) external onlyOwner {
        require(lockedAmount[account] >= amount, "Unlock amount exceeds locked");
        lockedAmount[account] -= amount;
    }

    /// @dev override transfer to check locked amounts
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        if (from != address(0)) { // not for mint
            uint256 senderBalance = balanceOf(from);
            uint256 senderLocked = lockedAmount[from];
            // available = balance - locked
            require(senderBalance - senderLocked >= amount, "Transfer amount exceeds unlocked balance");
        }
        super._beforeTokenTransfer(from, to, amount);
    }

    // helper to mint (owner only) for initial supply or future needs
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
