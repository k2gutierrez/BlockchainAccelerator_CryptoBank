// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Test, console2} from "forge-std/Test.sol";
import {CryptoBank} from "../src/CryptoBank.sol";
import {CryptoBankScript} from "../script/CryptoBank.s.sol";

contract CryptoBankTest is Test {

    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 public maxBalance;

    uint256 constant AMOUNT_TO_DEPOSIT_1 = 1 ether;

    uint256 constant AMOUNT_TO_DEPOSIT_2 = 3 ether;

    uint256 constant AMOUNT_TO_DEPOSIT_3 = 5 ether;

    CryptoBank public cryptoBank;

    address public admin;
    address public owner;

    address public USER1 = makeAddr("USER1");
    address public USER2 = makeAddr("USER2");

    function setUp() public {
        CryptoBankScript deployer = new CryptoBankScript();
        cryptoBank = deployer.run();
        admin = cryptoBank.getAdminAddress();
        owner = cryptoBank.getOwnerAddress();
        maxBalance = cryptoBank.getMaxBalance();

        vm.deal(USER1, STARTING_BALANCE);
    }

    function testDepositEther() public {
        vm.startPrank(USER1);
        uint256 startingBalanceUser1 = cryptoBank.getMyBalance();
        uint256 user1WalletBalance = address(USER1).balance;
        cryptoBank.depositEther{value: AMOUNT_TO_DEPOSIT_3}();
        uint256 newBankBalance = cryptoBank.getMyBalance();
        uint256 afterDepositUserBalance = address(USER1).balance;
        vm.stopPrank();

        assertEq(newBankBalance, AMOUNT_TO_DEPOSIT_3);
        assertNotEq(startingBalanceUser1, newBankBalance);
        assertNotEq(user1WalletBalance, afterDepositUserBalance);

    }

    function testDepositEtherMultipleTimes() public {
        vm.startPrank(USER1);
        uint256 startingBalanceUser1 = cryptoBank.getMyBalance();
        uint256 user1WalletBalance = address(USER1).balance;
        cryptoBank.depositEther{value: AMOUNT_TO_DEPOSIT_1}();
        cryptoBank.depositEther{value: AMOUNT_TO_DEPOSIT_2}();
        uint256 newBankBalance = cryptoBank.getMyBalance();
        uint256 afterDepositUserBalance = address(USER1).balance;
        vm.stopPrank();

        assertEq(newBankBalance, AMOUNT_TO_DEPOSIT_1 + AMOUNT_TO_DEPOSIT_2);
        assertNotEq(startingBalanceUser1, newBankBalance);
        assertNotEq(user1WalletBalance, afterDepositUserBalance);
    }

    function testDepositEtherAndRevertingForReachingMaxDepositAmount() public {
        vm.startPrank(USER1);
        cryptoBank.depositEther{value: AMOUNT_TO_DEPOSIT_3}();
        vm.expectRevert(CryptoBank.CryptoBank__MaxBalanceReached.selector);
        cryptoBank.depositEther{value: AMOUNT_TO_DEPOSIT_1}();
        vm.stopPrank();
    }

    function testWithdraw() public {
        vm.startPrank(USER1);
        cryptoBank.depositEther{value: AMOUNT_TO_DEPOSIT_3}();
        uint256 user1Wallet = address(USER1).balance;
        cryptoBank.withdraw(AMOUNT_TO_DEPOSIT_2);
        uint256 user1BankBalance = cryptoBank.getMyBalance();
        vm.stopPrank();
        uint256 user1WalletAfterWithdraw = address(USER1).balance;

        assertEq(user1WalletAfterWithdraw, user1Wallet + AMOUNT_TO_DEPOSIT_2);
        assertNotEq(user1Wallet, user1WalletAfterWithdraw);
        assert(user1BankBalance == AMOUNT_TO_DEPOSIT_3 - AMOUNT_TO_DEPOSIT_2);
    }

    function testWithdrawRevertForInsuficientAmountToWithdraw() public {
        uint256 amountToWithdraw = 6 ether;
        vm.startPrank(USER1);
        cryptoBank.depositEther{value: AMOUNT_TO_DEPOSIT_3}();
        vm.expectRevert(CryptoBank.CryptoBank__NotEnoughEther.selector);
        cryptoBank.withdraw(amountToWithdraw);
        vm.stopPrank();
    }

    function testModifyMaxBalance() public {
        uint256 balanceToChange = 10 ether;
        uint256 maxBalanceOld = cryptoBank.getMaxBalance();
        vm.prank(admin);
        cryptoBank.modifyMaxBalance(balanceToChange);
        uint256 maxBalanceNew = cryptoBank.getMaxBalance();

        assertNotEq(maxBalanceOld, maxBalanceNew);
    }

    function testRevertModifyLowerBalance() public {
        uint256 balanceToChange = 1 ether;
        vm.prank(admin);
        vm.expectRevert(CryptoBank.CryptoBank__CannotModifyToLowerBalance.selector);
        cryptoBank.modifyMaxBalance(balanceToChange);
    }

    function testModifyMaxBalanceRevertNotAdmin() public {
        uint256 balanceToChange = 10 ether;
        vm.prank(owner);
        vm.expectRevert(CryptoBank.CryptoBank__OnlyAdminFunction.selector);
        cryptoBank.modifyMaxBalance(balanceToChange);
    }

    function testSetAdmin() public {
        address oldAdmin = cryptoBank.getAdminAddress();
        vm.prank(owner);
        cryptoBank.setAdmin(USER1);
        address newAdmin = cryptoBank.getAdminAddress();
        assertEq(USER1, newAdmin);
        assertNotEq(oldAdmin, newAdmin);
    }

    function testSetAdminRevertNotOwner() public {
        vm.prank(admin);
        vm.expectRevert(CryptoBank.CryptoBank__OnlyOwnerFunction.selector);
        cryptoBank.setAdmin(USER1);
    }

    function testSetAdminRevertCantSetOwnerAsAdmin() public {
        vm.prank(owner);
        vm.expectRevert(CryptoBank.CryptoBank__OwnerCannotBeAdmin.selector);
        cryptoBank.setAdmin(owner);
    }

    function testGetMyBalance() public {
        vm.startPrank(USER1);
        uint256 oldBankBalance = cryptoBank.getMyBalance();
        cryptoBank.depositEther{value: AMOUNT_TO_DEPOSIT_2}();
        uint256 newBankBalance = cryptoBank.getMyBalance();
        assertNotEq(oldBankBalance, newBankBalance);
        assert(newBankBalance == AMOUNT_TO_DEPOSIT_2);
    }

    function testGetUserBalance() public {
        vm.prank(USER1);
        cryptoBank.depositEther{value: AMOUNT_TO_DEPOSIT_2}();

        vm.prank(admin);
        uint256 user1Balance = cryptoBank.getUserBalance(USER1);

        assertEq(user1Balance, AMOUNT_TO_DEPOSIT_2);
    }

    function testGetUserBalanceRevertNotAdmin() public {
        vm.prank(USER1);
        cryptoBank.depositEther{value: AMOUNT_TO_DEPOSIT_2}();

        vm.startPrank(owner);
        vm.expectRevert(CryptoBank.CryptoBank__OnlyAdminFunction.selector);
        cryptoBank.getUserBalance(USER1);
        vm.stopPrank();
    }

    function testGetAdminAddress() public view {
        address adminAddress = cryptoBank.getAdminAddress();
        assertEq(adminAddress, admin);
    }

    function testGetOwnerAddress() public view {
        address ownerAddress = cryptoBank.getOwnerAddress();
        assertEq(ownerAddress, owner);
    }

    function testGetMaxBalance() public view {
        uint256 maxBalanceBank = cryptoBank.getMaxBalance();
        assertEq(maxBalanceBank, maxBalance);
    }


}
