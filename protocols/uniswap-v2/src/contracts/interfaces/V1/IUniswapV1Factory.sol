pragma solidity ^0.8.0;

interface IUniswapV1Factory {
    function getExchange(address) external view returns (address);
}
