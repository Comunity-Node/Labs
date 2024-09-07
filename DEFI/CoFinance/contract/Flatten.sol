// Sources flattened with hardhat v2.17.1 https://hardhat.org

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/token/ERC20/IERC20.sol@v4.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol@v4.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}




// File @openzeppelin/contracts/utils/Context.sol@v4.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)



/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/token/ERC20/ERC20.sol@v4.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File @openzeppelin/contracts/utils/Address.sol@v4.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol@v4.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/utils/math/SafeMath.sol@v4.4.0

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

pragma solidity ^0.8.0;

interface IPriceFeed {
    function getTokenAPrice() external view returns (uint256);
    function getTokenBPrice() external view returns (uint256);
}


// File contracts/Staking.sol
pragma solidity ^0.8.0;
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

    function safeTransferFrom(address from, address to, uint256 amount) external {
        _safeTransfer(from, to, amount);
        approve(msg.sender, allowance(from, msg.sender) - amount);
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
// Original license: SPDX_License_Identifier: MIT
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

contract Staking {
    using SafeMath for uint256;

    uint256 public immutable APR_7_DAYS = 20; // 20% APR for 7 days
    uint256 public immutable APR_14_DAYS = 30; // 30% APR for 14 days
    uint256 public immutable APR_21_DAYS = 50; // 50% APR for 21 days
    uint256 public constant SECONDS_IN_7_DAYS = 7 days;
    uint256 public constant SECONDS_IN_14_DAYS = 14 days;
    uint256 public constant SECONDS_IN_21_DAYS = 21 days;

    IERC20 public liquidityToken;
    ICoFinance public coFinance;
    bool public isPoolIncentivized;

    mapping(address => uint256) public stakerBalances;
    mapping(address => uint256) public stakingStartTimes;
    mapping(address => uint256) public rewardBalances;

    constructor(address _liquidityToken, address _coFinance) {
        liquidityToken = IERC20(_liquidityToken);
        coFinance = ICoFinance(_coFinance);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than 0");
        liquidityToken.transferFrom(msg.sender, address(this), amount);
        updateRewards(msg.sender);
        stakerBalances[msg.sender] = stakerBalances[msg.sender].add(amount);
        stakingStartTimes[msg.sender] = block.timestamp;
        updateIncentives();
    }

    function withdraw(uint256 amount) external {
        require(stakerBalances[msg.sender] >= amount, "Insufficient balance");
        updateRewards(msg.sender);
        stakerBalances[msg.sender] = stakerBalances[msg.sender].sub(amount);
        liquidityToken.transfer(msg.sender, amount);
        updateIncentives();
    }

    function claimReward() external {
        updateRewards(msg.sender);
        uint256 reward = rewardBalances[msg.sender];
        require(reward > 0, "No rewards to claim");
        rewardBalances[msg.sender] = 0;
        IERC20 rewardToken = IERC20(coFinance.rewardToken());
        rewardToken.transfer(msg.sender, reward);
    }

    function updateRewards(address staker) internal {
        uint256 stakerBalance = stakerBalances[staker];
        uint256 stakingDuration = block.timestamp - stakingStartTimes[staker];
        
        uint256 apr = getAPRForDuration(stakingDuration);
        uint256 newReward = stakerBalance.mul(apr).div(100).mul(stakingDuration).div(365 days);

        rewardBalances[staker] = rewardBalances[staker].add(newReward);
        stakingStartTimes[staker] = block.timestamp;
    }

    function getAPRForDuration(uint256 duration) internal view returns (uint256) {
        if (duration <= SECONDS_IN_7_DAYS) {
            return APR_7_DAYS;
        } else if (duration <= SECONDS_IN_14_DAYS) {
            return APR_14_DAYS;
        } else if (duration <= SECONDS_IN_21_DAYS) {
            return APR_21_DAYS;
        } else {
            return 0;
        }
    }

    function updateIncentives() internal {
        isPoolIncentivized = liquidityToken.balanceOf(address(this)) > 0;
    }
}

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0; 

contract CoFinanceFactory {
    uint256 public creationFee  = 10;
    uint public Reward = 10;
    address public owner;
    uint256 public maxFeePercent; // Maximum fee percentage allowed for pools
    address[] public allPools; 
    mapping(address => mapping(address => address)) public pools; 
    mapping(address => address[]) public poolsByToken;
    mapping(address => address) public poolByPair; 
    mapping(address => bool) public incentivizedPools;

    event PoolCreated(
        address indexed poolAddress,
        address indexed tokenA,
        address indexed tokenB,
        address liquidityTokenAddress,
        address rewardToken,
        address priceFeed,
        address stakingContract,
        bool isPoolIncentivized,
        address factory
    );
    event CreationFeeUpdated(uint256 newFee);
    event FeesWithdrawn(address indexed owner, address token, uint256 amount);
    event PoolIncentivized(address indexed poolAddress); // Declared event

    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    function createPool(
        address tokenA,
        address tokenB,
        address rewardToken,
        address priceFeed,
        string memory liquidityTokenName,
        string memory liquidityTokenSymbol,
        bool isPoolIncentivized

    ) external payable returns (address) {
        require(msg.value == creationFee, "Incorrect ETH amount sent");
        require(tokenA != tokenB, "Token addresses must be different");
        if (tokenA > tokenB) {           
            (tokenA, tokenB) = (tokenB, tokenA);
        }
        address existingPool = pools[tokenA][tokenB];
        if (existingPool != address(0)) {
            return existingPool; 
        }
        LiquidityToken liquidityToken = new LiquidityToken(liquidityTokenName, liquidityTokenSymbol);
        Staking stakingContract = new Staking(address(liquidityToken), rewardToken); 
        CoFinance pool = new CoFinance(
            tokenA,
            tokenB,
            rewardToken,
            priceFeed,
            address(liquidityToken),
            address(stakingContract),
            isPoolIncentivized,
            address(this)
        );
        liquidityToken.setCoFinanceContract(address(pool));
        pools[tokenA][tokenB] = address(pool);
        poolsByToken[tokenA].push(address(pool));
        poolsByToken[tokenB].push(address(pool));
        allPools.push(address(pool));
        if (isPoolIncentivized) {
            incentivizedPools[address(pool)] = true;
        }
        emit PoolCreated(
            address(pool),
            tokenA,
            tokenB,
            address(liquidityToken),
            rewardToken,
            priceFeed,
            address(stakingContract),
            isPoolIncentivized,
            address(this)
        );
        return address(pool);
    }
    function getAllPools() external view returns (address[] memory) {
        return allPools;
    }
    function updateCreationFee(uint256 newFee) external onlyOwner {
        creationFee = newFee;
        emit CreationFeeUpdated(newFee);
    }
    function getPoolByToken(address token) external view returns (address[] memory) {
        return poolsByToken[token];
    }
    function getPoolByPair(address tokenA, address tokenB) external view returns (address) {
        if (tokenA > tokenB) {
            (tokenA, tokenB) = (tokenB, tokenA);
        }
        return pools[tokenA][tokenB];
    }
    function withdrawFees(address tokenAddress) external onlyOwner {
        if (tokenAddress == address(0)) {
            uint256 balance = address(this).balance;
            require(balance > 0, "No ETH to withdraw");
            payable(owner).transfer(balance);
            emit FeesWithdrawn(owner, address(0), balance);
        } else {
            IERC20 token = IERC20(tokenAddress);
            uint256 balance = token.balanceOf(address(this));
            require(balance > 0, "No ERC20 tokens to withdraw");
            token.transfer(owner, balance);
            emit FeesWithdrawn(owner, tokenAddress, balance);
        }
    }

    function getIncentivizedPools() external view returns (address[] memory) {
        address[] memory incentivizedPoolList = new address[](allPools.length);
        uint256 count = 0;

        for (uint256 i = 0; i < allPools.length; i++) {
            if (incentivizedPools[allPools[i]]) {
                incentivizedPoolList[count] = allPools[i];
                count++;
            }
        }
        address[] memory result = new address[](count);
        for (uint256 j = 0; j < count; j++) {
            result[j] = incentivizedPoolList[j];
        }
        return result;
    }

    function updateIncentivizedPool(address poolAddress, address tokenA, address tokenB) external {
        if (tokenA > tokenB) {
            (tokenA, tokenB) = (tokenB, tokenA);
        }
        require(pools[tokenA][tokenB] == poolAddress, "Pool not found");
        incentivizedPools[poolAddress] = true;
        emit PoolIncentivized(poolAddress);
    }
}
