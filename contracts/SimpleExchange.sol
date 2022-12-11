// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleExchange {
    address private _tokenA;
    address private _tokenB;
    address public partyA;
    address public partyB;
    uint256 private _expiredTime;
    uint8 withdrawed;

    struct Rate {
        uint128 numerator;
        uint128 denominator;
    }

    Rate private _rate;

    /**
    * @dev constructor function
    * @param expiredTime: timestamp is a Unix time stamp
    */

    constructor(address tokenA_, address tokenB_, uint128 rateNumerator, uint128 rateDenominator, uint256 expiredTime){
        _tokenA = tokenA_;
        _tokenB = tokenB_;
        _rate.numerator = rateNumerator;
        _rate.denominator = rateDenominator;
        _expiredTime = expiredTime;
    }

    /**
     * @dev agree function: users agree to this exchange;
     * @param select: if the value is true it means sign as a partyA.
     * if the value is false, it means sign as a partyB. 
     */
    function agree(bool select) external{
        if(select){
            require (partyA == address(0), "another one already sign this exchange");
            partyA = msg.sender;
        }
        else{
            require (partyB == address(0), "another one already sign this exchange");
            partyB = msg.sender;
        }
    }
    

    /**
     * @dev withdraw function:
     * if the contract is executed, users get the wanted Token
     * If not executed and the time is expired, the initial deposited token is returned
     */
    function withdraw() external {
        require(msg.sender == partyA || msg.sender == partyB, "You are not a member of this exchange");
        require(partyA != address(0) && partyB != address(0), "Two parties do not agree with this contract");
        if(msg.sender == partyA) {
            _withdrawA();
        } else{
            _withdrawB();
        }
        withdrawed++;
        if(withdrawed == 2) {
            withdrawed = 0;
            partyA = address(0);
            partyB = address(0);
        }
    }

    /**
     * @dev internal withdraw function for party A:
     */
    function _withdrawA() internal {
        if(checkExecuted()){
            uint256 balanceB = IERC20(_tokenB).balanceOf(address(this));
            IERC20(_tokenB).transfer(partyA, balanceB);
        } else if(block.timestamp > _expiredTime){
            uint256 balanceA = IERC20(_tokenA).balanceOf(address(this));
            IERC20(_tokenA).transfer(partyA, balanceA);
        } else{
            revert ("contract is not executed yet");
        }
    }

    /**
     * @dev internal withdraw function for party B:
     */
    function _withdrawB() internal {
        if(checkExecuted()){
            uint256 balanceA = IERC20(_tokenA).balanceOf(address(this));
            IERC20(_tokenA).transfer(partyB, balanceA);
        } else if(block.timestamp > _expiredTime){
            uint256 balanceB = IERC20(_tokenB).balanceOf(address(this));
            IERC20(_tokenB).transfer(partyB, balanceB);
        } else {
            revert ("contract is not executed yet");
        }
    }

    /**
     * @dev returns the value if the contract is executed or not:
     * true: executed;
     * false: not executed;
     */
    function checkExecuted() internal view returns (bool){
        uint256 balanceA = IERC20(_tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(_tokenA).balanceOf(address(this));
        if (balanceA*_rate.denominator == balanceB * _rate.numerator)return true;
        else return false;
    }

}
