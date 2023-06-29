pragma solidity ^0.8.0;
import "./Setup.sol";
import "./Asserts.sol";

abstract contract Tester is Setup, Asserts {
    struct Vars {
        uint256 pairBalanceBefore;
        uint256 pairBalanceAfter;
        uint256 pairTotalSupplyBefore;
        uint256 pairTotalSupplyAfter;
        uint256 balance1Before;
        uint256 balance2Before;
        uint256 balance1After;
        uint256 balance2After;
        uint256 reserve1Before;
        uint256 reserve1After;
        uint256 reserve2Before;
        uint256 reserve2After;
        uint256 kBefore;
        uint256 kAfter;
    }

    function addLiquidity(uint amount1, uint amount2) public initHandler {
        //PRECONDITIONS:

        Vars memory vars;

        amount1 = clampBetween(amount1, 1, type(uint256).max);
        amount2 = clampBetween(amount2, 1, type(uint256).max);
        _init(amount1, amount2);

        require(token1.balanceOf(address(handler)) > 0);
        require(token2.balanceOf(address(handler)) > 0);

        vars.pairBalanceBefore = pair.balanceOf(address(handler));
        vars.pairTotalSupplyBefore = pair.totalSupply();

        vars.balance1Before = token1.balanceOf(address(pair));
        vars.balance2Before = token2.balanceOf(address(pair));

        (vars.reserve1Before, vars.reserve2Before) = UniswapV2Library
            .getReserves(address(factory), address(token1), address(token2));

        vars.kBefore = vars.reserve1Before * vars.reserve2Before;

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
            (vars.reserve1After, vars.reserve2After) = UniswapV2Library
                .getReserves(
                    address(factory),
                    address(token1),
                    address(token2)
                );

            vars.pairBalanceAfter = pair.balanceOf(address(handler));
            vars.pairTotalSupplyAfter = pair.totalSupply();
            vars.kAfter = vars.reserve1After * vars.reserve2After;
            lt(
                vars.reserve1Before,
                vars.reserve1After,
                "Reserve 1 must increase when adding liquidity"
            );
            lt(
                vars.reserve2Before,
                vars.reserve2After,
                "Reserve 2 must increase when adding liquidity"
            );
            lt(
                vars.pairTotalSupplyBefore,
                vars.pairTotalSupplyAfter,
                "Total supply must increase when adding liquidity"
            );
            lt(
                vars.kBefore,
                vars.kAfter,
                "K must increase when adding liquidity"
            );
            lt(
                vars.pairBalanceBefore,
                vars.pairBalanceAfter,
                "LP token balance must increase when adding liquidity"
            );
            if (vars.kBefore == 0) {
                eq(
                    vars.pairBalanceAfter,
                    Math.sqrt(amount1 * amount2) - pair.MINIMUM_LIQUIDITY(),
                    "Adding liquidity for the first time should mint LP tokens equals to sqrt(amount1 * amount2) - MINIMUM_LIQUIDITY"
                );
            }
        } else {
            eq(
                pair.balanceOf(address(handler)),
                vars.pairBalanceBefore,
                "Adding liquidity should not mint LP tokens if the call fails"
            );
            t(
                // amounts overflow max reserve balance
                amount1 > type(uint112).max ||
                    amount2 > type(uint112).max ||
                    // amounts do not pass minimum initial liquidity check
                    Math.sqrt(amount1 * amount2) <= pair.MINIMUM_LIQUIDITY() ||
                    // amounts would mint zero liquidity
                    Math.min(
                        ((vars.balance1Before - vars.reserve1Before) *
                            (vars.pairTotalSupplyBefore)) / vars.reserve1Before,
                        ((vars.balance2Before - vars.reserve2Before) *
                            (vars.pairTotalSupplyBefore)) / vars.reserve2Before
                    ) ==
                    0,
                "Adding liquidity should only fail if the provided amounts is invalid"
            );
        }
    }

    function removeLiquidity(uint lpAmount) public initHandler {
        //PRECONDITIONS:
        Vars memory vars;

        vars.pairBalanceBefore = pair.balanceOf(address(handler));
        vars.pairTotalSupplyBefore = pair.totalSupply();
        //handler needs some LP tokens to burn
        require(vars.pairBalanceBefore > 0);
        lpAmount = clampBetween(lpAmount, 1, vars.pairBalanceBefore);

        (vars.reserve1Before, vars.reserve2Before) = UniswapV2Library
            .getReserves(address(factory), address(token1), address(token2));
        //need to approve more than min liquidity
        vars.kBefore = vars.reserve1Before * vars.reserve2Before;
        (bool success1, ) = handler.proxy(
            address(pair),
            abi.encodeWithSelector(
                pair.approve.selector,
                address(router),
                type(uint256).max
            )
        );
        require(success1);
        vars.balance1Before = token1.balanceOf(address(pair));
        vars.balance2Before = token2.balanceOf(address(pair));

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
            (vars.reserve1After, vars.reserve2After) = UniswapV2Library
                .getReserves(
                    address(factory),
                    address(token1),
                    address(token2)
                );
            vars.pairBalanceAfter = pair.balanceOf(address(handler));
            vars.pairTotalSupplyAfter = pair.totalSupply();
            vars.kAfter = vars.reserve1After * vars.reserve2After;
            gt(
                vars.kBefore,
                vars.kAfter,
                "K must decrease when removing liquidity"
            );
            gt(
                vars.pairBalanceBefore,
                vars.pairBalanceAfter,
                "LP token balance must decrease when removing liquidity"
            );

            gt(
                vars.reserve1Before,
                vars.reserve1After,
                "Reserve 1 must decrease when removing liquidity"
            );
            gt(
                vars.reserve2Before,
                vars.reserve2After,
                "Reserve 2 must decrease when removing liquidity"
            );
            gt(
                vars.pairTotalSupplyBefore,
                vars.pairTotalSupplyAfter,
                "Total supply must decrease when removing liquidity"
            );
        } else {
            eq(
                pair.balanceOf(address(handler)),
                vars.pairBalanceBefore,
                "Removing liquidity should not burn LP tokens if the call fails"
            );
            // amounts returned to the user must be greater than zero
            t(
                (lpAmount * vars.balance1Before) / vars.pairTotalSupplyBefore ==
                    0 ||
                    (lpAmount * vars.balance2Before) /
                        vars.pairTotalSupplyBefore ==
                    0,
                "Removing liquidity should never fail if the the returned amounts to the user are greater than zero"
            );
        }
    }

    function swapExactTokensForTokens(uint swapAmountIn) public initHandler {
        //PRECONDITIONS:

        Vars memory vars;
        _init(swapAmountIn, swapAmountIn);

        address[] memory path = new address[](2);
        path[0] = address(token1);
        path[1] = address(token2);

        vars.balance1Before = UniswapV2ERC20(path[0]).balanceOf(
            address(handler)
        );
        vars.balance2Before = UniswapV2ERC20(path[1]).balanceOf(
            address(handler)
        );

        uint feeToPairBalanceBefore = pair.balanceOf(factory.feeTo());

        require(vars.balance1Before > 0);

        swapAmountIn = clampBetween(swapAmountIn, 1, vars.balance1Before);
        (vars.reserve1Before, vars.reserve2Before) = UniswapV2Library
            .getReserves(address(factory), address(token1), address(token2));
        vars.kBefore = vars.reserve1Before * vars.reserve2Before;

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
            vars.balance1After = UniswapV2ERC20(path[0]).balanceOf(
                address(handler)
            );
            vars.balance2After = UniswapV2ERC20(path[1]).balanceOf(
                address(handler)
            );
            uint feeToPairBalanceAfter = pair.balanceOf(factory.feeTo());
            (vars.reserve1After, vars.reserve2After) = UniswapV2Library
                .getReserves(
                    address(factory),
                    address(token1),
                    address(token2)
                );
            vars.kAfter = vars.reserve1After * vars.reserve2After;
            lte(vars.kBefore, vars.kAfter, "K must not decrease when swapping");
            lt(
                vars.balance2Before,
                vars.balance2After,
                "pool tokenOut balance must decrease when swapping"
            );
            gt(
                vars.balance1Before,
                vars.balance1After,
                "pool tokenIn balance must increase when swapping"
            );
            gte(
                feeToPairBalanceAfter,
                feeToPairBalanceBefore,
                "Swapping does not decrease `feeTo` LP tokens balance"
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
    function swapExactTokensForTokensPathIndependence(
        uint x
    ) public initHandler {
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
            uint yOut = UniswapV2Library.getAmountOut(x, reserve1, reserve2);
            if (yOut == 0) yOut = 1;
            // x can only decrease here
            x = UniswapV2Library.getAmountIn(yOut, reserve1, reserve2);
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

        gt(x, xOut, "handler cannot get more tokens than what they give");
        // 100 * (x - xOut) will not overflow since we constrained x to be < uint(-1) / 100 before
        lte((x - xOut) * 100, 3 * x, "maximum loss of funds is 3%"); // (x - xOut) / x <= 0.03;
    }
}
