// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./utils/IERC20.sol";
import "./utils/Ownable.sol";
import "./utils/ReentrancyGuard.sol";

contract TRGStaking is Ownable, ReentrancyGuard {
    IERC20 public immutable trgToken;

    struct StakeInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 lastStakeTime;
    }

    mapping(address => StakeInfo) public stakes;
    uint256 public totalStaked;
    uint256 public rewardPool;
    uint256 public constant REWARD_RATE_PER_YEAR = 20;
    uint256 public constant SECONDS_IN_YEAR = 365 days;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount, uint256 reward);
    event RewardAdded(uint256 amount);

    constructor(address _tokenAddress) Ownable(msg.sender) {
        require(_tokenAddress != address(0), "Invalid token address");
        trgToken = IERC20(_tokenAddress);
    }

    function addReward(uint256 amount) external onlyOwner {
        require(trgToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        rewardPool += amount;
        emit RewardAdded(amount);
    }

    function stake(uint256 amount) external nonReentrant {
        require(amount > 0, "Cannot stake zero");
        require(trgToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        _updateReward(msg.sender);

        stakes[msg.sender].amount += amount;
        stakes[msg.sender].lastStakeTime = block.timestamp;
        totalStaked += amount;

        emit Staked(msg.sender, amount);
    }

    function unstake() external nonReentrant {
        StakeInfo storage user = stakes[msg.sender];
        require(user.amount > 0, "No stake to withdraw");

        _updateReward(msg.sender);

        uint256 amount = user.amount;
        uint256 reward = user.rewardDebt;

        require(reward <= rewardPool, "Not enough reward in pool");

        user.amount = 0;
        user.rewardDebt = 0;
        totalStaked -= amount;
        rewardPool -= reward;

        require(trgToken.transfer(msg.sender, amount + reward), "Transfer failed");

        emit Unstaked(msg.sender, amount, reward);
    }

    function _updateReward(address account) internal {
        StakeInfo storage user = stakes[account];
        if (user.amount > 0) {
            uint256 duration = block.timestamp - user.lastStakeTime;
            uint256 reward = (user.amount * REWARD_RATE_PER_YEAR * duration) / (100 * SECONDS_IN_YEAR);
            user.rewardDebt += reward;
            user.lastStakeTime = block.timestamp;
        }
    }

    function pendingReward(address account) external view returns (uint256) {
        StakeInfo storage user = stakes[account];
        if (user.amount == 0) return 0;

        uint256 duration = block.timestamp - user.lastStakeTime;
        uint256 reward = (user.amount * REWARD_RATE_PER_YEAR * duration) / (100 * SECONDS_IN_YEAR);
        return user.rewardDebt + reward;
    }
}

