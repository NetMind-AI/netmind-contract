// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITechnologyFund {
    event AddNodeAddr( address _nodeAddr ) ;
    event DeleteNodeAddr( address _nodeAddr ) ;
    event OwnershipTransferred( address indexed previousOwner,address indexed newOwner ) ;
    event Propose( address indexed proposer,uint256 proposalId,address targetAddr,uint256 amount,string content ) ;
    event UpdateVotingPeriod( uint256 _votingPeriod ) ;
    event Vote( address indexed voter,uint256 proposalId ) ;
    function LockTime(  ) external view returns (uint256 ) ;
    function addNodeAddr( address[] memory _nodeAddrs ) external   ;
    function calcRelease( uint256 time ) external view returns (uint256 ) ;
    function deleteNodeAddr( address[] memory _nodeAddrs ) external   ;
    function init( address[] memory _nodeAddrs,uint256 _LockTime ) external   ;
    function isOwner(  ) external view returns (bool ) ;
    function nodeAddrSta( address  ) external view returns (bool ) ;
    function nodeNum(  ) external view returns (uint256 ) ;
    function owner(  ) external view returns (address ) ;
    function proposalCount(  ) external view returns (uint256 ) ;
    function proposalMsg( uint256  ) external view returns (address proposalSponsor, string memory content, address targetAddr, uint256 amount, bool proposalSta, uint256 expire) ;
    function propose( address targetAddr,uint256 amount,string memory content ) external   ;
    function queryAllProposers( uint256 _proposalId ) external view returns (address[] memory ) ;
    function queryNodes(  ) external view returns (address[] memory ) ;
    function queryProposalMsg( bool _type,uint256 _page,uint256 _limit ) external view returns (address[] memory , string[] memory , address[] memory , uint256[] memory , bool[] memory , uint256[] memory , uint256[] memory , uint256 ) ;
    function queryUnlock(  ) external view returns (uint256 , uint256 ) ;
    function renounceOwnership(  ) external   ;
    function transferOwnership( address newOwner ) external   ;
    function unLockNum(  ) external view returns (uint256 ) ;
    function updateVotingPeriod( uint256 _votingPeriod ) external   ;
    function vote( uint256 _proposalId ) external   ;
    function votingPeriod(  ) external view returns (uint256 ) ;
    function withdraw( address to ) external   ;
    function withdrawSum(  ) external view returns (uint256 ) ;
}


