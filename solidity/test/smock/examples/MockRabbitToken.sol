/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {AliceGovernor, EIP712, ERC20, RabbitToken, WonderERC20Votes} from 'solidity/examples/RabbitToken.sol';
import {WonderERC20Votes} from 'solidity/contracts/token/ERC20/extensions/WonderERC20Votes.sol';
import {AliceGovernor} from 'solidity/examples/AliceGovernor.sol';
import {EIP712} from 'node_modules/@openzeppelin/contracts/utils/cryptography/EIP712.sol';
import {ERC20} from 'node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract MockRabbitToken is RabbitToken, Test {
  constructor(AliceGovernor _governor) RabbitToken(_governor) {}

  /// Mocked State Variables

  function set_governor(AliceGovernor _governor) public {
    governor = _governor;
  }

  function mock_call_governor(AliceGovernor _governor) public {
    vm.mockCall(address(this), abi.encodeWithSignature('governor()'), abi.encode(_governor));
  }

  /// Mocked External Functions

  function mock_call_proposalTypes(uint8[] memory _return0) public {
    vm.mockCall(address(this), abi.encodeWithSignature('proposalTypes()'), abi.encode(_return0));
  }

  /// Mocked Internal Functions

  struct _getProposalTypesOutput {
    uint8[] _returnParam0;
  }

  mapping(bytes32 => _getProposalTypesOutput) private _getProposalTypesOutputs;
  bytes32[] private _getProposalTypesInputHashes;

  function mock_call__getProposalTypes(uint8[] memory _returnParam0) public {
    bytes32 _key = keccak256(abi.encode());
    _getProposalTypesOutputs[_key] = _getProposalTypesOutput(_returnParam0);
    for (uint256 _i; _i < _getProposalTypesInputHashes.length; ++_i) {
      if (_key == _getProposalTypesInputHashes[_i]) {
        return;
      }
    }
    _getProposalTypesInputHashes.push(_key);
  }

  function _getProposalTypes() internal view override returns (uint8[] memory _returnParam0) {
    bytes32 _key = keccak256(abi.encode());
    for (uint256 _i; _i < _getProposalTypesInputHashes.length; ++_i) {
      if (_key == _getProposalTypesInputHashes[_i]) {
        _getProposalTypesOutput memory _output = _getProposalTypesOutputs[_key];
        return (_output._returnParam0);
      }
    }
    return super._getProposalTypes();
  }

  struct _maxDelegatesOutput {
    uint8 _returnParam0;
  }

  mapping(bytes32 => _maxDelegatesOutput) private _maxDelegatesOutputs;
  bytes32[] private _maxDelegatesInputHashes;

  function mock_call__maxDelegates(uint8 _returnParam0) public {
    bytes32 _key = keccak256(abi.encode());
    _maxDelegatesOutputs[_key] = _maxDelegatesOutput(_returnParam0);
    for (uint256 _i; _i < _maxDelegatesInputHashes.length; ++_i) {
      if (_key == _maxDelegatesInputHashes[_i]) {
        return;
      }
    }
    _maxDelegatesInputHashes.push(_key);
  }

  function _maxDelegates() internal view override returns (uint8 _returnParam0) {
    bytes32 _key = keccak256(abi.encode());
    for (uint256 _i; _i < _maxDelegatesInputHashes.length; ++_i) {
      if (_key == _maxDelegatesInputHashes[_i]) {
        _maxDelegatesOutput memory _output = _maxDelegatesOutputs[_key];
        return (_output._returnParam0);
      }
    }
    return super._maxDelegates();
  }

  struct _validProposalTypeOutput {
    bool _returnParam0;
  }

  mapping(bytes32 => _validProposalTypeOutput) private _validProposalTypeOutputs;
  bytes32[] private _validProposalTypeInputHashes;

  function mock_call__validProposalType(uint8 _proposalType, bool _returnParam0) public {
    bytes32 _key = keccak256(abi.encode(_proposalType));
    _validProposalTypeOutputs[_key] = _validProposalTypeOutput(_returnParam0);
    for (uint256 _i; _i < _validProposalTypeInputHashes.length; ++_i) {
      if (_key == _validProposalTypeInputHashes[_i]) {
        return;
      }
    }
    _validProposalTypeInputHashes.push(_key);
  }

  function _validProposalType(uint8 _proposalType) internal view override returns (bool _returnParam0) {
    bytes32 _key = keccak256(abi.encode(_proposalType));
    for (uint256 _i; _i < _validProposalTypeInputHashes.length; ++_i) {
      if (_key == _validProposalTypeInputHashes[_i]) {
        _validProposalTypeOutput memory _output = _validProposalTypeOutputs[_key];
        return (_output._returnParam0);
      }
    }
    return super._validProposalType(_proposalType);
  }

  struct _weightNormalizerOutput {
    uint256 _returnParam0;
  }

  mapping(bytes32 => _weightNormalizerOutput) private _weightNormalizerOutputs;
  bytes32[] private _weightNormalizerInputHashes;

  function mock_call__weightNormalizer(uint256 _returnParam0) public {
    bytes32 _key = keccak256(abi.encode());
    _weightNormalizerOutputs[_key] = _weightNormalizerOutput(_returnParam0);
    for (uint256 _i; _i < _weightNormalizerInputHashes.length; ++_i) {
      if (_key == _weightNormalizerInputHashes[_i]) {
        return;
      }
    }
    _weightNormalizerInputHashes.push(_key);
  }

  function _weightNormalizer() internal view override returns (uint256 _returnParam0) {
    bytes32 _key = keccak256(abi.encode());
    for (uint256 _i; _i < _weightNormalizerInputHashes.length; ++_i) {
      if (_key == _weightNormalizerInputHashes[_i]) {
        _weightNormalizerOutput memory _output = _weightNormalizerOutputs[_key];
        return (_output._returnParam0);
      }
    }
    return super._weightNormalizer();
  }
}
