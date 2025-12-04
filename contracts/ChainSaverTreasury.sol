// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title ChainSaver Treasury
 * @notice A decentralized on-chain treasury to store project funds and distribute them
 *         among multiple recipients in a transparent and permissioned manner.
 */

contract ChainSaverTreasury {
    address public owner;

    struct Allocation {
        address recipient;
        uint256 percentage; // e.g., 2000 = 20%
        bool active;
    }

    Allocation[] public allocations;
    uint256 public totalPercentage; // must always be <= 10000 (100%)

    event Deposit(address indexed sender, uint256 amount);
    event AllocationAdded(address indexed recipient, uint256 percentage);
    event AllocationUpdated(uint256 index, uint256 percentage, bool status);
    event Distribution(uint256 totalAmount, uint256 timestamp);
    event Withdraw(address indexed owner, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function deposit() external payable {
        require(msg.value > 0, "No ETH sent");
        emit Deposit(msg.sender, msg.value);
    }

    // Add new allocation for a beneficiary
    function addAllocation(address _recipient, uint256 _percentage) external onlyOwner {
        require(_recipient != address(0), "Invalid address");
        require(_percentage > 0, "Percentage > 0");
        require(totalPercentage + _percentage <= 10000, "Exceeds max");

        allocations.push(Allocation(_recipient, _percentage, true));
        totalPercentage += _percentage;

        emit AllocationAdded(_recipient, _percentage);
    }

    // Update existing allocation
    function updateAllocation(uint256 index, uint256 _percentage, bool _active) external onlyOwner {
        require(index < allocations.length, "Invalid index");

        // update total %
        totalPercentage = totalPercentage - allocations[index].percentage + _percentage;
        require(totalPercentage <= 10000, "Exceeds max");

        allocations[index].percentage = _percentage;
        allocations[index].active = _active;

        emit AllocationUpdated(index, _percentage, _active);
    }

    // Distribute ETH to all active recipients based on percentages
    function distribute() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to distribute");
        require(totalPercentage > 0, "No allocations");

        for (uint256 i = 0; i < allocations.length; i++) {
            if (!allocations[i].active) continue;

            uint256 share = (balance * allocations[i].percentage) / 10000;
            payable(allocations[i].recipient).transfer(share);
        }

        emit Distribution(balance, block.timestamp);
    }

    // Emergency withdraw — only owner
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        payable(owner).transfer(amount);
        emit Withdraw(owner, amount);
    }

    // Change owner
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

    // View total treasury balance
    function getTreasuryBalance() external view returns (uint256) {
        return address(this).balance;
    }

    // Get allocation list count
    function getAllocationCount() external view returns (uint256) {
        return allocations.length;
    }
}
