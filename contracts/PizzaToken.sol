// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract DAOPizzaToken is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    address public dao;

    function initialize(uint256 initialSupply) public initializer {
        __ERC20_init("DAO Pizza", "PIZZA");
        __Ownable_init();
        __UUPSUpgradeable_init();

        _mint(msg.sender, initialSupply * 10 ** decimals());
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function setDAO(address _dao) external onlyOwner {
        dao = _dao;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
