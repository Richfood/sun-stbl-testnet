// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

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

interface ERC20 {
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

    function mintReward(address _user, uint _amount) external;

    function burn(uint256 _amount, uint256 _userId) external;
}

contract Redeem is Ownable, ReentrancyGuard {

    address public stblCoin;
    address public pulsexRouter;
    address public sunMinimealSOILToken;

    uint public STBLLimitPerTransaction = 4000;
    uint256 public constant DAY_IN_SECONDS = 86400; // 24 hours

    mapping(address => uint256) public mintedTokens;
    mapping(address => uint256) public lastMintTimestamp;

    //struct to manage user staking data
    struct userData {
        uint staked;
        uint reward;
        bool isStaked;
    }

    //Mapping will return the data of user
    mapping(address => userData) public stakingData;

    //Show the total staked STBL
    uint256 public totalTBLStaked;

    //array to track all stakers
    address[] public stakers;

    //event log for all function of STBL farm

    event Stake(uint value, address userAddress, uint userId);

    event UnStake(uint value, address userAddress, uint userId);

    event Redeemed(
        address indexed user,
        uint tblAmount,
        uint mmBurned,
        uint userId
    );

    event Swap(
        address indexed user,
        address amountInToken,
        uint amountIn,
        address amountOutToken,
        uint amountOut,
        uint userId
    );

    /**
     * @dev constructor for itializing the contract
     *Assingn the global variables to local variable.
     */
    constructor(
        address _STBLToken,
        address _router,
        address _SUNMinimealSOIL
    ) Ownable(msg.sender) {
        pulsexRouter = _router;
        stblCoin = _STBLToken;
        sunMinimealSOILToken = _SUNMinimealSOIL;
    }

    /**
     * @dev internal stake function
     * @param _stakeAmount will be amount which user want to stake.
     * @param  _user user address
     */

    function _stake(uint256 _stakeAmount, address _user) private {
        require(
            ERC20(stblCoin).allowance(msg.sender, address(this)) >=
                _stakeAmount,
            "TBLStaking: Insufficient allowance"
        );

        require(_stakeAmount > 0, "TBLStaking: Cannot stake zero tokens");

        ERC20(stblCoin).transferFrom(msg.sender, address(this), _stakeAmount);

        if (!stakingData[_user].isStaked) {
            stakers.push(_user);
            stakingData[_user].isStaked = true;
        }

        stakingData[_user].staked += _stakeAmount;
        totalTBLStaked += _stakeAmount;
    }

    /**
     * @dev Create the user Staking
     * @param _stakeAmount amount to mint
     */
    function stake(uint256 _stakeAmount, uint256 _userId) public {
        _stake(_stakeAmount, msg.sender);
        emit Stake(_stakeAmount, msg.sender, _userId);
    }

    /**
     * @dev Function to unstake or claim rewards.
     */
    function unstakeOrClaim(
        uint256 _amount,
        uint256 _userId
    ) public nonReentrant {
        require(
            stakingData[msg.sender].staked >= _amount &&
                stakingData[msg.sender].isStaked,
            "No amount to unstake or claim"
        );

        // Add stable rewards to sender's total amount to unstake
        uint256 totalAmountToUnstake = _amount;
        uint contractBalance = ERC20(stblCoin).balanceOf(address(this));
        require(contractBalance >= totalAmountToUnstake, "Insufficient funds");
        // Transfer the total amount to unstake to the sender
        ERC20(stblCoin).transfer(msg.sender, totalAmountToUnstake);

        totalTBLStaked -= _amount;

        // Reset stake data
        stakingData[msg.sender].staked -= _amount;

        if (stakingData[msg.sender].staked == 0) {
            stakingData[msg.sender].isStaked = false;
            // Remove the address from the list of stakers
            for (uint256 i = 0; i < stakers.length; i++) {
                if (stakers[i] == msg.sender) {
                    stakers[i] = stakers[stakers.length - 1];
                    // Move the last element to the position of the removed element
                    stakers.pop(); // Remove the last element
                    break; // Exit the loop
                }
            }
        }

        emit UnStake(_amount, msg.sender, _userId);
    }

    function swap(
        uint amountIn,
        address amountInToken,
        uint amountOut,
        address amountOutToken,
        uint _userId
    ) external {
        require(
            amountIn > 0 && amountOut > 0,
            "Amounts must be greater than zero"
        );

        // Approve tokens for Uniswap router
        ERC20(amountInToken).transferFrom(msg.sender, address(this), amountIn);
        ERC20(amountInToken).approve(pulsexRouter, amountIn);

        // Prepare path for token swap
        address[] memory path = new address[](2);
        path[0] = amountInToken;
        path[1] = amountOutToken;

        // Perform swap through Uniswap router
        IPulseXSwapRouter(pulsexRouter).swapExactTokensForTokensV2(
            amountIn,
            amountOut,
            path,
            msg.sender
        );

        emit Swap(
            msg.sender,
            amountInToken,
            amountIn,
            amountOutToken,
            amountOut,
            _userId
        );
    }

    function setSTBLLimitPerTransaction(uint _amount) public onlyOwner {
        STBLLimitPerTransaction = _amount;
    }

    function setRouter(address _router) public onlyOwner {
        pulsexRouter = _router;
    }

    /**
     * @dev Function to redeem tokens.
     * @param amountIn The amount of tokens to redeem.
     * @param amountOut The amount of tokens to swap.
     * @param _userId ID of the user.
     */
    function redeem(
        uint amountIn,
        uint amountOut,
        uint _userId
    ) public nonReentrant {
        require(
            amountIn > 0 && amountOut > 0,
            "Amounts must be greater than zero"
        );

        require(
            amountIn <= STBLLimitPerTransaction,
            "you can't redeem more than a limit"
        );

         // Check if 24 hours have passed since the last mint
        if (block.timestamp > lastMintTimestamp[msg.sender] + DAY_IN_SECONDS) {
            // Reset the minted token count for the new day
            mintedTokens[msg.sender] = 0;
            lastMintTimestamp[msg.sender] = block.timestamp;
        }

        // Ensure the wallet can mint the requested amount
        require(mintedTokens[msg.sender] + amountIn <= STBLLimitPerTransaction, "Minting limit exceeded for today");

        // Increment the minted token count
        mintedTokens[msg.sender] += amountIn;

        // Approve tokens for Uniswap router
        ERC20(stblCoin).transferFrom(msg.sender, address(this), amountIn);
        ERC20(stblCoin).approve(pulsexRouter, amountIn);

        // Prepare path for token swap
        address[] memory path = new address[](2);
        path[0] = stblCoin;
        path[1] = sunMinimealSOILToken;

        // Perform swap through Uniswap router
        IPulseXSwapRouter(pulsexRouter).swapExactTokensForTokensV2(
            amountIn,
            amountOut,
            path,
            address(this)
        );

        ERC20 mmToken = ERC20(sunMinimealSOILToken);
        uint mmBalance = mmToken.balanceOf(address(this));
        mmToken.burn(mmBalance, _userId);

        // Emit event indicating redemption
        emit Redeemed(msg.sender, amountIn, mmBalance, _userId);
    }

}