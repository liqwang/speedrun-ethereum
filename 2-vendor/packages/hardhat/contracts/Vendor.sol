pragma solidity 0.8.20; //Do not change the solidity version as it negatively impacts submission grading
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(address seller, uint256 amountOfETH, uint256 amountOfTokens);

    YourToken public yourToken;
    uint256 public constant tokensPerEth = 100;

    constructor(address tokenAddress) Ownable(_msgSender()) {
        yourToken = YourToken(tokenAddress);
    }

    // ToDo: create a payable buyTokens() function:
    function buyTokens() public payable {
        require(msg.value > 0, "You must pay some ether to buy tokens");
        uint256 amountToBuy = msg.value * tokensPerEth;
        uint256 vendorBalance = yourToken.balanceOf(address(this));
        require(vendorBalance >= amountToBuy, "Not enough tokens in the reserve");
        yourToken.transfer(msg.sender, amountToBuy);
        emit BuyTokens(msg.sender, msg.value, amountToBuy);
    }

    // ToDo: create a withdraw() function that lets the owner withdraw ETH
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ether to withdraw");
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed");
    }

    // ToDo: create a sellTokens(uint256 _amount) function:
    function sellTokens(uint256 _amount) public {
        require(_amount > 0, "You must sell at least some tokens");
        uint256 etherAmount = _amount / tokensPerEth;
        require(address(this).balance >= etherAmount, "Not enough ether in the reserve");
        // get the sold tokens back
        yourToken.transferFrom(msg.sender, address(this), _amount);
        // send ether to the seller
        (bool success, ) = msg.sender.call{value: etherAmount}("");
        require(success, "Transfer failed");
        emit SellTokens(msg.sender, etherAmount, _amount);
    }
}
