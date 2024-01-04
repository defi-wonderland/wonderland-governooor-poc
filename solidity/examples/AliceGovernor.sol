// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import 'contracts/governance/WonderGovernor.sol';
import 'contracts/governance/utils/WonderVotes.sol';

contract AliceGovernor is WonderGovernor {
  WonderVotes public votes;
  string internal _countingMode = 'support=bravo&quorum=bravo';
  uint8[] internal __proposalTypes = [0, 1, 2, 3];

  mapping(uint256 proposalId => mapping(address => BallotReceipt)) public receipts;
  mapping(uint256 proposalId => ProposalTrack) public proposalTracks;

  /// @notice Ballot receipt record for a voter
  struct BallotReceipt {
    /// @notice Whether or not a vote has been cast
    bool hasVoted;
    /// @notice 0 = Against, 1 = For, 2 = Abstain
    uint8 support;
    /// @notice The number of votes the voter had, which were cast
    uint256 votes;
  }

  struct ProposalTrack {
    uint256 proposalId;
    uint256 votes;
    uint256 forVotes;
    uint256 againstVotes;
    uint256 abstainVotes;
  }

  constructor(address _wonderToken) WonderGovernor('AliceGovernor') {
    votes = WonderVotes(_wonderToken);
  }

  function CLOCK_MODE() public view override returns (string memory _clockMode) {
    return votes.CLOCK_MODE();
  }

  function COUNTING_MODE() external view override returns (string memory) {
    return _countingMode;
  }

  function _getVotes(
    address _account,
    uint8 _proposalType,
    uint256 _timepoint,
    uint256 _voteStart,
    bytes memory _params
  ) internal view virtual override returns (uint256) {
    return votes.getSnapshotVotes(_account, _proposalType, _timepoint, _voteStart);
  }

  function clock() public view override returns (uint48) {
    return votes.clock();
  }

  function votingPeriod() public view override returns (uint256) {
    // ~3 days in blocks (assuming 15s blocks)
    return 17_280;
  }

  function votingDelay() public view override returns (uint256) {
    // 1 block
    return 1;
  }

  function quorum(uint256 _timepoint, uint8 _proposalType) public view override returns (uint256) {
    // same quorum for all proposals types and timepoints
    return 400_000e18;
  }

  function _proposalTypes() internal view override returns (uint8[] memory) {
    return __proposalTypes;
  }

  function _isValidProposalType(uint8 _proposalType) internal view virtual override returns (bool) {
    return _proposalType < __proposalTypes.length;
  }

  function _countVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    uint256 _weight,
    bytes memory _params
  ) internal virtual override {
    proposalTracks[_proposalId].votes += _weight;
    if (_support == 0) {
      proposalTracks[_proposalId].againstVotes += _weight;
    } else if (_support == 1) {
      proposalTracks[_proposalId].forVotes += _weight;
    } else if (_support == 2) {
      proposalTracks[_proposalId].abstainVotes += _weight;
    } else {
      revert InvalidVoteType(_support);
    }

    BallotReceipt storage _receipt = receipts[_proposalId][_account];

    _receipt.hasVoted = true;
    _receipt.support = _support;
    _receipt.votes = _weight;
  }

  function hasVoted(uint256 _proposalId, address _account) external view override returns (bool) {
    return receipts[_proposalId][_account].hasVoted;
  }

  function _quorumReached(uint256 _proposalId) internal view virtual override returns (bool) {
    ProposalTrack memory _proposalTrack = proposalTracks[_proposalId];
    ProposalCore memory _proposal = _getProposal(_proposalId);

    uint256 _totalVotes = _proposalTrack.forVotes + _proposalTrack.againstVotes + _proposalTrack.abstainVotes;
    return _totalVotes >= quorum(_proposal.voteStart, _proposal.proposalType);
  }

  function _voteSucceeded(uint256 _proposalId) internal view virtual override returns (bool) {
    ProposalTrack memory _proposalTrack = proposalTracks[_proposalId];

    bool _succeded = _quorumReached(_proposalId) && _proposalTrack.forVotes > _proposalTrack.againstVotes;
    return _succeded;
  }

  function proposalThreshold(uint8 _proposalType) public view override returns (uint256) {
    // same threshold for all proposals types
    return 100_000e18;
  }

  function isValidProposalType(uint8 _proposalType) external view returns (bool) {
    return _isValidProposalType(_proposalType);
  }

  error InvalidVoteType(uint8 voteType);
}
