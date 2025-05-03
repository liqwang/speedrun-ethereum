// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; //Do not change the solidity version as it negatively impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    uint256 public constant threshold = 1 ether;

    ExampleExternalContract public exampleExternalContract;
    mapping(address => uint256) public balances;
    uint256 public deadline = block.timestamp + 30 seconds;
    bool public openForWithdraw = false;

    modifier notCompleted() {
        require(!exampleExternalContract.completed(), "Staking has already been completed");
        _;
    }

    // (Make sure to add a `Stake(address,uint256)` event and emit it for the frontend `All Stakings` tab to display)
    event Stake(address indexed staker, uint256 amount);

    constructor(address exampleExternalContractAddress) {
        exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    function stake() public payable {
        require(msg.value > 0, "Must send ETH to stake");
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
    function execute() public notCompleted {
        require(block.timestamp >= deadline, "Deadline not reached");
        if (address(this).balance >= threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
        } else {
            openForWithdraw = true;
        }
    }

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
    function withdraw() public notCompleted {
        require(openForWithdraw, "Withdrawals are not open yet");
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    /**
     * @dev `receive()` function is a special function, which doesn't have the keyword `function`
     * https://ethereum.stackexchange.com/questions/81994/what-is-the-receive-keyword-in-solidity
     */
    receive() external payable {
        stake();
    }
}
