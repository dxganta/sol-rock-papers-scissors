// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

abstract contract RockPaperScissorsData {
    enum Action {
        Rock,
        Paper,
        Scissors
    }

    enum GameState {
        InActive, // once game is finished, it will go to inactive state
        Active, // once player1 submits hash entry it will go to active state
        // and then once player2 submits game will go to finished state, waiting for player1 to reveal hash and decide winner
        Finished // players cannot bet if the game is in a finished state, you must wait till the game is in Inactive state again, which will happen after the bet amount is rewarded to the winner
    }

    struct Game {
        uint256 round;
        GameState state; // current state of the game
        address player1;
        address player2;
        uint256 betAmount;
        IERC20 token;
    }

    struct Hands {
        bytes32 player1; // the hashed entry of player 1 (rocks, paper or scissors)
        Action player2; // unhashed entry of player 2
    }

    event GameCreated(uint256 gameId, Game game);
    event ChipsAdded(uint256 gameId, address account, uint256 amount);
    event ChipsWithdrawn(uint256 gameId, address account, uint256 amount);
    event Player1Hand(uint256 gameId, bytes32 hand);
    event Player2Hand(uint256 gameId, Action hand);
    event GameFinished(
        uint256 gameId,
        Action player1Hand,
        Action player2Hand,
        address winner
    );
}
