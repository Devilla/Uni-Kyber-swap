// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswap {
    function swapExactTokensForTokens(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IKyberSwap {
    function swapTokensForExactTokens(
        uint amountOut, 
        uint amountInMax, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
}

contract TokenSwap {
    address private constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant KYBER_ROUTER_ADDRESS = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755;

    IUniswap public uniswapRouter;
    IKyberSwap public kyberRouter;
    IERC20 public tokenToBorrow;

    constructor(address _tokenToBorrow) {
        uniswapRouter = IUniswap(UNISWAP_ROUTER_ADDRESS);
        kyberRouter = IKyberSwap(KYBER_ROUTER_ADDRESS);
        tokenToBorrow = IERC20(_tokenToBorrow);
    }

    function swapAndReturn(address[] calldata _path) external {
        // Step 1: Borrow token from Uniswap
        uint amountOutMin = 0; // You can set the minimum amount you expect to receive
        uint deadline = block.timestamp + 300; // 5 minutes deadline
        tokenToBorrow.approve(address(uniswapRouter), type(uint).max);
        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            tokenToBorrow.balanceOf(address(this)),
            amountOutMin,
            _path,
            address(this),
            deadline
        );

        // Step 2: Swap borrowed token using KyberSwap
        uint amountInMax = amounts[amounts.length - 1]; // Use the received amount as maximum input
        IERC20 tokenToSwap = IERC20(_path[_path.length - 1]); // Get the token to swap
        tokenToSwap.approve(address(kyberRouter), type(uint).max);
        kyberRouter.swapTokensForExactTokens(
            tokenToBorrow.balanceOf(address(this)),
            amountInMax,
            _path,
            address(this),
            deadline
        );
        // Now, the token has been swapped using KyberSwap and should be available in this contract.
    }
}
