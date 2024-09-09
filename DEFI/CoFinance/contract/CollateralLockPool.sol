// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract CollateralLockPool is ReentrancyGuard {
    using SafeMath for uint256;

    IERC20 public tokenA;
    IERC20 public tokenB;
    
    // Mapping to track locked collateral for each user and token
    mapping(address => uint256) public lockedCollateralA;
    mapping(address => uint256) public lockedCollateralB;

    // Constructor to initialize tokenA and tokenB
    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }
    
    // Function to lock collateral in the contract
    function lockCollateral(address user, address tokenAddress, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(tokenAddress == address(tokenA) || tokenAddress == address(tokenB), "Invalid token address");
        
        if (tokenAddress == address(tokenA)) {
            tokenA.transferFrom(user, address(this), amount);
            lockedCollateralA[user] = lockedCollateralA[user] + amount;
        } else if (tokenAddress == address(tokenB)) {
            tokenB.transferFrom(user, address(this), amount);
            lockedCollateralB[user] = lockedCollateralB[user] + amount;
        }
    }
    
    function unlockCollateral(address user, address tokenAddress, uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(tokenAddress == address(tokenA) || tokenAddress == address(tokenB), "Invalid token address");
        
        if (tokenAddress == address(tokenA)) {
            require(lockedCollateralA[user] >= amount, "Insufficient collateral");
            lockedCollateralA[user] = lockedCollateralA[user] - amount;
            tokenA.transfer(user, amount);
        } else if (tokenAddress == address(tokenB)) {
            require(lockedCollateralB[user] >= amount, "Insufficient collateral");
            lockedCollateralB[user] = lockedCollateralB[user] - amount;
            tokenB.transfer(user, amount);
        }
    }
}
