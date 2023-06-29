pragma solidity ^0.8.0;

abstract contract SimpleMath {
    function min(uint256 a, uint256 b) public pure returns (uint256) {
        return a < b ? a : b;
    }
    function square(uint256 a) public pure returns (uint256) {
        return a * a;
    }
}
