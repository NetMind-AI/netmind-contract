// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface  IERC20 {
      function transferFrom(address from, address to, uint256 amount) external returns(bool);
}

contract Airdrop {
      address public nmt;
      address public bank;
      address public sender;

      modifier Onlysender(){
            require(msg.sender == sender, "Airdrop: Only sender");
            _;
      }
      constructor(address _nmt,address _bank) {
            require(_nmt != address(0), "The address is 0 address");
            require(_bank != address(0), "The address is 0 address");
            nmt = _nmt;
            bank = _bank;
            sender = msg.sender;
      }

      function airdrop(address[] memory users, uint256[] memory amts) public Onlysender {
            require(users.length == amts.length, "Airdrop: invalid length of users and amts");
            for (uint256 i = 0; i < users.length; i++){
                  require(users[i] != address(0), "The address is 0 address");
                  IERC20(nmt).transferFrom(bank, users[i], amts[i]);
            } 
      }

      function airdrop(address[] memory users, uint256 amt) public Onlysender {
            for (uint256 i = 0; i < users.length; i++){
                  require(users[i] != address(0), "The address is 0 address");
                  IERC20(nmt).transferFrom(bank, users[i], amt);
            }
      }
}