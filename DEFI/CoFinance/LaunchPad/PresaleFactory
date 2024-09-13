// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Presale.sol";  

contract PresaleFactory {
    address public owner;
    address[] public allPresales;

    event PresaleCreated(address indexed presaleAddress, address tokenAddress, address owner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }
    function createPresale(
        address _tokenAddress,
        address _usdtToken,
        address _wethToken,
        uint256 _pricePerToken,
        uint256 _minContribution,
        uint256 _maxContribution,
        uint256 _softCap,
        uint256 _hardCap,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner returns (address) {
        Presale newPresale = new Presale(
            _tokenAddress,
            _usdtToken,
            _wethToken,
            msg.sender,
            _pricePerToken,
            _minContribution,
            _maxContribution,
            _softCap,
            _hardCap,
            _startTime,
            _endTime
        );

        allPresales.push(address(newPresale));

        emit PresaleCreated(address(newPresale), _tokenAddress, msg.sender);

        return address(newPresale);
    }
    function getAllPresales() external view returns (address[] memory) {
        return allPresales;
    }
}
