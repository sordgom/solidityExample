pragma solidity ^0.8.13;
/**An example of a basic wallet.

Anyone can send ETH.
Only the owner can withdraw.
*/
contract Ether{
    
    address payable public owner;
    
    constructor(){
        owner = payable(msg.sender); 
    }

    receive() external payable {}

    function withdraw(uint _amount) external{
        require(owner == msg.sender, "Only the owner can withdraw");
        payable(msg.sender).transfer(_amount);
    }

    function getBalance() external view returns (uint){
        return address(this).balance;
    }

}