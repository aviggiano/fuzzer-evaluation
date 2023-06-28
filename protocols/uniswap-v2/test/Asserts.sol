pragma solidity ^0.8.0;
import "./Setup.sol";
import "@crytic/properties/contracts/util/PropertiesHelper.sol";

abstract contract Asserts is PropertiesAsserts {
    bool internal fail;

    function gt(uint256 a, uint256 b, string memory reason) internal {
        if (!(a > b)) {
            fail = true;
        }
        assertGt(a, b, reason);
    }

    function gte(uint256 a, uint256 b, string memory reason) internal {
        if (!(a >= b)) {
            fail = true;
        }
        assertGte(a, b, reason);
    }

    function lt(uint256 a, uint256 b, string memory reason) internal {
        if (!(a < b)) {
            fail = true;
        }
        assertLt(a, b, reason);
    }

    function lte(uint256 a, uint256 b, string memory reason) internal {
        if (!(a <= b)) {
            fail = true;
        }
        assertLte(a, b, reason);
    }

    function eq(uint256 a, uint256 b, string memory reason) internal {
        if (!(a == b)) {
            fail = true;
        }
        assertEq(a, b, reason);
    }

    function t(bool b, string memory reason) internal {
        if (!(b)) {
            fail = true;
        }
        assertWithMsg(b, reason);
    }
}
