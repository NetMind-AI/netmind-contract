// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./proxy.sol";

contract StrategicFundProxy is baseProxy{
    constructor(address impl) {
        _setAdmin(msg.sender);
        _setLogic(impl);
    }
}
