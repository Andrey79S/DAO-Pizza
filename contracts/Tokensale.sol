// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DAOPizzaSale is Ownable {
    IERC20 public token;
    uint256 public rate; // tokens per 1 ETH
    address public treasury;

    event Bought(address indexed buyer, uint256 amountTokens, uint256 paidWei);

    constructor() {
        treasury = msg.sender;
    }

    function initialize(IERC20 _token, uint256 _rate, address _treasury) external onlyOwner {
        token = _token;
        rate = _rate;
        if (_treasury != address(0)) treasury = _treasury;
    }

    receive() external payable {
        buy();
    }

    function buy() public payable {
        require(msg.value > 0, "Send ETH to buy tokens");
        uint256 tokensOut = (msg.value * rate);
        require(token.balanceOf(address(this)) >= tokensOut, "Not enough tokens in sale contract");

        require(token.transfer(msg.sender, tokensOut), "Token transfer failed");

        (bool sent, ) = payable(treasury).call{value: msg.value}("");
        require(sent, "Failed to forward ETH");

        emit Bought(msg.sender, tokensOut, msg.value);
    }

    function withdrawTokens(address _to, uint256 _amount) external onlyOwner {
        require(token.transfer(_to, _amount), "Transfer failed");
    }

    function setRate(uint256 _rate) external onlyOwner {
        rate = _rate;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }
}
