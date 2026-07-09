// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// Functions:
    // 1. Deposit ether
    // 2. Withdraw ether

// Rules:
    // 1. Multiuser
    // 2. Can only deposit ether
    // 3. User can only withdraw previously deposit ether
    // 4. Max balance = 5 ether
    // UserA -> Deposit(5 ether)
    // UserB -> Deposit(2 ether)
    // Bank Balance = 7 ether

contract CryptoBank {

    // Custom Errors
    error CryptoBank__NotEnoughEther();
    error CryptoBank__OnlyAdminFunction();
    error CryptoBank__MaxBalanceReached();
    error CryptoBank__OnlyOwnerFunction();
    error CryptoBank__OwnerCannotBeAdmin();
    error CryptoBank__CannotModifyToLowerBalance();
    
    // Variables
    address immutable i_owner;
    uint256 private s_maxBalance;
    address private s_admin;
    mapping(address user => uint256 balance) private s_userBalance;

    // Events
    event EtherDeposit(address user, uint256 etherAmount);
    event EtherWithdraw(address user, uint256 etherAmount);

    // Modifiers
    // Checks if the admin is calling the function
    modifier onlyAdmin() {
        if (msg.sender != s_admin) revert CryptoBank__OnlyAdminFunction();
        _;
    }

    // Checks if the owner is calling the function
    modifier onlyOwner() {
        if(msg.sender != i_owner) revert CryptoBank__OnlyOwnerFunction();
        _;
    }

    constructor(uint256 _maxBalance, address _admin) {
        i_owner = msg.sender;
        s_maxBalance = _maxBalance;
        s_admin = _admin;
    }

    // External Functions
    /**
     * @dev Deposit ether to contract / bank
     */
    function depositEther() external payable {
        if (s_userBalance[msg.sender] + msg.value >  s_maxBalance) revert CryptoBank__MaxBalanceReached();
        s_userBalance[msg.sender] += msg.value;

        emit EtherDeposit(msg.sender, msg.value);
    }

    /**
     * @dev withdraw certain amount from the contract / bank
     * @param _amount Amount to withdraw
     */
    function withdraw(uint256 _amount) external {
        if (_amount > s_userBalance[msg.sender]) revert CryptoBank__NotEnoughEther();
        s_userBalance[msg.sender] -= _amount;
        (bool success,) = msg.sender.call{value: _amount}("");
        require(success, "Transfer Failed!");
        emit EtherWithdraw(msg.sender, _amount);
    }

    /**
     * @dev Admin can change the max balance allowed to deposit
     * @param _newMaxBalance The new max balance allowed, cannot be lower or equal than the last value
     */
    function modifyMaxBalance(uint256 _newMaxBalance) external onlyAdmin {
        if (_newMaxBalance <= s_maxBalance) revert CryptoBank__CannotModifyToLowerBalance();
        s_maxBalance = _newMaxBalance;
    }

    /**
     * @dev Change the admin address -> only the owner can use this function
     * @param _newAdmin new admin address
     */
    function setAdmin(address _newAdmin) external onlyOwner {
        if (_newAdmin == i_owner) revert CryptoBank__OwnerCannotBeAdmin();
        s_admin = _newAdmin;
    }

    /**
     * @dev User can get his balance
     */
    // External view functions
    function getMyBalance() external view returns(uint256 userBalance) {
        userBalance = s_userBalance[msg.sender];
    }

    /**
     * @dev Function to check any user address balance
     * @param _user Address of user to check the balance
     * @return userBalance balance of the address to check
     */
    function getUserBalance(address _user) external view onlyAdmin returns(uint256 userBalance) {
        userBalance = s_userBalance[_user];
    }

    /**
     * @dev Get the admin address
     * @return admin The admin address
     */
    function getAdminAddress() external view returns(address admin) {
        admin = s_admin;
    }

    /**
     * @dev Get the owner address
     * @return owner The owner address
     */
    function getOwnerAddress() external view returns(address owner) {
        owner = i_owner;
    }

    /**
     * @dev Get the max balance allowed
     * @return maxBalance Max Balance allowed
     */
    function getMaxBalance() external view returns(uint256 maxBalance) {
        maxBalance = s_maxBalance;
    }

}
