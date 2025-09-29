// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title SimpleMultiSig
 * @dev A simple multi-signature wallet with pre-defined owners (no constructor inputs needed)
 */
contract SimpleMultiSig {
    // Pre-defined settings (no input required)
    address public owner1 = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4; // Default Remix account 1
    address public owner2 = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2; // Default Remix account 2
    address public owner3 = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db; // Default Remix account 3
    
    uint256 public constant REQUIRED_CONFIRMATIONS = 2; // Need 2 out of 3 confirmations
    
    // Events
    event Deposit(address sender, uint256 amount);
    event TransactionSubmitted(uint256 txId, address to, uint256 value);
    event TransactionConfirmed(uint256 txId, address owner);
    event TransactionExecuted(uint256 txId);

    // Transaction structure
    struct Transaction {
        address to;
        uint256 value;
        bool executed;
        uint256 confirmations;
    }

    // State variables
    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public hasConfirmed;
    
    // Modifiers
    modifier onlyOwner() {
        require(
            msg.sender == owner1 || msg.sender == owner2 || msg.sender == owner3,
            "Not an owner"
        );
        _;
    }
    
    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "Already executed");
        _;
    }

    // Receive Ether
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    /**
     * @dev Submit a new transaction (Core Function 1)
     * @param _to Recipient address
     * @param _value Amount to send
     */
    function submitTransaction(address _to, uint256 _value) 
        external 
        onlyOwner 
        returns (uint256) 
    {
        uint256 txId = transactions.length;
        
        transactions.push(Transaction({
            to: _to,
            value: _value,
            executed: false,
            confirmations: 0
        }));
        
        emit TransactionSubmitted(txId, _to, _value);
        return txId;
    }

    /**
     * @dev Confirm a transaction (Core Function 2)
     * @param _txId Transaction ID to confirm
     */
    function confirmTransaction(uint256 _txId) 
        external 
        onlyOwner 
        notExecuted(_txId) 
    {
        require(_txId < transactions.length, "Invalid transaction ID");
        require(!hasConfirmed[_txId][msg.sender], "Already confirmed");
        
        hasConfirmed[_txId][msg.sender] = true;
        transactions[_txId].confirmations++;
        
        emit TransactionConfirmed(_txId, msg.sender);
        
        // Auto-execute if enough confirmations
        if (transactions[_txId].confirmations >= REQUIRED_CONFIRMATIONS) {
            executeTransaction(_txId);
        }
    }

    /**
     * @dev Execute a confirmed transaction (Core Function 3)
     * @param _txId Transaction ID to execute
     */
    function executeTransaction(uint256 _txId) 
        public 
        onlyOwner 
        notExecuted(_txId) 
    {
        require(_txId < transactions.length, "Invalid transaction ID");
        require(
            transactions[_txId].confirmations >= REQUIRED_CONFIRMATIONS,
            "Not enough confirmations"
        );
        
        Transaction storage txn = transactions[_txId];
        txn.executed = true;
        
        (bool success, ) = txn.to.call{value: txn.value}("");
        require(success, "Transaction failed");
        
        emit TransactionExecuted(_txId);
    }

    // View functions for easy monitoring
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function getTransactionCount() external view returns (uint256) {
        return transactions.length;
    }
    
    function getTransaction(uint256 _txId) 
        external 
        view 
        returns (address, uint256, bool, uint256) 
    {
        Transaction memory txn = transactions[_txId];
        return (txn.to, txn.value, txn.executed, txn.confirmations);
    }
}
