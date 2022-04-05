// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        address[] memory accounts
    ) ERC20(name, symbol) {
        uint256 mintAmt = 10000 * 1e18;
        for (uint256 i = 0; i < accounts.length; i++) {
            _mint(accounts[i], mintAmt);
        }
    }
}
