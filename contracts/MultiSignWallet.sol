//SPDX-Licese-Identifier: UNLICENSED
pragma solidity ^0.8.17; // writing solidity for compiler version 0.8.17 and above but not exceeding 0.9.0
 contract OurWallet {
    // This is a multi-signature wallet

    //events
    event Deposit(address indexed sender, uint256 amount);
    event Submit(uint256 indexed txId); //submit event will be emitted whe a transaction is submitted
    event Approve(address indexed owner, uint256 indexed txId); // approve event will be emitted whe other owners of the multisign wallet approve the transaction
    event Revoke(address indexed ower, uint256 indexed txId);
    event Execute(uint256 indexed txId);

    struct Transaction {
        address to; // address of the account receiving the txt
        uint256 value; // amount of ether being sent with the txt
        bytes data; // payload data being sent together with the txt
        bool executed; // is set to true once the txt is executed
    }

    address[] public owners; // A dynamic array of addresses of owners(address that can approve transactions in the wallet)
    mapping (address => bool) public isOwner; //If a address is an owner of the wallet it will return true otherwise false, same to msg.sender
    uint256 public required; // These is the number of approvals required for a transaction to execute

    Transaction[] public transactions; // a dynamic array of txts to store all transactions that have been executed
    mapping (uint => mapping (address => bool)) public approved; // 

    modifier onlyOwer () {
        require(isOwner[msg.sender], "not owner"); // requires msg.sender is owner otherwise prints error msg "ot owner"
        _; 
    }

    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "Txt does not exist"); //checks whether txId is in the array, if falseprits error msg
        _;
    }

    modifier notApproved(uint256 _txId) {
        require(!approved[_txId][msg.sender], "Txt already approved"); // checks whether the txId is i the mapping, if yes throws an error msg to show its approved
        _;
    }

    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "Txt already executed"); // checks whether the txt has been executed and throws an error msg if true 
        _;
    }

    // 2 parameters for the constructor; the address of owner and the approval number required 
    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, " owners required"); // checks for owner's presence & prints error msg if no owners present
        require(
            _required > 0 && _required <= _owners.length,
            "Invalid required number of owners"
        ); // checks if _required is greater than zero & less than or equal to the number of owners and prints error msg if either is false

        // for loop to save owners to the state variable 
        for (uint256 i; i < _owners.length; i++; ) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner"); // check owner is not of address zero, if true print error msg 
            require(!isOwner[owner], "address is owner"); // checks whether owner is in isowner variable, if true, prints an error msg

            isOwner[owner] = true; // adding owner into isowner mapping 
            owners.push(owner); // pushing owner into the owners state variable
        }

        required = _required; // required (state variable) == _required(input)
    }


    receive() external payable {
        emit Deposit(msg.sender, msg.value); // enables the wallet to receive some ether
    }

    function submit(address _to, uint256 _value, bytes calldata _data)  returns () 
        external
        onlyOwner
    {
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            executed: false
        }));
        emit Submit(transactios.length -1); // 1st txt is stored at zero, 2nd txt at 1
    }

    function approve(uint256 _txId) 
        external
        onlyOwner
        txExists(_txId)
        notApproved(_txId)
        notExecuted(_txId)
    {
        approved[_txId][msg.sender] = true; //stores the approval of the txt to mapping
        emit Approved(msg.sender, _txId);
    }

    function _getApprovalCout(uint256 _txId) 
        private
        view
        returns (uint count) // initializing count
    {
        for (uint256 i; i < owners.length; i++) {
            if (approved[_txId][owners[i]]) {
                count += 1; //If owners of i have approved the txt then add the count with one
            }
        }
    }

    function execute(uint256 _txId)
        external
        txExists(_txId)
        notExecuted(_txId) 
    {
        require(_getApprovalCount(_txId) >= required, "approval < required"); // checks if approval count is greater than or equal to required if not throws an error msg "approvals < required"
        Transaction storage transaction = transaction[_txId];

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value} (
            transaction.data 
        );
        require(success, "txt failed"); //checks whether the transacation is executed otherwise throw an error msg

        emit Execute(_txId); 
    }

    function revoke(uint256 _txId) 
        external
        onlyOwner
        txId  returns () 
    {
        require(approved[_txId][msg.sender], "Txt not approved"); // checks whether the txt of _txId is approved by msg.sender
        approved[_txId][msg.sender] = false; //set approval of txt of _txId to false
        emit Revoke(msg.sender, _txId); //emit the revoke event
    }
 }
