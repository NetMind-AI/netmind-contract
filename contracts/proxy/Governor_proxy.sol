// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./proxy.sol";

<<<<<<<< HEAD:contracts/proxy/NetMindToken_proxy.sol
contract NetMindTokenProxy is baseProxy{
========
contract GovernorProxy is baseProxy{
>>>>>>>> dev:contracts/proxy/Governor_proxy.sol
       constructor(address impl) {
        _setAdmin(msg.sender);
        _setLogic(impl);
    }
}
