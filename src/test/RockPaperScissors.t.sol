// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "ds-test/test.sol";

import "../RockPaperScissors.sol";
import "../RockPaperScissorsData.sol";
import "../ERC20Mock.sol";

interface CheatCodes {
    function prank(address) external;

    function startPrank(address) external;

    function stopPrank() external;

    function expectRevert() external;

    function expectRevert(bytes calldata) external;

    function expectRevert(bytes4) external;
    // Expects an error on next call
}

contract RockPaperScissorsTest is DSTest, RockPaperScissorsData {
    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
    RockPaperScissors rps;
    ERC20Mock token;

    uint8 rock = 1;
    uint8 scissors = 2;
    uint8 paper = 3;

    address player1 = address(1);
    address player2 = address(2);
    address player3 = address(3);
    address player4 = address(4);

    function setUp() public {
        // deploy the contract
        rps = new RockPaperScissors();

        address[] memory accounts = new address[](4);
        accounts[0] = player1;
        accounts[1] = player2;
        accounts[2] = player3;
        accounts[3] = player4;
        token = new ERC20Mock("Plutoverse", "DOST", accounts);
    }

    function testCreateGame() public {
        uint256 betAmt = 10 * 1e18;
        uint256 gameId = rps.createGame(
            player1,
            player2,
            betAmt,
            address(token)
        );

        (
            ,
            ,
            address _player1,
            address _player2,
            uint256 _betAmt,
            IERC20 _token
        ) = rps.games(gameId);

        assertEq(_player1, player1);
        assertEq(_player2, player2);
        assertEq(_betAmt, betAmt);
        assertEq(address(token), address(_token));
    }

    function testBuyChips() public {
        uint256 betAmt = 10 * 1e18;
        uint256 gameId = rps.createGame(
            player1,
            player2,
            betAmt,
            address(token)
        );

        cheats.startPrank(player1);
        assertEq(rps.chips(player1, gameId), 0);
        assertEq(token.balanceOf(address(rps)), 0);
        uint256 chipAmt = betAmt * 100;
        token.approve(address(rps), chipAmt);
        uint256 initBal = token.balanceOf(player1);
        rps.buyChips(player1, gameId, chipAmt);

        // assert tokens have been taken from player1
        assertEq(initBal - token.balanceOf(player1), chipAmt);
        // assert chips balance of player1 has been increased for gameId
        assertEq(rps.chips(player1, gameId), chipAmt);
        // assert contract token balance increased
        assertEq(token.balanceOf(address(rps)), chipAmt);
    }

    /**
         _hand 1-Rock, 2-Scissors, 3-Paper
     */
    function testPlays() public {
        uint256 betAmt = 10 * 1e18;
        uint256 gameId = rps.createGame(
            player1,
            player2,
            betAmt,
            address(token)
        );

        uint256 chipAmt = betAmt * 100;
        // player 1 chooses rock
        uint256 secret = 69;
        bytes32 rockHash = keccak256(abi.encodePacked(secret, rock));

        _buyChips(player1, chipAmt, gameId);

        _buyChips(player2, chipAmt, gameId);

        cheats.startPrank(player2);
        cheats.expectRevert(bytes("Error: Wrong sender"));
        rps.playPlayer1(gameId, rockHash);
        cheats.expectRevert(bytes("Error: Not your turn"));
        rps.playPlayer2(gameId, rock);

        cheats.startPrank(player1);
        rps.playPlayer1(gameId, rockHash);
        cheats.expectRevert(bytes("Error: Not your turn"));
        rps.playPlayer1(gameId, rockHash);
        cheats.expectRevert(bytes("Error: Wrong sender"));
        rps.playPlayer2(gameId, rock);
        // players chip balance must be reduced by betAmt
        assertEq(rps.chips(player1, gameId), chipAmt - betAmt);

        cheats.startPrank(player2);
        rps.playPlayer2(gameId, paper);
        assertEq(rps.chips(player2, gameId), chipAmt - betAmt);
        cheats.expectRevert(bytes("Error: Not your turn"));
        rps.playPlayer2(gameId, paper);
        cheats.expectRevert(bytes("Error: Not your turn"));
        rps.playPlayer1(gameId, rockHash);

        cheats.startPrank(player1);
        cheats.expectRevert(bytes("Error: Not your turn"));
        rps.playPlayer1(gameId, rockHash);
        cheats.expectRevert(bytes("Error: Not your turn"));
        rps.playPlayer2(gameId, scissors);
    }

    function testShowdown() public {
        uint256 betAmt = 10 * 1e18;
        uint256 gameId = rps.createGame(
            player1,
            player2,
            betAmt,
            address(token)
        );

        uint256 chipAmt = betAmt * 100;

        _buyChips(player1, chipAmt, gameId);

        _buyChips(player2, chipAmt, gameId);

        // player 1 chooses rock
        uint256 secret = 69;
        bytes32 rockHash = keccak256(abi.encodePacked(secret, rock));
        cheats.prank(player1);
        rps.playPlayer1(gameId, rockHash);

        // player 2 chooses Scissors
        cheats.prank(player2);
        rps.playPlayer2(gameId, scissors);

        uint256 initBal = rps.chips(player1, gameId);
        // player 1 must win
        cheats.startPrank(player1);
        rps.showdown(gameId, secret, rock);

        // assert player 1 won
        assertEq(rps.chips(player1, gameId) - initBal, 2 * betAmt);
        // and player 2 lost
        assertEq(rps.chips(player2, gameId), chipAmt - betAmt);

        // test withdraw
        initBal = token.balanceOf(player1);
        rps.withdraw(gameId, 2 * betAmt);
        uint256 newBal = token.balanceOf(player1);
        assertEq(newBal - initBal, 2 * betAmt);

        // trying to withdraw more than chips balance must withdraw the chip balance
        uint256 chipBal = rps.chips(player1, gameId);
        rps.withdraw(gameId, 2 * chipBal);
        assertEq(token.balanceOf(player1) - newBal, chipBal);
        cheats.expectRevert(bytes("Eror: cannot withdraw 0"));
        rps.withdraw(gameId, betAmt);
    }

    function _buyChips(
        address player,
        uint256 chipAmt,
        uint256 gameId
    ) internal {
        cheats.startPrank(player);
        token.approve(address(rps), chipAmt);
        rps.buyChips(player, gameId, chipAmt);
        cheats.stopPrank();
    }
}
