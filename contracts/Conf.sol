// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Initialize {
    bool internal initialized;

    modifier init(){
        require(!initialized, "initialized");
        _;
        initialized = true;
    }
}

contract Conf is Initialize {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address guy) external auth { wards[guy] = 1; }
    function deny(address guy) external auth { wards[guy] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }

    // --- NetMind contracts ---
    address public WNMT;
    address public Training;
    address public Inference;
    address public Price;
    address public Credit;
    address public Staking;
    address public Award;

    // --- Award msg ---              part per ten-thousandth unit [THD]
    uint256 public begin;
    uint256 public award;            //total award => 10 billions
    uint256 public miner_awd_1;      //Award of first 10 years => 1%     [THD]
    uint256 public miner_awd_2;      //Award of 11-40 years => 0.5%      [THD]
    uint256 public miner_awd_3;      //Award of 41-100 years => 0.25%    [THD]
    uint256 public og_awd;           //Award of OG including node operator and staking => 0.3%   [THD]
    uint256 public node_awd;         //Award of node operator proportion => 20%     [THD]
    uint256 public staking_awd;      //Award of staking operator proportion => 80%  [THD]
    uint256 public staking_gini;     //Award of staking coefficients => 8%          [THD]

    // --- Payment ---
    uint256 public p_settlement;     //novc-settlement proportion => 50%    [THD]
    uint256 public N;                
    address public accountManageExecutor;
    address public priceServiceExecutor;
    address public trainingTaskExecutor;
    uint256 public v_settlement;     //vc-settlement proportion => 80%    [THD]
    uint256 public fmr_awd;          //Fully Managed Rewards => 1.1       [THD]
    uint256 public non_vc_awd;       //Only non-VC mode rewards => 0.95   [THD]
    uint256 public vc_awd;           //Only VC mode rewards  => 1         [THD]

    // --- Accountant ---
    mapping(address=> bool) public acts;  //accountants is the signer of ledger, snapshot and accountMange.       

    function initialize() external init {
        begin = block.timestamp;
        award = 10**28;
        wards[msg.sender] = 1;
    }

    function files(string[] calldata whats, address[] calldata dstas) external auth {
         require(whats.length == dstas.length, "Number of parameters does not match"); 
         bytes32 result;
         string memory str;
         for (uint256 i = 0; i < whats.length; i++) { 
            str = whats[i];
            assembly{
                 result := mload(add(str,32))
            }
            file(result, dstas[i]);
         }
     }

    function files(string[] calldata whats, uint[] calldata datas) external auth {
         require(whats.length == datas.length, "Number of parameters does not match"); 
         bytes32 result;
         string memory str;
         for (uint256 i = 0; i < whats.length; i++) { 
            str = whats[i];
            assembly{
                 result := mload(add(str,32))
            }
            file(result, datas[i]);
         }
    }

    // --- Administration ---
    function file(bytes32 what, address dst) public auth {
        if (what == "WNMT") WNMT = dst;
        else if (what == "Training") Training = dst;
        else if (what == "Inference") Inference = dst;
        else if (what == "Price") Price = dst;
        else if (what == "Credit") Credit = dst;
        else if (what == "Staking") Staking = dst;
        else if (what == "Award") Award = dst;
        else if (what == "AccountManageExecutor") accountManageExecutor = dst;
        else if (what == "PriceServiceExecutor") priceServiceExecutor = dst;
        else if (what == "TrainingTaskExecutor") trainingTaskExecutor = dst;
    }

    function file(bytes32 what, uint data) public auth {
        if (what == "miner_awd_1") miner_awd_1 = data;
        else if (what == "miner_awd_2") miner_awd_2 = data;
        else if (what == "miner_awd_3") miner_awd_3 = data;
        else if (what == "og_awd") og_awd = data;
        else if (what == "node_awd") node_awd = data;
        else if (what == "staking_awd") staking_awd = data;
        else if (what == "staking_gini") staking_gini = data;
        else if (what == "p_settlement") p_settlement = data;
        else if (what == "v_settlement") v_settlement = data;
        else if (what == "N") N = data;
        else if (what == "fmr_awd") fmr_awd = data;
        else if (what == "non_vc_awd") non_vc_awd = data;
        else if (what == "vc_awd") vc_awd = data;
    }

    function file(address act, bool flag) public auth {
        acts[act] = flag;
    }

    function getAwradMSG() public view 
    returns(
        uint256 miner_award, 
        uint256 node_award, 
        uint256 staking_award, 
        uint256 staking_gini_, 
        uint256 award_N,
        uint256 fmr_awd_,
        uint256 non_vc_awd_,
        uint256 vc_awd_
    ){
        require(begin > 0, "begin not set");
        require(node_awd > 0, "node_awd not set");
        uint256 i;
        if (block.timestamp < begin + 10 * 356 days) i = miner_awd_1;
        else if(block.timestamp < begin + 40 * 365 days) i = miner_awd_2;
        else i = miner_awd_3;

        uint256 og_award = award * og_awd /365 /10**4;
        award_N = N;
        fmr_awd_ = fmr_awd;
        non_vc_awd_ = non_vc_awd;
        vc_awd_ = vc_awd;
        return(
            award * i /365 /10**4,
            og_award * node_awd /10**4,
            og_award * staking_awd /10**4,
            staking_gini,
            award_N,
            fmr_awd,
            non_vc_awd,
            vc_awd
        );
    }

    function getAwradMSG(uint256 time) public view returns(uint256 miner_award, uint256 node_award, uint256 staking_award, uint256 staking_gini_){
        require(begin > 0, "begin not set");
        require(time > begin, "error time");
        require(node_awd > 0, "node_awd not set");
        uint256 i;
        if (time < begin + 10 * 356 days) i = miner_awd_1;
        else if(time < begin + 40 * 365 days) i = miner_awd_2;
        else i = miner_awd_3;

        uint256 og_award = award * og_awd /365 /10**4;
        return(
        award * i /365 /10**4,
        og_award * node_awd /10**4,
        og_award * staking_awd /10**4,
        staking_gini
        );
    }
}
