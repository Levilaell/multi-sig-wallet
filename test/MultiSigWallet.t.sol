// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    address alice;
    address bob;
    address carol;

    MultiSigWallet wallet;

    function setUp() public {
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        carol = makeAddr("carol");

        address[] memory _owners = new address[](3);
        _owners[0] = alice;
        _owners[1] = bob;
        _owners[2] = carol;

        wallet = new MultiSigWallet(_owners, 2);
    }

    function test_Owners() public view {
        assertEq(wallet.getOwners().length, 3);
        assertEq(wallet.getOwners()[0], alice);
        assertEq(wallet.getOwners()[1], bob);
        assertEq(wallet.getOwners()[2], carol);
    }

    function test_SubmitTransaction() public {
        vm.prank(alice);
        wallet.submitTransaction(bob, 0, "");

        assertEq(wallet.getTransactionCount(), 1);
    }

    function test_ConfirmTransaction() public {
        vm.prank(alice);
        wallet.submitTransaction(bob, 0, "");

        vm.prank(bob);
        wallet.confirmTransaction(0);

        assertEq(wallet.isConfirmed(0, bob), true);
    }

    function test_ExecuteTransaction() public {
        vm.deal(address(wallet), 1 ether);

        vm.prank(alice);
        wallet.submitTransaction(bob, 0.5 ether, "");

        vm.prank(bob);
        wallet.confirmTransaction(0);

        vm.prank(alice);
        wallet.executeTransaction(0);

        assertEq(address(bob).balance, 0.5 ether);
    }

    function test_RevertWhen_NotOwner() public {
        vm.expectRevert("not owner");

        address lara = makeAddr("lara");
        vm.prank(lara);
        wallet.submitTransaction(alice, 1 ether, "");
    }

    function test_RevertWhen_AlreadyConfirmed() public {
        vm.prank(alice);
        wallet.submitTransaction(bob, 1 ether, "");

        vm.expectRevert("owner already confirmed");

        vm.prank(alice);
        wallet.confirmTransaction(0);
    }

    function test_RevertWhen_NotEnoughConfirmations() public {
        vm.prank(alice);
        wallet.submitTransaction(bob, 1 ether, "");

        vm.expectRevert("required not enough");

        vm.prank(alice);
        wallet.executeTransaction(0);
    }

    function test_RevokeConfirmation() public {
        vm.prank(alice);
        wallet.submitTransaction(bob, 1 ether, "");

        assertEq(wallet.isConfirmed(0, alice), true);

        vm.prank(alice);
        wallet.revokeConfirmation(0);

        assertEq(wallet.isConfirmed(0, alice), false);
    }

    function test_RevertWhen_ExecuteTwice() public {
        vm.deal(address(wallet), 1 ether);

        vm.prank(alice);
        wallet.submitTransaction(bob, 0.5 ether, "");

        vm.prank(bob);
        wallet.confirmTransaction(0);

        vm.prank(alice);
        wallet.executeTransaction(0);

        vm.expectRevert("already executed");

        vm.prank(alice);
        wallet.executeTransaction(0);
    }
}
