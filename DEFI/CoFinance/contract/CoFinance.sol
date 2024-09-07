// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

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
    uint256 public LIQUIDATION_THRESHOLD_PERCENT = 80; // 80% maximum loan-to-value ratio
    uint256 public INTEREST_RATE_90_DAYS = 6;
    uint256 public INTEREST_RATE_30_DAYS = 2;
    uint256 public MAX_FEE_PERCENT;
    uint256 public constant SECONDS_IN_30_DAYS = 30 days;
    uint256 public constant SECONDS_IN_90_DAYS = 90 days;
    uint256 public OWNER_SHARE_PERCENT = 7;
    bool public isPoolIncentivized;
    mapping(address => uint256) public balances;
    mapping(address => uint256) public borrowed;
    mapping(address => uint256) public collateralA; 
    mapping(address => CollateralPool) public userPools;
    mapping(address => uint256) public collateralB; 
    mapping(address => uint256) public loanStartTime;
    mapping(address => uint256) public loanDuration;
    mapping(address => address) public borrowedToken;
    mapping(address => bool) public incentivizedPools;
    mapping(address => uint256) public userLiquidityBalance;
    mapping(address => uint256) public userSwapFees;
    mapping(address => uint256) public userInterestFees;
    uint256 public FeePoolA = 0;
    uint256 public FeePoolB = 0;
    uint256 public totalCollateralA = 0;
    uint256 public totalCollateralB = 0;
    address public factory;
    address[] public liquidityProviders;

    event TokensSwapped(address indexed swapper, uint256 tokenAAmount, uint256 tokenBAmount, uint256 feeAmount);
    event LiquidityProvided(address indexed provider, uint256 tokenAAmount, uint256 tokenBAmount, uint256 liquidityTokensMinted);
    event TokensBorrowed(address indexed borrower, uint256 tokenAAmount, uint256 tokenBAmount, uint256 duration);
    event CollateralLocked(address indexed borrower, address poolAddress, uint256 amount);
    event CollateralDeposited(address indexed depositor, address indexed tokenAddress, uint256 amount);
    event CollateralWithdrawn(address indexed withdrawer, uint256 amount);
    event LoanRepaid(address indexed borrower, uint256 amount);
    event CollateralLiquidated(address indexed borrower, uint256 collateralAmount);
    event RewardsClaimed(address indexed staker, uint256 rewardAmount);
    event WithdrawLiquidity(address indexed exiter, uint256 tokenAAmount, uint256 tokenBAmount);
    event SwapFeeClaimed(address indexed claimer, uint256 amount);
    event InterestFeeClaimed(address indexed claimer, uint256 amount);
    event IncentiveDeposited(address indexed depositor, uint256 amount);
    event LiquidityTokensMinted(address recipient, uint256 amount);
    event LiquidityTokensSent(address recipient, uint256 amount);

    struct CollateralPool {
        address poolAddress;
        bool isActive;
    }

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
        uint256 factoryFee = totalFee.mul(10).div(100); // 10% of the swap fee
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
            distributeSwapFees(poolReward, false);
            tokenA.safeTransfer(msg.sender, tokenAAmount);
            emit TokensSwapped(msg.sender, tokenAmount, tokenAAmount, factoryFee);
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
        require(duration == SECONDS_IN_30_DAYS || duration == SECONDS_IN_90_DAYS, "Invalid duration");
        require(userPools[msg.sender].isActive == false, "Active loan already exists");

        // Fetch the current price of tokens
        uint256 priceTokenA = priceFeed.getTokenAPrice();
        uint256 priceTokenB = priceFeed.getTokenBPrice();
        uint256 collateralValue;

        if (tokenAddress == address(tokenA)) {
            require(collateralB[msg.sender] > 0, "No collateral to lock");
            collateralValue = collateralB[msg.sender].mul(priceTokenB).div(priceTokenA);
            require(collateralValue >= amount, "Insufficient collateral value");
            CollateralLockPool newPool = new CollateralLockPool(address(tokenA), address(tokenB));
            userPools[msg.sender] = CollateralPool(address(newPool), true);
            newPool.lockCollateral(msg.sender, tokenAddress, amount);
            tokenA.safeTransfer(msg.sender, amount);
            collateralB[msg.sender] = collateralB[msg.sender].sub(amount.mul(priceTokenA).div(priceTokenB));
        } else if (tokenAddress == address(tokenB)) {
            require(collateralA[msg.sender] > 0, "No collateral to lock");
            collateralValue = collateralA[msg.sender].mul(priceTokenA).div(priceTokenB);
            require(collateralValue >= amount, "Insufficient collateral value");
            CollateralLockPool newPool = new CollateralLockPool(address(tokenA), address(tokenB));
            userPools[msg.sender] = CollateralPool(address(newPool), true);
            newPool.lockCollateral(msg.sender, tokenAddress, amount);
            tokenB.safeTransfer(msg.sender, amount);
            collateralA[msg.sender] = collateralA[msg.sender].sub(amount.mul(priceTokenB).div(priceTokenA));
        } else {
            revert("Invalid token address provided");
        }

        borrowed[msg.sender] = borrowed[msg.sender].add(amount);
        loanStartTime[msg.sender] = block.timestamp;
        loanDuration[msg.sender] = duration;
        borrowedToken[msg.sender] = tokenAddress;
        emit TokensBorrowed(msg.sender, amount, 0, duration);
    }

    function repayLoan(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        require(borrowed[msg.sender] >= amount, "Repay amount exceeds borrowed amount");
        uint256 fee = calculateInterestFee();
        uint256 totalAmount = amount.add(fee);
        if (borrowedToken[msg.sender] == address(tokenA)) {
            tokenA.safeTransferFrom(msg.sender, address(this), totalAmount);
        } else if (borrowedToken[msg.sender] == address(tokenB)) {
            tokenB.safeTransferFrom(msg.sender, address(this), totalAmount);
        } else {
            revert("Invalid token address");
        }
        borrowed[msg.sender] = borrowed[msg.sender].sub(amount);
        uint256 factoryFee = fee.mul(10).div(100); // 10% of interest fee
        uint256 ownerFee = fee.mul(OWNER_SHARE_PERCENT).div(100); // 7% of remaining interest fee
        uint256 liquidityProviderFee = fee.sub(factoryFee).sub(ownerFee); // Remaining fee for liquidity providers
        tokenA.safeTransfer(factory, factoryFee);
        tokenA.safeTransfer(owner, ownerFee);

        uint256 totalLiquidity = liquidityToken.totalSupply();
        if (totalLiquidity > 0) {
            uint256 feePerShare = liquidityProviderFee.div(totalLiquidity);
            for (uint i = 0; i < liquidityProviders.length; i++) {
                address provider = liquidityProviders[i];
                uint256 providerShare = liquidityToken.balanceOf(provider).mul(feePerShare);
                tokenA.safeTransfer(provider, providerShare);
            }
        }

        emit LoanRepaid(msg.sender, amount);
    }

    function liquidateCollateral(address borrower) external {
        require(borrowed[borrower] > 0, "No outstanding loan");
        uint256 loanStart = loanStartTime[borrower];
        uint256 duration = loanDuration[borrower];
        require(loanStart > 0, "Loan start time not set");
        require(block.timestamp > loanStart + duration, "Loan duration has not yet passed");
        ICollateralLockPool pool = ICollateralLockPool(userPools[borrower].poolAddress);
        uint256 collateralAmountA = pool.getLockedCollateralA(borrower);
        uint256 collateralAmountB = pool.getLockedCollateralB(borrower);
        require(collateralAmountA > 0 || collateralAmountB > 0, "No collateral to liquidate");
        if (collateralAmountA > 0) {
            tokenA.safeTransfer(owner, collateralAmountA);
        }
        if (collateralAmountB > 0) {
            tokenB.safeTransfer(owner, collateralAmountB);
        }
        userPools[borrower].isActive = false;
        borrowed[borrower] = 0;
        emit CollateralLiquidated(borrower, collateralAmountA.add(collateralAmountB));
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

        // Fetch current prices of Token A and Token B
        uint256 priceTokenA = priceFeed.getTokenAPrice();
        uint256 priceTokenB = priceFeed.getTokenBPrice();

        // Calculate the value of provided Token A and Token B
        uint256 valueTokenA = tokenAAmount.mul(priceTokenA);
        uint256 valueTokenB = tokenBAmount.mul(priceTokenB);

        // Ensure that provided liquidity values are balanced
        require(valueTokenA == valueTokenB, "Token amounts must be balanced according to current prices");

        (uint256 reserveA, uint256 reserveB) = getTotalLiquidity();
        uint256 netReserveA = reserveA.sub(FeePoolA).sub(totalCollateralA);
        uint256 netReserveB = reserveB.sub(FeePoolB).sub(totalCollateralB);

        uint256 liquidityMinted;
        uint256 liquidityTotalSupply = liquidityToken.totalSupply();

        // Transfer tokens from the user to the contract
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

    function calculateInterestFee() internal view returns (uint256) {
        uint256 interestRate = loanDuration[msg.sender] == SECONDS_IN_30_DAYS ? INTEREST_RATE_30_DAYS : INTEREST_RATE_90_DAYS;
        uint256 interestFee = borrowed[msg.sender].mul(interestRate).div(100);
        return interestFee;
    }

    function distributeSwapFees(uint256 poolReward, bool isTokenA) internal {
        uint256 totalLiquidity = liquidityToken.totalSupply();
        if (totalLiquidity > 0) {
            uint256 feePerShare = poolReward.div(totalLiquidity);

            for (uint i = 0; i < liquidityProviders.length; i++) {
                address provider = liquidityProviders[i];
                uint256 providerShare = liquidityToken.balanceOf(provider).mul(feePerShare);
                
                if (isTokenA) {
                    FeePoolA = FeePoolA.add(providerShare);
                } else {
                    FeePoolB = FeePoolB.add(providerShare);
                }
                
                userSwapFees[provider] = userSwapFees[provider].add(providerShare);
            }
        }
    }

    function claimSwapFees() external {
        uint256 amount = userSwapFees[msg.sender];
        require(amount > 0, "No swap fees to claim");

        if (FeePoolA > 0) {
            uint256 feeA = amount; // Use the specific logic for feeA here
            tokenA.safeTransfer(msg.sender, feeA);
            FeePoolA = FeePoolA.sub(feeA);
        }

        if (FeePoolB > 0) {
            uint256 feeB = amount; // Use the specific logic for feeB here
            tokenB.safeTransfer(msg.sender, feeB);
            FeePoolB = FeePoolB.sub(feeB);
        }

        userSwapFees[msg.sender] = 0;
        emit SwapFeeClaimed(msg.sender, amount);
    }

    function claimInterestFees() external {
        uint256 amount = userInterestFees[msg.sender];
        require(amount > 0, "No interest fees to claim");
        tokenA.safeTransfer(msg.sender, amount);
        userInterestFees[msg.sender] = 0;
        emit InterestFeeClaimed(msg.sender, amount);
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
