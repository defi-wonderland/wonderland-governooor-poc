import 'forge-std/Test.sol';

import {WonderGovernor} from 'contracts/governance/WonderGovernor.sol';
import {IWonderGovernor} from 'interfaces/governance/IWonderGovernor.sol';
import {AliceGovernor} from 'examples/AliceGovernor.sol';
import {MockRabbitToken} from '../smock/examples/MockRabbitToken.sol';
import {IWonderVotes} from 'interfaces/governance/utils/IWonderVotes.sol';

contract BaseTest is Test {
  address deployer = makeAddr('deployer');
  address hatter = makeAddr('hatter');

  IWonderGovernor governor;
  MockRabbitToken rabbit;

  function _mockGetPastVotes(address _account, uint8 _proposalType, uint256 _timePoint, uint256 _votes) internal {
    vm.mockCall(
      address(rabbit),
      abi.encodeWithSelector(IWonderVotes.getPastVotes.selector, _account, _proposalType, _timePoint),
      abi.encode(_votes)
    );
  }

  function setUp() public {
    vm.startPrank(deployer);

    address tokenAddress = vm.computeCreateAddress(deployer, vm.getNonce(deployer) + 1);
    governor = new AliceGovernor(tokenAddress);
    rabbit = new MockRabbitToken(AliceGovernor(payable(address(governor))));

    vm.stopPrank();
  }

  function _expectEmit(address _contract) internal {
    vm.expectEmit(true, true, true, true, _contract);
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

  function test_propose_Emit_ProposalCreated(
    uint8 _proposalType,
    address _target,
    uint256 _value,
    bytes memory _calldata,
    string memory _description
  ) public {
    vm.assume(_proposalType < governor.proposalTypes().length);

    // hatter will pass the proposal threshold limit
    _mockGetPastVotes(hatter, _proposalType, block.number - 1, governor.proposalThreshold(_proposalType));

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
    uint256 _proposeId = governor.propose(_proposalType, _targets, _values, _calldatas, _description);
  }
}
