pragma solidity ^0.8.0;

interface IPriceFeed {
    function getTokenAPrice() external view returns (uint256);
    function getTokenBPrice() external view returns (uint256);
}
