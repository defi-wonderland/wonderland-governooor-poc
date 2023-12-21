/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {
  Address,
  AliceGovernor,
  Checkpoints,
  Context,
  DoubleEndedQueue,
  ECDSA,
  EIP712,
  ERC165,
  IERC1155Receiver,
  IERC165,
  IERC6372,
  IERC721Receiver,
  IWonderGovernor,
  IWonderVotes,
  Nonces,
  SafeCast,
  SignatureChecker,
  Time,
  WonderGovernor,
  WonderVotes
} from 'solidity/examples/AliceGovernor.sol';
import 'solidity/contracts/governance/WonderGovernor.sol';
import 'solidity/contracts/governance/utils/WonderVotes.sol';

contract MockAliceGovernor is AliceGovernor, Test {
  constructor(address _wonderToken) AliceGovernor(_wonderToken) {}

  /// Mocked State Variables

  function set_votes(WonderVotes _votes) public {
    votes = _votes;
  }

  function mock_call_votes(WonderVotes _votes) public {
    vm.mockCall(address(this), abi.encodeWithSignature('votes()'), abi.encode(_votes));
  }

  function set__countingMode(string memory __countingMode) public {
    _countingMode = __countingMode;
  }

  function set___proposalTypes(uint8[] memory ___proposalTypes) public {
    __proposalTypes = ___proposalTypes;
  }

  function set_receipts(uint256 _key0, address _key1, AliceGovernor.BallotReceipt memory _value) public {
    receipts[_key0][_key1] = _value;
  }

  function mock_call_receipts(uint256 _key0, address _key1, AliceGovernor.BallotReceipt memory _value) public {
    vm.mockCall(address(this), abi.encodeWithSignature('receipts(uint256,address)', _key0, _key1), abi.encode(_value));
  }

  function set_proposalTracks(uint256 _key0, AliceGovernor.ProposalTrack memory _value) public {
    proposalTracks[_key0] = _value;
  }

  function mock_call_proposalTracks(uint256 _key0, AliceGovernor.ProposalTrack memory _value) public {
    vm.mockCall(address(this), abi.encodeWithSignature('proposalTracks(uint256)', _key0), abi.encode(_value));
  }

  /// Mocked External Functions

  function mock_call_CLOCK_MODE(string memory _clockMode) public {
    vm.mockCall(address(this), abi.encodeWithSignature('CLOCK_MODE()'), abi.encode(_clockMode));
  }

  function mock_call_COUNTING_MODE(string memory _return0) public {
    vm.mockCall(address(this), abi.encodeWithSignature('COUNTING_MODE()'), abi.encode(_return0));
  }

  function mock_call_clock(uint48 _return0) public {
    vm.mockCall(address(this), abi.encodeWithSignature('clock()'), abi.encode(_return0));
  }

  function mock_call_votingPeriod(uint256 _return0) public {
    vm.mockCall(address(this), abi.encodeWithSignature('votingPeriod()'), abi.encode(_return0));
  }

  function mock_call_votingDelay(uint256 _return0) public {
    vm.mockCall(address(this), abi.encodeWithSignature('votingDelay()'), abi.encode(_return0));
  }

  function mock_call_quorum(uint256 _timepoint, uint8 _proposalType, uint256 _return0) public {
    vm.mockCall(
      address(this), abi.encodeWithSignature('quorum(uint256,uint8)', _timepoint, _proposalType), abi.encode(_return0)
    );
  }

  function mock_call_hasVoted(uint256 _proposalId, address _account, bool _return0) public {
    vm.mockCall(
      address(this), abi.encodeWithSignature('hasVoted(uint256,address)', _proposalId, _account), abi.encode(_return0)
    );
  }

  function mock_call_proposalThreshold(uint8 _proposalType, uint256 _return0) public {
    vm.mockCall(address(this), abi.encodeWithSignature('proposalThreshold(uint8)', _proposalType), abi.encode(_return0));
  }

  function mock_call_isValidProposalType(uint8 _proposalType, bool _return0) public {
    vm.mockCall(
      address(this), abi.encodeWithSignature('isValidProposalType(uint8)', _proposalType), abi.encode(_return0)
    );
  }

  /// Mocked Internal Functions

  struct _getVotesOutput {
    uint256 _returnParam0;
  }

  mapping(bytes32 => _getVotesOutput) private _getVotesOutputs;
  bytes32[] private _getVotesInputHashes;

  function mock_call__getVotes(
    address _account,
    uint8 _proposalType,
    uint256 _timepoint,
    bytes memory _params,
    uint256 _returnParam0
  ) public {
    bytes32 _key = keccak256(abi.encode(_account, _proposalType, _timepoint, _params));
    _getVotesOutputs[_key] = _getVotesOutput(_returnParam0);
    for (uint256 _i; _i < _getVotesInputHashes.length; ++_i) {
      if (_key == _getVotesInputHashes[_i]) {
        return;
      }
    }
    _getVotesInputHashes.push(_key);
  }

  function _getVotes(
    address _account,
    uint8 _proposalType,
    uint256 _timepoint,
    bytes memory _params
  ) internal view override returns (uint256 _returnParam0) {
    bytes32 _key = keccak256(abi.encode(_account, _proposalType, _timepoint, _params));
    for (uint256 _i; _i < _getVotesInputHashes.length; ++_i) {
      if (_key == _getVotesInputHashes[_i]) {
        _getVotesOutput memory _output = _getVotesOutputs[_key];
        return (_output._returnParam0);
      }
    }
    return super._getVotes(_account, _proposalType, _timepoint, _params);
  }

  struct _isValidProposalTypeOutput {
    bool _returnParam0;
  }

  mapping(bytes32 => _isValidProposalTypeOutput) private _isValidProposalTypeOutputs;
  bytes32[] private _isValidProposalTypeInputHashes;

  function mock_call__isValidProposalType(uint8 _proposalType, bool _returnParam0) public {
    bytes32 _key = keccak256(abi.encode(_proposalType));
    _isValidProposalTypeOutputs[_key] = _isValidProposalTypeOutput(_returnParam0);
    for (uint256 _i; _i < _isValidProposalTypeInputHashes.length; ++_i) {
      if (_key == _isValidProposalTypeInputHashes[_i]) {
        return;
      }
    }
    _isValidProposalTypeInputHashes.push(_key);
  }

  function _isValidProposalType(uint8 _proposalType) internal view override returns (bool _returnParam0) {
    bytes32 _key = keccak256(abi.encode(_proposalType));
    for (uint256 _i; _i < _isValidProposalTypeInputHashes.length; ++_i) {
      if (_key == _isValidProposalTypeInputHashes[_i]) {
        _isValidProposalTypeOutput memory _output = _isValidProposalTypeOutputs[_key];
        return (_output._returnParam0);
      }
    }
    return super._isValidProposalType(_proposalType);
  }

  function mock_call__countVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    uint256 _weight,
    bytes memory _params
  ) public {
    vm.mockCall(
      address(this),
      abi.encodeWithSignature(
        '_countVote(uint256,address,uint8,uint256,bytes)', _proposalId, _account, _support, _weight, _params
      ),
      abi.encode()
    );
  }

  function _countVote(
    uint256 _proposalId,
    address _account,
    uint8 _support,
    uint256 _weight,
    bytes memory _params
  ) internal override {
    (bool _success, bytes memory _data) = address(this).call(
      abi.encodeWithSignature(
        '_countVote(uint256,address,uint8,uint256,bytes)', _proposalId, _account, _support, _weight, _params
      )
    );
    if (_success) return abi.decode(_data, ());
    else return super._countVote(_proposalId, _account, _support, _weight, _params);
  }

  struct _quorumReachedOutput {
    bool _returnParam0;
  }

  mapping(bytes32 => _quorumReachedOutput) private _quorumReachedOutputs;
  bytes32[] private _quorumReachedInputHashes;

  function mock_call__quorumReached(uint256 _proposalId, bool _returnParam0) public {
    bytes32 _key = keccak256(abi.encode(_proposalId));
    _quorumReachedOutputs[_key] = _quorumReachedOutput(_returnParam0);
    for (uint256 _i; _i < _quorumReachedInputHashes.length; ++_i) {
      if (_key == _quorumReachedInputHashes[_i]) {
        return;
      }
    }
    _quorumReachedInputHashes.push(_key);
  }

  function _quorumReached(uint256 _proposalId) internal view override returns (bool _returnParam0) {
    bytes32 _key = keccak256(abi.encode(_proposalId));
    for (uint256 _i; _i < _quorumReachedInputHashes.length; ++_i) {
      if (_key == _quorumReachedInputHashes[_i]) {
        _quorumReachedOutput memory _output = _quorumReachedOutputs[_key];
        return (_output._returnParam0);
      }
    }
    return super._quorumReached(_proposalId);
  }

  struct _voteSucceededOutput {
    bool _returnParam0;
  }

  mapping(bytes32 => _voteSucceededOutput) private _voteSucceededOutputs;
  bytes32[] private _voteSucceededInputHashes;

  function mock_call__voteSucceeded(uint256 _proposalId, bool _returnParam0) public {
    bytes32 _key = keccak256(abi.encode(_proposalId));
    _voteSucceededOutputs[_key] = _voteSucceededOutput(_returnParam0);
    for (uint256 _i; _i < _voteSucceededInputHashes.length; ++_i) {
      if (_key == _voteSucceededInputHashes[_i]) {
        return;
      }
    }
    _voteSucceededInputHashes.push(_key);
  }

  function _voteSucceeded(uint256 _proposalId) internal view override returns (bool _returnParam0) {
    bytes32 _key = keccak256(abi.encode(_proposalId));
    for (uint256 _i; _i < _voteSucceededInputHashes.length; ++_i) {
      if (_key == _voteSucceededInputHashes[_i]) {
        _voteSucceededOutput memory _output = _voteSucceededOutputs[_key];
        return (_output._returnParam0);
      }
    }
    return super._voteSucceeded(_proposalId);
  }
}
