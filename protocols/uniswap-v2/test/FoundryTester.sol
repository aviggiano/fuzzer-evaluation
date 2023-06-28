pragma solidity ^0.8.0;
import "./Tester.sol";

contract FoundryTester is Tester {
    constructor(
        UniswapV2ERC20 _token1,
        UniswapV2ERC20 _token2,
        UniswapV2Pair _pair,
        UniswapV2Factory _factory,
        UniswapV2Router01 _router
    ) {
        token1 = _token1;
        token2 = _token2;
        pair = _pair;
        factory = _factory;
        router = _router;
    }
}
