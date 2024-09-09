// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ISnapshoot {
    event UpdateSnapshoot( uint256 _type,uint256 _day,string dataId,string dataHash ) ;
    event UpdateSnapshootFail( uint256 _type,uint256 _day,string dataId,string dataHash ) ;
    function conf(  ) external view returns (address ) ;
    function currentDay(  ) external view returns (uint256 ) ;
    function init( address _conf ) external   ;
    function queryCurrentVotes( uint256 _type ) external view returns (uint256 , uint256 , uint256 , uint256 , address[] memory , uint256[] memory , string memory , string memory , uint256 ) ;
    function queryVotes( uint256 _type,uint256 _day ) external view returns (uint256 , uint256 , uint256 , uint256 , address[] memory , uint256[] memory , string memory , string memory , uint256 ) ;
    function startDay(  ) external view returns (uint256 ) ;
    function updateSnapshoot( uint256[] memory _types,uint256[] memory _days,string[] memory _dataHashs,string[] memory _dataIds ) external   ;
}
