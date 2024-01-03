// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IWonderGovernor} from 'interfaces/governance/IWonderGovernor.sol';
import {IWonderVotes} from 'interfaces/governance/utils/IWonderVotes.sol';
import {AliceGovernor} from 'examples/AliceGovernor.sol';
import {RabbitToken} from 'examples/RabbitToken.sol';

import {Script, console} from 'forge-std/Script.sol';

abstract contract Deploy is Script {
  function _deploy(address _deployer) internal {
    vm.startBroadcast(_deployer);

    // Deploy the contracts
    address tokenAddress = vm.computeCreateAddress(_deployer, vm.getNonce(_deployer) + 1);
    AliceGovernor governor = new AliceGovernor(tokenAddress);
    console.log('WonderGovernor:', address(governor));
    RabbitToken rabbitToken = new RabbitToken(AliceGovernor(payable(address(governor))));
    console.log('WonderVotes:', address(rabbitToken));

    vm.stopBroadcast();
  }
}

contract DeployMainnet is Deploy {
  function run() external {
    address _deployer = vm.rememberKey(vm.envUint('MAINNET_DEPLOYER_PK'));

    _deploy(_deployer);
  }
}

contract DeployGoerli is Deploy {
  function run() external {
    address _deployer = vm.rememberKey(vm.envUint('GOERLI_DEPLOYER_PK'));

    _deploy(_deployer);
  }
}

contract DeployLocal is Deploy {
  function run() external {
    address _deployer = vm.rememberKey(vm.envUint('LOCAL_DEPLOYER_PK'));

    _deploy(_deployer);
  }
}

contract DeployOptimism is Deploy {
  function run() external {
    address _deployer = vm.rememberKey(vm.envUint('OPTIMISM_DEPLOYER_PK'));

    _deploy(_deployer);
  }
}
