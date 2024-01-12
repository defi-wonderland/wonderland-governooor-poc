// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import './IntegrationBase.t.sol';

import {WonderVotes} from 'contracts/governance/utils/WonderVotes.sol';
import {WonderGovernor} from 'contracts/governance/WonderGovernor.sol';

contract Integration_Propose is IntegrationBase {
  event ProposalCanceled(uint256 _proposalId);

  function _propose() internal returns (uint256 _proposalId) {
    address[] memory _targets = new address[](1);
    _targets[0] = address(governor);

    uint256[] memory _values = new uint256[](1);
    _values[0] = 1;

    bytes[] memory _calldatas = new bytes[](1);
    _calldatas[0] = abi.encode(0);

    string memory _description = 'test proposal';

    vm.prank(holders[0]);

    // Propose
    return governor.propose(0, _targets, _values, _calldatas, _description);
  }

  function _vote(uint256 _proposalId, uint256 _forVoters, uint256 _againstVoters) internal {
    for (uint256 _i = 0; _i < VOTERS_NUMBER; _i++) {
      address _holder = holders[_i];
      vm.prank(_holder);

      // for 60% , against 40%
      uint8 _support = _forVoters > _i ? 1 : _forVoters + _againstVoters > _i ? 0 : 2;
      // Vote
      governor.castVote(_proposalId, _support);
    }
  }

  function test_ProposalSucceeded() public {
    uint256 _proposalId = _propose();

    _mineBlocks(governor.votingDelay() + 1);

    uint256 _forVoters = VOTERS_NUMBER / 2 + 1;
    uint256 _againstVoters = VOTERS_NUMBER - _forVoters;

    _vote(_proposalId, _forVoters, _againstVoters);

    (uint256 _votes, uint256 _forVotes, uint256 _againstVotes, uint256 _abstainVotes) =
      AliceGovernor(payable(address(governor))).proposalTracks(_proposalId);

    assertEq(_forVotes, INITIAL_VOTERS_BALANCE * _forVoters);
    assertEq(_againstVotes, INITIAL_VOTERS_BALANCE * _againstVoters);
    assertEq(_abstainVotes, 0);
    assertEq(_votes, INITIAL_VOTERS_BALANCE * VOTERS_NUMBER);

    // End voting period
    _mineBlocks(governor.votingPeriod());

    assertEq(uint256(governor.state(_proposalId)), 4);
  }

  function test_ProposalDefeated() public {
    uint256 _proposalId = _propose();

    _mineBlocks(governor.votingDelay() + 1);

    uint256 _againstVoters = VOTERS_NUMBER / 2 + 1;
    uint256 _forVoters = VOTERS_NUMBER - _againstVoters;

    _vote(_proposalId, _forVoters, _againstVoters);

    (uint256 _votes, uint256 _forVotes, uint256 _againstVotes, uint256 _abstainVotes) =
      AliceGovernor(payable(address(governor))).proposalTracks(_proposalId);

    assertEq(_forVotes, INITIAL_VOTERS_BALANCE * _forVoters);
    assertEq(_againstVotes, INITIAL_VOTERS_BALANCE * _againstVoters);
    assertEq(_abstainVotes, 0);
    assertEq(_votes, INITIAL_VOTERS_BALANCE * VOTERS_NUMBER);

    // End voting period
    _mineBlocks(governor.votingPeriod());

    assertEq(uint256(governor.state(_proposalId)), 3);
  }

  function test_ProposalEven() public {
    uint256 _proposalId = _propose();

    _mineBlocks(governor.votingDelay() + 1);

    uint256 _againstVoters = VOTERS_NUMBER / 2;
    uint256 _forVoters = VOTERS_NUMBER - _againstVoters;

    _vote(_proposalId, _forVoters, _againstVoters);

    (uint256 _votes, uint256 _forVotes, uint256 _againstVotes, uint256 _abstainVotes) =
      AliceGovernor(payable(address(governor))).proposalTracks(_proposalId);

    assertEq(_forVotes, INITIAL_VOTERS_BALANCE * _forVoters);
    assertEq(_againstVotes, INITIAL_VOTERS_BALANCE * _againstVoters);
    assertEq(_abstainVotes, 0);
    assertEq(_votes, INITIAL_VOTERS_BALANCE * VOTERS_NUMBER);

    // End voting period
    _mineBlocks(governor.votingPeriod());

    assertEq(uint256(governor.state(_proposalId)), 3);
  }

  function test_ProposalSucceedWithAbstentions() public {
    uint256 _proposalId = _propose();

    _mineBlocks(governor.votingDelay() + 1);

    uint256 _abstainVoters = VOTERS_NUMBER / 2 + 1;
    uint256 _againstVoters = (VOTERS_NUMBER - _abstainVoters) / 2 - 1;
    uint256 _forVoters = VOTERS_NUMBER - _abstainVoters - _againstVoters;

    _vote(_proposalId, _forVoters, _againstVoters);

    (uint256 _votes, uint256 _forVotes, uint256 _againstVotes, uint256 _abstainVotes) =
      AliceGovernor(payable(address(governor))).proposalTracks(_proposalId);

    assertEq(_forVotes, INITIAL_VOTERS_BALANCE * _forVoters);
    assertEq(_againstVotes, INITIAL_VOTERS_BALANCE * _againstVoters);
    assertEq(_abstainVotes, INITIAL_VOTERS_BALANCE * _abstainVoters);
    assertEq(_votes, INITIAL_VOTERS_BALANCE * VOTERS_NUMBER);

    // End voting period
    _mineBlocks(governor.votingPeriod());

    assertEq(uint256(governor.state(_proposalId)), 4);
  }

  function test_ProposeAndCancel() public {
    address[] memory _targets = new address[](1);
    _targets[0] = address(governor);

    uint256[] memory _values = new uint256[](1);
    _values[0] = 1;

    bytes[] memory _calldatas = new bytes[](1);
    _calldatas[0] = abi.encode(0);

    string memory _description = 'test proposal';

    vm.startPrank(holders[0]);

    // Propose
    uint256 _proposalId = governor.propose(0, _targets, _values, _calldatas, _description);

    _expectEmit(address(governor));
    emit ProposalCanceled(_proposalId);

    // Cancel proposal
    governor.cancel(0, _targets, _values, _calldatas, keccak256(bytes(_description)));

    vm.stopPrank();

    _mineBlocks(governor.votingDelay() + 1);

    vm.prank(holders[1]);

    vm.expectRevert(abi.encodeWithSelector(IWonderGovernor.GovernorUnexpectedProposalState.selector, _proposalId, 2, 2));
    governor.castVote(_proposalId, 1);
  }
}
