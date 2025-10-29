// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title PizzaToken
 * Simple ERC20 for 🍕 tokens. Only distributor can mint.
 */
contract PizzaToken is ERC20, Ownable {
    address public distributor;

    modifier onlyDistributor() {
        require(msg.sender == distributor, "Only distributor");
        _;
    }

    constructor() ERC20("Pizza Token", "PIZZA") {}

    function setDistributor(address _distributor) external onlyOwner {
        distributor = _distributor;
    }

    /// mint only by distributor
    function mintTo(address to, uint256 amount) external onlyDistributor {
        _mint(to, amount);
    }

    /// burnFrom is available via ERC20 standard allowance: distributor can burn tokens from user (requires approval)
    function burnFromUser(address from, uint256 amount) external onlyDistributor {
        _spendAllowance(from, msg.sender, amount); // reduce allowance
        _burn(from, amount);
    }
}
