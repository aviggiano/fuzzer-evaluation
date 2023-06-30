pragma solidity ^0.8.0;

import "@uniswap/UniswapV2Pair.sol";
import "@uniswap/UniswapV2ERC20.sol";
import "@uniswap/UniswapV2Factory.sol";
import "@uniswap/contracts/libraries/UniswapV2Library.sol";
import "@uniswap/contracts/UniswapV2Router01.sol";
import "./User.sol";

/// @title Foundry/Echidna compatible setup contract
/// @author Justin Jacob <@technovision99>, Antonio Viggiano <@agfviggiano>
/// @notice Serves as a compatible setup contract to compare foundry and echidna. This contract was largely inspired by @technovision99's work on the `crytic/echidna-streaming-series` repository.
/// @dev Contains modifiers and initialization functions common to both frameworks, in addition to deploment functions that must be applied at different stages. See specific tester contracts for more information.
contract Setup {
    struct Vars {
        uint256 userLpBalanceBefore;
        uint256 userLpBalanceAfter;
        uint256 feeToLpBalanceBefore;
        uint256 feeToLpBalanceAfter;
        uint256 lpTotalSupplyBefore;
        uint256 lpTotalSupplyAfter;
        uint256 pairBalance1Before;
        uint256 pairBalance2Before;
        uint256 pairBalance1After;
        uint256 pairBalance2After;
        uint256 userBalance1Before;
        uint256 userBalance2Before;
        uint256 userBalance1After;
        uint256 userBalance2After;
        uint256 reserve1Before;
        uint256 reserve1After;
        uint256 reserve2Before;
        uint256 reserve2After;
        uint256 kBefore;
        uint256 kAfter;
    }
    UniswapV2ERC20 internal token1;
    UniswapV2ERC20 internal token2;
    UniswapV2Pair internal pair;
    UniswapV2Factory internal factory;
    UniswapV2Router01 internal router;

    User internal user;
    Vars internal vars;

    bool private complete;

    modifier initUser() {
        if (user == User(address(0))) {
            user = new User();
        }

        _;
    }

    function _deploy() internal {
        token1 = new UniswapV2ERC20();
        token2 = new UniswapV2ERC20();
        factory = new UniswapV2Factory(address(this)); //this contract will be the fee setter
        router = new UniswapV2Router01(address(factory), address(0)); // we don't need to test WETH pairs for now
        pair = UniswapV2Pair(
            factory.createPair(address(token1), address(token2))
        );
        // Sort the test tokens we just created, for clarity when writing invariant tests later
        (address testTokenA, address testTokenB) = UniswapV2Library.sortTokens(
            address(token1),
            address(token2)
        );
        token1 = UniswapV2ERC20(testTokenA);
        token2 = UniswapV2ERC20(testTokenB);
    }

    function _mintTokensOnce(uint256 amount1, uint256 amount2) internal {
        // NOTE This initial setup is done only once across the whole fuzzing campaign. You may get different results if you allow minting to happen every time.
        if (complete) return;

        token2.mint(address(user), amount2);
        token1.mint(address(user), amount1);
        user.proxy(
            address(token1),
            abi.encodeWithSelector(
                token1.approve.selector,
                address(router),
                type(uint256).max
            )
        );
        user.proxy(
            address(token2),
            abi.encodeWithSelector(
                token2.approve.selector,
                address(router),
                type(uint256).max
            )
        );
        complete = true;
    }

    function _before() internal {
        (vars.reserve1Before, vars.reserve2Before) = UniswapV2Library
            .getReserves(address(factory), address(token1), address(token2));
        vars.userLpBalanceBefore = pair.balanceOf(address(user));
        vars.feeToLpBalanceBefore = pair.balanceOf(factory.feeTo());
        vars.lpTotalSupplyBefore = pair.totalSupply();
        vars.userBalance1Before = token1.balanceOf(address(user));
        vars.userBalance2Before = token2.balanceOf(address(user));
        vars.pairBalance1Before = token1.balanceOf(address(pair));
        vars.pairBalance2Before = token2.balanceOf(address(pair));
        vars.userBalance1Before = token1.balanceOf(address(user));
        vars.userBalance2Before = token2.balanceOf(address(user));
        vars.kBefore = vars.reserve1Before * vars.reserve2Before;
    }

    function _after() internal {
        (vars.reserve1After, vars.reserve2After) = UniswapV2Library.getReserves(
            address(factory),
            address(token1),
            address(token2)
        );
        vars.userLpBalanceAfter = pair.balanceOf(address(user));
        vars.feeToLpBalanceAfter = pair.balanceOf(factory.feeTo());
        vars.lpTotalSupplyAfter = pair.totalSupply();
        vars.userBalance1After = token1.balanceOf(address(user));
        vars.userBalance2After = token2.balanceOf(address(user));
        vars.pairBalance1After = token1.balanceOf(address(pair));
        vars.pairBalance2After = token2.balanceOf(address(pair));
        vars.userBalance1After = token1.balanceOf(address(user));
        vars.userBalance2After = token2.balanceOf(address(user));
        vars.kAfter = vars.reserve1After * vars.reserve2After;
    }
}
