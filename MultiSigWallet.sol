pragma solidity ^0.8.13;
/**
Let's create an multi-sig wallet. Here are the specifications.

The wallet owners can

submit a transaction
approve and revoke approval of pending transcations
anyone can execute a transcation after enough owners has approved it.
*/ 


/* My logic:
* Constructor
I wanted to just use owners = _owners but there's no guarantee to the eligibility  of _owners.
So a solution is to create a list or mapping to make sure the owners are valid
* modifiers
An only owner since most transactions require an owner
*submitTransaction
Had to create a list of transactions to keep track of all the transactions
*approveTransaction/revoke/execute
Change the corresponding variable in the Transaction list =>
Check if the transaction is already exectued or not =>
Check if the this address already approved/revoked the transaction or not => 
Add a mapping of boleans to check if the transactions has been already checked or not =>
We have to edit the entire code to add this new index thing  ( isChecked[_index]=true; ) =>
Realised that this doesn't work because it'll be checked after 1 approval instead of everyone's approvals =>
Change the mapping to uint => mapping(address => bool)  To check for EACH address ( isChecked[_index][owner]=true; ) 

*/ 
contract Sig {
    address[] public owners;
    uint public minNumOfApprovals;
    mapping(address => bool) public validOwners;
    
    constructor(address[] memory _owners, uint _numOfApprovals) {
        require(_owners.length > 0,"Owners required");
        require(_numOfApprovals > 0 &&  _numOfApprovals <= _owners.length, "Number of approvals can't be more than the number of owners");
        
        for(uint i = 0; i < _owners.length; i++){
            address owner = _owners[i];
            require(owner != address(0),"The owner isn't valid");
            require(!validOwners[owner],"This guy is already an owner");
            validOwners[owner] = true; 
            owners.push(owner); 
        }
        minNumOfApprovals = _numOfApprovals;
    }

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numOfApprovals;
    }
    Transaction[] public ledger; 
    mapping(uint => mapping(address=>bool)) public isChecked;


    receive() external payable {}

    modifier _onlyOwner(){
        require( validOwners[msg.sender] , "The sender isn't an owner for this wallet");
        _;
    }

    function submitTransaction(address _to, uint _value, bytes memory _data) public _onlyOwner{
        ledger.push(Transaction(_to, _value, _data, false, 0));
    }

    function approveTransaction(uint _index) public _onlyOwner{
        require(_index < ledger.length,"Transaction index doesn't exist");
        require(!isChecked[_index][msg.sender],"Transaction already checked");
        Transaction storage tsx = ledger[_index];
        tsx.numOfApprovals++;
        isChecked[_index][msg.sender]=true;
    }
    function revokeTransaction(uint _index) public _onlyOwner{
        require(_index < ledger.length,"Transaction index doesn't exist");
        require(!isChecked[_index][msg.sender],"Transaction already checked");
        Transaction storage tsx = ledger[_index];
        tsx.numOfApprovals--;
        isChecked[_index][msg.sender]=true;
    }
    function executeTransaction(uint _index)public _onlyOwner{
        require(_index < ledger.length,"Transaction index doesn't exist");
        Transaction storage tsx = ledger[_index];
        require(!tsx.executed,"This transaction is already executed");
        require(tsx.numOfApprovals >= minNumOfApprovals,"Not enough approvals");
        tsx.executed=true;
        (bool success, ) = tsx.to.call{value: tsx.value}(
            tsx.data
        );
        require(success, "Failed");
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function getTransactionCount() public view returns (uint) {
        return ledger.length;
    }

    function getTransaction(uint _txIndex) public view returns (
            address to,
            uint value,
            bytes memory data,
            bool executed,
            uint numConfirmations
        )
    {
        Transaction storage transaction = ledger[_txIndex];
        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.numOfApprovals
        );
    }

}