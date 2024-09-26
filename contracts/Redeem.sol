// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;
import "hardhat/console.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IPulseXSwapRouter {
    function swapExactTokensForTokensV2(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to
    ) external payable returns (uint256 amountOut);
}

interface IERC20 {
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function burn(uint256 _amount, uint256 _userId) external;
}

contract Redeem is Ownable, ReentrancyGuard {
    address public stblToken;
    address public pulsexRouter;
    address public soilToken;

    uint256 public stblRedeemLimitPerPeriod = 20000;
    uint256 public HOURS_GAP = 120 hours;

    mapping(address => uint256) public mintedTokens;
    mapping(address => uint256) public lastMintTimestamp;

    event Redeemed(
        address indexed user,
        uint stblAmount,
        uint soilBurned,
        uint userId
    );

    /**
     * @dev constructor for itializing the contract
     *Assingn the global variables to local variable.
     */
    constructor(
        address _owner,
        address _router,
        address _stblToken,
        address _soilToken
    ) Ownable(_owner) {
        pulsexRouter = _router;
        stblToken = _stblToken;
        soilToken = _soilToken;
    }

    /**
     * @dev Set the STBL limit per period
     * @param _amount New limit amount
     */
    function setStblRedeemLimitPerPeriod(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Invalid limit amount");
        stblRedeemLimitPerPeriod = _amount;
    }

    /**
     * @dev Sets the hours gap for redemption
     * @param _hoursGap New hours gap
     */
    function setHoursGap(uint256 _hoursGap) external onlyOwner {
        require(_hoursGap > 0, "Invalid hours gap");
        HOURS_GAP = _hoursGap * 1 hours;
    }

    /**
     * @dev Set the PulseXRouter
     * @param _routerAddress New router address
     */
    function setRouter(address _routerAddress) external onlyOwner {
        require(_routerAddress != address(0), "Invalid router address");
        pulsexRouter = _routerAddress;
    }

    /**
     * @dev Function to redeem tokens.
     * @param _amountIn The amount of tokens to redeem.
     * @param _amountOutMin The amount of tokens to swap.
     * @param _userId ID of the user.
     */
    function redeem(
        uint256 _amountIn,
        uint256 _amountOutMin,
        uint256 _userId
    ) external nonReentrant {
        require(
            _amountIn > 0 && _amountOutMin > 0,
            "Amounts must be greater than zero"
        );
        require(
            _amountIn <= stblRedeemLimitPerPeriod,
            "Exceeds redemption limit"
        );

        // Check if 24 hours have passed since the last mint
        if (block.timestamp > lastMintTimestamp[msg.sender] + HOURS_GAP) {
            // Reset the minted token counter for the new day
            mintedTokens[msg.sender] = 0;
            lastMintTimestamp[msg.sender] = block.timestamp;
        }

        require(
            mintedTokens[msg.sender] + _amountIn <= stblRedeemLimitPerPeriod,
            "Redemption limit exceeded"
        );

        // Transfer STBL to this smart contract
        require(
            IERC20(stblToken).transferFrom(
                msg.sender,
                address(this),
                _amountIn
            ),
            "Transfer failed"
        );

        // Approve tokens for PulseX router
        require(
            IERC20(stblToken).approve(pulsexRouter, _amountIn),
            "Approval failed"
        );

        // Increment the minted token count
        mintedTokens[msg.sender] += _amountIn;

        address[] memory path = new address[](2);
        path[0] = stblToken;
        path[1] = soilToken;

        // Perform swap through PulseX router
        uint256 amountOut = IPulseXSwapRouter(pulsexRouter)
            .swapExactTokensForTokensV2(
                _amountIn,
                _amountOutMin,
                path,
                address(this)
            );
        console.log(" ~ amountOut:", amountOut);

        IERC20(soilToken).burn(amountOut, _userId);

        // Emit event indicating redemption
        emit Redeemed(msg.sender, _amountIn, amountOut, _userId);
    }
}
