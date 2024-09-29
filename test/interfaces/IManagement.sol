// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IManagemenInterface {
    event Propose( address indexed proposer,uint256 proposalId,string label ) ;
    event Vote( address indexed voter,uint256 proposalId ) ;
    function addNodePropose( address _addr ) external   ;
    function deleteNodePropose( address _addr ) external   ;
    function excContractPropose( address _targetAddr,bytes memory _data ) external   ;
    function excContractProposes( address[] memory _targetAddrs,bytes[] memory _datas ) external   ;
    function nodeAddrSta( address  ) external view returns (bool ) ;
    function nodeNum(  ) external view returns (uint256 ) ;
    function proposalCount(  ) external view returns (uint256 ) ;
    function proposalMsg( uint256  ) external view returns (bool proposalSta, address targetAddr, address addr, bytes memory data, uint256 expire, uint8 typeIndex, string memory label) ;
    function queryNodes(  ) external view returns (address[] memory ) ;
    function queryVotes( uint256 _proposalId ) external view returns (address[] memory , bool , address , address , bytes memory , uint256 , string memory ) ;
    function updateProxyAdminPropose( address _targetAddr,address _addr ) external   ;
    function updateProxyUpgradPropose( address _targetAddr,address _addr ) external   ;
    function vote( uint256 _proposalId ) external   ;
    function votes( uint256[] memory _proposalIds ) external   ;
}
