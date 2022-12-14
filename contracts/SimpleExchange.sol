// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Pool {
    address _swapContract;    

    event Withdrawed(address addr, uint256 amount);
    modifier onlySwapContract{
        require(msg.sender == _swapContract, "invalid contract!");
        _;
    }

    constructor(){
        _swapContract = msg.sender;
    }

    function withdraw(address addr, address token) public onlySwapContract{
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).transfer(addr, balance);
        emit Withdrawed(addr, balance);
    }
}

contract GSwap is Ownable{
    uint8 _fee;
    mapping(uint256 => Swap) swaps;

    struct Swap {
        address tokenA;
        address tokenB;
        address partyA;
        address partyB;
        address poolAddress;
        uint256 amountA;
        uint256 amountB;
        uint256 expiredTime;
    }

    
    event CreatedSwap(
        address tokenA, 
        address tokenB, 
        address creator,
        address poolAddress,
        uint256 amountA,
        uint256 amountB,
        uint256 expiredTime,
        uint256 swapId
    );

    constructor() {
        _fee = 1;
    }

    function getFee() public view returns (uint8){
        return _fee;
    }

    function setFee(uint8 fee) external onlyOwner{
        _fee = fee;
    }
    
    /**
     * @dev partyA proposes the swap 
     */
    function createSwap(
        address tokenA, 
        address tokenB, 
        uint256 amountA,
        uint256 amountB, 
        uint256 afterDays
        ) external {
        Pool pool = new Pool();
        uint256 swapId =uint256(keccak256(abi.encodePacked(
            msg.sender,
            tokenA,
            tokenB,
            amountA,
            amountB,
            afterDays,
            address(pool)
            )));
        swaps[swapId].tokenA = tokenA;
        swaps[swapId].tokenB = tokenB;
        swaps[swapId].amountA = amountA;
        swaps[swapId].amountB = amountB;
        swaps[swapId].expiredTime = block.timestamp + afterDays * (1 days);
        swaps[swapId].partyA = msg.sender;
        swaps[swapId].poolAddress = address(pool);
        emit CreatedSwap(tokenA, tokenB, msg.sender, 
                    address(pool), amountA, amountB, 
                    swaps[swapId].expiredTime, swapId);
    }

    /**
    * @dev users join the swap 
    */  

    function join(uint256 swapId) external{
        require (msg.sender != swaps[swapId].partyA, "not allowed self-swap");
        require (swaps[swapId].partyB != address(0), "You cannot join this swap. already filled!");
        swaps[swapId].partyB = msg.sender;
    }

    /**
    * @dev users withdraw the swaped token 
    */  
    
    function withdraw(uint256 swapId) external {
        require(swaps[swapId].partyA == msg.sender || swaps[swapId].partyB == msg.sender, 
                "you are not party member!");
        address pool = swaps[swapId].poolAddress;
        if(checkExecuted(swapId)){
            if(msg.sender == swaps[swapId].partyA){
                Pool(pool).withdraw(msg.sender, swaps[swapId].tokenB);
            } else{
                Pool(pool).withdraw(msg.sender, swaps[swapId].tokenA);
            } 
        }else if(swaps[swapId].expiredTime > block.timestamp){
            if(msg.sender == swaps[swapId].partyA){
                Pool(pool).withdraw(msg.sender, swaps[swapId].tokenA);
            } else{
                Pool(pool).withdraw(msg.sender, swaps[swapId].tokenB);
            }
        } else {
            revert("Contract is not executed!");
        }
    }

    /**
    * @dev users withdraw the swaped token 
    */  
    
    function checkExecuted(uint256 swapId) internal view returns (bool) {
        if(swaps[swapId].partyB == address(0)) return false;
        address pool = swaps[swapId].poolAddress;
        if( IERC20(pool).balanceOf(swaps[swapId].partyA) == 0) return false;        
        if( IERC20(pool).balanceOf(swaps[swapId].partyB) == 0) return false;
        return true;        
    }

}
