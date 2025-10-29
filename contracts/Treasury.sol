// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * DAO PIZZA — Treasury Contract (MVP version)
 * Хранение и управление средствами от продажи DAO токенов.
 * Управление — у владельца (создателя проекта), до запуска DAO Governance.
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DaoTreasury is Ownable, ReentrancyGuard {
    // Принятые токены (например USDT, USDC)
    mapping(address => bool) public acceptedTokens;

    // DAO governance (будет добавлено позже)
    address public daoGovernance;

    // Флаг аварийного режима
    bool public emergencyMode = false;

    // События
    event FundsDeposited(address indexed token, address indexed from, uint256 amount);
    event FundsReleased(address indexed token, address indexed to, uint256 amount);
    event EmergencyActivated(bool active);
    event AcceptedTokenUpdated(address token, bool accepted);
    event DaoGovernanceTransferred(address indexed dao);

    constructor() {
        // На старте управление у владельца (создателя)
    }

    // Установить DAO Governance контракт (после запуска DAO)
    function setDaoGovernance(address _daoGovernance) external onlyOwner {
        daoGovernance = _daoGovernance;
        emit DaoGovernanceTransferred(_daoGovernance);
    }

    // Добавить или удалить токен из whitelist
    function setAcceptedToken(address token, bool accepted) external onlyOwner {
        acceptedTokens[token] = accepted;
        emit AcceptedTokenUpdated(token, accepted);
    }

    // Внести USDT/USDC в трезори
    function deposit(address token, uint256 amount) external nonReentrant {
        require(acceptedTokens[token], "Token not accepted");
        require(amount > 0, "Amount must be > 0");

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit FundsDeposited(token, msg.sender, amount);
    }

    // ✅ На MVP этапе средства может выводить только владелец (создатель проекта)
    function releaseFunds(address token, address to, uint256 amount) external onlyOwner nonReentrant {
        require(!emergencyMode, "Emergency mode active");
        require(acceptedTokens[token], "Token not accepted");
        require(IERC20(token).balanceOf(address(this)) >= amount, "Insufficient balance");

        IERC20(token).transfer(to, amount);
        emit FundsReleased(token, to, amount);
    }

    // Активация аварийного режима (на будущее — для DAO)
    function activateEmergency(bool _active) external onlyOwner {
        emergencyMode = _active;
        emit EmergencyActivated(_active);
    }

    // Проверка баланса
    function getBalance(address token) external view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
}
