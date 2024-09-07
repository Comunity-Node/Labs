// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CoFinance.sol"; 

contract CoFinanceFactory {
    uint256 public creationFee  = 10;
    uint public Reward = 10;
    address public owner;
    uint256 public maxFeePercent; // Maximum fee percentage allowed for pools
    address[] public allPools; 
    mapping(address => mapping(address => address)) public pools; 
    mapping(address => address[]) public poolsByToken;
    mapping(address => address) public poolByPair; 
    mapping(address => bool) public incentivizedPools;

    event PoolCreated(
        address indexed poolAddress,
        address indexed tokenA,
        address indexed tokenB,
        address liquidityTokenAddress,
        address rewardToken,
        address priceFeed,
        address stakingContract,
        bool isPoolIncentivized,
        address factory
    );
    event CreationFeeUpdated(uint256 newFee);
    event FeesWithdrawn(address indexed owner, address token, uint256 amount);
    event PoolIncentivized(address indexed poolAddress); // Declared event

    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    function createPool(
        address tokenA,
        address tokenB,
        address rewardToken,
        address priceFeed,
        string memory liquidityTokenName,
        string memory liquidityTokenSymbol,
        bool isPoolIncentivized

    ) external payable returns (address) {
        require(msg.value == creationFee, "Incorrect ETH amount sent");
        require(tokenA != tokenB, "Token addresses must be different");
        if (tokenA > tokenB) {           
            (tokenA, tokenB) = (tokenB, tokenA);
        }
        address existingPool = pools[tokenA][tokenB];
        if (existingPool != address(0)) {
            return existingPool; 
        }
        LiquidityToken liquidityToken = new LiquidityToken(liquidityTokenName, liquidityTokenSymbol);
        Staking stakingContract = new Staking(address(liquidityToken), rewardToken); 
        CoFinance pool = new CoFinance(
            tokenA,
            tokenB,
            rewardToken,
            priceFeed,
            address(liquidityToken),
            address(stakingContract),
            isPoolIncentivized,
            address(this)
        );
        liquidityToken.setCoFinanceContract(address(pool));
        pools[tokenA][tokenB] = address(pool);
        poolsByToken[tokenA].push(address(pool));
        poolsByToken[tokenB].push(address(pool));
        allPools.push(address(pool));
        if (isPoolIncentivized) {
            incentivizedPools[address(pool)] = true;
        }
        emit PoolCreated(
            address(pool),
            tokenA,
            tokenB,
            address(liquidityToken),
            rewardToken,
            priceFeed,
            address(stakingContract),
            isPoolIncentivized,
            address(this)
        );
        return address(pool);
    }
    function getAllPools() external view returns (address[] memory) {
        return allPools;
    }
    function updateCreationFee(uint256 newFee) external onlyOwner {
        creationFee = newFee;
        emit CreationFeeUpdated(newFee);
    }
    function getPoolByToken(address token) external view returns (address[] memory) {
        return poolsByToken[token];
    }
    function getPoolByPair(address tokenA, address tokenB) external view returns (address) {
        if (tokenA > tokenB) {
            (tokenA, tokenB) = (tokenB, tokenA);
        }
        return pools[tokenA][tokenB];
    }
    function withdrawFees(address tokenAddress) external onlyOwner {
        if (tokenAddress == address(0)) {
            uint256 balance = address(this).balance;
            require(balance > 0, "No ETH to withdraw");
            payable(owner).transfer(balance);
            emit FeesWithdrawn(owner, address(0), balance);
        } else {
            IERC20 token = IERC20(tokenAddress);
            uint256 balance = token.balanceOf(address(this));
            require(balance > 0, "No ERC20 tokens to withdraw");
            token.transfer(owner, balance);
            emit FeesWithdrawn(owner, tokenAddress, balance);
        }
    }

    function getIncentivizedPools() external view returns (address[] memory) {
        address[] memory incentivizedPoolList = new address[](allPools.length);
        uint256 count = 0;

        for (uint256 i = 0; i < allPools.length; i++) {
            if (incentivizedPools[allPools[i]]) {
                incentivizedPoolList[count] = allPools[i];
                count++;
            }
        }
        address[] memory result = new address[](count);
        for (uint256 j = 0; j < count; j++) {
            result[j] = incentivizedPoolList[j];
        }
        return result;
    }

    function updateIncentivizedPool(address poolAddress, address tokenA, address tokenB) external {
        if (tokenA > tokenB) {
            (tokenA, tokenB) = (tokenB, tokenA);
        }
        require(pools[tokenA][tokenB] == poolAddress, "Pool not found");
        incentivizedPools[poolAddress] = true;
        emit PoolIncentivized(poolAddress);
    }
}
