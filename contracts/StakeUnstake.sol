// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

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


contract StakeUnstake{
    bytes private constant PREFIX = "\x19Ethereum Signed Message:\n32";
    address public stblCoin;
    address public Verifier;

    //struct to manage user staking data
    struct userData {
        uint staked;
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

    /**
     * @dev constructor for itializing the contract
     *Assingn the global variables to local variable.
     */
    constructor(address _verifier, address _STBLToken) {
        stblCoin = _STBLToken;
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
     * @dev Unstakes the user's staked amount and claims rewards if applicable.
     * The function transfers the staked amount back to the user and updates the staking data.
     * Requirements:
     * - The caller must have staked a positive amount.
     * - Uses reentrancy guard to prevent reentrant attacks.
     *
     * @param _userId The ID of the user performing the unstake operation.
     *
     * Emits an {UnStake} event indicating the user's unstaked amount and ID.
     */
    function unstakeOrClaim(uint256 _userId) public {
        // Ensure the user has staked some amount
        require(
            stakingData[msg.sender].staked > 0,
            "Insufficient staked amount"
        );

        // Fetch user's staked amount
        uint256 stakedAmount = stakingData[msg.sender].staked;

        // Calculate the total amount to transfer (staked + rewards)
        uint256 totalAmountToUnstake = stakedAmount;

        // Transfer the total unstaked amount and rewards back to the user
        ERC20(stblCoin).transfer(msg.sender, totalAmountToUnstake);

        // Update the global and user's staked data
        totalTBLStaked -= stakedAmount; // Decrease the global staked amount
        stakingData[msg.sender].staked = 0; // Reset the user's staked amount
        stakingData[msg.sender].isStaked = false; // Mark user as no longer staked

        // Emit the unstake event
        emit UnStake(stakedAmount, msg.sender, _userId);
    }
}
