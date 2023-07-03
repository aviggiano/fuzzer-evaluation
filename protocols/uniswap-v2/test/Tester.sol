pragma solidity ^0.8.0;
import "./Setup.sol";
import "./Asserts.sol";
import "@crytic/properties/contracts/util/PropertiesHelper.sol";

/// @title Foundry/Echidna compatible tester contract
/// @author Justin Jacob <@technovision99>, Antonio Viggiano <@agfviggiano>
/// @notice Serves as a compatible tester contract to compare foundry and echidna. This contract was largely inspired by @technovision99's work on the `crytic/echidna-streaming-series` repository.
/// @dev Contains all necessary functions to be called by stateful fuuzers.
abstract contract Tester is Setup, Asserts, PropertiesAsserts {
    function addLiquidity(uint amount1, uint amount2) public initUser {
        //PRECONDITIONS:
        amount1 = clampBetween(amount1, 1, type(uint256).max);
        amount2 = clampBetween(amount2, 1, type(uint256).max);

        _mintTokensOnce(amount1, amount2);

        _before();

        //ACTION:

        (bool success, ) = user.proxy(
            address(router),
            abi.encodeWithSelector(
                router.addLiquidity.selector,
                address(token1),
                address(token2),
                amount1,
                amount2,
                0,
                0,
                address(user),
                type(uint256).max
            )
        );

        _after();
        //POSTCONDITIONS

        if (success) {
            gt(
                vars.kAfter,
                vars.kBefore,
                "P-01 | Adding liquidity increases K"
            );
            gt(
                vars.lpTotalSupplyAfter,
                vars.lpTotalSupplyBefore,
                "P-02 | Adding liquidity increases the total supply of LP tokens"
            );
            gt(
                vars.reserve1After,
                vars.reserve1Before,
                "P-03 | Adding liquidity increases reserves of both tokens"
            );
            gt(
                vars.reserve2After,
                vars.reserve2Before,
                "P-03 | Adding liquidity increases reserves of both tokens"
            );
            gt(
                vars.userLpBalanceAfter,
                vars.userLpBalanceBefore,
                "P-04 | Adding liquidity increases the user's LP balance"
            );
            lt(
                vars.userBalance1After,
                vars.userBalance1Before,
                "P-05 | Adding liquidity decreases the user's token balances"
            );
            lt(
                vars.userBalance2After,
                vars.userBalance2Before,
                "P-05 | Adding liquidity decreases the user's token balances"
            );
            gte(
                vars.feeToLpBalanceAfter,
                vars.feeToLpBalanceBefore,
                "P-06 | Adding liquidity does not decrease the `feeTo` LP balance"
            );
            if (vars.kBefore == 0) {
                gt(
                    (amount1 * amount2),
                    vars.userLpBalanceAfter * vars.userLpBalanceAfter,
                    "P-07 | Adding liquidity for the first time should mint LP tokens equals to the square root of the product of the token amounts minus a minimum liquidity constant"
                );
            }
        } else {
            eq(
                vars.reserve1After,
                vars.reserve1Before,
                "P-08 | Adding liquidity should not change anything if it fails"
            );
            eq(
                vars.reserve2After,
                vars.reserve2Before,
                "P-08 | Adding liquidity should not change anything if it fails"
            );
            eq(
                vars.userLpBalanceAfter,
                vars.userLpBalanceBefore,
                "P-08 | Adding liquidity should not change anything if it fails"
            );
            eq(
                vars.feeToLpBalanceAfter,
                vars.feeToLpBalanceBefore,
                "P-08 | Adding liquidity should not change anything if it fails"
            );
            eq(
                vars.lpTotalSupplyAfter,
                vars.lpTotalSupplyBefore,
                "P-08 | Adding liquidity should not change anything if it fails"
            );
            eq(
                vars.userBalance1After,
                vars.userBalance1Before,
                "P-08 | Adding liquidity should not change anything if it fails"
            );
            eq(
                vars.userBalance2After,
                vars.userBalance2Before,
                "P-08 | Adding liquidity should not change anything if it fails"
            );
            eq(
                vars.kAfter,
                vars.kBefore,
                "P-08 | Adding liquidity should not change anything if it fails"
            );
            // TODO decode each error and break down revert conditions accordingly
            t(
                // UniswapV2: OVERFLOW
                // amounts overflow max reserve balance
                amount1 + vars.reserve1Before > type(uint112).max ||
                    amount2 + vars.reserve2Before > type(uint112).max ||
                    // UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED
                    // amounts do not pass minimum initial liquidity check
                    (amount1 * amount2) <=
                    pair.MINIMUM_LIQUIDITY() * pair.MINIMUM_LIQUIDITY() ||
                    // UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED
                    // amounts would mint zero liquidity
                    ((vars.pairBalance1Before - vars.reserve1Before) *
                        (vars.lpTotalSupplyBefore)) /
                        vars.reserve1Before ==
                    0 ||
                    ((vars.pairBalance2Before - vars.reserve2Before) *
                        (vars.lpTotalSupplyBefore)) /
                        vars.reserve2Before ==
                    0,
                "P-09 | Adding liquidity should not fail if the provided amounts are withing the valid range of `uint112`, would mint positive liquidity and are above the minimum initial liquidity check when minting for the first time"
            );
        }
    }

    function removeLiquidity(uint lpAmount) public initUser {
        //PRECONDITIONS:
        _before();

        //user needs some LP tokens to burn
        require(vars.userLpBalanceBefore > 0);
        lpAmount = clampBetween(lpAmount, 1, vars.userLpBalanceBefore);

        //need to approve more than min liquidity
        (bool success1, ) = user.proxy(
            address(pair),
            abi.encodeWithSelector(
                pair.approve.selector,
                address(router),
                type(uint256).max
            )
        );
        t(success1, "This call should never fail");

        //ACTION:

        (bool success, ) = user.proxy(
            address(router),
            abi.encodeWithSelector(
                router.removeLiquidity.selector,
                address(token1),
                address(token2),
                lpAmount,
                0,
                0,
                address(user),
                type(uint256).max
            )
        );

        _after();

        //POSTCONDITIONS

        if (success) {
            lt(
                vars.kAfter,
                vars.kBefore,
                "P-10 | Removing liquidity decreases K"
            );
            if (factory.feeTo() == address(0)) {
                lt(
                    vars.lpTotalSupplyAfter,
                    vars.lpTotalSupplyBefore,
                    "P-11 | Removing liquidity decreases the total supply of LP tokens if fee is off"
                );
            } else {
                gte(
                    vars.feeToLpBalanceAfter,
                    vars.feeToLpBalanceBefore,
                    "P-15 | Removing liquidity does not decrease the `feeTo` LP balance"
                );
            }
            lt(
                vars.reserve1After,
                vars.reserve1Before,
                "P-12 | Removing liquidity decreases reserves of both tokens"
            );
            lt(
                vars.reserve2After,
                vars.reserve2Before,
                "P-12 | Removing liquidity decreases reserves of both tokens"
            );
            lt(
                vars.userLpBalanceAfter,
                vars.userLpBalanceBefore,
                "P-13 | Removing liquidity decreases the user's LP balance"
            );
            gt(
                vars.userBalance1After,
                vars.userBalance1Before,
                "P-14 | Removing liquidity increases the user's token balances"
            );
            gt(
                vars.userBalance2After,
                vars.userBalance2Before,
                "P-14 | Removing liquidity increases the user's token balances"
            );
        } else {
            eq(
                vars.reserve1After,
                vars.reserve1Before,
                "P-16 | Removing liquidity should not change anything if it fails"
            );
            eq(
                vars.reserve2After,
                vars.reserve2Before,
                "P-16 | Removing liquidity should not change anything if it fails"
            );
            eq(
                vars.userLpBalanceAfter,
                vars.userLpBalanceBefore,
                "P-16 | Removing liquidity should not change anything if it fails"
            );
            eq(
                vars.feeToLpBalanceAfter,
                vars.feeToLpBalanceBefore,
                "P-16 | Removing liquidity should not change anything if it fails"
            );
            eq(
                vars.lpTotalSupplyAfter,
                vars.lpTotalSupplyBefore,
                "P-16 | Removing liquidity should not change anything if it fails"
            );
            eq(
                vars.userBalance1After,
                vars.userBalance1Before,
                "P-16 | Removing liquidity should not change anything if it fails"
            );
            eq(
                vars.userBalance2After,
                vars.userBalance2Before,
                "P-16 | Removing liquidity should not change anything if it fails"
            );
            eq(
                vars.kAfter,
                vars.kBefore,
                "P-16 | Removing liquidity should not change anything if it fails"
            );
            // amounts returned to the user must be greater than zero
            t(
                // UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED
                (lpAmount * vars.pairBalance1Before) /
                    vars.lpTotalSupplyBefore ==
                    0 ||
                    (lpAmount * vars.pairBalance2Before) /
                        vars.lpTotalSupplyBefore ==
                    0,
                "P-17 | Removing liquidity should not fail if the returned amounts to the user are greater than zero"
            );
        }
    }

    function swapExactTokensForTokens(uint swapAmountIn) public initUser {
        //PRECONDITIONS:

        _mintTokensOnce(swapAmountIn, swapAmountIn);
        _before();

        address[] memory path = new address[](2);
        path[0] = address(token1);
        path[1] = address(token2);

        require(vars.userBalance1Before > 0);

        swapAmountIn = clampBetween(swapAmountIn, 1, vars.userBalance1Before);

        //ACTION:

        (bool success, ) = user.proxy(
            address(router),
            abi.encodeWithSelector(
                router.swapExactTokensForTokens.selector,
                swapAmountIn,
                0,
                path,
                address(user),
                type(uint256).max
            )
        );

        _after();

        //POSTCONDITIONS:

        if (success) {
            gte(
                vars.kAfter,
                vars.kBefore,
                "P-18 | Swapping does not decrease K"
            );
            gt(
                vars.userBalance2After,
                vars.userBalance2Before,
                "P-19 | Swapping increases the sender's tokenOut balance"
            );
            eq(
                vars.userBalance1After,
                vars.userBalance1Before - swapAmountIn,
                "P-20 | Swapping decreases the sender's tokenIn balance by swapAmountIn"
            );
            gte(
                vars.feeToLpBalanceAfter,
                vars.feeToLpBalanceBefore,
                "P-21 | Swapping does not decrease the `feeTo` LP balance"
            );
        } else {
            uint[] memory amounts = UniswapV2Library.getAmountsOut(
                address(factory),
                swapAmountIn,
                path
            );
            // TODO decode each error and break down revert conditions accordingly
            t(
                // UniswapV2: INSUFFICIENT_LIQUIDITY
                amounts[1] > vars.reserve2Before ||
                    // UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT
                    amounts[1] == 0 ||
                    // UniswapV2: OVERFLOW
                    swapAmountIn + vars.reserve1Before > type(uint112).max,
                "P-22 | Swapping should not fail if there's enough liquidity, if the output would be positive and if the input would not overflow the valid range of `uint112`"
            );
        }
    }
}
