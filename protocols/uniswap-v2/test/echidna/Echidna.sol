pragma solidity ^0.8.0;
import "./Setup.sol";

contract Echidna is Setup {
    function echidnaTestProvideLiquidityInvariants(
        uint amount1,
        uint amount2
    ) public initHandlers {
        //PRECONDITIONS:
        amount1 = clampBetween(amount1, 1000, type(uint256).max);
        amount2 = clampBetween(amount2, 1000, type(uint256).max);
        _init(amount1, amount2);

        uint pairBalanceBefore = pair.balanceOf(address(handler));

        (uint reserve1Before, uint reserve2Before) = UniswapV2Library
            .getReserves(address(factory), address(token1), address(token2));

        uint kBefore = reserve1Before * reserve2Before;

        //CALL:

        (bool success, ) = handler.proxy(
            address(router),
            abi.encodeWithSelector(
                router.addLiquidity.selector,
                address(token1),
                address(token2),
                amount1,
                amount2,
                0,
                0,
                address(handler),
                type(uint256).max
            )
        );

        //POSTCONDITIONS

        if (success) {
            (uint reserve1After, uint reserve2After) = UniswapV2Library
                .getReserves(
                    address(factory),
                    address(token1),
                    address(token2)
                );
            uint pairBalanceAfter = pair.balanceOf(address(handler));
            uint kAfter = reserve1After * reserve2After;
            assertLt(kBefore, kAfter, "K must increase when adding liquidity");
            assertLt(
                pairBalanceBefore,
                pairBalanceAfter,
                "LP token balance must increase when adding liquidity"
            );
        }
    }

    function echidnaTestSwapTokens(uint swapAmountIn) public initHandlers {
        //PRECONDITIONS:
        _init(swapAmountIn, swapAmountIn);

        address[] memory path = new address[](2);
        path[0] = address(token1);
        path[1] = address(token2);

        uint prevBal1 = UniswapV2ERC20(path[0]).balanceOf(address(handler));
        uint prevBal2 = UniswapV2ERC20(path[1]).balanceOf(address(handler));

        require(prevBal1 > 0);
        swapAmountIn = clampBetween(swapAmountIn, 1, prevBal1);
        (uint reserve1Before, uint reserve2Before) = UniswapV2Library
            .getReserves(address(factory), address(token1), address(token2));
        uint kBefore = reserve1Before * reserve2Before;
        //CALL:
        (bool success, ) = handler.proxy(
            address(router),
            abi.encodeWithSelector(
                router.swapExactTokensForTokens.selector,
                swapAmountIn,
                0,
                path,
                address(handler),
                type(uint256).max
            )
        );
        //POSTCONDITIONS:

        if (success) {
            uint balance1After = UniswapV2ERC20(path[0]).balanceOf(
                address(handler)
            );
            uint balance2After = UniswapV2ERC20(path[1]).balanceOf(
                address(handler)
            );
            (uint reserve1After, uint reserve2After) = UniswapV2Library
                .getReserves(
                    address(factory),
                    address(token1),
                    address(token2)
                );
            uint kAfter = reserve1After * reserve2After;
            assertLte(kBefore, kAfter, "K must not decrease when swapping");
            assertLt(
                prevBal2,
                balance2After,
                "pool tokenOut balance must decrease when swapping"
            );
            assertGt(
                prevBal1,
                balance1After,
                "pool tokenIn balance must increase when swapping"
            );
        }
    }

    function echidnaTestRemoveLiquidityInvariants(
        uint lpAmount
    ) public initHandlers {
        //PRECONDITIONS:

        uint pairBalanceBefore = pair.balanceOf(address(handler));
        //handler needs some LP tokens to burn
        require(pairBalanceBefore > 0);
        lpAmount = clampBetween(lpAmount, 1, pairBalanceBefore);

        (uint reserve1Before, uint reserve2Before) = UniswapV2Library
            .getReserves(address(factory), address(token1), address(token2));
        //need to provide more than min liquidity
        uint kBefore = reserve1Before * reserve2Before;
        (bool success1, ) = handler.proxy(
            address(pair),
            abi.encodeWithSelector(
                pair.approve.selector,
                address(router),
                type(uint256).max
            )
        );
        require(success1);
        //CALL:

        (bool success, ) = handler.proxy(
            address(router),
            abi.encodeWithSelector(
                router.removeLiquidity.selector,
                address(token1),
                address(token2),
                lpAmount,
                0,
                0,
                address(handler),
                type(uint256).max
            )
        );

        //POSTCONDITIONS

        if (success) {
            (uint reserve1After, uint reserve2After) = UniswapV2Library
                .getReserves(
                    address(factory),
                    address(token1),
                    address(token2)
                );
            uint pairBalanceAfter = pair.balanceOf(address(handler));
            uint kAfter = reserve1After * reserve2After;
            assertGt(
                kBefore,
                kAfter,
                "K must decrease when removing liquidity"
            );
            assertGt(
                pairBalanceBefore,
                pairBalanceAfter,
                "LP token balance must decrease when removing liquidity"
            );
        }
    }

    /*
    Swapping x of token1 for y token of token2 and back should (roughly) give handler x of token1.
    The following function checks this condition by assessing that the resulting x is no more than 3% from the original x.
    
    However, this condition may be false when the pool has roughly the same amount of A and B and handler swaps minimal amount of tokens.
    For instance, if pool consists of:
    - 1000 A
    - 1500 B
    then handler can swap 2 A for 2 B (1002 * 1497 = 1 499 994 < 1 500 000 = k, so the handler won't get 3 B).
    Then, while handler swaps back 2 B in the pool, he will get only 1 A, which is 50% loss from initial 2 A. 

    Similar situation may happen if the handler pays for some constant amount of token2 more than he needs to.
    For instance, consider a pool with:
    - 20 000 of token A
    - 5 of token B
    Then, k = 100 000. If handler pays 10 000 of A, we will get only 1 token B (since otherwise new k < 100 000).
    Now, k = 120 000, and the pool consists of 30 000 A and 4 B. 
    If he swaps back 1 B for A, he gets only 6 000 A back (pool consists of 5 B and 24 000 A and k stays the same).
    So, after the trades, he lost 4 000 of A, which is 40% of his initial balance.
    But this wouldn't happen if handler swapped initially 5 000 of A for 1 B.
    
    To prevent such situations, the following function imposes following limits on the handler's input:
    1. It has to be greater than MINIMUM_AMOUNT = 100.
    2. For some amount y of token2, it has to be minimal among all inputs giving the handler y testTokens2 from the swap.
    */
    function echidnaTestPathIndependenceForSwaps(uint x) public initHandlers {
        // PRECONDITIONS:
        _init(1_000_000_000, 1_000_000_000);

        (uint reserve1, uint reserve2) = UniswapV2Library.getReserves(
            address(factory),
            address(token1),
            address(token2)
        );
        // if reserve1 or reserve2 <= 1, then we cannot even make a swap
        require(reserve1 > 1);
        require(reserve2 > 1);

        uint MINIMUM_AMOUNT = 100;
        uint userBalance1 = token1.balanceOf(address(handler));
        require(userBalance1 > MINIMUM_AMOUNT);

        x = clampBetween(x, MINIMUM_AMOUNT, type(uint256).max / 100); // uint(-1) / 100 needed in POSTCONDITIONS to avoid overflow
        x = clampBetween(x, MINIMUM_AMOUNT, userBalance1);

        // use optimal x - it makes no sense to pay more for a given amount of tokens than necessary
        // nor it makes sense to "buy" 0 tokens
        // scope created to prevent "stack too deep" error
        {
            uint yOut = getAmountOut(x, reserve1, reserve2);
            if (yOut == 0) yOut = 1;
            // x can only decrease here
            x = getAmountIn(yOut, reserve1, reserve2);
        }
        address[] memory path12 = new address[](2);
        path12[0] = address(token1);
        path12[1] = address(token2);
        address[] memory path21 = new address[](2);
        path21[0] = address(token2);
        path21[1] = address(token1);

        bool success;
        bytes memory returnData;
        uint[] memory amounts;
        uint xOut;
        uint y;

        // CALLS:
        (success, returnData) = handler.proxy(
            address(router),
            abi.encodeWithSelector(
                router.swapExactTokensForTokens.selector,
                x,
                0,
                path12,
                address(handler),
                type(uint256).max
            )
        );
        if (!success) return;
        amounts = abi.decode(returnData, (uint[]));
        // y should be the same as yOut computed previously
        y = amounts[1];
        (success, returnData) = handler.proxy(
            address(router),
            abi.encodeWithSelector(
                router.swapExactTokensForTokens.selector,
                y,
                0,
                path21,
                address(handler),
                type(uint256).max
            )
        );
        if (!success) return;
        amounts = abi.decode(returnData, (uint[]));
        xOut = amounts[1];

        // POSTCONDITIONS:
        assertGt(x, xOut, "handler cannot get more tokens than what they give");
        // 100 * (x - xOut) will not overflow since we constrained x to be < uint(-1) / 100 before
        assertLte((x - xOut) * 100, 3 * x, "maximum loss of funds is 3%"); // (x - xOut) / x <= 0.03;
    }
}
