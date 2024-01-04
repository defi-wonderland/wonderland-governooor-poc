// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import './IntegrationBase.t.sol';

import {WonderVotes} from 'contracts/governance/utils/WonderVotes.sol';
import {WonderGovernor} from 'contracts/governance/WonderGovernor.sol';

contract Integration_Delegation is IntegrationBase {
  function test_AllVotersDelegateToProposer() public {
    // AllVoters delegates to proposer
    for (uint256 _i = 0; _i < VOTERS_NUMBER; _i++) {
      address holder = holders[_i];
      vm.prank(holder);
      rabbitToken.delegate(proposer);
    }

    for (uint256 _i = 0; _i < VOTERS_NUMBER; _i++) {
      address holder = holders[_i];

      for (uint256 _j = 0; _j < governor.proposalTypes().length; _j++) {
        uint8 proposalType = governor.proposalTypes()[_j];
        assertEq(rabbitToken.getVotes(holder, proposalType), 0);
      }
    }

    for (uint256 _j = 0; _j < governor.proposalTypes().length; _j++) {
      uint8 proposalType = governor.proposalTypes()[_j];
      assertEq(rabbitToken.getVotes(proposer, proposalType), INITIAL_VOTERS_BALANCE * VOTERS_NUMBER);
    }
  }

  function test_AllVotersDelegateAndTransferToProposerWithoutProposerDelegation() public {
    for (uint256 _i = 0; _i < VOTERS_NUMBER; _i++) {
      address holder = holders[_i];
      vm.prank(holder);
      rabbitToken.delegate(proposer);
    }

    for (uint256 _i = 0; _i < VOTERS_NUMBER; _i++) {
      address holder = holders[_i];

      for (uint256 _j = 0; _j < governor.proposalTypes().length; _j++) {
        uint8 proposalType = governor.proposalTypes()[_j];
        assertEq(rabbitToken.getVotes(holder, proposalType), 0);
      }
    }

    for (uint256 _j = 0; _j < governor.proposalTypes().length; _j++) {
      uint8 proposalType = governor.proposalTypes()[_j];
      assertEq(rabbitToken.getVotes(proposer, proposalType), INITIAL_VOTERS_BALANCE * VOTERS_NUMBER);
    }

    for (uint256 _i = 0; _i < VOTERS_NUMBER; _i++) {
      address holder = holders[_i];
      vm.prank(holder);
      IERC20(address(rabbitToken)).transfer(proposer, INITIAL_VOTERS_BALANCE);
    }

    for (uint256 _i = 0; _i < VOTERS_NUMBER; _i++) {
      address holder = holders[_i];

      for (uint256 _j = 0; _j < governor.proposalTypes().length; _j++) {
        uint8 proposalType = governor.proposalTypes()[_j];
        assertEq(rabbitToken.getVotes(holder, proposalType), 0);
      }
    }

    // Since proposer never delegated himself, and the accounts that delegates proposer has 0 tokens, proposer has now NO votes
    for (uint256 _j = 0; _j < governor.proposalTypes().length; _j++) {
      uint8 proposalType = governor.proposalTypes()[_j];
      assertEq(rabbitToken.getVotes(proposer, proposalType), 0);
    }
  }

  function test_AllVotersDelegateAndTransferToProposerWithProposerDelegation() public {
    for (uint256 _i = 0; _i < VOTERS_NUMBER; _i++) {
      address holder = holders[_i];
      vm.prank(holder);
      rabbitToken.delegate(proposer);
    }

    for (uint256 _i = 0; _i < VOTERS_NUMBER; _i++) {
      address holder = holders[_i];

      for (uint256 _j = 0; _j < governor.proposalTypes().length; _j++) {
        uint8 proposalType = governor.proposalTypes()[_j];
        assertEq(rabbitToken.getVotes(holder, proposalType), 0);
      }
    }

    for (uint256 _j = 0; _j < governor.proposalTypes().length; _j++) {
      uint8 proposalType = governor.proposalTypes()[_j];
      assertEq(rabbitToken.getVotes(proposer, proposalType), INITIAL_VOTERS_BALANCE * VOTERS_NUMBER);
    }

    // Proposer delegates to himself
    vm.prank(proposer);
    rabbitToken.delegate(proposer);

    for (uint256 _i = 0; _i < VOTERS_NUMBER; _i++) {
      address holder = holders[_i];
      vm.prank(holder);
      IERC20(address(rabbitToken)).transfer(proposer, INITIAL_VOTERS_BALANCE);
    }

    for (uint256 _i = 0; _i < VOTERS_NUMBER; _i++) {
      address holder = holders[_i];

      for (uint256 _j = 0; _j < governor.proposalTypes().length; _j++) {
        uint8 proposalType = governor.proposalTypes()[_j];
        assertEq(rabbitToken.getVotes(holder, proposalType), 0);
      }
    }

    // Since proposer delegated himself, all the token transfers are now voting power of proposer
    for (uint256 _j = 0; _j < governor.proposalTypes().length; _j++) {
      uint8 proposalType = governor.proposalTypes()[_j];
      assertEq(rabbitToken.getVotes(proposer, proposalType), INITIAL_VOTERS_BALANCE * VOTERS_NUMBER);
    }
  }

  function test_AllVotersDelegateByProposalType() public {
    uint8[] memory proposalTypes = governor.proposalTypes();

    for (uint256 _i = 0; _i < proposalTypes.length; _i++) {
      address _holder = holders[_i];
      vm.prank(_holder);
      rabbitToken.delegate(proposer, proposalTypes[_i]);
    }

    for (uint256 _i = 0; _i < proposalTypes.length; _i++) {
      address _holder = holders[_i];
      assertEq(rabbitToken.getVotes(_holder, proposalTypes[_i]), 0);
      assertEq(rabbitToken.getVotes(proposer, proposalTypes[_i]), INITIAL_VOTERS_BALANCE);
    }
  }

  function test_AllVotersDelegatePartially() public {
    uint8[] memory proposalTypes = governor.proposalTypes();

    // 50% of votes
    uint256 _weight = rabbitToken.weightNormalizer() / 2;

    IWonderVotes.Delegate memory _delegate = IWonderVotes.Delegate({account: proposer, weight: _weight});
    IWonderVotes.Delegate memory _delegate2 = IWonderVotes.Delegate({account: proposer2, weight: _weight});

    IWonderVotes.Delegate[] memory _delegates = new IWonderVotes.Delegate[](2);
    _delegates[0] = _delegate;
    _delegates[1] = _delegate2;

    for (uint256 _i = 0; _i < proposalTypes.length; _i++) {
      for (uint256 _j = 0; _j < VOTERS_NUMBER; _j++) {
        address _holder = holders[_j];
        vm.prank(_holder);
        rabbitToken.delegate(_delegates, proposalTypes[_i]);
      }
    }

    for (uint256 _i = 0; _i < proposalTypes.length; _i++) {
      assertEq(rabbitToken.getVotes(proposer, proposalTypes[_i]), INITIAL_VOTERS_BALANCE * VOTERS_NUMBER / 2);
      assertEq(rabbitToken.getVotes(proposer2, proposalTypes[_i]), INITIAL_VOTERS_BALANCE * VOTERS_NUMBER / 2);

      for (uint256 _j = 0; _j < VOTERS_NUMBER; _j++) {
        address _holder = holders[_j];
        assertEq(rabbitToken.getVotes(_holder, proposalTypes[_i]), 0);
      }
    }
  }

  function test_ProposeWithDelegatedVotes() public {
    address _voter1 = holders[0];

    vm.prank(proposer);
    rabbitToken.delegate(proposer);

    // delegate to proposer
    vm.prank(_voter1);
    rabbitToken.delegate(proposer);

    address[] memory _targets = new address[](1);
    _targets[0] = address(governor);

    uint256[] memory _values = new uint256[](1);
    _values[0] = 1;

    bytes[] memory _calldatas = new bytes[](1);
    _calldatas[0] = abi.encode(0);

    string memory _description = 'test proposal';

    // To propose Governor controls the proposal threshold calling getSnapshotVotes, so we need to mine a block to be able to propose
    _mineBlock();

    uint8[] memory _proposalTypes = governor.proposalTypes();

    vm.startPrank(proposer);
    for (uint256 _i = 0; _i < _proposalTypes.length; _i++) {
      uint8 _proposalType = _proposalTypes[_i];

      uint256 _precomputedProposalId =
        governor.hashProposal(_proposalType, _targets, _values, _calldatas, keccak256(bytes(_description)));
      _expectEmit(address(governor));

      emit ProposalCreated(
        _precomputedProposalId,
        _proposalType,
        address(proposer),
        _targets,
        _values,
        new string[](1),
        _calldatas,
        block.number + 1,
        block.number + governor.votingPeriod() + 1,
        _description
      );
      governor.propose(_proposalType, _targets, _values, _calldatas, block.number - 1, _description);
    }
    vm.stopPrank();
  }

  function test_AllVotersChangeDelegation() public {
    uint8[] memory _proposalTypes = governor.proposalTypes();

    for (uint256 _i = 0; _i < VOTERS_NUMBER; _i++) {
      address _holder = holders[_i];
      vm.prank(_holder);
      rabbitToken.delegate(proposer);
    }

    for (uint256 _i = 0; _i < VOTERS_NUMBER; _i++) {
      address _holder = holders[_i];
      vm.prank(_holder);
      rabbitToken.delegate(proposer2);
    }

    for (uint8 i = 0; i < _proposalTypes.length; i++) {
      assertEq(rabbitToken.getVotes(proposer, _proposalTypes[i]), 0);
      assertEq(rabbitToken.getVotes(proposer2, _proposalTypes[i]), INITIAL_VOTERS_BALANCE * VOTERS_NUMBER);
    }
  }

  function test_DelegationSuspensionDoesNotAffectPreviousVotesDelegation() public {
    // Delegates himself befor suspending
    vm.prank(proposer);
    rabbitToken.delegate(proposer);

    uint8[] memory _proposalTypes = governor.proposalTypes();

    // Holder 0 delegates to proposer before suspending
    vm.prank(holders[0]);
    rabbitToken.delegate(proposer);

    for (uint8 i = 0; i < _proposalTypes.length; i++) {
      assertEq(rabbitToken.getVotes(proposer, _proposalTypes[i]), INITIAL_VOTERS_BALANCE);
    }

    // Suspend delegation
    vm.prank(proposer);
    rabbitToken.suspendDelegation(true);

    // Checks that delegation suspension does not affect previous delegation
    for (uint8 i = 0; i < _proposalTypes.length; i++) {
      assertEq(rabbitToken.getVotes(proposer, _proposalTypes[i]), INITIAL_VOTERS_BALANCE);
    }

    // Previous delegation also includes transfers that the holder 0 receives
    vm.prank(holders[1]);
    IERC20(address(rabbitToken)).transfer(holders[0], INITIAL_VOTERS_BALANCE);

    // Checks that the votes is increased
    for (uint8 i = 0; i < _proposalTypes.length; i++) {
      assertEq(rabbitToken.getVotes(proposer, _proposalTypes[i]), INITIAL_VOTERS_BALANCE * 2);
    }

    // Holder 2 delegates to proposer which previously delegated himself before suspending
    vm.prank(holders[2]);
    IERC20(address(rabbitToken)).transfer(proposer, INITIAL_VOTERS_BALANCE);

    // Checks that the votes of proposer is increased
    for (uint8 i = 0; i < _proposalTypes.length; i++) {
      assertEq(rabbitToken.getVotes(proposer, _proposalTypes[i]), INITIAL_VOTERS_BALANCE * 3);
    }
  }
}
