// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./DaoToken.sol";
import "./PizzaToken.sol";
import "./Treasury.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Distributor
 * 1) recordSale(n) -> creates snapshot and mints n PIZZA tokens to this contract
 * 2) users claim their share of that snapshot proportional to DAO holdings at snapshot
 * 3) users can burn PIZZA (approve Distributor), Distributor burns and pays from Treasury
 */
contract Distributor is Ownable {
    DaoToken public dao;
    PizzaToken public pizza;
    Treasury public treasury;

    struct SaleSnapshot {
        uint256 snapshotId;      // snapshot id from DaoToken
        uint256 totalPizzas;     // total pizza tokens minted for this period
        uint256 totalDaoSupply;  // total supply at snapshot
        mapping(address => bool) claimed;
    }

    SaleSnapshot[] public sales;

    // pricePerPizza for current burn campaign (in stable token smallest units)
    uint256 public currentBurnPrice; // e.g., 1 USDC = 1e6 if USDC has 6 decimals

    event SaleRecorded(uint256 indexed saleIndex, uint256 snapshotId, uint256 totalPizzas);
    event Claimed(address indexed user, uint256 indexed saleIndex, uint256 amount);
    event BurnedAndPaid(address indexed user, uint256 pizzaAmount, uint256 paidAmount);

    constructor(DaoToken _dao, PizzaToken _pizza, Treasury _treasury) {
        dao = _dao;
        pizza = _pizza;
        treasury = _treasury;
    }

    /// owner (or authorized) records a sale: creates snapshot, mints `count` pizzas to this contract
    function recordSale(uint256 count) external onlyOwner {
        // create snapshot on dao
        uint256 snapId = dao.snapshot();
        // mint pizza tokens to this contract
        pizza.mintTo(address(this), count * (10 ** pizza.decimals()));
        uint256 totSupply = dao.totalSupply(); // current supply; for safety we also keep snapshot total available via ERC20Snapshot .totalSupplyAt but it's accessible off-chain
        SalesStorage storage s = salesStoragePush();
        s.snapshotId = snapId;
        s.totalPizzas = count * (10 ** pizza.decimals());
        s.totalDaoSupply = dao.totalSupply(); // note: can also use dao.totalSupplyAt(snapId) via interface if exposed
        emit SaleRecorded(sales.length - 1, snapId, s.totalPizzas);
    }

    // Internal helper for dynamic array of structs with mapping (since mappings not allowed in arrays directly)
    struct SalesStorage { uint256 snapshotId; uint256 totalPizzas; uint256 totalDaoSupply; mapping(address => bool) claimed; }
    SalesStorage[] private _salesStorage;

    function salesCount() external view returns (uint256) {
        return _salesStorage.length;
    }

    function salesInfo(uint256 index) external view returns (uint256 snapshotId, uint256 totalPizzas, uint256 totalDaoSupply) {
        SalesStorage storage s = _salesStorage[index];
        return (s.snapshotId, s.totalPizzas, s.totalDaoSupply);
    }

    function salesStoragePush() internal returns (SalesStorage storage s) {
        _salesStorage.push();
        return _salesStorage[_salesStorage.length - 1];
    }

    // claim calculated share for a specific sale index
    function claim(uint256 saleIndex) external {
        require(saleIndex < _salesStorage.length, "Invalid sale index");
        SalesStorage storage s = _salesStorage[saleIndex];
        require(!s.claimed[msg.sender], "Already claimed");
        uint256 userBalanceAt = dao.balanceOfAt(msg.sender, s.snapshotId);
        require(userBalanceAt > 0, "No DAO tokens at snapshot");
        uint256 totalSupplyAt = dao.totalSupplyAt(s.snapshotId);
        require(totalSupplyAt > 0, "Zero total supply at snapshot");

        // amount = totalPizzas * userBalanceAt / totalSupplyAt
        uint256 amount = (s.totalPizzas * userBalanceAt) / totalSupplyAt;
        require(amount > 0, "Zero pizza to claim");

        s.claimed[msg.sender] = true;
        // transfer pizza tokens from contract to user
        require(pizza.transfer(msg.sender, amount), "transfer failed");
        emit Claimed(msg.sender, saleIndex, amount);
    }

    // burn pizza tokens from user (user must approve this contract)
    function burnAndRedeem(uint256 pizzaAmount) external {
        require(pizzaAmount > 0, "Zero amount");
        // burn user tokens (requires user to approve this contract)
        pizza.burnFromUser(msg.sender, pizzaAmount);

        // calculate payment in stable token units
        uint256 payAmount = (pizzaAmount * currentBurnPrice) / (10 ** pizza.decimals());
        // transfer stable from treasury to user (treasury must have funds and Distributor set as authorized)
        treasury.pay(msg.sender, payAmount);

        emit BurnedAndPaid(msg.sender, pizzaAmount, payAmount);
    }

    // Governance/admin sets price per pizza in stable smallest units (e.g., USDC:6 decimals)
    function setBurnPrice(uint256 price) external onlyOwner {
        currentBurnPrice = price;
    }

    // helper to set tokens/treasury after deploy
    function setAddresses(DaoToken _dao, PizzaToken _pizza, Treasury _treasury) external onlyOwner {
        dao = _dao;
        pizza = _pizza;
        treasury = _treasury;
    }
}
