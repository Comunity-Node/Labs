// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Interface/ICollateralLockPool.sol";
import "./Interface/ILiquidityToken.sol";
import "./Staking.sol";
import "./Interface/IPricefeed.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract CoFinance is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    IERC20 public tokenA;
    IERC20 public tokenB;
    ILiquidityToken public liquidityToken;
    Staking public stakingContract;
    IERC20 public rewardToken;
    IPriceFeed public priceFeed;
    ICollateralLockPool public collateralLockPool; 
    address public owner;
    address public factory;
    uint256 public swapFeePercent = 5;
    uint256 public constant INTEREST_RATE_30_DAYS = 2;
    uint256 public constant INTEREST_RATE_90_DAYS = 6;
    uint256 public constant SECONDS_IN_30_DAYS = 30 days;
    uint256 public constant SECONDS_IN_90_DAYS = 90 days;
    uint256 public ownerSharePercent = 7;
    bool public isPoolIncentivized;

    address private immutable _thisAddress;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public borrowed;
    mapping(address => uint256) public collateralA;
    mapping(address => uint256) public collateralB;
    mapping(address => uint256) public loanStartTime;
    mapping(address => uint256) public loanDuration;
    mapping(address => address) public borrowedToken;
    mapping(address => uint256) public userLiquidityBalance;
    mapping(address => uint256) public userSwapFees;
    mapping(address => uint256) public userInterestFees;
    mapping(address => CollateralPool) public userPools;
    mapping(address => uint256) public userAccumulatedSwapFees;

    uint256 public totalSwapFeesA;
    uint256 public totalSwapFeesB;
    uint256 public totalCollateralA;
    uint256 public totalCollateralB;
    uint256 public totalLiquidity;

    struct CollateralPool {
        address poolAddress;
        bool isActive;
    }

    event TokensSwapped(address indexed swapper, uint256 tokenAAmount, uint256 tokenBAmount, uint256 feeAmount);
    event LiquidityProvided(address indexed provider, uint256 tokenAAmount, uint256 tokenBAmount, uint256 liquidityTokensMinted);
    event TokensBorrowed(address indexed borrower, uint256 tokenAAmount, address tokenAddress, uint256 duration);
    event CollateralDeposited(address indexed depositor, address indexed tokenAddress, uint256 amount);
    event CollateralWithdrawn(address indexed withdrawer, uint256 amount);
    event LoanRepaid(address indexed borrower, uint256 amount);
    event CollateralLiquidated(address indexed borrower, uint256 collateralAmount);
    event SwapFeeClaimed(address indexed claimer, uint256 amount);
    event InterestFeeClaimed(address indexed claimer, uint256 amount);
    event LiquidityTokensSent(address recipient, uint256 amount);
    event WithdrawLiquidity(address indexed exiter, uint256 tokenAAmount, uint256 tokenBAmount);

    constructor(
        address _tokenA,
        address _tokenB,
        address _rewardToken,
        address _priceFeed,
        address _liquidityToken,
        address _stakingContract,
        address _collateralLockPool,  
        bool _isPoolIncentivized,
        address _factory
    ) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        rewardToken = IERC20(_rewardToken);
        priceFeed = IPriceFeed(_priceFeed);
        liquidityToken = ILiquidityToken(_liquidityToken);
        stakingContract = Staking(_stakingContract);
        collateralLockPool = ICollateralLockPool(_collateralLockPool); 
        owner = msg.sender;
        isPoolIncentivized = _isPoolIncentivized;
        factory = _factory;
        _thisAddress = address(this);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier hasCollateral() {
        require(collateralA[msg.sender] != 0 || collateralB[msg.sender] != 0, "No collateral available");
        _;
    }

     function swapTokens(address tokenAddress, uint256 tokenAmount) external {
        require(tokenAmount != 0, "Token amount must be greater than 0");
        uint256 totalFee = tokenAmount * swapFeePercent / 1000; // 0.5%
        uint256 factoryFee = totalFee * 10 / 100; 
        uint256 poolReward = totalFee - factoryFee;
        uint256 amountAfterFee = tokenAmount - totalFee;
        uint256 priceTokenA = priceFeed.getTokenAPrice();
        uint256 priceTokenB = priceFeed.getTokenBPrice();

        if (tokenAddress == address(tokenA)) {
            uint256 tokenBAmount = amountAfterFee * priceTokenA / priceTokenB;
            tokenA.safeTransferFrom(msg.sender, _thisAddress, tokenAmount);
            tokenA.safeTransfer(factory, factoryFee);
            distributeFees(poolReward, true);
            tokenB.safeTransfer(msg.sender, tokenBAmount);
            emit TokensSwapped(msg.sender, tokenAmount, tokenBAmount, factoryFee);
        } else if (tokenAddress == address(tokenB)) {
            uint256 tokenAAmount = amountAfterFee * priceTokenB / priceTokenA;
            tokenB.safeTransferFrom(msg.sender, _thisAddress, tokenAmount);
            tokenB.safeTransfer(factory, factoryFee);
            distributeFees(poolReward, false);
            tokenA.safeTransfer(msg.sender, tokenAAmount);
            emit TokensSwapped(msg.sender, tokenAmount, tokenAAmount, factoryFee);
        } else {
            revert("Invalid token address");
        }
    }


    function depositCollateral(address tokenAddress, uint256 amount) external {
        require((tokenAddress == address(tokenA) || tokenAddress == address(tokenB)) && amount != 0, "Invalid input");

        IERC20(tokenAddress).safeTransferFrom(msg.sender, _thisAddress, amount);

        if (tokenAddress == address(tokenA)) {
            collateralA[msg.sender] += amount;
            totalCollateralA += amount;
        } else {
            collateralB[msg.sender] += amount;
            totalCollateralB += amount;
        }

        emit CollateralDeposited(msg.sender, tokenAddress, amount);
    }

    function withdrawCollateral(uint256 amount) external hasCollateral {
        require(amount != 0, "Amount must be greater than 0");
        uint256 collateralAmount;
        if (collateralA[msg.sender] >= amount) {
            collateralAmount = amount;
            collateralA[msg.sender] -= amount;
            totalCollateralA -= amount;
            tokenA.safeTransfer(msg.sender, amount);
        } else if (collateralB[msg.sender] >= amount) {
            collateralAmount = amount;
            collateralB[msg.sender] -= amount;
            totalCollateralB -= amount;
            tokenB.safeTransfer(msg.sender, amount);
        } else {
            revert("Insufficient collateral");
        }
        emit CollateralWithdrawn(msg.sender, collateralAmount);
    }

    function borrowTokens(uint256 amount, uint256 duration) external hasCollateral {
        require(amount > 0 && duration > 0, "Invalid amount or duration");
        require(duration == SECONDS_IN_30_DAYS || duration == SECONDS_IN_90_DAYS, "Invalid duration");
        uint256 priceA = priceFeed.getTokenAPrice();
        uint256 priceB = priceFeed.getTokenBPrice();
        require(priceA != 0 && priceB != 0, "Price feed error");
        uint256 collateralValueInUSD;
        uint256 amountInUSD;
        if (borrowedToken[msg.sender] == address(tokenA)) {
            collateralValueInUSD = priceA * collateralA[msg.sender];
            amountInUSD = priceA * amount;
            require(amountInUSD <= collateralValueInUSD * 80 / 100, "Borrow amount exceeds 80% of collateral");
            uint256 collateralToLock = amount * 2;
            collateralA[msg.sender] -= collateralToLock;
            totalCollateralA -= collateralToLock;
            IERC20(borrowedToken[msg.sender]).safeTransfer(msg.sender, amount);
            tokenA.safeTransfer(address(collateralLockPool), collateralToLock);
            ICollateralLockPool(collateralLockPool).lockCollateral(msg.sender, address(tokenA), collateralToLock);

        } else {
            collateralValueInUSD = priceB * collateralB[msg.sender];
            amountInUSD = priceB * amount;
            require(amountInUSD < collateralValueInUSD * 80 / 100, "Borrow amount exceeds 80% of collateral");
            uint256 collateralToLock = amount * 2;
            collateralB[msg.sender] -= collateralToLock;
            totalCollateralB -= collateralToLock;
            IERC20(borrowedToken[msg.sender]).safeTransfer(msg.sender, amount);
            tokenB.safeTransfer(address(collateralLockPool), collateralToLock);
            ICollateralLockPool(collateralLockPool).lockCollateral(msg.sender, address(tokenB), collateralToLock);
    }
    borrowed[msg.sender] += amount;
    loanStartTime[msg.sender] = block.timestamp;
    loanDuration[msg.sender] = duration;
    emit TokensBorrowed(msg.sender, amount, borrowedToken[msg.sender], duration);
    }

    function repayLoan(uint256 amount) external {
    require(amount != 0, "Amount must be greater than 0");
    require(borrowed[msg.sender] >= amount, "Repayment exceeds borrowed amount");
    
    bool isTokenA = borrowedToken[msg.sender] == address(tokenA);
    require(borrowedToken[msg.sender] != address(0), "No token borrowed");
    
    uint256 principalRepayment = amount;
    uint256 interest = calculateInterest(principalRepayment, loanStartTime[msg.sender], loanDuration[msg.sender]);
    uint256 totalRepayment = principalRepayment + interest;
    
    IERC20(borrowedToken[msg.sender]).safeTransferFrom(msg.sender, address(this), totalRepayment);
    borrowed[msg.sender] -= principalRepayment;
    distributeFees(interest, isTokenA);
    
    if (borrowed[msg.sender] == 0) {
        releaseCollateral();
    }

    emit LoanRepaid(msg.sender, principalRepayment);
    }



    function releaseCollateral() internal {
        uint256 collateralAmount;
        if (borrowedToken[msg.sender] == address(tokenA)) {
            collateralAmount = collateralLockPool.lockedCollateralB(msg.sender);
            collateralLockPool.unlockCollateral(msg.sender, address(tokenB), collateralAmount);
            collateralB[msg.sender] += collateralAmount;
            totalCollateralB += collateralAmount;
        } else {
            collateralAmount = collateralLockPool.lockedCollateralA(msg.sender);
            collateralLockPool.unlockCollateral(msg.sender, address(tokenA), collateralAmount);
            collateralA[msg.sender] += collateralAmount;
            totalCollateralA += collateralAmount;
        }
    }

    function calculateInterest(uint256 amount, uint256 startTime, uint256 duration) internal view returns (uint256) {
        uint256 elapsedTime = block.timestamp - startTime;
        uint256 interestRate;
        if (duration == SECONDS_IN_30_DAYS) {
            interestRate = INTEREST_RATE_30_DAYS;
        } else if (duration == SECONDS_IN_90_DAYS) {
            interestRate = INTEREST_RATE_90_DAYS;
        } else {
            revert("Invalid duration");
        }
            uint256 interest = (amount * interestRate * elapsedTime) / (duration * 100);
        return interest;
    }

    function distributeFees(uint256 amount, bool isTokenA) internal {
        uint256 userFeeShare;
        if (totalLiquidity > 0) {
            userFeeShare = amount * userLiquidityBalance[msg.sender] / totalLiquidity;
            if (isTokenA) {
                userSwapFees[msg.sender] += userFeeShare;
                totalSwapFeesA -= userFeeShare;
            } else {
                userSwapFees[msg.sender] += userFeeShare;
                totalSwapFeesB -= userFeeShare;
            }
        }
    }

    function claimFees() external {
        uint256 userLiquidity = userLiquidityBalance[msg.sender];
        require(userLiquidity != 0, "No liquidity provided");
        uint256 totalFees = totalSwapFeesA + totalSwapFeesB;
        require(totalFees != 0, "No fees available");
        uint256 userFeeA = userAccumulatedSwapFees[msg.sender];
        uint256 userFeeB = userAccumulatedSwapFees[msg.sender];
        require(userFeeA != 0 || userFeeB != 0, "No fees to claim");
        if (userFeeA != 0) {
            tokenA.safeTransfer(msg.sender, userFeeA);
            totalSwapFeesA -= userFeeA;
            userAccumulatedSwapFees[msg.sender] = 0;
        }    
        if (userFeeB != 0) {
            tokenB.safeTransfer(msg.sender, userFeeB);
            totalSwapFeesB -= userFeeB;
            userAccumulatedSwapFees[msg.sender] = 0;
    }

    emit SwapFeeClaimed(msg.sender, userFeeA + userFeeB);
    }
    function updateSwapFee(uint256 newFee) external onlyOwner {
        require(newFee <= 1000, "Fee too high");
        swapFeePercent = newFee;
    }

    function updateOwnerShare(uint256 newShare) external onlyOwner {
        require(newShare <= 100, "Share too high");
        ownerSharePercent = newShare;
    }

    function provideLiquidity(uint256 tokenAAmount, uint256 tokenBAmount) external {
        require(tokenAAmount != 0 && tokenBAmount != 0, "Token amounts must be greater than 0");

        uint256 netReserveA = IERC20(tokenA).balanceOf(_thisAddress) - totalSwapFeesA - totalCollateralA;
        uint256 netReserveB = IERC20(tokenB).balanceOf(_thisAddress) - totalSwapFeesB - totalCollateralB;
        uint256 liquidityMinted;
        uint256 liquidityTotalSupply = liquidityToken.totalSupply();

        tokenA.safeTransferFrom(msg.sender, _thisAddress, tokenAAmount);
        tokenB.safeTransferFrom(msg.sender, _thisAddress, tokenBAmount);

        if (liquidityTotalSupply == 0) {
            liquidityMinted = calculateInitialLiquidity(tokenAAmount, tokenBAmount);
        } else {
            liquidityMinted = calculateSubsequentLiquidity(tokenAAmount, tokenBAmount, netReserveA, netReserveB, liquidityTotalSupply);
        }

        liquidityToken.mint(_thisAddress, liquidityMinted);
        liquidityToken.safeTransfer(msg.sender, liquidityMinted);
        userLiquidityBalance[msg.sender] += liquidityMinted;
        totalLiquidity += liquidityMinted;

        emit LiquidityProvided(msg.sender, tokenAAmount, tokenBAmount, liquidityMinted);
    }


    function calculateInitialLiquidity(uint256 tokenAAmount, uint256 tokenBAmount) internal pure returns (uint256) {
        return Math.sqrt(tokenAAmount * tokenBAmount);
    }

    function calculateSubsequentLiquidity(
        uint256 tokenAAmount,
        uint256 tokenBAmount,
        uint256 netReserveA,
        uint256 netReserveB,
        uint256 liquidityTotalSupply
        ) internal pure returns (uint256) {
        uint256 liquidityA = (tokenAAmount * liquidityTotalSupply) / netReserveA;
        uint256 liquidityB = (tokenBAmount * liquidityTotalSupply) / netReserveB;
        return Math.min(liquidityA, liquidityB);
    }

    function withdrawLiquidity(uint256 liquidityTokenAmount) external {
        require(liquidityTokenAmount != 0, "Liquidity token amount must be greater than 0");

        uint256 liquidityTotalSupply = liquidityToken.totalSupply();
        require(liquidityTotalSupply != 0, "No liquidity tokens in circulation");

        uint256 reserveA = tokenA.balanceOf(_thisAddress);
        uint256 reserveB = tokenB.balanceOf(_thisAddress);
        uint256 netReserveA = reserveA - totalSwapFeesA - totalCollateralA;
        uint256 netReserveB = reserveB - totalSwapFeesB - totalCollateralB;
        uint256 tokenAAmount = liquidityTokenAmount * netReserveA / liquidityTotalSupply;
        uint256 tokenBAmount = liquidityTokenAmount * netReserveB / liquidityTotalSupply;
        liquidityToken.burn(msg.sender, liquidityTokenAmount);
        tokenA.safeTransfer(msg.sender, tokenAAmount);
        tokenB.safeTransfer(msg.sender, tokenBAmount);
        userLiquidityBalance[msg.sender] -= liquidityTokenAmount;
        totalLiquidity -= liquidityTokenAmount;
        emit WithdrawLiquidity(msg.sender, tokenAAmount, tokenBAmount);
    }

    function getCollateralAmounts() external view returns (uint256, uint256) {
        return (collateralA[msg.sender], collateralB[msg.sender]);
    }

    function getBorrowedAmount() external view returns (uint256) {
        return borrowed[msg.sender];
    }
}
