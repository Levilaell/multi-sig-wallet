// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

contract Deploy is Script {
    function run() public {
        address deployer = vm.envAddress("DEPLOYER_ADDRESS");
        address[] memory _owners = new address[](1);
        _owners[0] = deployer;

        vm.startBroadcast();

        new MultiSigWallet(_owners, 1);

        vm.stopBroadcast();
    }
}
