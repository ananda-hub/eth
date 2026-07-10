// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PersonalVault {
    // --- State Variables ---
    address public owner;           // Who owns this vault
    uint256 public unlockTime;      // When funds become available

    // --- Events ---
    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(uint256 amount, uint256 timestamp);
    event LockExtended(uint256 newUnlockTime);

    // --- Custom Errors ---
    error FundsLocked();
    error NotOwner();
    error InvalidUnlockTime();
    error NoBalance();
    error TransferFailed();

    // --- Modifiers ---
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // --- Constructor ---
    // Deploys the contract, sets the owner, initial unlock time, and allows an initial deposit
    constructor(uint256 _unlockTime) payable {
        require(_unlockTime > block.timestamp, "Unlock time must be in the future");
        owner = msg.sender;
        unlockTime = _unlockTime;
    }

    // --- Core Functions ---

    // 1. Deposit
    // Allows the owner (or anyone) to add funds to the vault
    function deposit() public payable {
        // Contract balance is automatically updated by the 'payable' keyword
        emit Deposit(msg.sender, msg.value);
    }

    // Fallback function to catch direct ETH transfers without calling deposit()
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // 2. Withdraw
    // Allows the owner to withdraw all funds AFTER the lock period expires
    function withdraw() public onlyOwner {
        // Check time requirement
        if (block.timestamp < unlockTime) {
            revert FundsLocked();
        }
        
        // Check balance requirement
        uint256 balance = address(this).balance;
        if (balance == 0) {
            revert NoBalance();
        }

        // Transfer funds using call (Checks-Effects-Interactions pattern)
        (bool success, ) = msg.sender.call{value: balance}("");
        if (!success) {
            revert TransferFailed();
        }

        // Emit event
        emit Withdrawal(balance, block.timestamp);
    }

    // 3. Extend Lock
    // Allows the owner to push the unlock time further into the future
    function extendLock(uint256 newTime) public onlyOwner {
        // Validate that the new time is strictly greater than the current unlock time
        if (newTime <= unlockTime) {
            revert InvalidUnlockTime();
        }
        
        unlockTime = newTime;
        emit LockExtended(newTime);
    }
}