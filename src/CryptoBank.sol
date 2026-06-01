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
    modifier onlyAdmin() {
        if (msg.sender != s_admin) revert CryptoBank__OnlyAdminFunction();
        _;
    }

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
    function depositEther() external payable {
        if (s_userBalance[msg.sender] + msg.value >  s_maxBalance) revert CryptoBank__MaxBalanceReached();
        s_userBalance[msg.sender] += msg.value;

        emit EtherDeposit(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) external {
        if (_amount > s_userBalance[msg.sender]) revert CryptoBank__NotEnoughEther();
        s_userBalance[msg.sender] -= _amount;
        (bool success,) = msg.sender.call{value: _amount}("");
        require(success, "Transfer Failed!");
        emit EtherWithdraw(msg.sender, _amount);
    }

    function modifyMaxBalance(uint256 _newMaxBalance) external onlyAdmin {
        if (_newMaxBalance <= s_maxBalance) revert CryptoBank__CannotModifyToLowerBalance();
        s_maxBalance = _newMaxBalance;
    }

    function setAdmin(address _newAdmin) external onlyOwner {
        if (_newAdmin == i_owner) revert CryptoBank__OwnerCannotBeAdmin();
        s_admin = _newAdmin;
    }

    // External view functions
    function getMyBalance() external view returns(uint256 userBalance) {
        userBalance = s_userBalance[msg.sender];
    }

    function getUserBalance(address _user) external view onlyAdmin returns(uint256 userBalance) {
        userBalance = s_userBalance[_user];
    }

    function getAdminAddress() external view returns(address admin) {
        admin = s_admin;
    }

    function getOwnerAddress() external view returns(address owner) {
        owner = i_owner;
    }

    function getMaxBalance() external view returns(uint256 maxBalance) {
        maxBalance = s_maxBalance;
    }

}
