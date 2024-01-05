// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IWonderVotes} from 'interfaces/governance/utils/IWonderVotes.sol';

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of Delegate type.
 *
 * Based on OZ EnumerableSet.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an DelegateSet, you can either remove all elements one by one or create a fresh instance using an
 * array of DelegateSet.
 * ====
 */
library DelegateSet {
  struct Set {
    // Storage of set delegates
    IWonderVotes.Delegate[] _delegates;
    // Position is the index of the delegate in the `delegates` array plus 1.
    // Position 0 is used to mean a delegate is not in the set.
    mapping(address delegate => uint256) _positions;
  }

  /**
   * @dev Add a delegate to a set. O(1).
   *
   * Returns true if the delegate was added to the set, that is if it was not
   * already present.
   */
  function add(Set storage set, IWonderVotes.Delegate memory _delegate) internal returns (bool) {
    if (!contains(set, _delegate)) {
      set._delegates.push(_delegate);
      // The delegate is stored at length-1, but we add 1 to all indexes
      // and use 0 as a sentinel delegate
      set._positions[_delegate.account] = set._delegates.length;
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Removes a delegate from a set. O(1).
   *
   * Returns true if the delegate was removed from the set, that is if it was
   * present.
   */
  function remove(Set storage set, IWonderVotes.Delegate memory _delegate) internal returns (bool) {
    return remove(set, _delegate.account);
  }

  /**
   * @dev Removes a delegate from a set. O(1).
   *
   * Returns true if the delegate was removed from the set, that is if it was
   * present.
   */
  function remove(Set storage set, address _account) internal returns (bool) {
    // We cache the delegate's position to prevent multiple reads from the same storage slot
    uint256 position = set._positions[_account];

    if (position != 0) {
      // Equivalent to contains(set, delegate)
      // To delete an element from the _delegate array in O(1), we swap the element to delete with the last one in
      // the array, and then remove the last element (sometimes called as 'swap and pop').
      // This modifies the order of the array, as noted in {at}.

      uint256 delegateIndex = position - 1;
      uint256 lastIndex = set._delegates.length - 1;

      if (delegateIndex != lastIndex) {
        IWonderVotes.Delegate memory _lastDelegate = set._delegates[lastIndex];

        // Move the lastDelegate to the index where the delegate to delete is
        set._delegates[delegateIndex] = _lastDelegate;
        // Update the tracked position of the lastDelegate (that was just moved)
        set._positions[_lastDelegate.account] = position;
      }

      // Delete the slot where the moved delegate was stored
      set._delegates.pop();

      // Delete the tracked position for the deleted slot
      delete set._positions[_account];

      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Returns true if the delegate is in the set. O(1).
   */
  function contains(Set storage set, IWonderVotes.Delegate memory _delegate) internal view returns (bool) {
    return contains(set, _delegate.account);
  }

  /**
   * @dev Returns true if the delegate is in the set. O(1).
   */
  function contains(Set storage set, address _account) internal view returns (bool) {
    return set._positions[_account] != 0;
  }

  /**
   * @dev Returns the number of delegates on the set. O(1).
   */
  function length(Set storage set) internal view returns (uint256) {
    return set._delegates.length;
  }

  /**
   * @dev Returns the delegate stored at position `index` in the set. O(1).
   *
   * Note that there are no guarantees on the ordering of delegates inside the
   * array, and it may change when more delegates are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function at(Set storage set, uint256 index) internal view returns (IWonderVotes.Delegate storage) {
    return set._delegates[index];
  }

  /**
   * @dev Returns the delegate from the set with the given account. O(1).
   */
  function get(Set storage set, address _account) internal view returns (IWonderVotes.Delegate storage) {
    return at(set, set._positions[_account]);
  }

  /**
   * @dev Return the entire set in an array
   *
   * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
   * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
   * this function has an unbounded cost, and using it as part of a state-changing function may render the function
   * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
   */
  function values(Set storage set) internal view returns (IWonderVotes.Delegate[] memory) {
    return set._delegates;
  }

  /**
   * @dev Removes all delegates from a set. O(n).
   */
  function flush(Set storage set) internal {
    for (uint256 i = 0; i < set._delegates.length; i++) {
      delete set._positions[set._delegates[i].account];
    }

    delete set._delegates;
  }
}
