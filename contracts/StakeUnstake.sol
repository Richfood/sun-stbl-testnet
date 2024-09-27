// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

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
}

/// @title StakeUnstake
/// @notice A contract for staking and unstaking tokens
/// @dev Implements staking, unstaking, and management of stakers
contract StakeUnstake is Ownable, ReentrancyGuard {
    bytes private constant PREFIX = "\x19Ethereum Signed Message:\n32";
    address public stblToken;
    address public verifier;

    //struct to manage user staking data
    struct userData {
        uint staked;
        bool isStaked;
    }

    struct AirdropDetail {
        uint256 user_id;
        address recipient;
    }

    //Mapping will return the data of user
    mapping(address => userData) public stakingData;

    mapping(uint256 => bool) public usedBatch;

    // Mapping to store staker indices
    mapping(address => uint256) private stakerIndices;

    // Mapping to check usedSignatures to prevent same Signatures use
    mapping(bytes32 => bool) private usedSignatures;

    //Show the total staked STBL
    uint256 public totalStblStaked;

    //array to track all stakers
    address[] public stakers;

    //events
    event Staked(uint value, address userAddress, uint userId);
    event Unstaked(uint value, address userAddress, uint userId);
    event UnstakedByAdmin(
        AirdropDetail[] airdropDetails,
        uint256 indexed sumAmounts,
        uint256 indexed batchId
    );

    /**
     * @dev constructor for itializing the contract
     *Assingn the global variables to local variable.
     */
    constructor(
        address _owner,
        address _verifier,
        address _stblToken
    ) Ownable(_owner) {
        stblToken = _stblToken;
        verifier = _verifier;
    }

    function checkStakers() public view returns (uint256) {
        return stakers.length;
    }

    /**
     * @notice Public function to stake tokens by a user.
     * @dev This function validates and processes a stake request from the user. It verifies the user's
     *      signature to ensure authenticity, and emits a `Stake` event on successful staking.
     * @param _stakeAmount The amount of tokens to be staked.
     * @param _user The address of the user staking tokens.
     * @param _userId The unique ID of the user (used for verification).
     * @param _nonce The nonce value used to prevent replay attacks.
     * @param _hashedMessage The hashed message containing staking details, signed by the user.
     * @param _deadline The deadline timestamp before which the staking request must be processed.
     * @param _v The recovery byte of the user's signature.
     * @param _r The first 32 bytes of the user's signature.
     * @param _s The second 32 bytes of the user's signature.
     * @notice Ensure that the `_stakeAmount` is greater than 0 and the user has approved sufficient allowance.
     */
    function stake(
        uint256 _stakeAmount,
        address _user,
        uint _userId,
        uint _nonce,
        bytes32 _hashedMessage,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(_stakeAmount > 0, "STBLStaking: Cannot stake zero tokens");
        require(block.timestamp <= _deadline, "ERC20Permit: expired deadline");

        // Check token allowance
        require(
            IERC20(stblToken).allowance(_user, address(this)) >= _stakeAmount,
            "STBLStaking: Insufficient allowance"
        );

        // Hash and verify the message
        bytes32 hash = keccak256(
            abi.encodePacked(_userId, _nonce, _stakeAmount, _deadline, _user)
        );

        require(hash == _hashedMessage, "STBLStaking: Invalid hash");

        // Prefix the message and recover the signer
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(PREFIX, _hashedMessage)
        );

        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        require(
            !usedSignatures[prefixedHashMessage],
            "STBLStaking: Signature already used"
        );
        require(signer == verifier, "STBLStaking: Invalid signature");

        // Mark the signature as used
        usedSignatures[prefixedHashMessage] = true;

        // Check if the user is staking for the first time
        if (!stakingData[_user].isStaked) {
            stakerIndices[_user] = stakers.length;
            stakers.push(_user);
            stakingData[_user].isStaked = true;
        }

        // Update user's stake and total staked amount
        stakingData[_user].staked += _stakeAmount;
        totalStblStaked += _stakeAmount;

        // Transfer tokens from user to contract
        require(
            IERC20(stblToken).transferFrom(_user, address(this), _stakeAmount),
            "Transfer failed"
        );

        emit Staked(_stakeAmount, _user, _userId);
    }

    /**
     * @dev Function to unstake principal
     * @param _amount Amount to unstake
     * @param _userId User ID
     */
    function unstake(uint256 _amount, uint256 _userId) external {
        require(
            stakingData[msg.sender].staked >= _amount &&
                stakingData[msg.sender].isStaked,
            "No amount to unstake"
        );

        uint256 contractBalance = IERC20(stblToken).balanceOf(address(this));
        require(contractBalance >= _amount, "Insufficient funds");

        totalStblStaked -= _amount;
        stakingData[msg.sender].staked -= _amount;

        if (stakingData[msg.sender].staked == 0) {
            stakingData[msg.sender].isStaked = false;
            _removeStaker(msg.sender);
        }

        require(
            IERC20(stblToken).transfer(msg.sender, _amount),
            "Transfer failed"
        );

        emit Unstaked(_amount, msg.sender, _userId);
    }

    /**
     * @dev Internal function to remove a staker
     * @param _staker address of the staker to remove
     */
    function _removeStaker(address _staker) private {
        uint256 index = stakerIndices[_staker];
        uint256 lastIndex = stakers.length - 1;

        if (index != lastIndex) {
            address lastStaker = stakers[lastIndex];
            stakers[index] = lastStaker;
            stakerIndices[lastStaker] = index;
        }

        stakers.pop();
        delete stakerIndices[_staker];
    }

    /**
     * @dev Function for admin to send tokens to user.
     * @param airdropDetails users address and their respective claim amount.
     * @param _sumAmounts total Amounts of tokens claimed by recipients.
     * @param _batchId maintaining unique batch Id to distinguish staking data.
     */
    function unstakeByAdmin(
        AirdropDetail[] calldata airdropDetails,
        uint256 _sumAmounts,
        uint256 _batchId
    ) public nonReentrant onlyOwner {
        require(!usedBatch[_batchId], "batch id already used");
        uint256 contractBalance = IERC20(stblToken).balanceOf(address(this));
        require(contractBalance >= _sumAmounts, "Insufficient funds");

        // Mark the batch as used and reset total staked
        usedBatch[_batchId] = true;
        totalStblStaked -= _sumAmounts;

        for (uint256 i = 0; i < airdropDetails.length; i++) {
            address recipient = airdropDetails[i].recipient;
            // Remove the staker and clear their staking data
            uint256 stakedAmountPerUser = stakingData[recipient].staked;
            _removeStaker(recipient);
            stakingData[recipient] = userData({isStaked: false, staked: 0});
            require(
                IERC20(stblToken).transfer(recipient, stakedAmountPerUser),
                "Transfer failed"
            );
        }

        emit UnstakedByAdmin(airdropDetails, _sumAmounts, _batchId);
    }
}
