# Solidity Rock-Papers-Scissors

## Introduction

Due to the open nature of the blockchain, a very simple game like Rocks-Papers-Scissors also gets a little complicated to code in solidity.
Transactions on the blockchain are single-threaded, i.e each transaction is executed one by one in the evm. The order depending on whichever transactions the miner chooses to execute from the mempool (which is further dependent on the amount of gas fee each transaction is willing to pay).

But in the game of rock-papers-scissors(RPS), each player plays their hand at the same time because if one player plays the hand before the other one, then the other player can easily play the hand which is higher than whatever hand the first player played and thus win every single time. Hence the first player will be at a very big disadvantage. This is exactly the problem in coding a RPS game smart contract on the evm, some player has to send a transaction and play his hand first.

So how do we solve this? Well ofcourse, if whatever hand the first player was encrypted (or hashed). So the second player will only see the encrypted hand and wont be able to figure out the actual hand of the first player. Then the second player will play a open hand (not encrypted). Now the first player will give the secret, which will be used to decrypt his encrypted hand and reveal the original hand. Thus the contract will then compare this with the second player's hand and give the reward to whoever is the winner.

### The smart contract has the following features:

1.  No owner & No proxy: The contract is ownerless and without proxy. i.e once deployed the code is the law here. You dont have to worry about anyone rugging you or changing the implementation to a different address on a proxy address and take all your funds.
2.  You can bet with any token (but we prefer $DOST).
3.  You can create different games with different accounts, different tokens, different bet amounts.

### Flow

First one player has to create a game calling the createGame() method with the following parameters

```
        address _player1 : Address of the first player,
        address _player2 : Address of the second player,
        uint256 _betAmount : Amount of tokens to bet in each round,
        address _token : Address of the betting token in the game
```

This will output a gameId, which will be id of your created game. So any two players can create a game, and will be given their unique gameIds which they can use to play the game.

Then, each player have buy chips for that game from the contract using the betting token using the <storng>buyChips()</strong>. You will have to use these chips to play in the game. Then in each round of the RPS game, you have to bet an equal amount of chips. The winner will win all.

Once chips bought, the player1 has to call the <strong>playPlayer1()</strong> to play his encrypted hand.
Second, the player2 will call the <strong>playPlayer2()</strong> method to play his open hand.

Thirdly, the player1 has to call the <strong>showdown()</strong> method to reveal his card, the contract will first check if his
revealed card matches his already saved encrypted card, if verified the contract will compare both the players' cards to determine the winner and reward all the chips to the winner. And then forward the game to the next round where player1 & player2 can play again.

But you dont have to worry about all this encryption because it will be done behind the react frontend. You can just play your cards.

Alsow there is a <strong>withdraw</strong> method to withdraw your chips which you can do anytime to withdraw your chips back to tokens. (remember, if you lose chips, your actual tokens are also gone)

## Deployment (Polygon Mainnet):

[0xe793f0720fDF720cEBa8Ae219D4ab633BC275649](https://polygonscan.com/address/0xe793f0720fdf720ceba8ae219d4ab633bc275649)

## Tests

To run tests run

```
        forge test
```
