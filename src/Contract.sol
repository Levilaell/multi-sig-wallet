// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {
    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    uint public required;
    address[] public owners;
    Transaction[] public transactions;
    mapping(address => bool) isOwner;
    mapping(uint => mapping(address => bool)) public isConfirmed;

    event SubmitTransaction(
        address indexed owner,
        uint indexed txId,
        address to,
        uint value,
        bytes data
    );

    event ConfirmTransaction(address indexed owner, uint indexed txId);

    event RevokeConfirmation(address indexed owner, uint indexed txId);

    event ExecuteTransaction(address indexed owner, uint indexed txId);

    event Deposit(address indexed sender, uint value, uint balance);

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint txId) {
        require(txId < transactions.length, "no transaction");
        _;
    }

    modifier notExecuted(uint txId) {
        require(!transactions[txId].executed, "already executed");
        _;
    }

    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "no owner");
        require(_required > 0, "required not enough");
        require(_required <= _owners.length, "required not enough");
        for (uint i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0), "invalid owner");
            require(!isOwner[_owners[i]], "duplicate owner");
            owners.push(_owners[i]);
            isOwner[_owners[i]] = true;
        }
        required = _required;
    }

    function submitTransaction(
        address _to,
        uint _value,
        bytes memory _data
    ) public onlyOwner {
        transactions.push(
            Transaction({to: _to, value: _value, data: _data, executed: false})
        );
        uint txId = transactions.length - 1;
        isConfirmed[txId][msg.sender] = true;
        emit SubmitTransaction(msg.sender, txId, _to, _value, _data);
    }

    function confirmTransaction(
        uint txId
    ) public onlyOwner txExists(txId) notExecuted(txId) {
        require(!isConfirmed[txId][msg.sender], "owner already confirmed");

        isConfirmed[txId][msg.sender] = true;
        emit ConfirmTransaction(msg.sender, txId);
    }

    function revokeConfirmation(
        uint txId
    ) public onlyOwner txExists(txId) notExecuted(txId) {
        require(isConfirmed[txId][msg.sender], "owner have not confirmed yet");

        isConfirmed[txId][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, txId);
    }

    function executeTransaction(
        uint txId
    ) public onlyOwner txExists(txId) notExecuted(txId) {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (isConfirmed[txId][owners[i]]) {
                count++;
            }
        }
        require(count >= required);

        Transaction storage txn = transactions[txId];
        txn.executed = true;
        (bool success, ) = txn.to.call{value: txn.value}(txn.data);
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, txId);
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getTransaction(
        uint txId
    )
        public
        view
        returns (address to, uint value, bytes memory data, bool executed)
    {
        Transaction storage txn = transactions[txId];

        return (txn.to, txn.value, txn.data, txn.executed);
    }
}
