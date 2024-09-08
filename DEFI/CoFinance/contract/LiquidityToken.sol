// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LiquidityToken is ERC20 {
    using SafeERC20 for IERC20;

    address public owner;
    address public cofinanceContract;
    bool public poolIncentivized;

    modifier onlyCoFinance() {
        require(msg.sender == cofinanceContract, "LiquidityToken: Only CoFinance contract can call this function");
        _;
    }

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        owner = msg.sender;
    }

    function mint(address account, uint256 amount) external onlyCoFinance {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }

    function safeTransfer(address to, uint256 amount) external {
        _safeTransfer(msg.sender, to, amount);
    }

    function setCoFinanceContract(address _cofinanceContract) external {
        require(msg.sender == owner, "LiquidityToken: Only owner can set CoFinance contract");
        cofinanceContract = _cofinanceContract;
    }

    function _safeTransfer(address from, address to, uint256 amount) internal {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance");
        _transfer(from, to, amount);
    }
}
