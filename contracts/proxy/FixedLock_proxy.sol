// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./proxy.sol";

contract FixedLockPorxy is basePorxy{
       constructor(address impl) {
        _setAdmin(msg.sender);
        _setLogic(impl);
    }
}
