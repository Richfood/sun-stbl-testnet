// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

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

    function mintReward(address _user, uint _amount) external;

    function burn(uint256 _amount, uint256 _userId) external;
}

contract StakeUnstake {
    bytes private constant PREFIX = "\x19Ethereum Signed Message:\n32";
    address public stblToken;
    address public Verifier;

    //struct to manage user staking data
    struct userData {
        uint staked;
        bool isStaked;
    }

    //Mapping will return the data of user
    mapping(address => userData) public stakingData;

    // Mapping to store staker indices
    mapping(address => uint256) private stakerIndices;

    //Show the total staked STBL
    uint256 public totalStblStaked;

    //array to track all stakers
    address[] public stakers;

    //event log for all function of STBL farm

    event Stake(uint value, address userAddress, uint userId);

    event UnStake(uint value, address userAddress, uint userId);

    /**
     * @dev constructor for itializing the contract
     *Assingn the global variables to local variable.
     */
    constructor(address _verifier, address _STBLToken) {
        stblToken = _STBLToken;
        Verifier = _verifier;
    }

    /**
     * @dev internal stake function
     * @param _stakeAmount will be amount which user want to stake.
     * @param  _user user address
     */

    function _stake(
        uint256 _stakeAmount,
        address _user,
        uint _userId,
        uint _nonce,
        bytes32 _hashedMessage,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) private {
        require(block.timestamp <= _deadline, "ERC20Permit: expired deadline");
        bytes32 hash = keccak256(
            abi.encodePacked(_userId, _nonce, _stakeAmount, _deadline, _user)
        );

        require(hash == _hashedMessage, "invalid hash");
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(PREFIX, _hashedMessage)
        );

        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);

        require(signer == Verifier, "invalid signature");

        require(
            IERC20(stblToken).allowance(msg.sender, address(this)) >=
                _stakeAmount,
            "TBLStaking: Insufficient allowance"
        );

        require(_stakeAmount > 0, "Cannot stake zero tokens");

        require(
            IERC20(stblToken).transferFrom(_user, address(this), _stakeAmount),
            "Transfer failed"
        );

        if (!stakingData[_user].isStaked) {
            if (!stakingData[_user].isStaked) {
                stakerIndices[_user] = stakers.length;
                stakers.push(_user);
                stakingData[_user].isStaked = true;
            }
        }
        stakingData[_user].staked += _stakeAmount;
        totalStblStaked += _stakeAmount;
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
    ) public {
        _stake(
            _stakeAmount,
            _user,
            _userId,
            _nonce,
            _hashedMessage,
            _deadline,
            _v,
            _r,
            _s
        );
        emit Stake(_stakeAmount, _user, _userId);
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
            "No amount to unstake or claim"
        );

        uint256 contractBalance = IERC20(stblToken).balanceOf(address(this));
        require(contractBalance >= _amount, "Insufficient funds");

        require(
            IERC20(stblToken).transfer(msg.sender, _amount),
            "Transfer failed"
        );
        totalStblStaked -= _amount;
        stakingData[msg.sender].staked -= _amount;

        if (stakingData[msg.sender].staked == 0) {
            stakingData[msg.sender].isStaked = false;
            _removeStaker(msg.sender);
        }

        emit UnStake(_amount, msg.sender, _userId);
    }

    /**
     * @dev Internal function to remove a staker
     * @param _staker Address of the staker to remove
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
}
