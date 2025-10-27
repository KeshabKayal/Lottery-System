// SPDX-License-Identifier: MIT
// This line is standard and specifies the software license.
pragma solidity ^0.8.0;


contract SimpleRaffle {



    // The address of the person who deployed the contract.
    address payable public manager;
    
    // A dynamic list to store the addresses of all participants.
    address[] public participants;
    
    // The fixed price for one raffle ticket
    // We set it to 0.01 Ether (using the 'ether' keyword is very handy).
    uint public constant TICKET_PRICE = 0.01 ether;
    
    // The address of the person who wins the raffle.
    address public winner;
    
    // The total amount of Ether collected from ticket sales.
    uint public prizePool;

    // --- EVENTS ---

    // Events are signals the contract sends out.
    // Your JavaScript app can listen for these to update the UI.
    event RaffleEntered(address indexed participant);
    event WinnerPicked(address indexed winnerAddress, uint prizeAmount);
    event PrizeDistributed(address indexed winnerAddress, uint prizeAmount);

    // --- MODIFIER ---

    /**
     * @dev A modifier is a reusable check. This one ensures that
     * only the manager's address can call a function.
     */
    modifier restrictedToManager() {
        // 'msg.sender' is the address of the person calling the function.
        require(msg.sender == manager, "Only the manager can call this function.");
        
        // The '_' symbol means "run the rest of the function's code."
        _;
    }

    // --- CONSTRUCTOR ---

    /**
     * @dev The constructor runs *only once* when the contract is deployed.
     * It sets the 'manager' to be the address that deployed it.
     */
    constructor() {
        manager = payable(msg.sender);
    }

    // --- FUNCTIONS ---

    /**
     * @dev Allows any user to enter the raffle.
     * It is 'payable', meaning it can receive Ether.
     */
    function enter() public payable {
        // 1. Check: Did the user send the *exact* ticket price?
        // 'msg.value' is the amount of Ether sent with the function call.
        require(msg.value == TICKET_PRICE, "You must send exactly the ticket price.");
        
        // 2. Logic: Add the user's address to the participants list.
        participants.push(msg.sender);
        
        // 3. Logic: Add the sent Ether to the prize pool.
        prizePool += msg.value;
        
        // 4. Event: Emit an event so the frontend knows someone entered.
        emit RaffleEntered(msg.sender);
    }

    /**
     * @dev Picks a winner. Only the manager can call this.
     * WARNING: This 'random' method is NOT secure for a real-money lottery.
     */
    function pickWinner() public restrictedToManager {
        // 1. Check: Is there at least one person in the raffle?
        require(participants.length > 0, "No participants have entered yet.");
        
        // 2. Logic: Generate a simple, pseudo-random index.
        uint randomIndex = uint(
            keccak256(abi.encodePacked(block.timestamp, participants.length))
        ) % participants.length;
        
        // 3. Logic: Set the winner using the random index.
        winner = participants[randomIndex];
        
        // 4. Event: Announce the winner.
        emit WinnerPicked(winner, prizePool);
    }

    /**
     * @dev Sends the entire prize pool to the winner and resets the raffle.
     * Only the manager can call this.
     */
    function distributePrize() public restrictedToManager {
        // 1. Check: Has a winner been picked?
        require(winner != address(0), "A winner must be picked first.");
        
        // 2. Check: Is there money to send?
        require(prizePool > 0, "The prize pool is empty.");

        // --- Security Pattern: Checks-Effects-Interactions ---
        
        // 3. (Effects) Store prize amount and reset state *before* sending.
        // This prevents a "re-entrancy" attack.
        uint amountToSend = prizePool;
        
        participants = new address[](0); // Reset the participants array
        prizePool = 0;                   // Reset the prize pool
        address payable winnerAddress = payable(winner);
        winner = address(0);             // Reset the winner

        // 4. (Interaction) Send the Ether to the winner.
        // We use .call() as it is the modern, recommended way.
        (bool success, ) = winnerAddress.call{value: amountToSend}("");
        require(success, "Failed to send Ether to the winner.");
        
        // 5. Event: Announce that the prize was sent.
        emit PrizeDistributed(winnerAddress, amountToSend);
    }

    // --- VIEW FUNCTIONS (Read-only) ---

    /**
     * @dev A helper function to see the list of all participants.
     * 'view' means it's read-only and doesn't cost any gas to call.
     */
    function getParticipants() public view returns (address[] memory) {
        return participants;
    }
}