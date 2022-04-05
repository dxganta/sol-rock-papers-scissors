// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./RockPaperScissorsData.sol";

/**
    First a game will be created with the addresses of each player, bet amount and the token
    Then each player will buy chips by sending some amount of token to bet in the game
    On start of a game, the first player will first send a hashed version of his hand(rocks, papers or scissors)
    Then the second player will play his hand openly
    Then the first player will reveal his hand
    The contract will first verify that his hand is correct based on the hash that she submitted before 
    Once verified, the contract will send the bet amount chips to whoever won that round
 */

contract RockPaperScissors is RockPaperScissorsData {
    uint256 public totalGames;
    // gameId => Game
    mapping(uint256 => Game) public games;
    // player => gameId => number of chips
    mapping(address => mapping(uint256 => uint256)) public chips;

    // gameId => roundId => Hands
    mapping(uint256 => mapping(uint256 => Hands)) public hands;

    // player1_hand => player2_hand => index of the winner (0 for player1 & 1 for player2)
    mapping(Action => mapping(Action => uint256)) private _judge;

    constructor() {
        _judge[Action.Rock][Action.Paper] = 1;
        _judge[Action.Rock][Action.Scissors] = 0;
        _judge[Action.Paper][Action.Rock] = 0;
        _judge[Action.Paper][Action.Scissors] = 1;
        _judge[Action.Scissors][Action.Rock] = 1;
        _judge[Action.Scissors][Action.Paper] = 0;
    }

    function createGame(
        address _player1,
        address _player2,
        uint256 _betAmount,
        address _token
    ) external returns (uint256 gameId) {
        gameId = totalGames;
        games[gameId] = Game({
            round: 0,
            state: GameState.InActive,
            player1: _player1,
            player2: _player2,
            betAmount: _betAmount,
            token: IERC20(_token)
        });
        emit GameCreated(gameId, games[gameId]);

        totalGames += 1;
    }

    /**
        @dev once a game is created, the players must call this method to buy chips for that game that
        they will use to bet 
     */
    function buyChips(
        address _for,
        uint256 _gameId,
        uint256 _amount
    ) public {
        Game memory game = games[_gameId];

        require(
            IERC20(game.token).transferFrom(msg.sender, address(this), _amount)
        );

        chips[_for][_gameId] += _amount;

        emit ChipsAdded(_gameId, _for, _amount);
    }

    /**
        called by a player1 to play rock, paper or scissors
        player1 sends a hashed entry with a secret key to the game
     */
    function playPlayer1(uint256 _gameId, bytes32 _hand) external {
        Game storage game = games[_gameId];

        require(game.state == GameState.InActive, "Error: Not your turn");
        require(msg.sender == game.player1, "Error: Wrong sender");

        chips[msg.sender][_gameId] -= game.betAmount;
        hands[_gameId][game.round].player1 = _hand; // saved for later proof when the hand is revealed
        game.state = GameState.Active;

        emit Player1Hand(_gameId, _hand);
    }

    /**
        called by a player2 to play his/her hand without hash
     */
    function playPlayer2(uint256 _gameId, Action _hand) external {
        Game storage game = games[_gameId];

        require(game.state == GameState.Active, "Error: Not your turn");
        require(msg.sender == game.player2, "Error: Wrong sender");

        chips[msg.sender][_gameId] -= game.betAmount;
        hands[_gameId][game.round].player2 = _hand;
        game.state = GameState.Finished;

        emit Player2Hand(_gameId, _hand);
    }

    /**
        @dev called by player1 with his hand revealed to decide the winner
     */
    function showdown(
        uint256 _gameId,
        uint256 _secret,
        Action _hand
    ) external {
        Game storage game = games[_gameId];

        require(game.state == GameState.Finished, "Error: game not finished");
        require(msg.sender == game.player1, "Error: Wrong sender");

        // verify player1's card
        bytes32 actualHash = keccak256(abi.encodePacked(_secret, _hand));
        require(
            actualHash == hands[_gameId][game.round].player1,
            "Error: Cannot verify hash"
        );

        // decide the winner
        uint256 winnerIndex = _judge[_hand][hands[_gameId][game.round].player2];
        address winner;
        if (winnerIndex == 0) {
            winner = game.player1;
        } else {
            winner = game.player2;
        }

        chips[winner][_gameId] += 2 * game.betAmount;

        emit GameFinished(
            _gameId,
            _hand,
            hands[_gameId][game.round].player2,
            winner
        );

        // re initialize the game
        game.round += 1;
        game.state = GameState.InActive;
    }

    /**
        method used by players to convert chips back to tokens and withdraw
     */
    function withdraw(uint256 _gameId, uint256 _amount) external {
        Game memory game = games[_gameId];

        uint256 max = chips[msg.sender][_gameId];

        if (_amount > max) {
            _amount = max;
        }

        require(_amount > 0, "Eror: cannot withdraw 0");

        require(game.token.transfer(msg.sender, _amount));

        chips[msg.sender][_gameId] -= _amount;

        emit ChipsWithdrawn(_gameId, msg.sender, _amount);
    }
}

// TODO:
// 1. Feature: if player1 takes a lot of time to call showdown then after a certain deadline player2 can call a method to win
// all the bet amount in that round irrespective of who won
