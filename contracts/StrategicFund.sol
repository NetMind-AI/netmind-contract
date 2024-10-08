// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;

interface IStrategicFund {
    function addNodeAddr(address[] calldata _nodeAddrs) external;		
    function deleteNodeAddr(address[] calldata _nodeAddrs) external;				
    function propose(address targetAddr, uint256 amount, string memory content) external;		
    function vote(uint256 _proposalId) external;	

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

    function _disableInitializers() internal {
        _initialized = true;
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

contract StrategicFund is IStrategicFund,Ownable{
    uint256 public votingPeriod;
    uint256 public proposalCount;                           
    mapping(uint256 => ProposalMsg) public proposalMsg;
    uint256 public nodeNum;
    mapping(address => uint256) nodeAddrIndex;
    mapping(uint256 => address) nodeIndexAddr;
    mapping(address => bool) public nodeAddrSta;
    bool private reentrancyLock;
    uint256 public withdrawSum;
    uint256 public LockTime;

    event AddNodeAddr(address _nodeAddr);
    event DeleteNodeAddr(address _nodeAddr);
    event Propose(address indexed proposer, uint256 proposalId, address targetAddr, uint256 amount,string content);
    event Vote(address indexed voter, uint256 proposalId);
    event UpdateVotingPeriod(uint256 _votingPeriod);

    struct ProposalMsg {
        address proposalSponsor;
        string  content;  
        address targetAddr;   
        uint256 amount;  
        bool proposalSta; 
        uint256 expire; 
        address[] allProposers;
        mapping(address => bool) voterSta;  
    }

    struct QueryProposalMsgData {
        address[] proposalSponsors; 
        string[] contents;
        address[] targetAddrs;
        uint256[] amounts;
        bool[] proposalStas;
        uint256[] expires;
        address[] allProposers;
    }

    modifier nonReentrant() {
        require(!reentrancyLock);
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    constructor(){_disableInitializers();}

    function init(address[] calldata _nodeAddrs, uint256 _LockTime) external initializer{
        __Ownable_init_unchained();
        __StrategicFund_init_unchained(_nodeAddrs, _LockTime);
    }

    function __StrategicFund_init_unchained(address[] calldata _nodeAddrs, uint256 _LockTime) internal initializer{
        _addNodeAddr(_nodeAddrs);
        votingPeriod = 2 days;
        reentrancyLock = false;
        LockTime = _LockTime;
    }
   
    function updateVotingPeriod(uint256 _votingPeriod) external onlyOwner{
        require(_votingPeriod <= 15 days && _votingPeriod > votingPeriod, "Parameter error");
        votingPeriod = _votingPeriod;
        emit UpdateVotingPeriod(_votingPeriod);
    }

    function withdraw(address to) external onlyOwner{
        uint256 amount = address(this).balance + withdrawSum - 750 * 1e22;
        payable(to).transfer(amount);
    }

    function addNodeAddr(address[] calldata _nodeAddrs) override external onlyOwner{
        _addNodeAddr(_nodeAddrs);
    }

    function _addNodeAddr(address[] calldata _nodeAddrs) internal {
        for (uint256 i = 0; i< _nodeAddrs.length; i++){
            address _nodeAddr = _nodeAddrs[i];
            require(!nodeAddrSta[_nodeAddr], "This node is already a node");
            nodeAddrSta[_nodeAddr] = true;
            uint256 _nodeAddrIndex = nodeAddrIndex[_nodeAddr];
            if (_nodeAddrIndex == 0){
                _nodeAddrIndex = ++nodeNum;
                nodeAddrIndex[_nodeAddr] = _nodeAddrIndex;
                nodeIndexAddr[_nodeAddrIndex] = _nodeAddr;
            }
            emit AddNodeAddr(_nodeAddrs[i]);
        }
    }
    
    /**
    * @notice A method to cancel the list of untrusted nodes
    * @param _nodeAddrs the list of untrusted nodes
    */
    function deleteNodeAddr(address[] calldata _nodeAddrs) override external onlyOwner{
        for (uint256 i = 0; i< _nodeAddrs.length; i++){
            address _nodeAddr = _nodeAddrs[i];
            require(nodeAddrSta[_nodeAddr], "This node is not a node");
            nodeAddrSta[_nodeAddr] = false;
            uint256 _nodeAddrIndex = nodeAddrIndex[_nodeAddr];
            if (_nodeAddrIndex > 0){
                uint256 _nodeNum = nodeNum;
                address _lastNodeAddr = nodeIndexAddr[_nodeNum];
                nodeAddrIndex[_lastNodeAddr] = _nodeAddrIndex;
                nodeIndexAddr[_nodeAddrIndex] = _lastNodeAddr;
                nodeAddrIndex[_nodeAddr] = 0;
                nodeIndexAddr[_nodeNum] = address(0x0);
                nodeNum--;
            }
            emit DeleteNodeAddr(_nodeAddrs[i]);
        }
    }

    function propose(
        address targetAddr,   
        uint256 amount,
        string memory content
    ) 
        override
        external
    {   
        address _sender = msg.sender;
        require(nodeAddrSta[_sender], "The caller is not the nodeAddr"); 
        require(nodeAddrSta[targetAddr], "The receiving address is not the node address"); 
        uint256 _time = block.timestamp;
        uint256 _allAmount = calcRelease(_time);
        require(amount <= _allAmount - withdrawSum, "withdraw error"); 
        uint256 _proposalId = ++proposalCount;
        ProposalMsg storage _proposalMsg = proposalMsg[_proposalId];
        _proposalMsg.proposalSponsor = _sender;
        _proposalMsg.content = content;
        _proposalMsg.targetAddr = targetAddr;
        _proposalMsg.amount = amount;
        _proposalMsg.expire = block.timestamp + votingPeriod;
        _proposalMsg.allProposers.push(_sender);
        _proposalMsg.voterSta[_sender] = true;
        emit Propose(_sender, _proposalId, targetAddr, amount, content);
    }
    
    function vote(uint256 _proposalId) override external nonReentrant(){
        address _sender = msg.sender;
        require(nodeAddrSta[_sender], "The caller is not the nodeAddr"); 
        uint256 _time = block.timestamp;
        ProposalMsg storage _proposalMsg = proposalMsg[_proposalId];
        require(!_proposalMsg.proposalSta, "The proposal has already been executed");
        require(_proposalMsg.expire > _time, "The vote on the proposal has expired");
        require(!_proposalMsg.voterSta[_sender], "The proposer has already voted");
        _proposalMsg.allProposers.push(_sender);
        _proposalMsg.voterSta[_sender] = true;
        uint256 length = _proposalMsg.allProposers.length;
        if(length> nodeNum/2 && !_proposalMsg.proposalSta){
            _proposalMsg.proposalSta = true;
            uint256 _allAmount = calcRelease(_time);
            require(_proposalMsg.amount <= _allAmount - withdrawSum, "withdraw error"); 
            withdrawSum = withdrawSum + _proposalMsg.amount;
            require(address(this).balance >= _proposalMsg.amount, "Insufficient balance");
            payable(_proposalMsg.targetAddr).transfer(_proposalMsg.amount);
        }
        emit Vote(_sender, _proposalId);
    }

    function queryProposalMsg(
        bool _type,
        uint256 _page,
        uint256 _limit
    )
        external
        view
        returns(
            address[] memory, 
            string[] memory,
            address[] memory, 
            uint256[] memory, 
            bool[] memory, 
            uint256[] memory,
            address[] memory, 
            uint256[] memory,
            uint256 
        )
    {   
        QueryProposalMsgData memory queryProposalMsgData;
        uint256 _num;
        uint256[] memory indexs;
        if(_type){
            (indexs, _num) = _allProposalMsg(_page, _limit);
        }else{
            (indexs, _num) = _votingProposalMsg(_page, _limit);
        }
        queryProposalMsgData = _obtainProposalMsg(indexs);
        return (
                queryProposalMsgData.proposalSponsors,
                queryProposalMsgData.contents,
                queryProposalMsgData.targetAddrs,
                queryProposalMsgData.amounts,
                queryProposalMsgData.proposalStas,
                queryProposalMsgData.expires,
                queryProposalMsgData.allProposers,
                indexs,
                _num);

    }

    function _votingProposalMsg(uint256 _page, uint256 _limit) internal view returns(uint256[] memory indexs, uint256 _num){
            uint256[] memory proposalIndexs = new uint256[](proposalCount);
            _num = 0;
            for (uint256 i = proposalCount; i > 0; i--) {
                ProposalMsg storage _proposalMsg = proposalMsg[i];
                if(_proposalMsg.expire > block.timestamp){
                    if(!_proposalMsg.proposalSta) {
                        proposalIndexs[_num++] = i;
                    }
                }else{
                    break;
                }
            } 
            if (_limit > _num){
                _limit = _num;
            }
            if (_page<2){
                _page = 1;
            }
            _page--;
            uint256 start = _page * _limit;
            uint256 end = start + _limit;
            if (end > _num){
                end = _num;
                _limit = end - start;
            }
            start = _num - start;
            end = _num - end; 
            indexs = new uint256[](_limit);
            if (_num > 0){
                uint256 j;
                for (uint256 i = end; i < start; i++) {
                    indexs[j] = proposalIndexs[i];
                    j++;
                }
            }
    }

    function _allProposalMsg(uint256 _page, uint256 _limit) internal view returns(uint256[] memory indexs, uint256 _num){
            _num = proposalCount;
            if (_limit > _num){
                _limit = _num;
            }
            if (_page<2){
                _page = 1;
            }
            _page--;
            uint256 start = _page * _limit;
            uint256 end = start + _limit;
            if (end > _num){
                end = _num;
                _limit = end - start;
            }
            start = _num - start;
            end = _num - end; 
            indexs = new uint256[](_limit);
            if (_num > 0){
                uint256 j;
                for (uint256 i = start; i > end; i--) {
                    indexs[j] = i;
                    j++;
                }
            }
    }

    function _obtainProposalMsg(
        uint256[] memory _proposalIds
    ) 
        internal 
        view 
        returns(
            QueryProposalMsgData memory queryProposalMsgData
        )
    {   
        uint256 len = _proposalIds.length;
        uint256 _nodeNum = nodeNum;
        queryProposalMsgData.proposalSponsors = new address[](len);
        queryProposalMsgData.contents = new string[](len);
        queryProposalMsgData.targetAddrs = new address[](len);
        queryProposalMsgData.amounts = new uint256[](len);
        queryProposalMsgData.proposalStas = new bool[](len);
        queryProposalMsgData.expires = new uint256[](len);
        queryProposalMsgData.allProposers = new address[](len*_nodeNum);
        ProposalMsg storage _proposalMsg;
        for (uint256 i = 0; i < len; i++) {
            _proposalMsg = proposalMsg[_proposalIds[i]];
            queryProposalMsgData.proposalSponsors[i] = _proposalMsg.proposalSponsor;
            queryProposalMsgData.contents[i] = _proposalMsg.content;
            queryProposalMsgData.targetAddrs[i] = _proposalMsg.targetAddr;
            queryProposalMsgData.amounts[i] = _proposalMsg.amount;
            queryProposalMsgData.proposalStas[i] =  _proposalMsg.proposalSta;
            queryProposalMsgData.expires[i] = _proposalMsg.expire;
            for (uint256 j = 0; j < _proposalMsg.allProposers.length; j++) {
                queryProposalMsgData.allProposers[i * _nodeNum +j] = _proposalMsg.allProposers[j];
            }
        }
    }

    function calcRelease(uint256 time) public view returns (uint256) {
        uint256 year = 365;
        time = (time - LockTime) / 1 days;
        if(time >= 5 * year){
            return 750 * 1e22;
        }else if(time >= year/2){
            return 300* 1e22 + 450 * 1e22 * (time - year/2)/(5 * year - year/2);
        }else if(time >= 0){
            return 300 * 1e22 * time/(year/2);
        }else {
            return 0;
        }
    }

    function queryUnlock() external view returns(uint256, uint256){
        uint256 _time = block.timestamp;
        uint256 _allAmount = calcRelease(_time);
        return (withdrawSum, _allAmount - withdrawSum);
    }
    
    function queryNodes()  external view returns(address[] memory){
        address[] memory nodes = new address[](nodeNum);
        for (uint256 i = 1; i <= nodeNum; i++) {
            nodes[i-1] = nodeIndexAddr[i];
        }
        return nodes;
    }

}
