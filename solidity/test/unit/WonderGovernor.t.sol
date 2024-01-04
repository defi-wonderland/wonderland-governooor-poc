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

contract Unit_Propose is BaseTest {
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

  function test_Emit_ProposalCreated(
    uint8 _proposalType,
    address _target,
    uint256 _value,
    bytes memory _calldata,
    string memory _description,
    uint256 _proposerVotes
  ) public {
    vm.assume(_proposalType < governor.proposalTypes().length);
    vm.assume(_proposerVotes >= governor.proposalThreshold(_proposalType));

    // hatter will pass the proposal threshold limit
    _mockgetSnapshotVotes(hatter, _proposalType, block.number - 1, _proposerVotes);

    address[] memory _targets = new address[](1);
    _targets[0] = _target;

    uint256[] memory _values = new uint256[](1);
    _values[0] = _value;

    bytes[] memory _calldatas = new bytes[](1);
    _calldatas[0] = _calldata;

    uint256 _precomputedProposalId =
      governor.hashProposal(_proposalType, _targets, _values, _calldatas, keccak256(bytes(_description)));
    _expectEmit(address(governor));

    emit ProposalCreated(
      _precomputedProposalId,
      _proposalType,
      address(hatter),
      _targets,
      _values,
      new string[](1),
      _calldatas,
      block.number + 1,
      block.number + governor.votingPeriod() + 1,
      _description
    );

    vm.prank(hatter);
    uint256 _proposeId = governor.propose(_proposalType, _targets, _values, _calldatas, block.number - 1, _description);
  }

  function test_Stores_New_Proposal(
    uint8 _proposalType,
    address _target,
    uint256 _value,
    bytes memory _calldata,
    string memory _description,
    uint256 _proposerVotes
  ) public {
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
    uint256 _proposeId = governor.propose(_proposalType, _targets, _values, _calldatas, block.number - 1, _description);

    WonderGovernor.ProposalCore memory _proposal = GovernorForTest(payable(address(governor))).getProposal(_proposeId);

    assertEq(_proposal.proposer, hatter);
    assertEq(_proposal.proposalType, _proposalType);
    assertEq(_proposal.voteStart, block.number + 1);
    assertEq(_proposal.voteDuration, governor.votingPeriod());
    assertEq(_proposal.executed, false);
    assertEq(_proposal.canceled, false);
    assertEq(_proposal.etaSeconds, 0);
  }

  function test_Call_IWonderVotes_GetVotes(
    uint8 _proposalType,
    address _target,
    uint256 _value,
    bytes memory _calldata,
    string memory _description,
    uint256 _proposerVotes
  ) public {
    vm.assume(_proposalType < governor.proposalTypes().length);
    vm.assume(_proposerVotes >= governor.proposalThreshold(_proposalType));

    // hatter will pass the proposal threshold limit
    _mockgetSnapshotVotes(hatter, _proposalType, block.number - 1, _proposerVotes);

    address[] memory _targets = new address[](1);
    _targets[0] = _target;

    uint256[] memory _values = new uint256[](1);
    _values[0] = _value;

    bytes[] memory _calldatas = new bytes[](1);
    _calldatas[0] = _calldata;

    vm.expectCall(
      address(rabbit),
      abi.encodeWithSelector(IWonderVotes.getSnapshotVotes.selector, hatter, _proposalType, block.number - 1),
      1
    );

    vm.prank(hatter);
    governor.propose(_proposalType, _targets, _values, _calldatas, block.number - 1, _description);
  }

  function test_Revert_GovernorInvalidProposalType(
    uint8 _proposalType,
    address _target,
    uint256 _value,
    bytes memory _calldata
  ) public {
    vm.assume(_proposalType >= governor.proposalTypes().length);

    _mockgetSnapshotVotes(hatter, _proposalType, block.number - 1, governor.proposalThreshold(_proposalType));

    address[] memory _targets = new address[](1);
    _targets[0] = _target;

    uint256[] memory _values = new uint256[](1);
    _values[0] = _value;

    bytes[] memory _calldatas = new bytes[](1);
    _calldatas[0] = _calldata;

    vm.prank(hatter);

    vm.expectRevert(abi.encodeWithSelector(IWonderGovernor.GovernorInvalidProposalType.selector, _proposalType));
    governor.propose(_proposalType, _targets, _values, _calldatas, block.number - 1, '');
  }

  function test_Revert_GovernorInsufficientProposerVotes(
    uint8 _proposalType,
    address _target,
    uint256 _value,
    bytes memory _calldata,
    uint256 _proposerVotes
  ) public {
    vm.assume(_proposalType < governor.proposalTypes().length);
    uint256 _votesThreshold = governor.proposalThreshold(_proposalType);
    vm.assume(_proposerVotes < _votesThreshold);

    _mockgetSnapshotVotes(hatter, _proposalType, block.number - 1, _proposerVotes);

    address[] memory _targets = new address[](1);
    _targets[0] = _target;

    uint256[] memory _values = new uint256[](1);
    _values[0] = _value;

    bytes[] memory _calldatas = new bytes[](1);
    _calldatas[0] = _calldata;

    vm.prank(hatter);

    vm.expectRevert(
      abi.encodeWithSelector(
        IWonderGovernor.GovernorInsufficientProposerVotes.selector, hatter, _proposerVotes, _votesThreshold
      )
    );
    governor.propose(_proposalType, _targets, _values, _calldatas, block.number - 1, '');
  }

  function test_Revert_GovernorInvalidProposalLength(
    uint8 _proposalType,
    address[] memory _targets,
    uint256[] memory _values,
    bytes[] memory _calldatas
  ) public {
    vm.assume(_proposalType < governor.proposalTypes().length);
    vm.assume(_targets.length != _values.length || _targets.length != _calldatas.length || _targets.length == 0);
    _mockgetSnapshotVotes(hatter, _proposalType, block.number - 1, governor.proposalThreshold(_proposalType));

    vm.prank(hatter);
    vm.expectRevert(
      abi.encodeWithSelector(
        IWonderGovernor.GovernorInvalidProposalLength.selector, _targets.length, _calldatas.length, _values.length
      )
    );

    governor.propose(_proposalType, _targets, _values, _calldatas, block.number - 1, '');
  }
}

contract Unit_CastVote is BaseTest {
  event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason);

  function test_Emit_VoteCast(
    uint8 _proposalType,
    uint8 _support,
    address _target,
    uint256 _value,
    bytes memory _calldata,
    string memory _description,
    uint256 _proposerVotes,
    uint256 _voterVotes
  ) public {
    vm.assume(_proposalType < governor.proposalTypes().length);
    vm.assume(_proposerVotes >= governor.proposalThreshold(_proposalType));
    vm.assume(_support < 2);

    _mockgetSnapshotVotes(hatter, _proposalType, block.number - 1, _proposerVotes);
    _mockgetSnapshotVotes(cat, _proposalType, block.number + governor.votingDelay(), _voterVotes);

    uint256 _proposalId = _createProposal(_proposalType, _target, _value, _calldata, _description, _proposerVotes);

    vm.roll(block.number + governor.votingDelay() + 1);

    _expectEmit(address(governor));
    emit VoteCast(cat, _proposalId, _support, _voterVotes, '');

    vm.prank(cat);
    governor.castVote(_proposalId, _support, block.number - 1);
  }

  function test_Call_GetVotes(
    uint8 _proposalType,
    uint8 _support,
    address _target,
    uint256 _value,
    bytes memory _calldata,
    string memory _description,
    uint256 _proposerVotes,
    uint256 _voterVotes
  ) public {
    vm.assume(_proposalType < governor.proposalTypes().length);
    vm.assume(_proposerVotes >= governor.proposalThreshold(_proposalType));
    vm.assume(_voterVotes > 0);
    vm.assume(_support < 2);

    uint256 _voteStart = block.number + governor.votingDelay();
    _mockgetSnapshotVotes(hatter, _proposalType, block.number - 1, _proposerVotes);
    _mockgetSnapshotVotes(cat, _proposalType, _voteStart, _voterVotes);

    uint256 _proposalId = _createProposal(_proposalType, _target, _value, _calldata, _description, _proposerVotes);

    vm.roll(block.number + governor.votingDelay() + 1);

    vm.expectCall(
      address(rabbit), abi.encodeWithSelector(IWonderVotes.getSnapshotVotes.selector, cat, _proposalType, _voteStart), 1
    );

    vm.prank(cat);
    governor.castVote(_proposalId, _support, block.number - 1);
  }

  function test_Count_VoteFor(
    uint8 _proposalType,
    address _target,
    uint256 _value,
    bytes memory _calldata,
    string memory _description,
    uint256 _proposerVotes,
    uint256 _voterVotes
  ) public {
    vm.assume(_proposalType < governor.proposalTypes().length);
    vm.assume(_proposerVotes >= governor.proposalThreshold(_proposalType));

    uint256 _voteStart = block.number + governor.votingDelay();
    _mockgetSnapshotVotes(hatter, _proposalType, block.number - 1, _proposerVotes);
    _mockgetSnapshotVotes(cat, _proposalType, _voteStart, _voterVotes);

    uint256 _proposalId = _createProposal(_proposalType, _target, _value, _calldata, _description, _proposerVotes);

    vm.roll(block.number + governor.votingDelay() + 1);

    vm.prank(cat);
    governor.castVote(_proposalId, 1, block.number - 1);

    (uint256 _id, uint256 _votes, uint256 _forVotes, uint256 _againstVotes, uint256 _abstainVotes) =
      AliceGovernor(payable(address(governor))).proposalTracks(_proposalId);

    assertEq(_votes, _voterVotes);
    assertEq(_forVotes, _voterVotes);
    assertEq(_againstVotes, 0);
    assertEq(_abstainVotes, 0);
  }

  function test_Count_VoteAgainst(
    uint8 _proposalType,
    address _target,
    uint256 _value,
    bytes memory _calldata,
    string memory _description,
    uint256 _proposerVotes,
    uint256 _voterVotes
  ) public {
    vm.assume(_proposalType < governor.proposalTypes().length);
    vm.assume(_proposerVotes >= governor.proposalThreshold(_proposalType));

    uint256 _voteStart = block.number + governor.votingDelay();
    _mockgetSnapshotVotes(hatter, _proposalType, block.number - 1, _proposerVotes);
    _mockgetSnapshotVotes(cat, _proposalType, _voteStart, _voterVotes);

    uint256 _proposalId = _createProposal(_proposalType, _target, _value, _calldata, _description, _proposerVotes);

    vm.roll(block.number + governor.votingDelay() + 1);

    vm.prank(cat);
    governor.castVote(_proposalId, 0, block.number - 1);

    (uint256 _id, uint256 _votes, uint256 _forVotes, uint256 _againstVotes, uint256 _abstainVotes) =
      AliceGovernor(payable(address(governor))).proposalTracks(_proposalId);

    assertEq(_votes, _voterVotes);
    assertEq(_forVotes, 0);
    assertEq(_againstVotes, _voterVotes);
    assertEq(_abstainVotes, 0);
  }

  function test_Count_VoteAbstain(
    uint8 _proposalType,
    address _target,
    uint256 _value,
    bytes memory _calldata,
    string memory _description,
    uint256 _proposerVotes,
    uint256 _voterVotes
  ) public {
    vm.assume(_proposalType < governor.proposalTypes().length);
    vm.assume(_proposerVotes >= governor.proposalThreshold(_proposalType));

    uint256 _voteStart = block.number + governor.votingDelay();
    _mockgetSnapshotVotes(hatter, _proposalType, block.number - 1, _proposerVotes);
    _mockgetSnapshotVotes(cat, _proposalType, _voteStart, _voterVotes);

    uint256 _proposalId = _createProposal(_proposalType, _target, _value, _calldata, _description, _proposerVotes);

    vm.roll(block.number + governor.votingDelay() + 1);

    vm.prank(cat);
    governor.castVote(_proposalId, 2, block.number - 1);

    (uint256 _id, uint256 _votes, uint256 _forVotes, uint256 _againstVotes, uint256 _abstainVotes) =
      AliceGovernor(payable(address(governor))).proposalTracks(_proposalId);

    assertEq(_votes, _voterVotes);
    assertEq(_forVotes, 0);
    assertEq(_againstVotes, 0);
    assertEq(_abstainVotes, _voterVotes);
  }
}

contract Unit_CastVoteWithReason is BaseTest {
  event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason);

  function test_Emit_VoteCast(
    uint8 _proposalType,
    uint8 _support,
    address _target,
    uint256 _value,
    bytes memory _calldata,
    string memory _description,
    uint256 _proposerVotes,
    uint256 _voterVotes,
    string memory _reason
  ) public {
    vm.assume(_proposalType < governor.proposalTypes().length);
    vm.assume(_proposerVotes >= governor.proposalThreshold(_proposalType));
    vm.assume(_support < 2);

    _mockgetSnapshotVotes(hatter, _proposalType, block.number - 1, _proposerVotes);
    _mockgetSnapshotVotes(cat, _proposalType, block.number + governor.votingDelay(), _voterVotes);

    uint256 _proposalId = _createProposal(_proposalType, _target, _value, _calldata, _description, _proposerVotes);

    vm.roll(block.number + governor.votingDelay() + 1);

    _expectEmit(address(governor));
    emit VoteCast(cat, _proposalId, _support, _voterVotes, _reason);

    vm.prank(cat);
    governor.castVoteWithReason(_proposalId, _support, block.number - 1, _reason);
  }

  function test_Call_GetVotes(
    uint8 _proposalType,
    uint8 _support,
    address _target,
    uint256 _value,
    bytes memory _calldata,
    string memory _description,
    uint256 _proposerVotes,
    uint256 _voterVotes,
    string memory _reason
  ) public {
    vm.assume(_proposalType < governor.proposalTypes().length);
    vm.assume(_proposerVotes >= governor.proposalThreshold(_proposalType));
    vm.assume(_voterVotes > 0);
    vm.assume(_support < 2);

    uint256 _voteStart = block.number + governor.votingDelay();
    _mockgetSnapshotVotes(hatter, _proposalType, block.number - 1, _proposerVotes);
    _mockgetSnapshotVotes(cat, _proposalType, _voteStart, _voterVotes);

    uint256 _proposalId = _createProposal(_proposalType, _target, _value, _calldata, _description, _proposerVotes);

    vm.roll(block.number + governor.votingDelay() + 1);

    vm.expectCall(
      address(rabbit), abi.encodeWithSelector(IWonderVotes.getSnapshotVotes.selector, cat, _proposalType, _voteStart), 1
    );

    vm.prank(cat);
    governor.castVoteWithReason(_proposalId, _support, block.number - 1, _reason);
  }

  function test_Count_VoteFor(
    uint8 _proposalType,
    address _target,
    uint256 _value,
    bytes memory _calldata,
    string memory _description,
    uint256 _proposerVotes,
    uint256 _voterVotes,
    string memory _reason
  ) public {
    vm.assume(_proposalType < governor.proposalTypes().length);
    vm.assume(_proposerVotes >= governor.proposalThreshold(_proposalType));

    uint256 _voteStart = block.number + governor.votingDelay();
    _mockgetSnapshotVotes(hatter, _proposalType, block.number - 1, _proposerVotes);
    _mockgetSnapshotVotes(cat, _proposalType, _voteStart, _voterVotes);

    uint256 _proposalId = _createProposal(_proposalType, _target, _value, _calldata, _description, _proposerVotes);

    vm.roll(block.number + governor.votingDelay() + 1);

    vm.prank(cat);
    governor.castVoteWithReason(_proposalId, 1, block.number - 1, _reason);

    (uint256 _id, uint256 _votes, uint256 _forVotes, uint256 _againstVotes, uint256 _abstainVotes) =
      AliceGovernor(payable(address(governor))).proposalTracks(_proposalId);

    assertEq(_votes, _voterVotes);
    assertEq(_forVotes, _voterVotes);
    assertEq(_againstVotes, 0);
    assertEq(_abstainVotes, 0);
  }

  function test_Count_VoteAgainst(
    uint8 _proposalType,
    address _target,
    uint256 _value,
    bytes memory _calldata,
    string memory _description,
    uint256 _proposerVotes,
    uint256 _voterVotes,
    string memory _reason
  ) public {
    vm.assume(_proposalType < governor.proposalTypes().length);
    vm.assume(_proposerVotes >= governor.proposalThreshold(_proposalType));

    uint256 _voteStart = block.number + governor.votingDelay();
    _mockgetSnapshotVotes(hatter, _proposalType, block.number - 1, _proposerVotes);
    _mockgetSnapshotVotes(cat, _proposalType, _voteStart, _voterVotes);

    uint256 _proposalId = _createProposal(_proposalType, _target, _value, _calldata, _description, _proposerVotes);

    vm.roll(block.number + governor.votingDelay() + 1);

    vm.prank(cat);
    governor.castVoteWithReason(_proposalId, 0, block.number - 1, _reason);

    (uint256 _id, uint256 _votes, uint256 _forVotes, uint256 _againstVotes, uint256 _abstainVotes) =
      AliceGovernor(payable(address(governor))).proposalTracks(_proposalId);

    assertEq(_votes, _voterVotes);
    assertEq(_forVotes, 0);
    assertEq(_againstVotes, _voterVotes);
    assertEq(_abstainVotes, 0);
  }

  function test_Count_VoteAbstain(
    uint8 _proposalType,
    address _target,
    uint256 _value,
    bytes memory _calldata,
    string memory _description,
    uint256 _proposerVotes,
    uint256 _voterVotes,
    string memory _reason
  ) public {
    vm.assume(_proposalType < governor.proposalTypes().length);
    vm.assume(_proposerVotes >= governor.proposalThreshold(_proposalType));

    uint256 _voteStart = block.number + governor.votingDelay();
    _mockgetSnapshotVotes(hatter, _proposalType, block.number - 1, _proposerVotes);
    _mockgetSnapshotVotes(cat, _proposalType, _voteStart, _voterVotes);

    uint256 _proposalId = _createProposal(_proposalType, _target, _value, _calldata, _description, _proposerVotes);

    vm.roll(block.number + governor.votingDelay() + 1);

    vm.prank(cat);
    governor.castVoteWithReason(_proposalId, 2, block.number - 1, _reason);

    (uint256 _id, uint256 _votes, uint256 _forVotes, uint256 _againstVotes, uint256 _abstainVotes) =
      AliceGovernor(payable(address(governor))).proposalTracks(_proposalId);

    assertEq(_votes, _voterVotes);
    assertEq(_forVotes, 0);
    assertEq(_againstVotes, 0);
    assertEq(_abstainVotes, _voterVotes);
  }
}

contract Unit_CastVoteWithReasonAndParams is BaseTest {
  event VoteCastWithParams(
    address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason, bytes params
  );

  function test_Emit_VoteCastWithParams(
    uint8 _proposalType,
    uint8 _support,
    address _target,
    uint256 _value,
    bytes memory _calldata,
    string memory _description,
    uint256 _proposerVotes,
    uint256 _voterVotes,
    string memory _reason,
    bytes memory _params
  ) public {
    vm.assume(_proposalType < governor.proposalTypes().length);
    vm.assume(_proposerVotes >= governor.proposalThreshold(_proposalType));
    vm.assume(_support < 2);
    vm.assume(_params.length > 0);

    _mockgetSnapshotVotes(hatter, _proposalType, block.number - 1, _proposerVotes);
    _mockgetSnapshotVotes(cat, _proposalType, block.number + governor.votingDelay(), _voterVotes);

    uint256 _proposalId = _createProposal(_proposalType, _target, _value, _calldata, _description, _proposerVotes);

    vm.roll(block.number + governor.votingDelay() + 1);

    _expectEmit(address(governor));
    emit VoteCastWithParams(cat, _proposalId, _support, _voterVotes, _reason, _params);

    vm.prank(cat);
    governor.castVoteWithReasonAndParams(_proposalId, _support, block.number - 1, _reason, _params);
  }

  function test_Call_GetVotes(
    uint8 _proposalType,
    uint8 _support,
    address _target,
    uint256 _value,
    bytes memory _calldata,
    string memory _description,
    uint256 _proposerVotes,
    uint256 _voterVotes,
    bytes memory _params
  ) public {
    vm.assume(_proposalType < governor.proposalTypes().length);
    vm.assume(_proposerVotes >= governor.proposalThreshold(_proposalType));
    vm.assume(_voterVotes > 0);
    vm.assume(_support < 2);
    vm.assume(_params.length > 0);

    uint256 _voteStart = block.number + governor.votingDelay();
    _mockgetSnapshotVotes(hatter, _proposalType, block.number - 1, _proposerVotes);
    _mockgetSnapshotVotes(cat, _proposalType, _voteStart, _voterVotes);

    uint256 _proposalId = _createProposal(_proposalType, _target, _value, _calldata, _description, _proposerVotes);

    vm.roll(block.number + governor.votingDelay() + 1);

    vm.expectCall(
      address(rabbit), abi.encodeWithSelector(IWonderVotes.getSnapshotVotes.selector, cat, _proposalType, _voteStart), 1
    );

    vm.prank(cat);
    governor.castVoteWithReasonAndParams(_proposalId, _support, block.number - 1, '', _params);
  }

  function test_Count_VoteFor(
    uint8 _proposalType,
    address _target,
    uint256 _value,
    bytes memory _calldata,
    string memory _description,
    uint256 _proposerVotes,
    uint256 _voterVotes,
    string memory _reason,
    bytes memory _params
  ) public {
    vm.assume(_proposalType < governor.proposalTypes().length);
    vm.assume(_proposerVotes >= governor.proposalThreshold(_proposalType));
    vm.assume(_params.length > 0);

    uint256 _voteStart = block.number + governor.votingDelay();
    _mockgetSnapshotVotes(hatter, _proposalType, block.number - 1, _proposerVotes);
    _mockgetSnapshotVotes(cat, _proposalType, _voteStart, _voterVotes);

    uint256 _proposalId = _createProposal(_proposalType, _target, _value, _calldata, _description, _proposerVotes);

    vm.roll(block.number + governor.votingDelay() + 1);

    vm.prank(cat);
    governor.castVoteWithReasonAndParams(_proposalId, 1, block.number - 1, _reason, _params);

    (uint256 _id, uint256 _votes, uint256 _forVotes, uint256 _againstVotes, uint256 _abstainVotes) =
      AliceGovernor(payable(address(governor))).proposalTracks(_proposalId);

    assertEq(_votes, _voterVotes);
    assertEq(_forVotes, _voterVotes);
    assertEq(_againstVotes, 0);
    assertEq(_abstainVotes, 0);
  }

  function test_Count_VoteAgainst(
    uint8 _proposalType,
    address _target,
    uint256 _value,
    bytes memory _calldata,
    string memory _description,
    uint256 _proposerVotes,
    uint256 _voterVotes,
    string memory _reason,
    bytes memory _params
  ) public {
    vm.assume(_proposalType < governor.proposalTypes().length);
    vm.assume(_proposerVotes >= governor.proposalThreshold(_proposalType));
    vm.assume(_params.length > 0);

    uint256 _voteStart = block.number + governor.votingDelay();
    _mockgetSnapshotVotes(hatter, _proposalType, block.number - 1, _proposerVotes);
    _mockgetSnapshotVotes(cat, _proposalType, _voteStart, _voterVotes);

    uint256 _proposalId = _createProposal(_proposalType, _target, _value, _calldata, _description, _proposerVotes);

    vm.roll(block.number + governor.votingDelay() + 1);

    vm.prank(cat);
    governor.castVoteWithReasonAndParams(_proposalId, 0, block.number - 1, _reason, _params);

    (uint256 _id, uint256 _votes, uint256 _forVotes, uint256 _againstVotes, uint256 _abstainVotes) =
      AliceGovernor(payable(address(governor))).proposalTracks(_proposalId);

    assertEq(_votes, _voterVotes);
    assertEq(_forVotes, 0);
    assertEq(_againstVotes, _voterVotes);
    assertEq(_abstainVotes, 0);
  }

  function test_Count_VoteAbstain(
    uint8 _proposalType,
    address _target,
    uint256 _value,
    bytes memory _calldata,
    string memory _description,
    uint256 _proposerVotes,
    uint256 _voterVotes,
    string memory _reason,
    bytes memory _params
  ) public {
    vm.assume(_proposalType < governor.proposalTypes().length);
    vm.assume(_proposerVotes >= governor.proposalThreshold(_proposalType));
    vm.assume(_params.length > 0);

    uint256 _voteStart = block.number + governor.votingDelay();
    _mockgetSnapshotVotes(hatter, _proposalType, block.number - 1, _proposerVotes);
    _mockgetSnapshotVotes(cat, _proposalType, _voteStart, _voterVotes);

    uint256 _proposalId = _createProposal(_proposalType, _target, _value, _calldata, _description, _proposerVotes);

    vm.roll(block.number + governor.votingDelay() + 1);

    vm.prank(cat);
    governor.castVoteWithReasonAndParams(_proposalId, 2, block.number - 1, _reason, _params);

    (uint256 _id, uint256 _votes, uint256 _forVotes, uint256 _againstVotes, uint256 _abstainVotes) =
      AliceGovernor(payable(address(governor))).proposalTracks(_proposalId);

    assertEq(_votes, _voterVotes);
    assertEq(_forVotes, 0);
    assertEq(_againstVotes, 0);
    assertEq(_abstainVotes, _voterVotes);
  }
}
