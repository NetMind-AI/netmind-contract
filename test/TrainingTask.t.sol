// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {AccountManage} from "../contracts/AccountManage.sol";
import {AccountManageProxy} from "../contracts/proxy/AccountManage_proxy.sol";
import {IAccountManage} from "./interfaces/IAccountManage.sol";
import {TrainingTask} from "../contracts/TrainingTask.sol";
import {TrainingTaskProxy} from "../contracts/proxy/TrainingTask_proxy.sol";
import {ITrainingTask} from "./interfaces/ITrainingTask.sol";
import {ConfInit} from "./ConfInit.sol";


contract TrainingTaskTest is ConfInit {
    IAccountManage public accountManage;
    ITrainingTask public trainingTask;
    address public owner = 0x2cD77303737430D78F5a5FbCf8B8f8064d2a92a9;
    address user = 0x70Da4f87fE2E695a058E5CBdB324c0935efd836C;
    address executor = 0xA82d72F648037c075554882Bd4FBF0C80E950644;
    address taskExecutor = 0x1111111254EEB25477B68fb85Ed929f73A960582;
    string userId = "test";
                
    function setUp() public {
        vm.startPrank(owner);
        ConfInit.init();
        vm.deal(address(trainingTask), 100000 ether);
        accountManage = IAccountManage(address(new AccountManageProxy(address(new AccountManage()))));
        accountManage.init(address(conf));
        trainingTask = ITrainingTask(address(new TrainingTaskProxy(address(new TrainingTask()))));
        trainingTask.init(address(conf), address(accountManage));
        accountManage.updateAuthSta(address(trainingTask), true);
        vm.stopPrank();
    }

    function initJob() public {
        vm.startPrank(owner);
        conf.file(accountManageExecutor, executor);
        conf.file(trainingTaskExecutor, taskExecutor);
        conf.file(0x705f736574746c656d656e740000000000000000000000000000000000000000, 5000); //set p_settlement
        vm.stopPrank();
        vm.prank(executor);
        accountManage.initUserId(userId, user);
        vm.deal(user,1e32);
        vm.prank(user);
        accountManage.tokenCharge{value: 1e23}();
    }

    function testOwner() public {
        assertEq(trainingTask.owner(), owner);
    }

    function test_execJob() public {
        initJob();
        vm.prank(taskExecutor);
        trainingTask.execJob(userId, "job123", 10 ether, 1);

        (uint256 freezeAmount, uint256 usageAmount, uint256 surplusAmount, uint256 state, uint256 jobType) = trainingTask.queryJobMsg("job123");

        assertEq(freezeAmount, 10 ether);
        assertEq(state, 1); 
        assertEq(jobType, 1);
    }

    function test_updateJob() public {
        initJob();
        vm.prank(taskExecutor);
        trainingTask.execJob(userId, "job123", 10 ether, 1);

        vm.prank(taskExecutor); 
        trainingTask.updateJob(userId, "job123", 2 ether, "order001");

        (uint256 freezeAmount,,,,) = trainingTask.queryJobMsg("job123");
        assertEq(freezeAmount, 12 ether); 
    }

    function test_execJobDebit() public {
        initJob();
        vm.prank(taskExecutor);
        trainingTask.execJob(userId, "job123", 10 ether, 1);

        vm.prank(taskExecutor); 
        trainingTask.execJobDebit(userId, "job123", 3 ether, "order002");

        (uint256 freezeAmount, uint256 usageAmount,,,) = trainingTask.queryJobMsg("job123");

        assertEq(freezeAmount, 7 ether);  
        assertEq(usageAmount, 3 ether); 
    }

    function test_endJob() public {
        initJob();
        vm.startPrank(taskExecutor);
        trainingTask.execJob(userId, "job123", 10 ether, 1);
        trainingTask.execJobDebit(userId, "job123", 3 ether, "order002");
        trainingTask.endJob(userId, "job123", 3 ether, 2);

        (uint256 freezeAmount, uint256 usageAmount,,,) = trainingTask.queryJobMsg("job123");
        assertEq(usageAmount, 6 ether); 
        assertEq(freezeAmount, 0); 
        vm.stopPrank();
    }

}
