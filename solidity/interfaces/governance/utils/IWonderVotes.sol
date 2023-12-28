// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.20;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 */
interface IWonderVotes {
  struct Delegate {
    address account;
    uint256 weight;
  }

  /**
   * @dev The signature used has expired.
   */
  error VotesExpiredSignature(uint256 expiry);

  /**
   * @dev The weight delegation sum is different from weightNormalizer.
   */
  error InvalidWeightSum(uint256 weightSum);

  /**
   * @dev The weight set for a delegate is zero.
   */
  error ZeroWeight();

  /**
   * @dev The proposal type is invalid.
   */
  error InvalidProposalType(uint8 proposalType);

  /**
   * @dev The delegates number for a `proposalType` exceeds the maximum number of delegates.
   */
  error DelegatesMaxNumberExceeded(uint256 delegateesNumber);

  /**
   * @dev The delegation of votes is suspended for the account.
   */
  error DelegationSuspended(address account);

  /**
   * @dev Emitted when an account changes their delegates.
   */
  event DelegateChanged(
    address indexed delegator, uint8 indexed proposalType, Delegate[] fromDelegates, Delegate[] toDelegates
  ); // TODO: check if we should index the rest of arguments

  /**
   * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of voting units.
   */
  event DelegateVotesChanged(address indexed delegate, uint8 proposalType, uint256 previousVotes, uint256 newVotes);

  /**
   * @dev Returns the current amount of votes that `account` has for a `proposalType`.
   */
  function getVotes(address account, uint8 proposalType) external view returns (uint256);

  /**
   * @dev Returns the amount of votes that `account` had at a specific moment in the past for a given `proposalType`.
   * If the `clock()` is configured to use block numbers, this will return the value at the end of the corresponding block.
   */
  function getPastVotes(address account, uint8 proposalType, uint256 timepoint) external view returns (uint256);

  /**
   * @dev Returns for a given `proposalType` the total supply of votes available at a specific moment in the past. If the `clock()` is
   * configured to use block numbers, this will return the value at the end of the corresponding block.
   *
   * NOTE: This value is the sum of all available votes for a `proposalType`, which is not necessarily the sum of all delegated votes.
   * Votes that have not been delegated are still part of total supply, even though they would not participate in a
   * vote.
   */
  function getPastTotalSupply(uint8 proposalType, uint256 timepoint) external view returns (uint256);

  /**
   * @dev Returns the delegates that `account` has chosen for a given `proposalType`.
   */
  function delegates(address account, uint8 proposalType) external view returns (Delegate[] memory);

  /**
   * @dev Delegates 100% of the votes for all proposalTypes from the sender to `delegatee`.
   */
  function delegate(address delegatee) external;

  /**
   * @dev Delegates 100% of the votes for all proposalTypes from the sender to `delegatee` for a given `proposalType`.
   */
  function delegate(address delegatee, uint8 proposalType) external;

  /**
   * @dev Delegates a specific amount of votes  according to the weight from the sender to the `delegates` for a given proposalType.
   */
  function delegate(Delegate[] memory delegates, uint8 proposalType) external;

  /**
   * @dev Delegates 100% of the votes for all proposalTypes votes from signer to `delegatee`.
   */
  function delegateBySig(address delegatee, uint256 nonce, uint256 expiry, uint8 v, bytes32 r, bytes32 s) external;

  /**
   * @dev Delegates 100% of the votes for a specific `proposalType` votes from signer to `delegatee`.
   */
  function delegateBySig(
    address delegatee,
    uint8 proposalType,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @dev Delegates a specific amount of votes  according to the weight for a given `proposalType` votes from signer to `delegatee`.
   */
  function delegateBySig(
    Delegate[] memory delegates,
    uint8 proposalType,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  /**
   * @dev The caller account can enable or disable the ability to be delegated votes by a delegator.
   *      If set to true, the caller account is not eligible to be a delegatee; if set to false, it can be a delegatee.
   *
   *      NOTE: changing the delegation status does not affect the already delegated votes to the account.
   *      By default, all accounts are allowed to be delegated.
   */
  function suspendDelegation(bool suspend) external;

  /**
   * @dev Returns the amount that represents 100% of the weight sum for every delegation
   *      used to calculate the amount of votes when partial delegating to more than 1 delegate.
   *      Example: 100% = 10000 - beware of precision loss from division and overflows from multiplications
   */
  function weightNormalizer() external view returns (uint256);

  /**
   * @dev Returns the maximum amount of delegates that a `proposalType` can be delegated to.
   */
  function maxDelegates() external view returns (uint8);

  /**
   * @dev Returns the `proposalTypes` supported.
   */
  function proposalTypes() external view returns (uint8[] memory);

  /**
   * @dev Returns whether the delegation of votes is suspended for a given account.
   *  Note: changing the delegation status does not affect the already delegated votes to the account.
   */
  function isSuspendedDelegation(address account) external view returns (bool);
}
