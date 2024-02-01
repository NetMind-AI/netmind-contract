// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface  IERC20 {
      function transfer(address to, uint256 amount) external returns(bool);
      function balanceOf(address user) external returns(uint256);
}

contract Airdrop {
      address public nmt;
      address public sender;

      modifier Onlysender(){
            require(msg.sender == sender, "Airdrop: Only sender");
            _;
      }
      constructor(address _nmt,address _sender) {
            nmt = _nmt;
            sender = _sender;
      }

      function airdrop(address[] memory users, uint256[] memory amts) public Onlysender {
            for (uint256 i = 0; i < users.length; i++){
                  IERC20(nmt).transfer(users[i], amts[i]);
            } 
      }

      function airdrop(address[] memory users, uint256 amt) public Onlysender {
            for (uint256 i = 0; i < users.length; i++){
                  IERC20(nmt).transfer(users[i], amt);
            }
      }

      function withdrewAndDestruct(address to) public Onlysender {
            //withdrew 
            uint256 balance = IERC20(nmt).balanceOf(address(this));
            IERC20(nmt).transfer(to, balance);

            //destruct
            //selfdestruct(to);
      }
}