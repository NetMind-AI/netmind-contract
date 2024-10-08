// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;

interface IProxy {
    function changeAdmin(address newAdmin) external returns(bool);
    function upgrad(address newLogic) external returns(bool);
}

interface IManagement {
    function addNodePropose(address _addr) external;
    function deleteNodePropose(address _addr) external;
    function updateProxyAdminPropose(address _targetAddr, address _addr) external;
    function updateProxyUpgradPropose(address _targetAddr, address _addr) external;
    function excContractPropose(address _targetAddr, bytes memory _data) external;
    function excContractProposes(address[] calldata _targetAddrs, bytes[] calldata _datas) external;
    function vote(uint256 _proposalId) external;
    function votes(uint256[] calldata _proposalIds) external;

}

contract Management is IManagement{
    uint256 public  proposalCount;                           
    mapping(uint256 => ProposalMsg) public proposalMsg;
    uint256 public nodeNum;
    mapping(address => uint256) nodeAddrIndex;
    mapping(uint256 => address) nodeIndexAddr;
    mapping(address => bool) public nodeAddrSta;
    bool private reentrancyLock = false;
    enum TypeIndex{AddNodeAddr, DeleteNodeAddr, ChangeAdmin, Upgrad, ExcContract}

    event Propose(address indexed proposer, uint256 proposalId, string label);
    event Vote(address indexed voter, uint256 proposalId);
    
    struct ProposalMsg {
        address[] proposers;
        bool proposalSta; 
        address targetAddr;   
        address addr;  
        bytes data;
		uint256 expire; 
        TypeIndex typeIndex;  
        string  label;  
        mapping(address => bool) voterSta;  
    }

    modifier nonReentrant() {
        require(!reentrancyLock);
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    constructor(address[] memory _nodeAddrs) {
        uint256 len = _nodeAddrs.length;
        require( len> 4,"The number of node addresses cannot be less than 5");
        for (uint256 i = 0; i< _nodeAddrs.length; i++){
            addNodeAddr(_nodeAddrs[i]);
        }
    }
 
    function addNodePropose(address _addr) override external{
        require(_addr != address(0), "The address is 0 address");
        require(!nodeAddrSta[_addr], "This node is already a node address");
        bytes memory data = new bytes(0x00);
        _propose(address(0), _addr, data, TypeIndex.AddNodeAddr, "addNode");
    }
  
    function deleteNodePropose(address _addr) override external{
        require(nodeAddrSta[_addr], "This node is not a node address");
        require(nodeNum > 5, "The number of node addresses cannot be less than 5");
        _propose(address(0), _addr, new bytes(0x00), TypeIndex.DeleteNodeAddr, "deleteNode");
    }
     
    function updateProxyAdminPropose(address _targetAddr, address _addr) override external{
        _propose(_targetAddr, _addr, new bytes(0x00), TypeIndex.ChangeAdmin, "updateProxyAdmin");
    }
      
    function updateProxyUpgradPropose(address _targetAddr, address _addr) override external{
        _propose(_targetAddr, _addr, new bytes(0x00), TypeIndex.Upgrad, "updateProxyUpgrad");
    }
    
    function excContractProposes(address[] calldata _targetAddrs, bytes[] calldata _datas) override external{
        for(uint i=0; i<_targetAddrs.length; i++){
            _excContractPropose(_targetAddrs[i], _datas[i]);
        }
    }
    
    function excContractPropose(address _targetAddr, bytes memory _data) override external{
        _excContractPropose(_targetAddr, _data);
    }
  
    function _excContractPropose(address _targetAddr, bytes memory _data) internal{
        require(_targetAddr != address(this), "targetAddr error"); 
        require(bytesToUint(_data) != 2401778032 && bytesToUint(_data) != 822583150, "Calls to methods of proxy contracts are not allowed");
        _propose(_targetAddr, address(0), _data, TypeIndex.ExcContract, "excContract");
    }

    function _propose(
        address _targetAddr, 
        address _addr, 
        bytes memory _data, 
        TypeIndex _typeIndex, 
        string memory _label
    ) internal{
        address _sender = msg.sender;
        require(nodeAddrSta[_sender], "The caller is not the nodeAddr"); 
        uint256 _time = block.timestamp;
        uint256 _proposalId = ++proposalCount;
        ProposalMsg storage _proposalMsg = proposalMsg[_proposalId];
        _proposalMsg.proposers.push(_sender);
        _proposalMsg.targetAddr = _targetAddr;
        _proposalMsg.addr = _addr;
        _proposalMsg.data = _data;
        _proposalMsg.expire = _time + 86400*3;
        _proposalMsg.typeIndex = _typeIndex;
        _proposalMsg.label = _label;
        _proposalMsg.voterSta[_sender] = true;
        emit Propose(_sender, _proposalId, _label);
    }
    
    function vote(uint256 _proposalId) override external nonReentrant(){
        _vote(_proposalId);
    }
       
    function votes(uint256[] calldata _proposalIds) override external nonReentrant(){
        for(uint i=0; i<_proposalIds.length; i++){
            _vote(_proposalIds[i]);
        }
    }
         
    function _vote(uint256 _proposalId) internal {
        address _sender = msg.sender;
        require(nodeAddrSta[_sender], "The caller is not the nodeAddr"); 
        uint256 _time = block.timestamp;
        ProposalMsg storage _proposalMsg = proposalMsg[_proposalId];
        require(!_proposalMsg.proposalSta, "The proposal has already been executed");
        require(_proposalMsg.expire > _time, "The vote on the proposal has expired");
        require(!_proposalMsg.voterSta[_sender], "The proposer has already voted");
        _proposalMsg.proposers.push(_sender);
        _proposalMsg.voterSta[_sender] = true;
        uint256 length = _proposalMsg.proposers.length;
        if(length> nodeNum/2 && !_proposalMsg.proposalSta){
            require(_actuator(_proposalId), "The method call failed");
            _proposalMsg.proposalSta = true;
        }
        emit Vote(_sender, _proposalId);
    }

    function _actuator(uint256 _proposalId) internal returns(bool){
        bool result = false;
        ProposalMsg storage _proposalMsg = proposalMsg[_proposalId];
        TypeIndex _typeIndex = _proposalMsg.typeIndex;
        if(_typeIndex == TypeIndex.AddNodeAddr){
            addNodeAddr(_proposalMsg.addr);
            result = true;
        }else if(_typeIndex == TypeIndex.DeleteNodeAddr){
            deleteNodeAddr(_proposalMsg.addr);
            result = true;
        }else if(_typeIndex == TypeIndex.ChangeAdmin){
            IProxy proxy = IProxy(_proposalMsg.targetAddr);
            result = proxy.changeAdmin(_proposalMsg.addr);
        }else if(_typeIndex == TypeIndex.Upgrad){
            IProxy proxy = IProxy(_proposalMsg.targetAddr);
            result = proxy.upgrad(_proposalMsg.addr);
        }else if(_typeIndex == TypeIndex.ExcContract){
            bytes memory _data = _proposalMsg.data;
            (result, ) = _proposalMsg.targetAddr.call(_data);
        }
        return result;
    }

    function addNodeAddr(address _nodeAddr) internal{
        require(_nodeAddr != address(0), "The address is 0");
        require(!nodeAddrSta[_nodeAddr], "This node is already a node address");
        nodeAddrSta[_nodeAddr] = true;
        uint256 _nodeAddrIndex = nodeAddrIndex[_nodeAddr];
        if (_nodeAddrIndex == 0){
            _nodeAddrIndex = ++nodeNum;
            nodeAddrIndex[_nodeAddr] = _nodeAddrIndex;
            nodeIndexAddr[_nodeAddrIndex] = _nodeAddr;
        }
    }

    function deleteNodeAddr(address _nodeAddr) internal{
        require(nodeAddrSta[_nodeAddr], "This node is not a pledge node");
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
        require(nodeNum > 4, "The number of node addresses cannot be less than 5");
    }

    function bytesToUint(bytes memory _data) internal pure returns (uint256){
        require(_data.length >= 4, "Insufficient byte length");
        uint256 number;
        for(uint i= 0; i<4; i++){
            number = number + uint8(_data[i])*(2**(8*(4-(i+1))));
        }
        return  number;
    }

    function queryVotes(
        uint256 _proposalId
    ) 
        external 
        view 
        returns(
            address[] memory, 
            bool, 
            address, 
            address,
            bytes memory, 
            uint256, 
            string memory)
    {
        ProposalMsg storage _proposalMsg = proposalMsg[_proposalId];
        uint256 len = _proposalMsg.proposers.length;
        address[] memory proposers = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            proposers[i] = _proposalMsg.proposers[i];
        }
        return (proposers, _proposalMsg.proposalSta, _proposalMsg.targetAddr, _proposalMsg.addr, _proposalMsg.data, 
               _proposalMsg.expire, _proposalMsg.label);
    }

    function queryNodes()  external view returns(address[] memory){
        address[] memory nodes = new address[](nodeNum);
        for (uint256 i = 1; i <= nodeNum; i++) {
            nodes[i-1] = nodeIndexAddr[i];
        }
        return nodes;
    }

}
