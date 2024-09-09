// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;  // Specify compiler version for safety

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CoFinance.sol";
import "./LiquidityToken.sol";
import "./Staking.sol";
import "./CollateralLockPool.sol";

contract CoFinanceFactory {
    uint256 public creationFee = 10;
    address public owner;
    address public immutable thisAddress; 
    address[] public allPools;
    mapping(address => mapping(address => address)) public pools; 
    mapping(address => address[]) private  poolsByToken;
    mapping(address => bool) public incentivizedPools;

    event PoolCreated(
        address indexed poolAddress,
        address indexed tokenA,
        address indexed tokenB,
        address liquidityTokenAddress,
        address rewardToken,
        address priceFeed,
        address stakingContract,
        address collateralLockPool, 
        bool isPoolIncentivized
    );
    event CreationFeeUpdated(uint256 newFee);
    event FeesWithdrawn(address indexed owner, address token, uint256 amount);
    event PoolIncentivized(address indexed poolAddress);

    constructor() {
        owner = msg.sender;
        thisAddress = address(this);  
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
        require(msg.value == creationFee, "Incorrect amount sent");
        require(tokenA != tokenB, "Token addresses must be different");

        if (tokenA > tokenB) {
            (tokenA, tokenB) = (tokenB, tokenA);
        }

        address existingPool = pools[tokenA][tokenB];
        if (existingPool != address(0)) {
            return existingPool; 
        }
        CollateralLockPool collateralLockPool = new CollateralLockPool(tokenA, tokenB);
        LiquidityToken liquidityToken = new LiquidityToken(liquidityTokenName, liquidityTokenSymbol);
        Staking stakingContract = new Staking(address(liquidityToken), rewardToken);
        CoFinance pool = new CoFinance(
            tokenA,
            tokenB,
            rewardToken,
            priceFeed,
            address(liquidityToken),
            address(stakingContract),
            address(collateralLockPool), 
            isPoolIncentivized,
            thisAddress
        );
        liquidityToken.setCoFinanceContract(address(pool));
        pools[tokenA][tokenB] =address(pool);
        poolsByToken[tokenA].push(address(pool));
        poolsByToken[tokenB].push(address(pool));
        allPools.push(address(pool));
        emit PoolCreated(
            address(pool),
            tokenA,
            tokenB,
            address(liquidityToken),
            rewardToken,
            priceFeed,
            address(stakingContract),
            address(collateralLockPool),
            isPoolIncentivized
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
        if (tokenA != tokenB) {
            (tokenA, tokenB) = (tokenB, tokenA);
        }
        return pools[tokenA][tokenB];
    }

    function withdrawFees(address tokenAddress) external onlyOwner {
        if (tokenAddress == address(0)) {
            uint256 balance = thisAddress.balance; 
            require(balance > 0, "No ETH to withdraw");
            (bool success, ) = owner.call{value: balance}("");
            require(success, "Transfer failed");
            emit FeesWithdrawn(owner, address(0), balance);
        } else {
            IERC20 token = IERC20(tokenAddress);
            uint256 balance = token.balanceOf(thisAddress); 
            require(balance > 0, "No ERC20 tokens to withdraw");
            bool success = token.transfer(owner, balance);
            require(success, "Transfer failed");
            emit FeesWithdrawn(owner, tokenAddress, balance);
        }
    }

}
