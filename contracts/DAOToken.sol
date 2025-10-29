// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DaoToken
 * DAO governance token with snapshot support.
 * Initial supply minted to deployer.
 */
contract DaoToken is ERC20Snapshot, Ownable {
    uint256 public constant INITIAL_SUPPLY = 1_250_000 * 10 ** 18;

    // address allowed to create snapshots (e.g. Distributor)
    address public snapshotter;

    constructor() ERC20("DAO Pizza", "DAOPIZZA") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function setSnapshotter(address _snapshotter) external onlyOwner {
        snapshotter = _snapshotter;
    }

    /// snapshot creation can be called by owner or designated snapshotter
    function snapshot() external returns (uint256) {
        require(msg.sender == owner() || msg.sender == snapshotter, "Not allowed to snapshot");
        return _snapshot();
    }

    // override _beforeTokenTransfer required by ERC20Snapshot
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
    }
}
