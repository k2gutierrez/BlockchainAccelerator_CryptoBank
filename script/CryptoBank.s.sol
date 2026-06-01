// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.30;

import {Script} from "forge-std/Script.sol";
import { CryptoBank } from "../src/CryptoBank.sol";

contract CryptoBankScript is Script {
    CryptoBank public cryptoBank;
    uint256 maxBalance = 5 ether;
    address admin = makeAddr("admin");

    // function setUp() public {}

    function run() public returns(CryptoBank) {
        vm.startBroadcast();

        cryptoBank = new CryptoBank(maxBalance, admin);

        vm.stopBroadcast();

        return cryptoBank;
    }
}
