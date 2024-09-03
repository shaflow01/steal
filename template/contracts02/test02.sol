// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

contract setUp2 {
    bytes constant target = hex"53be43be54be46be";
    bool isDeposit;
    bool isWithdraw;

    constructor() {}
    function deposit() public payable {
        require(msg.value == 5);
        require(!isDeposit);
        isDeposit = true;
    }

    function containsTargetBytes(
        address contractAddress
    ) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(contractAddress)
        }

        if (size == 0 || size > 64) {
            return false;
        }

        bytes memory code = new bytes(size);
        assembly {
            extcodecopy(contractAddress, add(code, 0x20), 0, size)
        }

        for (uint256 i = 0; i <= size - target.length; i++) {
            bool found = true;
            for (uint256 j = 0; j < target.length; j++) {
                if (code[i + j] != target[j]) {
                    found = false;
                    break;
                }
            }
            if (found) {
                return true;
            }
        }
        return false;
    }

    function steal() public {
        require(isDeposit);
        require(!isWithdraw);
        require(containsTargetBytes(msg.sender), "Bad contract");
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success);
        isWithdraw = true;
    }

    function isSolved() public view returns (bool) {
        if (isDeposit && isWithdraw && address(this).balance == 0) {
            return true;
        }
        return false;
    }
}
