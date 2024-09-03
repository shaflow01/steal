// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

import "./ERC20.sol";

contract USDC is ERC20 {
    constructor(
        address owner,
        uint supply,
        uint8 decimals
    ) ERC20("USDC", "usdc", decimals) {
        _mint(owner, supply);
    }
}
