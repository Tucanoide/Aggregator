// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

import "https://github.com/pancakeswap/pancake-smart-contracts/blob/master/projects/exchange-protocol/contracts/interfaces/IPancakeRouter01.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract testJPDR {

    using SafeMath for uint;

    address[3] addrRouters = [0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3,0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506,0xCDe540d7eAFE93aC5fE6233Bee57E1270D3E330F];

     struct sRet {
        bool bOk;
        uint toBuy;
        uint available;
        uint pos;
    }
  

    //Events
    event traePrecio(string, uint);


 function _oneGetAmountsOut(uint _id, uint _amountIn, address[] memory path) internal view returns (uint[] memory) {
    IPancakeRouter01 pRouter = IPancakeRouter01(addrRouters[_id]);
    return pRouter.getAmountsOut(_amountIn, path);
} // MyGetAmountsOut

//get price of each router in aDexes
//@return array with swaps information
function allGetAmountsOut(uint _amountIn, address tokenIn, address tokenOut) internal view returns (sRet memory, uint iPos ) {
    uint8  j = 0;
    uint[] memory x;
    uint iRet = 0;

    address[] memory path2 = new address[](2);
    path2[0] = tokenIn;
    path2[1] = tokenOut;

    sRet[] memory aRet = new sRet[](addrRouters.length);


    for (j=0; j<aRet.length; j++ ) {
        x = _oneGetAmountsOut(j, _amountIn, path2);
        aRet[j].toBuy = x[1];
        aRet[j].available = x[0];
        aRet[j].bOk = aRet[j].available == _amountIn;
        aRet[j].pos = j;
     }
    iPos = _getBestDex(aRet);
    iRet = iPos;
    if (iPos == 99) { //liquidity unavailable in all dexes
            iRet = 0;
     }

    return (aRet[iRet], iPos);
} // todosGetAmountOut

// look for cheapest dex with enough liquidity
// @return position of aRet or 99 if neither has liquidity
function _getBestDex(sRet[] memory aRet ) internal  pure returns (uint) {
    uint i =1;
    uint iRet = 99;
    if (aRet[0].bOk)  {iRet = 0;}
    
    for (i=1; i<aRet.length; i++) {
        if (aRet[i].bOk && aRet[i].toBuy > aRet[i-1].toBuy) {
            iRet = i;
        }
    }
    return iRet;
    }

function quote(
        uint amountIn, address tokenIn, address tokenOut) 
                external view returns (uint , address , address[] memory ) {

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        
        // get all dexes quote information
        sRet memory gRet;
        uint iPos;
        (gRet, iPos) = allGetAmountsOut( amountIn, tokenIn, tokenOut);
        require(iPos<99, "not liquidity available to swap");
        address retAddress;
        if (iPos == 99) {
            gRet.toBuy = 0;
             }
             else {
                 retAddress = addrRouters[gRet.pos];
             }
        return (gRet.toBuy, retAddress, path);
    }
function swapTokenForToken(uint _amountIn, 
                            uint _amountOutMin,
                            address _routerAddr,
                            address[] memory _path) external returns (uint amountOut) {

        IPancakeRouter01 router = IPancakeRouter01(_routerAddr);
        IERC20 Orig_token = IERC20(_path[0]);
 
        require (Orig_token.allowance(msg.sender, address(this))>=_amountIn, "Not enough allowance");

         Orig_token.transferFrom(
            msg.sender,
            address(this),
            _amountIn
        );
    
        Orig_token.approve(address(router), _amountIn);

        //slippage max 2%
        uint[] memory aAmounts;
        aAmounts = router.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            _path,
            msg.sender,
            block.timestamp + 5000
        ); 
        
        amountOut = aAmounts[1];
        return amountOut;
    }

}


 