pragma solidity ^0.8.0;

interface ICoFinance {
    function calculateInterest(uint256 amount) external view returns (uint256);
    function SWAP_FEE_PERCENT() external view returns (uint256);
    function APR_7_DAYS() external view returns (uint256);
    function APR_14_DAYS() external view returns (uint256);
    function APR_21_DAYS() external view returns (uint256);
    function SECONDS_IN_7_DAYS() external view returns (uint256);
    function SECONDS_IN_14_DAYS() external view returns (uint256);
    function SECONDS_IN_21_DAYS() external view returns (uint256);
    function rewardToken() external view returns (address);
}
