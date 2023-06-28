pragma solidity ^0.8.0;

import "@uniswap/UniswapV2Pair.sol";
import "@uniswap/UniswapV2ERC20.sol";
import "@uniswap/UniswapV2Factory.sol";
import "@uniswap/contracts/libraries/UniswapV2Library.sol";
import "@uniswap/contracts/UniswapV2Router01.sol";
import "@crytic/properties/contracts/util/PropertiesHelper.sol";

contract Handler {
    function proxy(
        address _target,
        bytes memory _calldata
    ) public returns (bool success, bytes memory returnData) {
        (success, returnData) = address(_target).call(_calldata);
    }
}

contract Setup is PropertiesAsserts {
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

    function _init(uint256 amount1, uint256 amount2) internal initHandlers {
        if (complete) return;

        token2.mint(address(handlers[msg.sender]), amount2);
        token1.mint(address(handlers[msg.sender]), amount1);
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
        complete = true;
    }

    /*
    Helper function, copied from UniswapV2Library, needed in testPathIndependenceForSwaps.
    */
    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    /*
    Helper function, copied from UniswapV2Library, needed in testPathIndependenceForSwaps.
    */
    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) internal pure returns (uint amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * (997);
        amountIn = (numerator / denominator) + (1);
    }
}
