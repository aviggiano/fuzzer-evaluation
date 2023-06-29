pragma solidity ^0.8.0;

import "@uniswap/UniswapV2Pair.sol";
import "@uniswap/UniswapV2ERC20.sol";
import "@uniswap/UniswapV2Factory.sol";
import "@uniswap/contracts/libraries/UniswapV2Library.sol";
import "@uniswap/contracts/UniswapV2Router01.sol";
import "./User.sol";

contract Setup {
    UniswapV2ERC20 internal token1;
    UniswapV2ERC20 internal token2;
    UniswapV2Pair internal pair;
    UniswapV2Factory internal factory;
    UniswapV2Router01 internal router;

    User internal user;

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

    function _mintTokens(uint256 amount1, uint256 amount2) internal {
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
}
