// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title ChainSaver Treasury
 * @notice Secure treasury contract for storing and managing multiple ERC20 tokens
 * @dev Includes time-locked withdrawals, admin control, and emergency rescue
 */

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract ChainSaverTreasury {
    address public owner;
    uint256 public withdrawalDelay = 1 days; // default 24h delay

    struct WithdrawalRequest {
        address token;
        uint256 amount;
        uint256 releaseTime;
        bool executed;
    }

    mapping(address => bool) public authorizedAdmins;
    mapping(uint256 => WithdrawalRequest) public withdrawalRequests;
    uint256 public requestCount;

    event AdminAuthorized(address indexed admin);
    event AdminRevoked(address indexed admin);
    event Deposit(address indexed token, uint256 amount, address indexed sender);
    event WithdrawalRequested(uint256 indexed requestId, address indexed token, uint256 amount, uint256 releaseTime);
    event WithdrawalExecuted(uint256 indexed requestId, address indexed token, uint256 amount);
    event EmergencyWithdraw(address indexed token, uint256 amount, address indexed to);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyAdmin() {
        require(authorizedAdmins[msg.sender] || msg.sender == owner, "Not admin");
        _;
    }

    constructor() {
        owner = msg.sender;
        authorizedAdmins[msg.sender] = true;
    }

    // ------------------------------------------------
    // ADMIN MANAGEMENT
    // ------------------------------------------------
    function authorizeAdmin(address admin) external onlyOwner {
        authorizedAdmins[admin] = true;
        emit AdminAuthorized(admin);
    }

    function revokeAdmin(address admin) external onlyOwner {
        authorizedAdmins[admin] = false;
        emit AdminRevoked(admin);
    }

    // ------------------------------------------------
    // DEPOSIT
    // ------------------------------------------------
    function deposit(address token, uint256 amount) external {
        require(amount > 0, "Zero deposit");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        emit Deposit(token, amount, msg.sender);
    }

    // ------------------------------------------------
    // WITHDRAWAL WITH TIME LOCK
    // ------------------------------------------------
    function requestWithdrawal(address token, uint256 amount) external onlyAdmin returns (uint256) {
        require(amount > 0, "Zero withdrawal");
        require(IERC20(token).balanceOf(address(this)) >= amount, "Insufficient balance");

        requestCount++;
        withdrawalRequests[requestCount] = WithdrawalRequest({
            token: token,
            amount: amount,
            releaseTime: block.timestamp + withdrawalDelay,
            executed: false
        });

        emit WithdrawalRequested(requestCount, token, amount, block.timestamp + withdrawalDelay);
        return requestCount;
    }

    function executeWithdrawal(uint256 requestId) external onlyAdmin {
        WithdrawalRequest storage req = withdrawalRequests[requestId];
        require(!req.executed, "Already executed");
        require(block.timestamp >= req.releaseTime, "Too early");

        req.executed = true;
        IERC20(req.token).transfer(msg.sender, req.amount);
        emit WithdrawalExecuted(requestId, req.token, req.amount);
    }

    // ------------------------------------------------
    // EMERGENCY WITHDRAW
    // ------------------------------------------------
    function emergencyWithdraw(address token, uint256 amount, address to) external onlyOwner {
        require(amount <= IERC20(token).balanceOf(address(this)), "Insufficient balance");
        IERC20(token).transfer(to, amount);
        emit EmergencyWithdraw(token, amount, to);
    }

    // ------------------------------------------------
    // VIEW UTILITIES
    // ------------------------------------------------
    function pendingWithdrawal(uint256 requestId) external view returns (uint256, uint256, bool) {
        WithdrawalRequest storage req = withdrawalRequests[requestId];
        return (req.amount, req.releaseTime, req.executed);
    }

    function isAdmin(address user) external view returns (bool) {
        return authorizedAdmins[user];
    }

    function setWithdrawalDelay(uint256 delaySeconds) external onlyOwner {
        withdrawalDelay = delaySeconds;
    }
}
