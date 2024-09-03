// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;
abstract contract ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    mapping(address account => uint256) private _balances;

    mapping(address account => mapping(address spender => uint256))
        private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }

    function transfer(address to, uint256 value) public virtual returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, value);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 value
    ) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        if (from == address(0)) {
            revert();
        }
        if (to == address(0)) {
            revert();
        }
        _update(from, to, value);
    }

    function _update(address from, address to, uint256 value) internal virtual {
        if (from == address(0)) {
            // Overflow check required: The rest of the code assumes that totalSupply never overflows
            _totalSupply += value;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < value) {
                revert();
            }
            unchecked {
                // Overflow not possible: value <= fromBalance <= totalSupply.
                _balances[from] = fromBalance - value;
            }
        }

        if (to == address(0)) {
            unchecked {
                // Overflow not possible: value <= totalSupply or value <= fromBalance <= totalSupply.
                _totalSupply -= value;
            }
        } else {
            unchecked {
                // Overflow not possible: balance + value is at most totalSupply, which we know fits into a uint256.
                _balances[to] += value;
            }
        }

        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        if (account == address(0)) {
            revert();
        }
        _update(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        if (account == address(0)) {
            revert();
        }
        _update(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        _approve(owner, spender, value, true);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value,
        bool emitEvent
    ) internal virtual {
        if (owner == address(0)) {
            revert();
        }
        if (spender == address(0)) {
            revert();
        }
        _allowances[owner][spender] = value;
        if (emitEvent) {
            emit Approval(owner, spender, value);
        }
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 value
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < value) {
                revert();
            }
            unchecked {
                _approve(owner, spender, currentAllowance - value, false);
            }
        }
    }
}

contract SCTF is ERC20 {
    constructor(
        address owner,
        uint supply,
        uint8 decimals
    ) ERC20("SCTF", "sctf", decimals) {
        _mint(owner, supply);
    }
}

contract USDC is ERC20 {
    constructor(
        address owner,
        uint supply,
        uint8 decimals
    ) ERC20("USDC", "usdc", decimals) {
        _mint(owner, supply);
    }
}

contract StakingReward {
    struct Checkpoint {
        uint64 ts;
        uint128 value;
    }

    uint256 public block_timestamp;
    /*///////////////////////////////////////////////////////////////
                        CONSTANTS/IMMUTABLES
    ///////////////////////////////////////////////////////////////*/

    uint256 public constant MIN_COOLDOWN_PERIOD = 1 days;

    uint256 public constant MAX_COOLDOWN_PERIOD = 10 days;

    ERC20 public immutable usdc;
    ERC20 public immutable SCTF;

    /*///////////////////////////////////////////////////////////////
                                STATE
    ///////////////////////////////////////////////////////////////*/

    mapping(address => Checkpoint[]) public balancesCheckpoints;

    Checkpoint[] public totalSupplyCheckpoints;

    uint256 public periodFinish;

    uint256 public rewardsDuration;

    uint256 public lastUpdateTime;

    uint256 public cooldownPeriod;

    address public owner;

    mapping(address => uint256) public userLastStakeTime;

    uint256 public rewardRateUSDC;

    uint256 public rewardPerTokenStoredUSDC;

    mapping(address => uint256) public userRewardPerTokenPaidUSDC;

    mapping(address => uint256) public rewardsUSDC;

    /*///////////////////////////////////////////////////////////////
                                AUTH
    ///////////////////////////////////////////////////////////////*/
    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }

    modifier afterCooldown(address _account) {
        _afterCooldown(_account);
        _;
    }

    function _afterCooldown(address _account) internal view {
        uint256 canUnstakeAt = userLastStakeTime[_account] + cooldownPeriod;
        if (canUnstakeAt > block_timestamp) revert();
    }

    /*///////////////////////////////////////////////////////////////
                        CONSTRUCTOR / INITIALIZER
    ///////////////////////////////////////////////////////////////*/

    constructor(address _usdc, address sctf) {
        usdc = ERC20(_usdc);
        SCTF = ERC20(sctf);
        owner = msg.sender;

        rewardsDuration = 5 days;
        cooldownPeriod = 10 days;
        block_timestamp = block.timestamp;
    }

    /*///////////////////////////////////////////////////////////////
                                VIEWS
    ///////////////////////////////////////////////////////////////*/

    function totalSupply() public view returns (uint256) {
        uint256 length = totalSupplyCheckpoints.length;
        unchecked {
            return length == 0 ? 0 : totalSupplyCheckpoints[length - 1].value;
        }
    }

    function balanceOf(address _account) public view returns (uint256) {
        Checkpoint[] storage checkpoints = balancesCheckpoints[_account];
        uint256 length = checkpoints.length;
        unchecked {
            return length == 0 ? 0 : checkpoints[length - 1].value;
        }
    }

    /*///////////////////////////////////////////////////////////////
                            STAKE/UNSTAKE
    ///////////////////////////////////////////////////////////////*/

    function stake(uint256 _amount) external updateReward(msg.sender) {
        if (_amount == 0) return;

        // update state
        userLastStakeTime[msg.sender] = block_timestamp;
        _addTotalSupplyCheckpoint(totalSupply() + _amount);
        _addBalancesCheckpoint(msg.sender, balanceOf(msg.sender) + _amount);

        // transfer token to this contract from the caller
        SCTF.transferFrom(msg.sender, address(this), _amount);
    }

    function unstake(
        uint256 _amount
    ) public updateReward(msg.sender) afterCooldown(msg.sender) {
        if (_amount == 0) return;
        uint256 balance = balanceOf(msg.sender);
        if (_amount > balance) revert();

        _addTotalSupplyCheckpoint(totalSupply() - _amount);
        _addBalancesCheckpoint(msg.sender, balanceOf(msg.sender) - _amount);

        SCTF.transfer(msg.sender, _amount);
    }

    /*///////////////////////////////////////////////////////////////
                            CLAIM REWARDS
    ///////////////////////////////////////////////////////////////*/

    function getReward() external {
        _getReward(msg.sender);
    }

    function _getReward(address _account) internal {
        _getReward(_account, _account);
    }

    function _getReward(
        address _account,
        address _to
    ) internal updateReward(_account) {
        uint256 rewardUSDC = rewardsUSDC[_account];
        if (rewardUSDC > 0) {
            // update state (first)
            rewardsUSDC[_account] = 0;

            // transfer token from this contract to the account
            // as newly issued rewards from inflation are now issued as non-escrowed
            usdc.transfer(_to, rewardUSDC);
        }
    }

    /*///////////////////////////////////////////////////////////////
                        REWARD UPDATE CALCULATIONS
    ///////////////////////////////////////////////////////////////*/

    /// @notice update reward state for the account and contract
    /// @param _account: address of account which rewards are being updated for
    /// @dev contract state not specific to an account will be updated also
    modifier updateReward(address _account) {
        _updateReward(_account);
        _;
    }

    function _updateReward(address _account) internal {
        rewardPerTokenStoredUSDC = rewardPerTokenUSDC();
        lastUpdateTime = lastTimeRewardApplicable();

        if (_account != address(0)) {
            rewardsUSDC[_account] = earnedUSDC(_account);

            userRewardPerTokenPaidUSDC[_account] = rewardPerTokenStoredUSDC;
        }
    }

    function rewardPerTokenUSDC() public view returns (uint256) {
        uint256 allTokensStaked = totalSupply();

        if (allTokensStaked == 0) {
            return rewardPerTokenStoredUSDC;
        }

        return
            rewardPerTokenStoredUSDC +
            (((lastTimeRewardApplicable() - lastUpdateTime) *
                rewardRateUSDC *
                1e18) / allTokensStaked);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block_timestamp < periodFinish ? block_timestamp : periodFinish;
    }

    function earnedUSDC(address _account) public view returns (uint256) {
        uint256 totalBalance = balanceOf(_account);

        return
            ((totalBalance *
                (rewardPerTokenUSDC() - userRewardPerTokenPaidUSDC[_account])) /
                1e18) + rewardsUSDC[_account];
    }

    /*///////////////////////////////////////////////////////////////
                            CHECKPOINTING VIEWS
    ///////////////////////////////////////////////////////////////*/

    function balancesCheckpointsLength(
        address _account
    ) external view returns (uint256) {
        return balancesCheckpoints[_account].length;
    }

    function totalSupplyCheckpointsLength() external view returns (uint256) {
        return totalSupplyCheckpoints.length;
    }

    function balanceAtTime(
        address _account,
        uint256 _timestamp
    ) external view returns (uint256) {
        return
            _checkpointBinarySearch(balancesCheckpoints[_account], _timestamp);
    }

    function totalSupplyAtTime(
        uint256 _timestamp
    ) external view returns (uint256) {
        return _checkpointBinarySearch(totalSupplyCheckpoints, _timestamp);
    }

    function _checkpointBinarySearch(
        Checkpoint[] storage _checkpoints,
        uint256 _timestamp
    ) internal view returns (uint256) {
        uint256 length = _checkpoints.length;
        if (length == 0) return 0;

        uint256 min = 0;
        uint256 max = length - 1;

        if (_checkpoints[min].ts > _timestamp) return 0;
        if (_checkpoints[max].ts <= _timestamp) return _checkpoints[max].value;

        while (max > min) {
            uint256 midpoint = (max + min + 1) / 2;
            if (_checkpoints[midpoint].ts <= _timestamp) min = midpoint;
            else max = midpoint - 1;
        }

        assert(min == max);

        return _checkpoints[min].value;
    }

    /*///////////////////////////////////////////////////////////////
                            UPDATE CHECKPOINTS
    ///////////////////////////////////////////////////////////////*/

    function _addBalancesCheckpoint(address _account, uint256 _value) internal {
        _addCheckpoint(balancesCheckpoints[_account], _value);
    }

    function _addTotalSupplyCheckpoint(uint256 _value) internal {
        _addCheckpoint(totalSupplyCheckpoints, _value);
    }

    function _addCheckpoint(
        Checkpoint[] storage checkpoints,
        uint256 _value
    ) internal {
        uint256 length = checkpoints.length;
        uint256 lastTimestamp;
        unchecked {
            lastTimestamp = length == 0 ? 0 : checkpoints[length - 1].ts;
        }

        if (lastTimestamp != block_timestamp) {
            checkpoints.push(
                Checkpoint({
                    ts: uint64(block_timestamp),
                    value: uint128(_value)
                })
            );
        } else {
            unchecked {
                checkpoints[length - 1].value = uint128(_value);
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                                SETTINGS
    ///////////////////////////////////////////////////////////////*/

    function notifyRewardAmount(
        uint256 _rewardUsdc
    ) external onlyOwner updateReward(address(0)) {
        if (block_timestamp >= periodFinish) {
            rewardRateUSDC = _rewardUsdc / rewardsDuration;
        } else {
            uint256 remaining = periodFinish - block_timestamp;

            uint256 leftoverUsdc = remaining * rewardRateUSDC;
            rewardRateUSDC = (_rewardUsdc + leftoverUsdc) / rewardsDuration;
        }

        lastUpdateTime = block_timestamp;
        periodFinish = block_timestamp + rewardsDuration;
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
        if (block_timestamp <= periodFinish) revert();
        if (_rewardsDuration == 0) revert();

        rewardsDuration = _rewardsDuration;
    }

    function setCooldownPeriod(uint256 _cooldownPeriod) external onlyOwner {
        if (_cooldownPeriod < MIN_COOLDOWN_PERIOD) revert();
        if (_cooldownPeriod > MAX_COOLDOWN_PERIOD) {
            revert();
        }

        cooldownPeriod = _cooldownPeriod;
    }

    function vm_warp(uint256 warp) public {
        if (periodFinish != 0) {
            require(block_timestamp + warp <= periodFinish, "error time warp");
        }
        block_timestamp += warp;
    }
}

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
