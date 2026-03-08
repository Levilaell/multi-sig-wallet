# Multi-Signature Wallet

A production-grade multi-signature wallet smart contract built in Solidity. Requires M-of-N owner approvals before executing any transaction — eliminating single points of failure in treasury management.

## Overview

Multi-sig wallets are the backbone of DAO treasuries, protocol upgrades, and corporate on-chain accounts. This implementation follows the same core architecture used by Gnosis Safe: owners propose transactions, co-signers confirm, and execution only happens after the required threshold is reached.

**Deployed on Sepolia:** [`0x64a20b838dfc2729B53d513Fb7E54e4B31e90Ce2`](https://sepolia.etherscan.io/address/0x64a20b838dfc2729B53d513Fb7E54e4B31e90Ce2)

---

## Features

- M-of-N signature threshold configurable at deploy time
- Any owner can propose a transaction
- Proposer auto-confirms on submission
- Owners can revoke confirmations before execution
- Supports arbitrary calldata — transfers ETH or calls external contracts
- Full event emission for frontend/indexer integration

---

## Architecture

### Transaction Lifecycle

```
SUBMIT → CONFIRMING → EXECUTED
                    ↘ REVOKED
```

### State Variables

| Variable       | Type                                        | Purpose                      |
| -------------- | ------------------------------------------- | ---------------------------- |
| `owners`       | `address[]`                                 | Iterable list of owners      |
| `isOwner`      | `mapping(address => bool)`                  | O(1) owner lookup            |
| `required`     | `uint`                                      | Confirmation threshold       |
| `transactions` | `Transaction[]`                             | All proposed transactions    |
| `isConfirmed`  | `mapping(uint => mapping(address => bool))` | Per-tx confirmation tracking |

**Design decision:** `owners` array and `isOwner` mapping are maintained in parallel — the array enables iteration (e.g. counting confirmations), the mapping enables O(1) access checks. Using only an array would require O(n) loops on every permission check.

### Security Patterns

**Checks-Effects-Interactions (CEI)**
State is updated before external calls to prevent reentrancy attacks:

```solidity
txn.executed = true;                                    // effect
(bool success,) = txn.to.call{value: txn.value}(...);  // interaction
```

**Defensive constructor validation**

- Rejects empty owner arrays
- Rejects `address(0)` owners
- Rejects duplicate owners
- Rejects `required > owners.length`

---

## Functions

| Function                             | Access | Description                              |
| ------------------------------------ | ------ | ---------------------------------------- |
| `submitTransaction(to, value, data)` | Owner  | Proposes and auto-confirms a transaction |
| `confirmTransaction(txId)`           | Owner  | Adds a confirmation                      |
| `revokeConfirmation(txId)`           | Owner  | Removes a confirmation                   |
| `executeTransaction(txId)`           | Owner  | Executes if threshold is met             |
| `getOwners()`                        | Public | Returns owner list                       |
| `getTransaction(txId)`               | Public | Returns transaction details              |
| `getTransactionCount()`              | Public | Returns total transaction count          |

---

## Events

```solidity
event Deposit(address indexed sender, uint value, uint balance);
event SubmitTransaction(address indexed owner, uint indexed txId, address to, uint value, bytes data);
event ConfirmTransaction(address indexed owner, uint indexed txId);
event RevokeConfirmation(address indexed owner, uint indexed txId);
event ExecuteTransaction(address indexed owner, uint indexed txId);
```

---

## Getting Started

### Prerequisites

- [Foundry](https://getfoundry.sh/)

### Install

```bash
git clone https://github.com/seu-usuario/multisig-wallet
cd multisig-wallet
forge install
```

### Run Tests

```bash
forge test -vv
```

### Coverage

```bash
forge coverage
```

### Deploy

```bash
cp .env.example .env
# fill in SEPOLIA_RPC_URL, PRIVATE_KEY, DEPLOYER_ADDRESS

source .env
forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast
```

---

## Tests

9 tests covering happy paths, revert cases, and edge cases:

```
✓ test_Owners
✓ test_SubmitTransaction
✓ test_ConfirmTransaction
✓ test_ExecuteTransaction
✓ test_RevokeConfirmation
✓ test_RevertWhen_NotOwner
✓ test_RevertWhen_AlreadyConfirmed
✓ test_RevertWhen_NotEnoughConfirmations
✓ test_RevertWhen_ExecuteTwice
```

**Coverage: 89.8% lines / 92.8% statements**

---

## License

MIT
