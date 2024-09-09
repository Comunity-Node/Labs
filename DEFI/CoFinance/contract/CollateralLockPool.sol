// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract CollateralLockPool is ReentrancyGuard {
    IERC20 public tokenA;
    IERC20 public tokenB;
        mapping(address => uint256) public lockedCollateralA;
    mapping(address => uint256) public lockedCollateralB;
    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }
    
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
