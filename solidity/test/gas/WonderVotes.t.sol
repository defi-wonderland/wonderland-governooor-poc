// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import 'forge-std/Test.sol';

import {WonderGovernor} from 'contracts/governance/WonderGovernor.sol';
import {IWonderGovernor} from 'interfaces/governance/IWonderGovernor.sol';
import {AliceGovernor} from 'examples/AliceGovernor.sol';
import {IWonderVotes} from 'interfaces/governance/utils/IWonderVotes.sol';
import {IWonderGovernor} from 'interfaces/governance/IWonderGovernor.sol';
import {WonderVotes} from 'contracts/governance/utils/WonderVotes.sol';

import {RabbitToken} from 'examples/RabbitToken.sol';
import {TestExtended} from '../utils/TestExtended.sol';

contract GovernorForTest is AliceGovernor {
  constructor(address _wonderToken) AliceGovernor(_wonderToken) {}

  function getProposal(uint256 _proposalId) public view returns (ProposalCore memory) {
    return _getProposal(_proposalId);
  }
}

contract WonderVotesForTest is RabbitToken {
  constructor(AliceGovernor _governor) RabbitToken(_governor) {}

  function mint(address _account, uint256 _amount) public {
    _mint(_account, _amount);
  }

  function burn(uint256 _amount) public {
    _burn(msg.sender, _amount);
  }
}

contract BaseTest is TestExtended {
  address deployer = makeAddr('deployer');
  address hatter = makeAddr('hatter');
  address cat = makeAddr('cat');

  IWonderGovernor governor;
  RabbitToken rabbit;

  function _mockgetSnapshotVotes(address _account, uint8 _proposalType, uint256 _timePoint, uint256 _votes) internal {
    vm.mockCall(
      address(rabbit),
      abi.encodeWithSelector(IWonderVotes.getSnapshotVotes.selector, _account, _proposalType, _timePoint),
      abi.encode(_votes)
    );
  }

  function setUp() public {
    vm.startPrank(deployer);

    address tokenAddress = vm.computeCreateAddress(deployer, vm.getNonce(deployer) + 1);
    governor = new GovernorForTest(tokenAddress);
    rabbit = new WonderVotesForTest(AliceGovernor(payable(address(governor))));

    vm.stopPrank();
  }

  function _createProposal(
    uint8 _proposalType,
    address _target,
    uint256 _value,
    bytes memory _calldata,
    string memory _description,
    uint256 _proposerVotes
  ) internal returns (uint256) {
    vm.assume(_proposalType < governor.proposalTypes().length);
    vm.assume(_proposerVotes >= governor.proposalThreshold(_proposalType));

    _mockgetSnapshotVotes(hatter, _proposalType, block.number - 1, _proposerVotes);

    address[] memory _targets = new address[](1);
    _targets[0] = _target;

    uint256[] memory _values = new uint256[](1);
    _values[0] = _value;

    bytes[] memory _calldatas = new bytes[](1);
    _calldatas[0] = _calldata;

    vm.prank(hatter);
    return governor.propose(_proposalType, _targets, _values, _calldatas, block.number - 1, _description);
  }
}

contract Gas_GetVotesAndTransfer is BaseTest {
  event VoteCastWithParams(
    address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason, bytes params
  );

  function test_bal(
    uint8 _proposalType,
    address _target,
    uint256 _value,
    bytes memory _calldata,
    string memory _description,
    uint256 _proposerVotes,
    uint128 _voterVotes,
    uint8 _previousTransfers
  ) public {
    vm.assume(_proposalType < governor.proposalTypes().length);
    vm.assume(_proposerVotes >= governor.proposalThreshold(_proposalType));

    for (uint256 i = 0; i <= _previousTransfers; i++) {
      (WonderVotesForTest(address(rabbit))).mint(cat, 1);
    }

    uint256 balanceBlock = block.number;
    (WonderVotesForTest(address(rabbit))).mint(cat, _voterVotes);
    _mineBlock();

    uint256 _voteStart = block.number + governor.votingDelay();
    _mockgetSnapshotVotes(hatter, _proposalType, block.number - 1, _proposerVotes);

    uint256 _proposalId = _createProposal(_proposalType, _target, _value, _calldata, _description, _proposerVotes);

    for (uint256 i = 0; i <= governor.votingDelay(); i++) {
      (WonderVotesForTest(address(rabbit))).mint(cat, 1);
      _mineBlock();
    }

    vm.prank(cat);
    governor.castVote(_proposalId, 1, balanceBlock);

    (uint256 _id, uint256 _votes, uint256 _forVotes, uint256 _againstVotes, uint256 _abstainVotes) =
      AliceGovernor(payable(address(governor))).proposalTracks(_proposalId);
  }

  function test_get_votes(uint8 _previousTransfers, uint8 _afterTransfers, uint8 _proposalStart) public {
    vm.assume(_proposalStart >= _previousTransfers && _proposalStart <= _afterTransfers);
    vm.prank(cat);
    rabbit.delegate(cat);

    for (uint256 i = 0; i <= _previousTransfers; i++) {
      (WonderVotesForTest(address(rabbit))).mint(cat, 1);
      _mineBlock();
    }

    for (uint256 i = 0; i <= _afterTransfers; i++) {
      (WonderVotesForTest(address(rabbit))).mint(cat, 1);
      _mineBlock();
    }

    emit log_uint(rabbit.getSnapshotVotes(cat, 0, _proposalStart, _proposalStart));
  }

  function test_get_votes_with_transfer(uint8 _previousTransfers, uint8 _afterTransfers, uint8 _proposalStart) public {
    vm.assume(_proposalStart >= _previousTransfers && _proposalStart <= _afterTransfers);

    vm.prank(cat);
    rabbit.delegate(cat);

    vm.prank(hatter);
    rabbit.delegate(hatter);

    (WonderVotesForTest(address(rabbit))).mint(hatter, uint256(_previousTransfers) + _afterTransfers);

    vm.startPrank(hatter);
    for (uint256 i = 0; i < _previousTransfers; i++) {
      rabbit.transfer(cat, 1);
      _mineBlock();
    }

    for (uint256 i = 0; i < _afterTransfers; i++) {
      rabbit.transfer(cat, 1);
      _mineBlock();
    }

    vm.stopPrank();

    emit log_uint(rabbit.getSnapshotVotes(cat, 0, _proposalStart, _proposalStart));
  }

  function test_get_votes_with_transfer_without_delegation(
    uint8 _previousTransfers,
    uint8 _afterTransfers,
    uint8 _proposalStart
  ) public {
    vm.assume(_proposalStart >= _previousTransfers && _proposalStart <= _afterTransfers);

    (WonderVotesForTest(address(rabbit))).mint(hatter, uint256(_previousTransfers) + _afterTransfers);

    vm.startPrank(hatter);
    for (uint256 i = 0; i < _previousTransfers; i++) {
      rabbit.transfer(cat, 1);
      _mineBlock();
    }

    for (uint256 i = 0; i < _afterTransfers; i++) {
      rabbit.transfer(cat, 1);
      _mineBlock();
    }

    vm.stopPrank();

    vm.prank(cat);
    rabbit.delegate(cat);

    emit log_uint(rabbit.getSnapshotVotes(cat, 0, _proposalStart, _proposalStart));
  }
}
