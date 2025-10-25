
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./DAOPIZZA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Simple Token Sale for DAOPIZZA
/// Buyers send ETH and receive DAOPIZZA tokens which are locked until admin unlocks.
contract TokenSale is Ownable {
    DAOPIZZA public token;
    uint256 public priceWeiPerToken; // price in wei per token unit (1 token with decimals considered)
    uint8 public tokenDecimals;

    event Bought(address indexed buyer, uint256 ethAmount, uint256 tokensAmount);

    constructor(address tokenAddress, uint256 _priceWeiPerToken) {
        token = DAOPIZZA(tokenAddress);
        priceWeiPerToken = _priceWeiPerToken;
        tokenDecimals = token.decimals();
    }

    receive() external payable {
        buyTokens();
    }

    function buyTokens() public payable {
        require(msg.value > 0, "Send ETH to buy tokens");
        // tokens = (msg.value / priceWeiPerToken) * (10 ** decimals)
        uint256 rawTokens = (msg.value * (10 ** tokenDecimals)) / priceWeiPerToken;
        require(rawTokens > 0, "Value too small for one token unit");

        // transfer tokens from owner to buyer (owner must have minted or funded sale contract)
        // For simplicity owner should approve this contract OR owner can transfer tokens to this contract in advance.
        // We'll use token.transferFrom(owner, buyer, rawTokens) pattern if approved. Simpler: contract must hold tokens.
        require(token.balanceOf(address(this)) >= rawTokens, "Not enough tokens in sale contract");

        bool ok = token.transfer(msg.sender, rawTokens);
        require(ok, "Token transfer failed");

        // immediately lock purchased tokens for the buyer
        token.lockTokens(msg.sender, rawTokens);

        emit Bought(msg.sender, msg.value, rawTokens);
    }

    // admin withdraws ETH funds
    function withdraw(address payable to) external onlyOwner {
        require(address(this).balance > 0, "No ETH to withdraw");
        to.transfer(address(this).balance);
    }

    // admin can set price
    function setPrice(uint256 newPriceWeiPerToken) external onlyOwner {
        priceWeiPerToken = newPriceWeiPerToken;
    }

    // admin can deposit tokens into this contract
    function depositTokens(uint256 amount) external {
        // caller must transfer tokens to this contract from owner's wallet
        // or owner can just transfer tokens to this contract address
        // This function is just a placeholder — tokens are transferred via ERC20 transfer
    }
}
