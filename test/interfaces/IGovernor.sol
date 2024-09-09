// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IGovernor {
    event OwnershipTransferred( address indexed previousOwner,address indexed newOwner ) ;
    event Propose( address indexed userAddr,uint256 proposalId,uint256 time ) ;
    event UpdateProposalThreshold( uint256 proposalThreshold ) ;
    event UpdateQuorumVotes( uint256 quorumVotes ) ;
    event UpdateVotingPeriod( uint256 votingPeriod ) ;
    event Vote( address indexed userAddr,uint256 proposalId,uint256 option,uint256 votes,uint256 time ) ;
    event WithdrawStake( address indexed userAddr,uint256 proposalId,uint256 amount,uint256 time ) ;
    function init( uint256 _proposalThreshold,uint256 _quorumVotes,uint256 _votingPeriod ) external   ;
    function isOwner(  ) external view returns (bool ) ;
    function owner(  ) external view returns (address ) ;
    function proposalCount(  ) external view returns (uint256 ) ;
    function proposalMsg( uint256  ) external view returns (address proposer, uint256 launchTime, uint256 expire, uint256 status, uint256 forVotes, uint256 againstVotes, string memory proposalContent) ;
    function proposalThreshold(  ) external view returns (uint256 ) ;
    function propose( string memory _proposalContent ) external payable  ;
    function queryVotes( uint256 _proposalId ) external view returns (ProposalMsg memory ) ;
    function quorumVotes(  ) external view returns (uint256 ) ;
    function renounceOwnership(  ) external   ;
    function transferOwnership( address newOwner ) external   ;
    function updateProposalThreshold( uint256 _proposalThreshold ) external   ;
    function updateQuorumVotes( uint256 _quorumVotes ) external   ;
    function updateVotingPeriod( uint256 _votingPeriod ) external   ;
    function userStakeNum( address ,uint256  ) external view returns (uint256 ) ;
    function vote( uint256 _proposalId,uint256 _type ) external payable  ;
    function votingPeriod(  ) external view returns (uint256 ) ;
    function withdrawStake( uint256[] memory _proposalIds ) external   ;
    struct ProposalMsg {
        address proposer;
        uint256 launchTime;
        uint256 expire;
        uint256 status;
        uint256 forVotes;
        uint256 againstVotes;
        string proposalContent;
    }
}

