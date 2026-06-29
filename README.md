<div align="center">
  <h1>🏦 CryptoBank Application</h1>
  <p><b>A secure, multi-user Web3 vault for native Ether deposits with dual-tier access control.</b></p>
</div>

## 📖 About the Project

The **CryptoBank Application** is a robust Web3 Smart Contract project built entirely with **Solidity `0.8.30`** and thoroughly tested using the **Foundry** framework. At its core, the project provides a highly secure, decentralized vault for users to deposit and withdraw native Ether.

This architecture is ideal for demonstrating foundational DeFi principles, smart contract security patterns, and strict state management. It implements custom errors for extreme gas efficiency and utilizes a dual-role access control system separating administrative duties from ownership rights.

**Key Technical Highlights:**
* **Solidity `0.8.30`:** Leveraging up-to-date compiler features for gas optimization and built-in overflow/underflow protection.
* [**Gas-Optimized Custom Errors:** Discarding standard string reverts in favor of custom errors (e.g., `CryptoBank__NotEnoughEther()`) to significantly reduce deployment and runtime gas costs.
* **Foundry Framework:** Complete with high-speed testing (`CryptoBankTest`), state assertions, cheatcode integration (`vm.prank`, `vm.expectRevert`), and deployment scripting (`CryptoBankScript`).

---

## ⚙️ How It Works

The `CryptoBank` contract allows an unlimited number of users to interact with the vault. When a user deposits Ether, their balance is tracked internally in a mapping (`s_userBalance`). To protect the protocol, there is a hard cap on the maximum balance any single user can hold (`s_maxBalance`).

The contract utilizes a strict separation of privileges:
* **The Owner:** Set immutably at deployment, the owner holds the exclusive right to assign or change the Admin.
* **The Admin:** Responsible for protocol parameters, the admin can modify the global maximum balance (but strictly cannot lower it below the current threshold) and can read any user's balance.

### Architecture Diagram

![CryptoBank Architecture Diagram](./images/diagram.png) 

### Core Component File Paths
* [`CryptoBank.sol`](./src/CryptoBank.sol) - Main Smart Contract Logic
* [`CryptoBank.s.sol`](./script/CryptoBank.s.sol) - Foundry Deployment Script
* [`CryptoBank.t.sol`](./test/CryptoBank.t.sol) - Comprehensive Test Suite

---

## 💻 Technical Docs

The primary interaction points of the application handle Ether deposits, secure withdrawals, and administrative parameter updates.

### depositEther
Allows any user to deposit native Ether into the bank. Reverts if the deposit would cause the user's total balance to exceed the globally configured `s_maxBalance`.

```solidity
    function depositEther() external payable {
        if (s_userBalance[msg.sender] + msg.value > s_maxBalance) revert CryptoBank__MaxBalanceReached();
        s_userBalance[msg.sender] += msg.value;

        emit EtherDeposit(msg.sender, msg.value);
    }
```

### withdraw
Allows users to securely withdraw their previously deposited Ether. Implements the checks-effects-interactions pattern to prevent reentrancy attacks by deducting the balance before executing the low-level .call.

```Solidity
    function withdraw(uint256 _amount) external {
        if (_amount > s_userBalance[msg.sender]) revert CryptoBank__NotEnoughEther();
        s_userBalance[msg.sender] -= _amount;
        (bool success,) = msg.sender.call{value: _amount}("");
        require(success, "Transfer Failed!");
        emit EtherWithdraw(msg.sender, _amount);
    }
```

### modifyMaxBalance
An administrative function to increase the vault's holding limit. It strictly prevents the admin from modifying the balance to a lower amount to protect existing user positions.

```Solidity
    function modifyMaxBalance(uint256 _newMaxBalance) external onlyAdmin {
        if (_newMaxBalance <= s_maxBalance) revert CryptoBank__CannotModifyToLowerBalance();
        s_maxBalance = _newMaxBalance;
    }
```

🚀 Execution ExampleHere is a step-by-step example of how users and administrators interact with the CryptoBank system, mirroring our Foundry testing environment:
- Step 1: Setup & Deploy: The deployment script (CryptoBank.s.sol) is executed. It provisions the CryptoBank contract, setting the initial maxBalance to 5 ether and assigning an admin address. The wallet deploying the contract becomes the immutable owner.

- Step 2: User Deposit: USER1 decides to utilize the bank. They call depositEther() and send 3 ether. The contract successfully logs the balance since it is under the 5 ether cap.

- Step 3: Hitting the Cap: USER1 attempts to deposit another 3 ether. The transaction reverts with CryptoBank__MaxBalanceReached() because their total balance would equal 6 ether, violating the 5 ether limit.

- Step 4: Admin Intervention: To accommodate higher volumes, the admin calls modifyMaxBalance(10 ether). The global limit is updated. USER1 can now successfully deposit additional funds.

- Step 5: Secure Withdrawal: USER1 calls withdraw(2 ether). The contract deducts the 2 ether from their internal balance and safely transfers the native ETH back to their wallet, emitting an EtherWithdraw event.

⬆️ Installation
Ensure you have Foundry installed on your local machine.
```Bash
forge install foundry-rs/forge-std
````

🧪 Testing
```bash
forge test -vvvv
````

📊 Coverage
```Bash
forge coverage
```

📜 Contract Address
(Provide deployed contract addresses here upon mainnet/testnet launch)