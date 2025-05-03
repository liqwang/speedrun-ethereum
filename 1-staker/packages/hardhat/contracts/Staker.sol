// SPDX-License-Identifier: MIT
pragma solidity 0.8.20; //Do not change the solidity version as it negatively impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;
    mapping(address => uint256) public balances;
    uint256 public constant THRESHOLD = 1 ether;

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

    // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
    function withdraw() public {
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

    // Add the `receive()` special function that receives eth and calls stake()
}
