// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Presale {
    address public owner;
    address public tokenAddress;
    uint256 public pricePerToken;
    uint256 public minContribution;
    uint256 public maxContribution;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public totalRaised;
    uint256 public startTime;
    uint256 public endTime;
    address public usdtToken; 
    address public wethToken; 

    mapping(address => uint256) public contributions;

    event ContributionReceived(address indexed contributor, uint256 amount, string paymentMethod);
    event TokensClaimed(address indexed contributor, uint256 tokenAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier activePresale() {
        require(block.timestamp >= startTime && block.timestamp <= endTime, "Presale not active");
        _;
    }

    constructor(
        address _tokenAddress,
        address _usdtToken,
        address _wethToken,
        address _owner,
        uint256 _pricePerToken,
        uint256 _minContribution,
        uint256 _maxContribution,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _startTime,
        uint256 _endTime
    ) {
        tokenAddress = _tokenAddress;
        usdtToken = _usdtToken;
        wethToken = _wethToken;
        owner = _owner;
        pricePerToken = _pricePerToken;
        minContribution = _minContribution;
        maxContribution = _maxContribution;
        softCap = _softCap;
        hardCap = _hardCap;
        startTime = _startTime;
        endTime = _endTime;
    }

    function contributeUSDT(uint256 _amount) external activePresale {
        require(_amount >= minContribution, "Contribution too low");
        require(contributions[msg.sender] + _amount <= maxContribution, "Contribution exceeds max limit");
        require(totalRaised + _amount <= hardCap, "Hard cap reached");
        IERC20(usdtToken).transferFrom(msg.sender, address(this), _amount);
        contributions[msg.sender] += _amount;
        totalRaised += _amount;
        emit ContributionReceived(msg.sender, _amount, "USDT");
    }

    function contributeWETH(uint256 _amount) external activePresale {
        require(_amount >= minContribution, "Contribution too low");
        require(contributions[msg.sender] + _amount <= maxContribution, "Contribution exceeds max limit");
        require(totalRaised + _amount <= hardCap, "Hard cap reached");

        IERC20(wethToken).transferFrom(msg.sender, address(this), _amount);

        contributions[msg.sender] += _amount;
        totalRaised += _amount;

        emit ContributionReceived(msg.sender, _amount, "WETH");
    }

    function contributeETH() external payable activePresale {
        require(msg.value >= minContribution, "Contribution too low");
        require(contributions[msg.sender] + msg.value <= maxContribution, "Contribution exceeds max limit");
        require(totalRaised + msg.value <= hardCap, "Hard cap reached");

        contributions[msg.sender] += msg.value;
        totalRaised += msg.value;

        emit ContributionReceived(msg.sender, msg.value, "ETH");
    }

    function contributeCard(uint256 _amount) external onlyOwner activePresale {
        require(_amount >= minContribution, "Contribution too low");
        require(totalRaised + _amount <= hardCap, "Hard cap reached");

        contributions[msg.sender] += _amount;
        totalRaised += _amount;

        emit ContributionReceived(msg.sender, _amount, "Card");
    }

    function withdrawFunds() external onlyOwner {
        require(block.timestamp > endTime, "Presale not ended yet");
        require(totalRaised >= softCap, "Soft cap not reached");

        payable(owner).transfer(address(this).balance);
        IERC20(tokenAddress).transferFrom(owner, address(this), totalRaised / pricePerToken);
    }
    function claimTokens() external {
        require(block.timestamp > endTime, "Presale not ended yet");
        require(totalRaised >= softCap, "Soft cap not reached");

        uint256 contribution = contributions[msg.sender];
        require(contribution > 0, "No contribution made");

        uint256 tokenAmount = contribution / pricePerToken;
        contributions[msg.sender] = 0;

        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);

        emit TokensClaimed(msg.sender, tokenAmount);
    }
    function refund() external {
     require(block.timestamp > endTime, "Presale not ended yet");
        require(totalRaised < softCap, "Soft cap reached");

        uint256 contribution = contributions[msg.sender];
        require(contribution > 0, "No contribution made");

        contributions[msg.sender] = 0;
        payable(msg.sender).transfer(contribution);
    }
}
