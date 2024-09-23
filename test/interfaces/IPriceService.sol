// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPriceService {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event UpdatePrice(uint256 _price);

    function conf() external view returns (address);

    function init(address _conf) external;

    function isOwner() external view returns (bool);

    function owner() external view returns (address);

    function queryPrice() external view returns (uint256);

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    function updatePrice(uint256 _price) external;
}
