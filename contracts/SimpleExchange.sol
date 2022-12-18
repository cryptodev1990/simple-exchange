// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// import "hardhat/console.sol";

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

    function withdraw(address addr, address token, uint256 amount) public onlySwapContract{
        IERC20(token).transfer(addr, amount);
        emit Withdrawed(addr, amount);
    }
}

contract GSwap is Ownable{
    uint8 _fee;
    mapping(uint256 => Swap) swaps;
    uint256 _swapId;
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
    
    event Joined(uint256 swapId);
    event Withdrawed(address addr, uint256 swapId);
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
        uint256 swapId = _swapId;
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
        _swapId++;
    }

    /**
    * @dev users join the swap 
    */  

    function join(uint256 swapId) external{
        require (msg.sender != swaps[swapId].partyA, "not allowed self-swap");
        require (swaps[swapId].partyB == address(0), "You cannot join this swap. already filled!");
        swaps[swapId].partyB = msg.sender;
        emit Joined(swapId);
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
                uint256 amount = IERC20(swaps[swapId].tokenB).balanceOf(pool);
                Pool(pool).withdraw(msg.sender, swaps[swapId].tokenB, amount * (100 - _fee) / 100);
                Pool(pool).withdraw(owner(), swaps[swapId].tokenB, amount * _fee / 100);
            } else{
                uint256 amount = IERC20(swaps[swapId].tokenA).balanceOf(pool);
                Pool(pool).withdraw(msg.sender, swaps[swapId].tokenA, amount * (100 - _fee) / 100);
                Pool(pool).withdraw(owner(), swaps[swapId].tokenA, amount * _fee / 100);
            } 
        }else if(swaps[swapId].expiredTime < block.timestamp){
            if(msg.sender == swaps[swapId].partyA){
                uint256 amount = IERC20(swaps[swapId].tokenA).balanceOf(pool);
                Pool(pool).withdraw(msg.sender, swaps[swapId].tokenA, amount);
            } else{
                uint256 amount = IERC20(swaps[swapId].tokenB).balanceOf(pool);
                Pool(pool).withdraw(msg.sender, swaps[swapId].tokenB, amount);
            }
        } else {
            revert("Contract is not executed!");
        }
        emit Withdrawed(msg.sender, swapId);
    }

    /**
    * @dev users withdraw the swaped token 
    */  
    
    function checkExecuted(uint256 swapId) internal view returns (bool) {
        if(swaps[swapId].partyB == address(0)) return false;
        address pool = swaps[swapId].poolAddress;
        if( IERC20(swaps[swapId].tokenA).balanceOf(pool) >= swaps[swapId].amountA &&
            IERC20(swaps[swapId].tokenB).balanceOf(pool) >= swaps[swapId].amountB
            ) return true;        
        return false;        
    }

}
