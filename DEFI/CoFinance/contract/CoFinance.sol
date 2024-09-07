// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/math.sol";
import "./Staking.sol";
import "./ipricefeed.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CoFinance {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    IERC20 public tokenA;
    IERC20 public tokenB;
    LiquidityToken public liquidityToken;
    Staking public stakingContract;
    address public owner;
    IERC20 public rewardToken;
    IPriceFeed public priceFeed;
    uint256 public SWAP_FEE_PERCENT = 5; // 0.5% swap fee
    uint256 public MAX_LTV_PERCENT = 80; // 80% maximum loan-to-value ratio
    uint256 public INTEREST_RATE = 5; 
    uint256 public MAX_FEE_PERCENT;
    uint256 public constant SECONDS_IN_30_DAYS = 30 days;
    uint256 public constant SECONDS_IN_90_DAYS = 90 days;
    uint256 public OWNER_SHARE_PERCENT = 10; // 10% of fees go to owner
    bool public isPoolIncentivized; // Flag to indicate if the pool is incentivized
    mapping(address => uint256) public balances;
    mapping(address => uint256) public borrowed;
    mapping(address => uint256) public collateralA; 

    mapping(address => uint256) public collateralB; 
    mapping(address => uint256) public loanStartTime;
    mapping(address => uint256) public loanDuration;
    mapping(address => address) public borrowedToken;
    mapping(address => bool) public incentivizedPools;
    mapping(address => uint256) public userLiquidityBalance;
    mapping(address => uint256) public totalFeesEarned;

    uint256 public FeePoolA = 0;
    uint256 public FeePoolB = 0;
    uint256 public totalCollateralA = 0;
    uint256 public totalCollateralB = 0;
    address public factory;
    address[] public liquidityProviders;


    event TokensSwapped(address indexed swapper, uint256 tokenAAmount, uint256 tokenBAmount, uint256 feeAmount);
    event LiquidityProvided(address indexed provider, uint256 tokenAAmount, uint256 tokenBAmount, uint256 liquidityTokensMinted);
    event TokensBorrowed(address indexed borrower, uint256 tokenAAmount, uint256 tokenBAmount, uint256 duration);
    event CollateralDeposited(address indexed depositor, address indexed tokenAddress, uint256 amount);
    event CollateralWithdrawn(address indexed withdrawer, uint256 amount);
    event LoanRepaid(address indexed borrower, uint256 amount);
    event CollateralLiquidated(address indexed borrower, uint256 collateralAmount);
    event RewardsClaimed(address indexed staker, uint256 rewardAmount);
    event WithdrawLiquidity(address indexed exiter, uint256 tokenAAmount, uint256 tokenBAmount);
    event SwapFeeWithdrawn(address indexed owner, uint256 amount);
    event InterestFeeWithdrawn(address indexed owner, uint256 amount);
    event IncentiveDeposited(address indexed depositor, uint256 amount);
    event LiquidityTokensMinted(address recipient, uint256 amount);
    event LiquidityTokensSent(address recipient, uint256 amount);

    constructor(
        address _tokenA,
        address _tokenB,
        address _rewardToken,
        address _priceFeed,
        address _liquidityToken,
        address _stakingContract,
        bool _isPoolIncentivized,
        address _factory
    ) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        rewardToken = IERC20(_rewardToken);
        owner = msg.sender;
        priceFeed = IPriceFeed(_priceFeed);
        liquidityToken = LiquidityToken(_liquidityToken);
        stakingContract = Staking(_stakingContract);
        isPoolIncentivized = _isPoolIncentivized;
        factory = _factory;
    }
    
    function depositIncentive(uint256 amount, address tokenA, address tokenB) external {
        require(amount > 0, "Amount must be greater than 0");
        rewardToken.safeTransferFrom(msg.sender, address(stakingContract), amount);
        if (!CoFinanceFactory(factory).incentivizedPools(address(this))) {
            CoFinanceFactory(factory).updateIncentivizedPool(address(this), tokenA, tokenB);
        }
        
    }

    function swapTokens(address tokenAddress, uint256 tokenAmount) external {
        require(tokenAmount > 0, "Token amount must be greater than 0");
        uint256 totalFee = tokenAmount.mul(SWAP_FEE_PERCENT).div(1000); // SWAP_FEE_PERCENT is 0.5% or 5/1000
        uint256 factoryFee = totalFee.mul(3).div(10); 
        uint256 poolReward = totalFee.sub(factoryFee);
        uint256 amountAfterFee = tokenAmount.sub(totalFee);
        uint256 priceTokenA = priceFeed.getTokenAPrice(); 
        uint256 priceTokenB = priceFeed.getTokenBPrice();
        if (tokenAddress == address(tokenA)) {
            uint256 tokenBAmount = amountAfterFee.mul(priceTokenA).div(priceTokenB);
            tokenA.safeTransferFrom(msg.sender, address(this), tokenAmount);
            tokenA.safeTransfer(factory, factoryFee); 
            distributeSwapFees(poolReward, true); 
            tokenB.safeTransfer(msg.sender, tokenBAmount);
            emit TokensSwapped(msg.sender, tokenAmount, tokenBAmount, factoryFee);
        } else if (tokenAddress == address(tokenB)) {
            uint256 tokenAAmount = amountAfterFee.mul(priceTokenB).div(priceTokenA);
            tokenB.safeTransferFrom(msg.sender, address(this), tokenAmount);
            tokenB.safeTransfer(factory, factoryFee);
            distributeSwapFees(poolReward, true);
            tokenA.safeTransfer(msg.sender, tokenAAmount);
            emit TokensSwapped(msg.sender, tokenAAmount, tokenAmount, factoryFee);
        } else {
            revert("Invalid token address provided");
        }
    }

    function depositCollateral(address tokenAddress, uint256 amount) external {
        require(tokenAddress == address(tokenA) || tokenAddress == address(tokenB), "Invalid token address");
        require(amount > 0, "Amount must be greater than 0");

        IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
        
        if (tokenAddress == address(tokenA)) {
            collateralA[msg.sender] = collateralA[msg.sender].add(amount);
            totalCollateralA = totalCollateralA.add(amount);
        } else {
            collateralB[msg.sender] = collateralB[msg.sender].add(amount);
            totalCollateralB = totalCollateralB.add(amount);
        }

        emit CollateralDeposited(msg.sender, tokenAddress, amount);
    }

    function withdrawCollateral(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(collateralA[msg.sender] >= amount || collateralB[msg.sender] >= amount, "Insufficient collateral");
        if (collateralA[msg.sender] >= amount) {
            collateralA[msg.sender] = collateralA[msg.sender].sub(amount);
            tokenA.safeTransfer(msg.sender, amount);
             totalCollateralA = totalCollateralA.sub(amount);
        } else {
            collateralB[msg.sender] = collateralB[msg.sender].sub(amount);
            tokenB.safeTransfer(msg.sender, amount);
            totalCollateralB = totalCollateralB.sub(amount);
        }
        emit CollateralWithdrawn(msg.sender, amount);
    }
    function borrowTokens(uint256 amount, address tokenAddress, uint256 duration) external {
        require(amount > 0, "Amount must be greater than 0");
        require(collateralA[msg.sender] >= amount || collateralB[msg.sender] >= amount, "Insufficient collateral");
        require(duration == SECONDS_IN_30_DAYS || duration == SECONDS_IN_90_DAYS, "Invalid duration");
        uint256 loanAmount = amount;
        if (tokenAddress == address(tokenA)) {
            require(collateralA[msg.sender] >= loanAmount, "Insufficient collateral");
            tokenA.safeTransfer(msg.sender, loanAmount);
            collateralA[msg.sender] = collateralA[msg.sender].sub(loanAmount);
        } else if (tokenAddress == address(tokenB)) {
            require(collateralB[msg.sender] >= loanAmount, "Insufficient collateral");
            tokenB.safeTransfer(msg.sender, loanAmount);
            collateralB[msg.sender] = collateralB[msg.sender].sub(loanAmount);
        } else {
            revert("Invalid token address provided");
        }
        borrowed[msg.sender] = borrowed[msg.sender].add(loanAmount);
        loanStartTime[msg.sender] = block.timestamp;
        loanDuration[msg.sender] = duration;
        borrowedToken[msg.sender] = tokenAddress;
        emit TokensBorrowed(msg.sender, amount, 0, duration);
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
            uint256 z = (x + 1) / 2;
            uint256 y = x;
            while (z < y) {
                y = z;
                z = (x / z + z) / 2;
            }
        return y;
    }
    function provideLiquidity(uint256 tokenAAmount, uint256 tokenBAmount) external {
        require(tokenAAmount > 0 && tokenBAmount > 0, "Token amounts must be greater than 0");
        (uint256 reserveA, uint256 reserveB) = getTotalLiquidity();
        uint256 netReserveA = reserveA.sub(FeePoolA).sub(totalCollateralA).sub(totalCollateralA);
        uint256 netReserveB = reserveB.sub(FeePoolB).sub(totalCollateralB).sub(totalCollateralB);
        uint256 liquidityMinted;
        uint256 liquidityTotalSupply = liquidityToken.totalSupply();
        tokenA.safeTransferFrom(msg.sender, address(this), tokenAAmount);
        tokenB.safeTransferFrom(msg.sender, address(this), tokenBAmount);
        if (liquidityTotalSupply == 0) {
            liquidityMinted = calculateInitialLiquidity(tokenAAmount, tokenBAmount);
        } else {
            liquidityMinted = calculateSubsequentLiquidity(tokenAAmount, tokenBAmount, netReserveA, netReserveB, liquidityTotalSupply);
        }
        liquidityToken.mint(address(this), liquidityMinted);
        sendLiquidityTokens(msg.sender, liquidityMinted);
        userLiquidityBalance[msg.sender] = userLiquidityBalance[msg.sender].add(liquidityMinted);
        emit LiquidityProvided(msg.sender, tokenAAmount, tokenBAmount, liquidityMinted);
    }

    function calculateInitialLiquidity(uint256 tokenAAmount, uint256 tokenBAmount) internal pure returns (uint256) {
        return sqrt(tokenAAmount.mul(tokenBAmount));
    }

    function calculateSubsequentLiquidity(
        uint256 tokenAAmount,
        uint256 tokenBAmount,
        uint256 netReserveA,
        uint256 netReserveB,
        uint256 liquidityTotalSupply
        ) internal pure returns (uint256) {
        uint256 liquidityA = (tokenAAmount.mul(liquidityTotalSupply)).div(netReserveA);
        uint256 liquidityB = (tokenBAmount.mul(liquidityTotalSupply)).div(netReserveB);
        return liquidityA < liquidityB ? liquidityA : liquidityB;
    }

    function getTotalLiquidity() public view returns (uint256 totalA, uint256 totalB) {
        totalA = tokenA.balanceOf(address(this));
        totalB = tokenB.balanceOf(address(this));
    }

    function sendLiquidityTokens(address recipient, uint256 amount) internal {
        liquidityToken.transfer(recipient, amount);
        emit LiquidityTokensSent(recipient, amount);(recipient, amount);
    }

    function withdrawLiquidity(uint256 liquidityTokenAmount) external {
        require(liquidityTokenAmount > 0, "Liquidity token amount must be greater than 0");
        uint256 liquidityTotalSupply = liquidityToken.totalSupply();
        require(liquidityTotalSupply > 0, "No liquidity tokens in circulation");
        uint256 reserveA = tokenA.balanceOf(address(this));
        uint256 reserveB = tokenB.balanceOf(address(this));
        uint256 netReserveA = reserveA.sub(FeePoolA).sub(totalCollateralA);
        uint256 netReserveB = reserveB.sub(FeePoolB).sub(totalCollateralB);
        uint256 tokenAAmount = liquidityTokenAmount.mul(netReserveA).div(liquidityTotalSupply);
        uint256 tokenBAmount = liquidityTokenAmount.mul(netReserveB).div(liquidityTotalSupply);
        liquidityToken.burn(msg.sender, liquidityTokenAmount);
        tokenA.safeTransfer(msg.sender, tokenAAmount);
        tokenB.safeTransfer(msg.sender, tokenBAmount);
        userLiquidityBalance[msg.sender] = userLiquidityBalance[msg.sender].sub(liquidityTokenAmount);
        emit WithdrawLiquidity(msg.sender, tokenAAmount, tokenBAmount);
    }

    function repayLoan(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(borrowed[msg.sender] >= amount, "Amount exceeds borrowed amount");
        uint256 interest = calculateInterest(amount);
        uint256 totalRepayment = amount.add(interest);
        if (borrowedToken[msg.sender] == address(tokenA)) {
            tokenA.safeTransferFrom(msg.sender, address(this), totalRepayment);
        } else if (borrowedToken[msg.sender] == address(tokenB)) {
            tokenB.safeTransferFrom(msg.sender, address(this), totalRepayment);
        } else {
            revert("Invalid borrowed token address");
        }
        borrowed[msg.sender] = borrowed[msg.sender].sub(amount);
        emit LoanRepaid(msg.sender, amount);
    }
    function calculateInterest(uint256 amount) public view returns (uint256) {
        uint256 duration = loanDuration[msg.sender];
        uint256 interestRate;
        if (duration == SECONDS_IN_30_DAYS) {
            interestRate = INTEREST_RATE;
        } else if (duration == SECONDS_IN_90_DAYS) {
            interestRate = INTEREST_RATE.add(6);
        } else {
            revert("Invalid loan duration");
        }
        return amount.mul(interestRate).div(100);
    }

    function distributeSwapFees(uint256 poolReward, bool isTokenA) internal {
        uint256 totalLiquidity = liquidityToken.totalSupply();
        for (uint i = 0; i < liquidityProviders.length; i++) {
            address provider = liquidityProviders[i];
            uint256 providerShare = userLiquidityBalance[provider].mul(poolReward).div(totalLiquidity);
            
            if (isTokenA) {
                FeePoolA = FeePoolA.add(providerShare);
            } else {
                FeePoolB = FeePoolB.add(providerShare);
            }
            
            totalFeesEarned[provider] = totalFeesEarned[provider].add(providerShare);
        }
    }

    function claimDistributedFees() external {
        uint256 totalFeesToClaim = totalFeesEarned[msg.sender];
        require(totalFeesToClaim > 0, "No fees to claim");
        uint256 feePoolAReward = FeePoolA.mul(userLiquidityBalance[msg.sender]).div(liquidityToken.totalSupply());
        uint256 feePoolBReward = FeePoolB.mul(userLiquidityBalance[msg.sender]).div(liquidityToken.totalSupply());
        require(feePoolAReward <= FeePoolA, "Insufficient funds in FeePoolA");
        require(feePoolBReward <= FeePoolB, "Insufficient funds in FeePoolB");
        if (feePoolAReward > 0) {
            FeePoolA = FeePoolA.sub(feePoolAReward);
            tokenA.safeTransfer(msg.sender, feePoolAReward);
        }
        if (feePoolBReward > 0) {
            FeePoolB = FeePoolB.sub(feePoolBReward);
            tokenB.safeTransfer(msg.sender, feePoolBReward);
        }
        totalFeesEarned[msg.sender] = 0;
        emit RewardsClaimed(msg.sender, feePoolAReward.add(feePoolBReward));
    }

    function setMaxFeePercent(uint256 _percent) external {
        require(msg.sender == owner, "Only owner can set max fee percent");
        MAX_FEE_PERCENT = _percent;
    }

    function getSwapAmount(uint256 amountA) internal view returns (uint256) {
        uint256 tokenAPrice = priceFeed.getTokenAPrice();
        uint256 tokenBPrice = priceFeed.getTokenBPrice();
        return amountA.mul(tokenAPrice).div(tokenBPrice);
    }

    function setFactory(address _factory) external {
        require(msg.sender == factory, "Only owner can set factory address");
        factory = _factory;
    }

    function updateIncentives() public {
        isPoolIncentivized = stakingContract.isPoolIncentivized();
    }

}
