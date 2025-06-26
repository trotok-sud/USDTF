// contracts/Migrations.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.5.10;

contract Migrations {
    address public owner;
    uint public last_completed_migration;

    constructor() public {
        owner = msg.sender;
    }

    function setCompleted(uint completed) public {
        require(msg.sender == owner, "Only owner can complete migration.");
        last_completed_migration = completed;
    }
}
