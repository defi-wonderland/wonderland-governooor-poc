// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import 'forge-std/Test.sol';

contract TestExtended is Test {
  uint256 public constant BLOCK_TIME = 12 seconds;

  function _mineBlock() internal {
    _mineBlocks(1);
  }

  function _mineBlocks(uint256 _blocks) internal {
    vm.warp(block.timestamp + _blocks * BLOCK_TIME);
    vm.roll(block.number + _blocks);
  }

  function _expectEmit(address _contract) internal {
    vm.expectEmit(true, true, true, true, _contract);
  }
}
