//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TEST is ERC20 {
    constructor() ERC20("Test ERC20 Token", "TEST") {
        _mint(msg.sender, 400_000_000_000000000000000000);
    }
}
