pragma solidity ^0.8.0;

interface ICollateralLockPool {
    function getLockedCollateralA(address borrower) external view returns (uint256);
    function getLockedCollateralB(address borrower) external view returns (uint256);
}
