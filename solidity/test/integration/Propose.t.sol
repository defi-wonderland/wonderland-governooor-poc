// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import './IntegrationBase.t.sol';

import {WonderVotes} from 'contracts/governance/utils/WonderVotes.sol';
import {WonderGovernor} from 'contracts/governance/WonderGovernor.sol';

contract Integration_Propose is IntegrationBase {
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

  function _vote(uint256 _proposalId, uint256 _forVoters) internal {
    for (uint256 _i = 0; _i < VOTERS_NUMBER; _i++) {
      address _holder = holders[_i];
      vm.prank(_holder);

      // for 60% , against 40%
      uint8 _vote = _forVoters > _i ? 1 : 0;
      // Vote
      governor.castVote(_proposalId, _vote);
    }
  }

  function test_ProposalSucceeded() public {
    uint256 _proposalId = _propose();

    _mineBlocks(governor.votingDelay() + 1);

    uint256 _forVoters = VOTERS_NUMBER / 2 + 1;
    uint256 _againstVoters = VOTERS_NUMBER - _forVoters;

    _vote(_proposalId, _forVoters);

    (uint256 _id, uint256 _votes, uint256 _forVotes, uint256 _againstVotes, uint256 _abstainVotes) =
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

    _vote(_proposalId, _forVoters);

    (uint256 _id, uint256 _votes, uint256 _forVotes, uint256 _againstVotes, uint256 _abstainVotes) =
      AliceGovernor(payable(address(governor))).proposalTracks(_proposalId);

    assertEq(_forVotes, INITIAL_VOTERS_BALANCE * _forVoters);
    assertEq(_againstVotes, INITIAL_VOTERS_BALANCE * _againstVoters);
    assertEq(_abstainVotes, 0);
    assertEq(_votes, INITIAL_VOTERS_BALANCE * VOTERS_NUMBER);

    // End voting period
    _mineBlocks(governor.votingPeriod());

    assertEq(uint256(governor.state(_proposalId)), 3);
  }
}
