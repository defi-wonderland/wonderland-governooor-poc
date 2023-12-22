import 'forge-std/Test.sol';

import {WonderGovernor} from 'contracts/governance/WonderGovernor.sol';
import {IWonderGovernor} from 'interfaces/governance/IWonderGovernor.sol';
import {IWonderVotes} from 'interfaces/governance/utils/IWonderVotes.sol';
import {IWonderGovernor} from 'interfaces/governance/IWonderGovernor.sol';
import {WonderVotes} from 'contracts/governance/utils/WonderVotes.sol';
import {RabbitToken} from 'examples/RabbitToken.sol';
import {MockAliceGovernor} from '../smock/examples/MockAliceGovernor.sol';
import {AliceGovernor} from 'examples/AliceGovernor.sol';

contract WonderVotesForTest is RabbitToken {
  constructor(AliceGovernor _governor) RabbitToken(_governor) {}

  function mint(address _account, uint256 _amount) public {
    _mint(_account, _amount);
  }

  function burn(uint256 _amount) public {
    _burn(msg.sender, _amount);
  }
}

contract BaseTest is Test {
  address deployer = makeAddr('deployer');
  address hatter = makeAddr('hatter');
  address cat = makeAddr('cat');

  MockAliceGovernor governor;
  RabbitToken rabbitToken;

  event DelegateVotesChanged(address indexed delegate, uint8 proposalType, uint256 previousVotes, uint256 newVotes);

  function _mockGetPastVotes(address _account, uint8 _proposalType, uint256 _timePoint, uint256 _votes) internal {
    vm.mockCall(
      address(rabbitToken),
      abi.encodeWithSelector(IWonderVotes.getPastVotes.selector, _account, _proposalType, _timePoint),
      abi.encode(_votes)
    );
  }

  function setUp() public virtual {
    vm.startPrank(deployer);

    address tokenAddress = vm.computeCreateAddress(deployer, vm.getNonce(deployer) + 1);
    governor = new MockAliceGovernor(tokenAddress);
    rabbitToken = new WonderVotesForTest(AliceGovernor(payable(address(governor))));

    vm.stopPrank();
  }

  function _expectEmit(address _contract) internal {
    vm.expectEmit(true, true, true, true, _contract);
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

    _mockGetPastVotes(hatter, _proposalType, block.number - 1, _proposerVotes);

    address[] memory _targets = new address[](1);
    _targets[0] = _target;

    uint256[] memory _values = new uint256[](1);
    _values[0] = _value;

    bytes[] memory _calldatas = new bytes[](1);
    _calldatas[0] = _calldata;

    vm.prank(hatter);
    return governor.propose(_proposalType, _targets, _values, _calldatas, _description);
  }
}

contract Unit_Delegate_Simple is BaseTest {
  function test_Minting_WithoutTracking_Add_Zero(uint128 _amount) public {
    WonderVotesForTest(address(rabbitToken)).mint(hatter, _amount);
    uint8[] memory _proposalTypes = rabbitToken.proposalTypes();

    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      assertEq(rabbitToken.getVotes(hatter, _proposalTypes[i]), 0);
    }
  }

  function test_Minting_SelfDelegate_Before(uint128 _amount) public {
    // To start tracking votes the account delegates himself
    vm.prank(hatter);
    rabbitToken.delegate(hatter);

    WonderVotesForTest(address(rabbitToken)).mint(hatter, _amount);
    uint8[] memory _proposalTypes = rabbitToken.proposalTypes();

    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      assertEq(rabbitToken.getVotes(hatter, _proposalTypes[i]), _amount);
    }
  }

  function test_Minting_SelfDelegate_After(uint128 _amount) public {
    WonderVotesForTest(address(rabbitToken)).mint(hatter, _amount);
    uint8[] memory _proposalTypes = rabbitToken.proposalTypes();

    // If the account does not have delegates it will not track votes
    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      assertEq(rabbitToken.getVotes(hatter, _proposalTypes[i]), 0);
    }

    // To start tracking votes the account delegates himself
    vm.prank(hatter);
    rabbitToken.delegate(hatter);

    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      assertEq(rabbitToken.getVotes(hatter, _proposalTypes[i]), _amount);
    }
  }

  function test_SelfDelegate_Changes(uint128 _amount) public {
    // To start tracking votes the account delegates himself
    vm.prank(hatter);
    rabbitToken.delegate(hatter);

    WonderVotesForTest(address(rabbitToken)).mint(hatter, _amount);
    uint8[] memory _proposalTypes = rabbitToken.proposalTypes();

    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      assertEq(rabbitToken.getVotes(hatter, _proposalTypes[i]), _amount);
    }

    vm.prank(hatter);
    rabbitToken.delegate(cat);
    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      assertEq(rabbitToken.getVotes(hatter, _proposalTypes[i]), 0);
      assertEq(rabbitToken.getVotes(cat, _proposalTypes[i]), _amount);
    }
  }

  function test_SelfDelegate_Burns(uint128 _amount) public {
    vm.prank(hatter);
    rabbitToken.delegate(hatter);

    WonderVotesForTest(address(rabbitToken)).mint(hatter, _amount);
    uint8[] memory _proposalTypes = rabbitToken.proposalTypes();

    vm.prank(hatter);
    WonderVotesForTest(address(rabbitToken)).burn(_amount);

    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      assertEq(rabbitToken.getVotes(hatter, _proposalTypes[i]), 0);
    }
  }

  function test_Emit_DelegateVotesChanged(uint128 _amount) public {
    vm.prank(hatter);
    rabbitToken.delegate(hatter);

    uint8[] memory _proposalTypes = rabbitToken.proposalTypes();
    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      _expectEmit(address(rabbitToken));
      emit DelegateVotesChanged(hatter, _proposalTypes[i], 0, _amount);
    }

    WonderVotesForTest(address(rabbitToken)).mint(hatter, _amount);
  }
}

contract Unit_Delegate_Smart is BaseTest {
  function test_Minting_SmartDelegation_Before(uint128 _amount) public {
    uint8[] memory _proposalTypes = rabbitToken.proposalTypes();

    // Will define one delegate per proposal type
    address[] memory _delegates = new address[](_proposalTypes.length);

    vm.startPrank(hatter);
    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      _delegates[i] = makeAddr(string(abi.encodePacked('delegate', i)));

      // 100% voting power to the delegate for the proposalType
      rabbitToken.delegate(_delegates[i], _proposalTypes[i]);
    }
    vm.stopPrank();
    WonderVotesForTest(address(rabbitToken)).mint(hatter, _amount);

    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      assertEq(rabbitToken.getVotes(hatter, _proposalTypes[i]), 0);
      assertEq(rabbitToken.getVotes(_delegates[i], _proposalTypes[i]), _amount);
    }
  }

  function test_Minting_SmartDelegation_After(uint128 _amount) public {
    uint8[] memory _proposalTypes = rabbitToken.proposalTypes();

    WonderVotesForTest(address(rabbitToken)).mint(hatter, _amount);

    // Will define one delegate per proposal type
    address[] memory _delegates = new address[](_proposalTypes.length);

    vm.startPrank(hatter);
    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      _delegates[i] = makeAddr(string(abi.encodePacked('delegate', i)));

      // 100% voting power to the delegate for the proposalType
      rabbitToken.delegate(_delegates[i], _proposalTypes[i]);
    }
    vm.stopPrank();

    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      assertEq(rabbitToken.getVotes(hatter, _proposalTypes[i]), 0);
      assertEq(rabbitToken.getVotes(_delegates[i], _proposalTypes[i]), _amount);
    }
  }

  function test_Minting_SmartDelegation_Changes(uint128 _amount) public {
    uint8[] memory _proposalTypes = rabbitToken.proposalTypes();

    // Will define one delegate per proposal type
    address[] memory _delegates = new address[](_proposalTypes.length);
    address[] memory _delegatesChange = new address[](_proposalTypes.length);

    vm.startPrank(hatter);
    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      _delegates[i] = makeAddr(string(abi.encodePacked('delegate', i)));

      // 100% voting power to the delegate for the proposalType
      rabbitToken.delegate(_delegates[i], _proposalTypes[i]);
    }

    WonderVotesForTest(address(rabbitToken)).mint(hatter, _amount);

    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      assertEq(rabbitToken.getVotes(hatter, _proposalTypes[i]), 0);
      assertEq(rabbitToken.getVotes(_delegates[i], _proposalTypes[i]), _amount);
    }

    // Delegates changes
    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      _delegatesChange[i] = makeAddr(string(abi.encodePacked('delegateChange', i)));

      // 100% voting power to the delegate for the proposalType
      rabbitToken.delegate(_delegatesChange[i], _proposalTypes[i]);
    }

    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      assertEq(rabbitToken.getVotes(hatter, _proposalTypes[i]), 0);
      assertEq(rabbitToken.getVotes(_delegates[i], _proposalTypes[i]), 0);
      assertEq(rabbitToken.getVotes(_delegatesChange[i], _proposalTypes[i]), _amount);
    }
  }

  function test_Revert_InvalidProposalType(uint8 _proposalType) public {
    vm.assume(_proposalType >= rabbitToken.proposalTypes().length);

    vm.expectRevert(abi.encodeWithSelector(IWonderVotes.InvalidProposalType.selector, _proposalType));

    vm.prank(hatter);
    rabbitToken.delegate(hatter, _proposalType);
  }

  function test_Emit_DelegateVotesChanged(uint128 _amount) public {
    vm.prank(hatter);
    rabbitToken.delegate(hatter);
    WonderVotesForTest(address(rabbitToken)).mint(hatter, _amount);

    uint8[] memory _proposalTypes = rabbitToken.proposalTypes();

    address[] memory _delegates = new address[](_proposalTypes.length);

    vm.startPrank(hatter);
    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      _delegates[i] = makeAddr(string(abi.encodePacked('delegate', i)));

      _expectEmit(address(rabbitToken));
      emit DelegateVotesChanged(_delegates[i], _proposalTypes[i], 0, _amount);

      rabbitToken.delegate(_delegates[i], _proposalTypes[i]);
    }
    vm.stopPrank();
  }
}

contract Unit_Delegate_SmartAndPartial is BaseTest {
  function test_Minting_SmartAndPartialDelegation_Before(uint128 _amount) public {
    uint8[] memory _proposalTypes = rabbitToken.proposalTypes();

    // To simply we will divide the voting power into 2 delegates 50% each
    // We can add a more complex test of this further
    uint256 _weightNormalizer = rabbitToken.weightNormalizer();
    uint256 _weight = _weightNormalizer / 2;

    address[] memory _delegates = new address[](_proposalTypes.length);
    address[] memory _delegates2 = new address[](_proposalTypes.length);

    vm.startPrank(hatter);
    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      _delegates[i] = makeAddr(string(abi.encodePacked('delegate', i)));
      _delegates2[i] = makeAddr(string(abi.encodePacked('delegate2', i)));

      IWonderVotes.Delegate memory _delegate = IWonderVotes.Delegate({account: _delegates[i], weight: _weight});
      IWonderVotes.Delegate memory _delegate2 = IWonderVotes.Delegate({account: _delegates2[i], weight: _weight});
      IWonderVotes.Delegate[] memory _delegatesStruct = new IWonderVotes.Delegate[](2);
      _delegatesStruct[0] = _delegate;
      _delegatesStruct[1] = _delegate2;

      rabbitToken.delegate(_delegatesStruct, _proposalTypes[i]);
    }

    vm.stopPrank();
    WonderVotesForTest(address(rabbitToken)).mint(hatter, _amount);

    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      assertEq(rabbitToken.getVotes(hatter, _proposalTypes[i]), 0);
      emit log_uint(rabbitToken.getVotes(_delegates[i], _proposalTypes[i]));
      emit log_uint(rabbitToken.getVotes(_delegates2[i], _proposalTypes[i]));

      assertEq(rabbitToken.getVotes(_delegates[i], _proposalTypes[i]), _amount / 2);
      assertEq(rabbitToken.getVotes(_delegates2[i], _proposalTypes[i]), _amount / 2);
    }
  }

  function test_Minting_SmartAndPartialDelegation_After(uint128 _amount) public {
    WonderVotesForTest(address(rabbitToken)).mint(hatter, _amount);

    uint8[] memory _proposalTypes = rabbitToken.proposalTypes();

    // To simply we will divide the voting power into 2 delegates 50% each
    // We can add a more complex test of this further
    uint256 _weightNormalizer = rabbitToken.weightNormalizer();
    uint256 _weight = _weightNormalizer / 2;

    address[] memory _delegates = new address[](_proposalTypes.length);
    address[] memory _delegates2 = new address[](_proposalTypes.length);

    vm.startPrank(hatter);
    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      _delegates[i] = makeAddr(string(abi.encodePacked('delegate', i)));
      _delegates2[i] = makeAddr(string(abi.encodePacked('delegate2', i)));

      IWonderVotes.Delegate memory _delegate = IWonderVotes.Delegate({account: _delegates[i], weight: _weight});
      IWonderVotes.Delegate memory _delegate2 = IWonderVotes.Delegate({account: _delegates2[i], weight: _weight});
      IWonderVotes.Delegate[] memory _delegatesStruct = new IWonderVotes.Delegate[](2);
      _delegatesStruct[0] = _delegate;
      _delegatesStruct[1] = _delegate2;

      rabbitToken.delegate(_delegatesStruct, _proposalTypes[i]);
    }
    vm.stopPrank();

    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      assertEq(rabbitToken.getVotes(hatter, _proposalTypes[i]), 0);
      emit log_uint(rabbitToken.getVotes(_delegates[i], _proposalTypes[i]));
      emit log_uint(rabbitToken.getVotes(_delegates2[i], _proposalTypes[i]));

      assertEq(rabbitToken.getVotes(_delegates[i], _proposalTypes[i]), _amount / 2);
      assertEq(rabbitToken.getVotes(_delegates2[i], _proposalTypes[i]), _amount / 2);
    }
  }

  function test_Revert_InvalidProposalType(uint8 _proposalType) public {
    vm.assume(_proposalType >= rabbitToken.proposalTypes().length);

    IWonderVotes.Delegate[] memory _delegates = new IWonderVotes.Delegate[](1);
    _delegates[0] = IWonderVotes.Delegate({account: makeAddr('delegate'), weight: rabbitToken.weightNormalizer()});

    vm.expectRevert(abi.encodeWithSelector(IWonderVotes.InvalidProposalType.selector, _proposalType));

    vm.prank(hatter);
    rabbitToken.delegate(_delegates, _proposalType);
  }

  function test_Emit_DelegateVotesChanged(uint128 _amount) public {
    uint8[] memory _proposalTypes = rabbitToken.proposalTypes();
    WonderVotesForTest(address(rabbitToken)).mint(hatter, _amount);

    // To simply we will divide the voting power into 2 delegates 50% each
    // We can add a more complex test of this further
    uint256 _weightNormalizer = rabbitToken.weightNormalizer();
    uint256 _weight = _weightNormalizer / 2;

    address[] memory _delegates = new address[](_proposalTypes.length);
    address[] memory _delegates2 = new address[](_proposalTypes.length);

    vm.startPrank(hatter);
    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      _delegates[i] = makeAddr(string(abi.encodePacked('delegate', i)));
      _delegates2[i] = makeAddr(string(abi.encodePacked('delegate2', i)));

      IWonderVotes.Delegate memory _delegate = IWonderVotes.Delegate({account: _delegates[i], weight: _weight});
      IWonderVotes.Delegate memory _delegate2 = IWonderVotes.Delegate({account: _delegates2[i], weight: _weight});
      IWonderVotes.Delegate[] memory _delegatesStruct = new IWonderVotes.Delegate[](2);
      _delegatesStruct[0] = _delegate;
      _delegatesStruct[1] = _delegate2;

      _expectEmit(address(rabbitToken));

      emit DelegateVotesChanged(_delegates[i], _proposalTypes[i], 0, _amount / 2);
      emit DelegateVotesChanged(_delegates2[i], _proposalTypes[i], 0, _amount / 2);

      rabbitToken.delegate(_delegatesStruct, _proposalTypes[i]);
    }

    vm.stopPrank();
  }

  function test_Revert_ZeroWeight(uint8 _proposalType) public {
    vm.assume(_proposalType < rabbitToken.proposalTypes().length);

    IWonderVotes.Delegate[] memory _delegatesStruct = new IWonderVotes.Delegate[](1);
    _delegatesStruct[0] = IWonderVotes.Delegate({account: makeAddr('delegate'), weight: 0});

    vm.expectRevert(abi.encodeWithSelector(IWonderVotes.ZeroWeight.selector));

    vm.prank(hatter);
    rabbitToken.delegate(_delegatesStruct, _proposalType);
  }

  function test_Revert_InvalidWeightSum_LessThan_WeighNormalizer(uint8 _proposalType, uint256 _weightSum) public {
    vm.assume(_proposalType < rabbitToken.proposalTypes().length);
    vm.assume(_weightSum > 0 && (_weightSum > rabbitToken.weightNormalizer()));

    IWonderVotes.Delegate[] memory _delegatesStruct = new IWonderVotes.Delegate[](1);
    _delegatesStruct[0] = IWonderVotes.Delegate({account: makeAddr('delegate'), weight: _weightSum});

    vm.expectRevert(abi.encodeWithSelector(IWonderVotes.InvalidWeightSum.selector, _weightSum));

    vm.prank(hatter);
    rabbitToken.delegate(_delegatesStruct, _proposalType);
  }

  function test_Revert_InvalidWeightSum_MoreThan_WeighNormalizer(uint8 _proposalType, uint256 _weightSum) public {
    vm.assume(_proposalType < rabbitToken.proposalTypes().length);
    vm.assume(_weightSum > 0 && (_weightSum > rabbitToken.weightNormalizer()));

    IWonderVotes.Delegate[] memory _delegatesStruct = new IWonderVotes.Delegate[](1);
    _delegatesStruct[0] = IWonderVotes.Delegate({account: makeAddr('delegate'), weight: _weightSum});

    vm.expectRevert(abi.encodeWithSelector(IWonderVotes.InvalidWeightSum.selector, _weightSum));

    vm.prank(hatter);
    rabbitToken.delegate(_delegatesStruct, _proposalType);
  }
}

contract Unit_TransferVotes is BaseTest {
  function setUp() public override {
    super.setUp();

    // To start tracking votes the accounts delegates themselves
    vm.prank(hatter);
    rabbitToken.delegate(hatter);
    vm.prank(cat);
    rabbitToken.delegate(cat);
  }

  function test_TransferVotes_SimpleDelegation(uint128 _balance, uint128 _transferAmount) public {
    vm.assume(_balance >= _transferAmount);
    uint8[] memory _proposalTypes = rabbitToken.proposalTypes();

    WonderVotesForTest(address(rabbitToken)).mint(hatter, _balance);

    vm.prank(hatter);
    rabbitToken.transfer(cat, _transferAmount);

    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      assertEq(rabbitToken.getVotes(hatter, _proposalTypes[i]), _balance - _transferAmount);
      assertEq(rabbitToken.getVotes(cat, _proposalTypes[i]), _transferAmount);
    }
  }

  function test_TransferVotes_SimpleDelegation_Emit_DelegateVotesChanged(
    uint128 _balance,
    uint128 _transferAmount
  ) public {
    vm.assume(_balance >= _transferAmount);
    uint8[] memory _proposalTypes = rabbitToken.proposalTypes();

    WonderVotesForTest(address(rabbitToken)).mint(hatter, _balance);

    _expectEmit(address(rabbitToken));

    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      emit DelegateVotesChanged(hatter, _proposalTypes[i], _balance, _balance - _transferAmount);
      emit DelegateVotesChanged(cat, _proposalTypes[i], 0, _transferAmount);
    }

    vm.prank(hatter);
    rabbitToken.transfer(cat, _transferAmount);
  }

  function test_TransferVotes_SmartDelegation(uint128 _balance, uint128 _transferAmount) public {
    vm.assume(_balance >= _transferAmount);
    uint8[] memory _proposalTypes = rabbitToken.proposalTypes();

    // Will define one delegate per proposal type
    address[] memory _hatterDelegates = new address[](_proposalTypes.length);
    address[] memory _catDelegates = new address[](_proposalTypes.length);

    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      _hatterDelegates[i] = makeAddr(string(abi.encodePacked('hatterDelegate', i)));
      _catDelegates[i] = makeAddr(string(abi.encodePacked('catDelegate', i)));

      // 100% voting power to the delegate for the proposalType

      vm.prank(hatter);
      rabbitToken.delegate(_hatterDelegates[i], _proposalTypes[i]);

      vm.prank(cat);
      rabbitToken.delegate(_catDelegates[i], _proposalTypes[i]);
    }

    WonderVotesForTest(address(rabbitToken)).mint(hatter, _balance);

    vm.prank(hatter);
    rabbitToken.transfer(cat, _transferAmount);

    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      assertEq(rabbitToken.getVotes(_hatterDelegates[i], _proposalTypes[i]), _balance - _transferAmount);
      assertEq(rabbitToken.getVotes(_catDelegates[i], _proposalTypes[i]), _transferAmount);
    }
  }

  function test_TransferVotes_SmartDelegation_Emits_DelegateVotesChanged(
    uint128 _balance,
    uint128 _transferAmount
  ) public {
    vm.assume(_balance >= _transferAmount);
    uint8[] memory _proposalTypes = rabbitToken.proposalTypes();

    // Will define one delegate per proposal type
    address[] memory _hatterDelegates = new address[](_proposalTypes.length);
    address[] memory _catDelegates = new address[](_proposalTypes.length);

    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      _hatterDelegates[i] = makeAddr(string(abi.encodePacked('hatterDelegate', i)));
      _catDelegates[i] = makeAddr(string(abi.encodePacked('catDelegate', i)));

      // 100% voting power to the delegate for the proposalType

      vm.prank(hatter);
      rabbitToken.delegate(_hatterDelegates[i], _proposalTypes[i]);

      vm.prank(cat);
      rabbitToken.delegate(_catDelegates[i], _proposalTypes[i]);
    }

    WonderVotesForTest(address(rabbitToken)).mint(hatter, _balance);

    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      emit DelegateVotesChanged(_hatterDelegates[i], _proposalTypes[i], _balance, _balance - _transferAmount);
      emit DelegateVotesChanged(_catDelegates[i], _proposalTypes[i], 0, _transferAmount);
    }

    vm.prank(hatter);
    rabbitToken.transfer(cat, _transferAmount);
  }

  function _partialDelegate(
    string memory _nameHash,
    address _account,
    uint8[] memory _proposalTypes
  ) internal returns (address[] memory, address[] memory) {
    // To simply we will divide the voting power into 2 delegates 50% each
    uint256 _weightNormalizer = rabbitToken.weightNormalizer();
    uint256 _weight = _weightNormalizer / 2;

    address[] memory _delegates = new address[](_proposalTypes.length);
    address[] memory _delegates2 = new address[](_proposalTypes.length);

    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      // smart partial delegation
      _delegates[i] = makeAddr(string(abi.encodePacked('1', _nameHash, i)));
      _delegates2[i] = makeAddr(string(abi.encodePacked('2', _nameHash, i)));

      IWonderVotes.Delegate memory _delegate = IWonderVotes.Delegate({account: _delegates[i], weight: _weight});
      IWonderVotes.Delegate memory _delegate2 = IWonderVotes.Delegate({account: _delegates2[i], weight: _weight});
      IWonderVotes.Delegate[] memory _delegatesStruct = new IWonderVotes.Delegate[](2);
      _delegatesStruct[0] = _delegate;
      _delegatesStruct[1] = _delegate2;

      vm.prank(_account);
      rabbitToken.delegate(_delegatesStruct, _proposalTypes[i]);
    }

    return (_delegates, _delegates2);
  }

  function test_TransferVotes_SmartAndPartialDelegation(uint128 _balance, uint128 _transferAmount) public {
    vm.assume(_balance >= _transferAmount);
    uint8[] memory _proposalTypes = rabbitToken.proposalTypes();

    (address[] memory _hatterDelegates1, address[] memory _hatterDelegates2) =
      _partialDelegate('hatter', hatter, _proposalTypes);
    (address[] memory _catDelegates1, address[] memory _catDelegates2) = _partialDelegate('cat', cat, _proposalTypes);

    WonderVotesForTest(address(rabbitToken)).mint(hatter, _balance);

    vm.prank(hatter);
    rabbitToken.transfer(cat, _transferAmount);

    for (uint256 i = 0; i < _proposalTypes.length; i++) {
      assertApproxEqAbs(
        rabbitToken.getVotes(_hatterDelegates1[i], _proposalTypes[i]), (_balance - _transferAmount) / 2, 1, ''
      );
      assertApproxEqAbs(
        rabbitToken.getVotes(_hatterDelegates2[i], _proposalTypes[i]), (_balance - _transferAmount) / 2, 1, ''
      );

      assertApproxEqAbs(rabbitToken.getVotes(_catDelegates1[i], _proposalTypes[i]), _transferAmount / 2, 1, '');
      assertApproxEqAbs(rabbitToken.getVotes(_catDelegates2[i], _proposalTypes[i]), _transferAmount / 2, 1, '');
    }
  }
}
