pragma solidity ^0.8.9;

import 'hardhat/console.sol';

contract RPS{
    
    // 0x5fe7f977e71dba2ea1a68e21057beebb9be2ac30c6410aa38d4f3fbe41dcffd2    Rock
    // 0xf2ee15ea639b73fa3db9b34a245bdfa015c260c598b211bf05a1ecc4b3e3b4f2    Paper 
    // 0x69c322e3248a5dfc29d73c5b0553b0185a35cd5bb6386747517ef7e53b15e287    Scissors

    //*** improvements:
    // * pull over push payments 
    // * can bet the previous winnings
    // * refine and reduce gas costs 
    

    enum Moves{None, Rock, Paper, Scissors}

    //after the first move has been entered the other player will have 5 minutes 
    //
    uint256 constant public timer = 5 minutes;
    uint8 private constant entered = 2;
    uint256 public wager;
    address payable private player1;
    address payable private player2;
    bool private bothHaveChosen;
    bytes32 private encrMovePlayer1;
    bytes32 private encrMovePlayer2;
    uint256 private firstReveal;      
    
    
     mapping( address => uint8 )addressEntered;
     mapping( address => uint8 )enteredMove;

     event NewGame(address _player1, address _player2, uint256 _wager, bytes32 _encrMovePlayer1, bytes32 _encrMovePlayer2);
     event Finished(address winner, uint256 winnings);

    
    
    function enroll()external payable { //validBet isJoinable
        require(player1 == address(0) || player2 == address(0), "Sorry game is full");
        require(msg.value >= wager, "you must enter a value >= player1's bet");

        if(player1 == address(0)){
            player1 = payable(msg.sender);
            wager = msg.value;
            console.log("%s is player1", msg.sender);
            console.log("%s is player1's wager", msg.value);
            
        }else{
            player2 = payable(msg.sender);
            console.log("%s is player2", msg.sender);
            console.log("%s is player2's wager", msg.value);
        }

        
    }
    

    function play(bytes32 encrMove) public returns(bool){ //madeMove

        

        require(player1 != address(0) && player2 != address(0), "both players must enroll to start the game");

        require(encrMove == bytes32(keccak256(abi.encodePacked(Moves.Rock))) || 
                encrMove == bytes32(keccak256(abi.encodePacked(Moves.Paper))) ||
                encrMove == bytes32(keccak256(abi.encodePacked(Moves.Scissors))), "Must enter a valid move");

        require(enteredMove[msg.sender] <= 1,  "you have already entered this function");

        console.log("%s is the encripted move made by %s = msg.sender", encrMove, msg.sender);

        enteredMove[msg.sender] += entered; // cannot re-enter/change move 

        bool player1HasChosen;
        bool player2HasChosen;

        if (msg.sender == player1 && encrMovePlayer1 == 0x0) {
            encrMovePlayer1 = encrMove;
            player1HasChosen = true;
        } else if (msg.sender == player2 && encrMovePlayer2 == 0x0) {
            encrMovePlayer2 = encrMove;
            player2HasChosen = true;
        } else {
            return false;
        }

        if(player1HasChosen && player2HasChosen){
            bothHaveChosen = true;
        }

        if (firstReveal == 0) {
            firstReveal = block.timestamp;
        }

        emit NewGame(player1, player2, wager, encrMovePlayer1, encrMovePlayer2);

        return true;

    }
    
    function evaluate() public  { //playersMadeChoice
        
        if(firstReveal != 0 && block.timestamp > firstReveal + timer){// check if the timer has passed 5 minutes 
            player1.transfer(wager);
            player2.transfer(wager);
            resetGame();

        }else{
            
            require(bothHaveChosen, "both players must make their move");
            delete enteredMove[player1];
            delete enteredMove[player2];

            address winner;

            bytes32 Rock = keccak256(abi.encodePacked(Moves.Rock));
            bytes32 Paper = keccak256(abi.encodePacked(Moves.Paper));
            bytes32 Scissors = keccak256(abi.encodePacked(Moves.Scissors));
        
            if( encrMovePlayer1 == Rock && encrMovePlayer2 == Paper ||
                encrMovePlayer1 == Scissors && encrMovePlayer2 == Rock ||
                encrMovePlayer1 == Paper && encrMovePlayer2 == Scissors ){
                winner = player2;

            }else if( encrMovePlayer1 == Rock && encrMovePlayer2 == Rock ||
                    encrMovePlayer1 == Paper && encrMovePlayer2 == Paper ||
                    encrMovePlayer1 == Scissors && encrMovePlayer2 == Scissors ){
                    winner = address(this);
            }else{
                winner = player1;
            }

            theWinner(payable(winner));
            emit Finished(winner, address(this).balance);
            
            
        }

    }

    function theWinner(address payable _winner) internal {
        if(_winner == address(this)){
            returnWager(player1, player2, wager);
        }else{
            pay(_winner);
        }
    }

    function returnWager(address payable _player1, address payable _player2, uint256 _wager) internal {
        resetGame(); //reset game before paying to avoid reentrancy 
        
        (bool success, ) = _player1.call{value: _wager}(""); //.call is more gas efficient and upgradable as gas prices may change in future 
        require(success);

        (bool success2, ) = _player2.call{value: address(this).balance}(""); // contract balance should be cleared after every game so no fund roll over 
        require(success2);


        // _player1.transfer(_wager);
        // _player2.transfer(address(this).balance);
    }
    
    function pay(address payable _winner) internal {
        resetGame(); 

        (bool success, ) = _winner.call{value: address(this).balance}("");
        require(success);

        // _winner.transfer(address(this).balance);
    }


    function resetGame() internal{
    
        delete wager;
        delete player1;
        delete player2;
        delete bothHaveChosen;
        delete encrMovePlayer1;
        delete encrMovePlayer2;
    }

    /*********** Helper Functions ************/

    function hash(Moves move) public  returns(bytes32){ // I used this function for remix IDE testing
       require(addressEntered[msg.sender] <= 1,  "you have already entered this function");
       addressEntered[msg.sender] += entered;
       bytes32 encryptedMove1 = keccak256(abi.encodePacked(move));
       return encryptedMove1;
    }
    

    function getContractBalance() public view returns (uint) {
        require(msg.sender ==  player1 || msg.sender == player2, "You must be a player to view the pot balance");
        return address(this).balance;
    }

    function getWager() public view returns(uint256){
        return wager;
    }



}