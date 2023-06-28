pragma solidity ^0.8.0;

contract Handler {
    function proxy(
        address _target,
        bytes memory _calldata
    ) public returns (bool success, bytes memory returnData) {
        (success, returnData) = address(_target).call(_calldata);
    }
}
