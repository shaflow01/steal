// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;
import "./staking.sol";
import "./SCTF.sol";
import "./USDC.sol";
contract test01 {
    StakingReward public staking;
    address public player;
    SCTF public sctf;
    USDC public usdc;
    bool isClaimed;
    constructor() {
        sctf = new SCTF(address(this), 120_000e18 + 10e18, 18);
        usdc = new USDC(address(this), 1_00e6, 6);
        staking = new StakingReward(address(usdc), address(sctf));
        sctf.approve(address(staking), 120_000e18);
        staking.stake(120_000e18);
        staking.vm_warp(1);
        usdc.transfer(address(staking), 100e6);
        staking.notifyRewardAmount(100e6);
    }

    function registerPlayer() public {
        require(staking.block_timestamp() != staking.periodFinish());
        require(player == address(0), "Already Registered");
        player = msg.sender;
        sctf.transfer(player, 10e18);
    }

    function claimReward() public {
        require(staking.block_timestamp() == staking.periodFinish());
        require(!isClaimed);
        staking.getReward();
        isClaimed = true;
    }

    function isSolved() public view returns (bool) {
        if (
            player != address(0) &&
            isClaimed &&
            (usdc.balanceOf(address(this)) < 1e6)
        ) {
            return true;
        }
        return false;
    }
}
