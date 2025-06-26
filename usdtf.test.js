// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.5.10;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/USDTF.sol";

contract USDTFTest {
    USDTF token;
    address owner;
    address userA;
    address userB;
    address spender;

    function beforeEach() public {
        // Deploy a fresh instance for each test
        token = new USDTF();
        owner = address(this);
        userA = TestsAccounts.getAccount(1);
        userB = TestsAccounts.getAccount(2);
        spender = TestsAccounts.getAccount(3);
    }

    // Flash Mint + Supply Test
    function testFlashMintCreatesCorrectBalance() public {
        beforeEach();
        token.flashMint(userA, 1000, 10);
        uint balanceA = token.balanceOf(userA);
        Assert.equal(balanceA, 1000, "User A should have 1000 tokens");
        uint totalSupply = token.totalSupply();
        Assert.equal(totalSupply, 1000, "Total supply should be 1000 after mint");
    }

    // Expiry Behavior Test
    function testFlashMintWithImmediateExpiry() public {
        beforeEach();
        token.flashMint(userA, 500, 0); // expires instantly
        uint balanceA = token.balanceOf(userA);
        Assert.equal(balanceA, 0, "Expired tokens should not appear in balance");
    }

    function testBurnExpiredTokens() public {
        beforeEach();
        token.flashMint(userA, 500, 0); // expires instantly
        uint burned = token.burnExpired(userA);
        Assert.equal(burned, 500, "Should burn 500 expired tokens");
        uint totalSupply = token.totalSupply();
        Assert.equal(totalSupply, 0, "Total supply should be zero after burn");
    }

    // Transfer Test
    function testTransferToUserB() public {
        beforeEach();
        token.flashMint(userA, 1000, 10);
        bool sent = token.transfer(userB, 400);
        Assert.isTrue(sent, "Transfer should succeed");
        uint balanceA = token.balanceOf(userA);
        uint balanceB = token.balanceOf(userB);
        Assert.equal(balanceA, 600, "User A should have 600 left");
        Assert.equal(balanceB, 400, "User B should have 400");
    }

    // Approve and TransferFrom Test
    function testApproveAndAllowance() public {
        beforeEach();
        token.flashMint(owner, 1000, 10);
        bool ok = token.approve(spender, 500);
        Assert.isTrue(ok, "Approval should succeed");
        uint allowed = token.allowance(owner, spender);
        Assert.equal(allowed, 500, "Allowance should be 500");
    }

    function testTransferFrom() public {
        beforeEach();
        token.flashMint(owner, 1000, 10);
        token.approve(spender, 500);
        // Simulate actions from spender by using DeployedAddresses if needed
        bool success = token.transferFrom(owner, userA, 300);
        Assert.isTrue(success, "transferFrom should succeed");
        uint remaining = token.allowance(owner, spender);
        Assert.equal(remaining, 200, "Remaining allowance should be 200");
        uint balanceA = token.balanceOf(userA);
        Assert.equal(balanceA, 300, "User A should have received 300 tokens");
    }
}
