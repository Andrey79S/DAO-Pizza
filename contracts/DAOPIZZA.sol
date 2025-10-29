// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DaoToken is ERC20, Ownable {
    constructor() ERC20("DAO Pizza", "DAOPIZZA") {
        uint256 totalSupply = 1_250_000 * 10 ** decimals();
        _mint(msg.sender, totalSupply);
    }
}
