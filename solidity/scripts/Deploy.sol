// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from 'forge-std/Script.sol';

abstract contract Deploy is Script {
  function _deploy() internal {
    vm.startBroadcast();
    // Deploy the contract
    vm.stopBroadcast();
  }
}

contract DeployMainnet is Deploy {
  function run() external {
    _deploy();
  }
}

contract DeployGoerli is Deploy {
  function run() external {
    _deploy();
  }
}
