pragma solidity ^0.8.0;

import "@uniswap/UniswapV2Pair.sol";
import "@uniswap/UniswapV2ERC20.sol";
import "@uniswap/UniswapV2Factory.sol";
import "@uniswap/contracts/libraries/UniswapV2Library.sol";
import "@uniswap/contracts/UniswapV2Router01.sol";

contract Handler {
    function proxy(
        address target,
        bytes memory _calldata
    ) public returns (bool success, bytes memory returnData) {
        (success, returnData) = address(target).call(_calldata);
    }
}

contract Setup {
    UniswapV2ERC20 token1;
    UniswapV2ERC20 token2;
    UniswapV2Pair pair;
    UniswapV2Factory factory;
    UniswapV2Router01 router;
    mapping(address => Handler) handlers;
    Handler handler;
    bool complete;

    constructor() {
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

    modifier initHandlers() {
        if (handlers[msg.sender] == Handler(address(0))) {
            handlers[msg.sender] = new Handler();
        }
        handler = handlers[msg.sender];
        _;
    }

    function _doApprovals() internal initHandlers {
        handlers[msg.sender].proxy(
            address(token1),
            abi.encodeWithSelector(
                token1.approve.selector,
                address(router),
                type(uint256).max
            )
        );
        handlers[msg.sender].proxy(
            address(token2),
            abi.encodeWithSelector(
                token2.approve.selector,
                address(router),
                type(uint256).max
            )
        );
    }

    function _init(uint256 amount1, uint256 amount2) internal initHandlers {
        token2.mint(address(handlers[msg.sender]), amount2);
        token1.mint(address(handlers[msg.sender]), amount1);
        _doApprovals();
        complete = true;
    }

    function _between(
        uint256 val,
        uint256 lower,
        uint256 upper
    ) internal pure returns (uint256) {
        return lower + (val % (upper - lower + 1));
    }
}
