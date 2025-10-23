// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LotteryRaffle {
    
    address payable public manager; 

   
    uint public prizePool;         
    uint public ticketPrice = 1 ether;
    uint public entryCount = 0;    

    
    address[] public participants;


}        