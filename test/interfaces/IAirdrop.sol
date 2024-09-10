// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IAirdrop {
    function airdrop(address[] memory users, uint256[] memory amts) external;

    function airdrop(address[] memory users, uint256 amt) external;

    function bank() external view returns (address);

    function nmt() external view returns (address);

    function sender() external view returns (address);
}
