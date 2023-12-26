// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// solhint-disable no-unused-import
// solhint-disable-next-line no-console
import {console} from 'forge-std/console.sol';

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {IWonderVotes} from 'interfaces/governance/utils/IWonderVotes.sol';
import {IWonderGovernor} from 'interfaces/governance/IWonderGovernor.sol';

import {AliceGovernor} from 'examples/AliceGovernor.sol';
import {RabbitToken} from 'examples/RabbitToken.sol';

import {TestExtended} from '../utils/TestExtended.sol';

contract IntegrationBase is TestExtended {
  uint256 public constant FORK_BLOCK = 111_361_902;

  uint256 internal _initialBalance = 100_000 ether;

  address public deployer = makeAddr('deployer');
  address public proposer = makeAddr('proposer');
  address public proposer2 = makeAddr('proposer2');

  address[] public holders;

  IWonderVotes public rabbitToken;
  IWonderGovernor public governor;

  uint256 public constant INITIAL_VOTERS_BALANCE = 100_000e18;
  uint8 public constant VOTERS_NUMBER = 10;

  function setUp() public virtual {
    vm.createSelectFork(vm.rpcUrl('optimism'), FORK_BLOCK);

    // Deploy the governance contracts
    vm.startPrank(deployer);

    address tokenAddress = vm.computeCreateAddress(deployer, vm.getNonce(deployer) + 1);
    governor = new AliceGovernor(tokenAddress);
    rabbitToken = new RabbitToken(AliceGovernor(payable(address(governor))));

    vm.stopPrank();

    for (uint256 i = 0; i < VOTERS_NUMBER; i++) {
      address holder = makeAddr(string(abi.encodePacked('holder', i)));
      holders.push(holder);
      deal(tokenAddress, holder, INITIAL_VOTERS_BALANCE);
      vm.prank(holder);

      // start tracking votes
      rabbitToken.delegate(holder);
    }

    _mineBlock();
  }

  event ProposalCreated(
    uint256 proposalId,
    uint8 proposalType,
    address proposer,
    address[] targets,
    uint256[] values,
    string[] signatures,
    bytes[] calldatas,
    uint256 voteStart,
    uint256 voteEnd,
    string description
  );
}
