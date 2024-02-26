// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

interface IGovernor {
    function propose(string memory _proposalContent) payable external;
    function vote(uint256 _proposalId, uint256 _type) payable external;
    function withdrawStake(uint256[] calldata _proposalIds) external;

}

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

contract Ownable is Initializable{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init_unchained() internal initializer {
        address msgSender = msg.sender;
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Governor is Initializable,Ownable,IGovernor{
    bool private reentrancyLock;
    uint256 public proposalThreshold;
    uint256 public quorumVotes;
    uint256 public votingPeriod;
    uint256 public  proposalCount;                           
    mapping(uint256 => ProposalMsg) public proposalMsg;  
    mapping(address => mapping(uint256 => uint256)) public userStakeNum;
    
    event UpdateProposalThreshold(uint256 proposalThreshold);
    event UpdateQuorumVotes(uint256 quorumVotes);
    event UpdateVotingPeriod(uint256 votingPeriod);
    event Propose(address indexed userAddr, uint256 proposalId, uint256 time);
    event Vote(address indexed userAddr, uint256 proposalId, uint256 option, uint256 votes, uint256 time);
    event WithdrawStake(address indexed userAddr, uint256 proposalId, uint256 amount, uint256 time);
    

    struct ProposalMsg {
        address proposer;
        uint256 launchTime;   
        uint256 expire;  
        uint256 status; 
        uint256 forVotes;
        uint256 againstVotes;
        string proposalContent; 
    }

    modifier nonReentrant() {
        require(!reentrancyLock);
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    function init(uint256 _proposalThreshold, uint256 _quorumVotes, uint256 _votingPeriod) external initializer{
        __Ownable_init_unchained();
        __Governor_init_unchained(_proposalThreshold, _quorumVotes, _votingPeriod);
    }

    function __Governor_init_unchained(uint256 _proposalThreshold, uint256 _quorumVotes, uint256 _votingPeriod) internal initializer{
        proposalThreshold = _proposalThreshold;
        quorumVotes = _quorumVotes;
        votingPeriod = _votingPeriod;
    }
   
    function updateVotingPeriod(uint256 _votingPeriod) external onlyOwner{
        votingPeriod = _votingPeriod;
        emit UpdateVotingPeriod(_votingPeriod);
    }
    
    function updateProposalThreshold(uint256 _proposalThreshold) external onlyOwner{
        proposalThreshold = _proposalThreshold;
        emit UpdateProposalThreshold(_proposalThreshold);
    }
     
    function updateQuorumVotes(uint256 _quorumVotes) external onlyOwner{
        quorumVotes = _quorumVotes;
        emit UpdateQuorumVotes(_quorumVotes);
    }
 
    function propose(string memory _proposalContent) payable override external{
        require(msg.value >= proposalThreshold, "not reached proposalThreshold");
        address _sender = msg.sender;
        uint256 _time = block.timestamp;
        uint256 proposalId = ++proposalCount;
        proposalMsg[proposalId] = ProposalMsg(_sender, _time, _time + votingPeriod, 0, 0, 0, _proposalContent);
        vote(proposalId,0);
        emit Propose(_sender, proposalId, _time);
    }
    
    function vote(uint256 _proposalId, uint256 _type) payable override public nonReentrant(){
        address _sender = msg.sender;
        uint256 _time = block.timestamp;
        require(msg.value > 0 , "cannot be 0");
        ProposalMsg storage _proposalMsg = proposalMsg[_proposalId];
        require(_proposalMsg.expire > _time, "vote expired");
        require(_type < 2, "The vote type does not exist");
        if(_type==0){
            _proposalMsg.forVotes = _proposalMsg.forVotes + msg.value;
        }else {
            _proposalMsg.againstVotes = _proposalMsg.againstVotes + msg.value;
        }
        userStakeNum[_sender][_proposalId] = userStakeNum[_sender][_proposalId] + msg.value;
        if(_proposalMsg.forVotes >= quorumVotes && _proposalMsg.status==0){
            _proposalMsg.status = 1;
        }
        emit Vote(_sender, _proposalId, _type, msg.value, _time);
    }
 
    function withdrawStake(uint256[] calldata _proposalIds) override external nonReentrant(){
        address _sender = msg.sender;
        uint256 _amount = 0;
        for (uint256 i = 0; i < _proposalIds.length; i++) {
            uint256 _proposalId = _proposalIds[i];
            require(_proposalId <= proposalCount, "The proposal ID is incorrect");
            if (_proposalId > 0){
                require(proposalMsg[_proposalId].expire < block.timestamp, "The vote on the agreement is not yet over");
                uint256 stakeNum = userStakeNum[_sender][_proposalId];
                require(stakeNum >0, "vote not exist");
                _amount = _amount + stakeNum;
                userStakeNum[_sender][_proposalId] = 0;
                emit WithdrawStake(_sender, _proposalId, stakeNum, block.timestamp);
            }
        }
        payable(msg.sender).transfer(_amount);

    } 
    
    function queryVotes(uint256 _proposalId) external view returns(ProposalMsg memory){
        ProposalMsg storage _proposalMsg = proposalMsg[_proposalId];
        return _proposalMsg;
    }
}

