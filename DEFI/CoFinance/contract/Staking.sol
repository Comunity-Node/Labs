// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interface/ILiquidityToken.sol";
import "./Interface/ICoFinance.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract Staking is ReentrancyGuard  {

    uint256 public immutable APR_7_DAYS = 20; // 20% APR for 7 days
    uint256 public immutable APR_14_DAYS = 30; // 30% APR for 14 days
    uint256 public immutable APR_21_DAYS = 50; // 50% APR for 21 days
    uint256 public constant SECONDS_IN_7_DAYS = 7 days;
    uint256 public constant SECONDS_IN_14_DAYS = 14 days;
    uint256 public constant SECONDS_IN_21_DAYS = 21 days;

    ILiquidityToken public liquidityToken;
    ICoFinance public coFinance;

    mapping(address => uint256) public stakerBalances;
    mapping(address => uint256) public stakingStartTimes;
    mapping(address => uint256) public rewardBalances;

    constructor(address _liquidityToken, address _coFinance) {
        liquidityToken = ILiquidityToken(_liquidityToken);
        coFinance = ICoFinance(_coFinance);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        IERC20(address(liquidityToken)).transferFrom(msg.sender, address(this), amount);
        updateRewards(msg.sender);
        stakerBalances[msg.sender] = stakerBalances[msg.sender] + amount;
        stakingStartTimes[msg.sender] = block.timestamp;
    }

    function withdraw(uint256 amount) external {
        require(stakerBalances[msg.sender] >= amount, "Insufficient balance");
        updateRewards(msg.sender);
        stakerBalances[msg.sender] = stakerBalances[msg.sender] - (amount);
        IERC20(address(liquidityToken)).transfer(msg.sender, amount);
    }

    function claimReward() external {
        updateRewards(msg.sender);
        uint256 reward = rewardBalances[msg.sender];
        require(reward != 0, "No rewards to claim");
        rewardBalances[msg.sender] = 0;
        IERC20 rewardToken = IERC20(coFinance.rewardToken());
        rewardToken.transfer(msg.sender, reward);
    }

    function updateRewards(address staker) internal {
        uint256 stakerBalance = stakerBalances[staker];
        uint256 stakingDuration = block.timestamp - stakingStartTimes[staker];

        uint256 apr = getAPRForDuration(stakingDuration);
        uint256 newReward = stakerBalance * apr / stakingDuration / 100 / 365 days;

        rewardBalances[staker] = rewardBalances[staker] + newReward;
        stakingStartTimes[staker] = block.timestamp;
    }

    function getAPRForDuration(uint256 duration) internal pure returns (uint256) {
        if (duration <= SECONDS_IN_7_DAYS) {
            return APR_7_DAYS;
        } else if (duration <= SECONDS_IN_14_DAYS) {
            return APR_14_DAYS;
        } else if (duration <= SECONDS_IN_21_DAYS) {
            return APR_21_DAYS;
        } else {
            return 0;
        }
    }
}
