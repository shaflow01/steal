// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./ERC20.sol";

contract SCTF is ERC20 {
    constructor(
        address owner,
        uint supply,
        uint8 decimals
    ) ERC20("SCTF", "sctf", decimals) {
        _mint(owner, supply);
    }
}
