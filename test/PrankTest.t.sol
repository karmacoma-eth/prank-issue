// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";

contract Target {
    Target public nested;
    address public caller;
    address public origin;

    constructor(Target _nested) {
        nested = _nested;
    }

    function reset() public {
        caller = address(0);
        origin = address(0);

        if (address(nested) != address(0)) {
            nested.reset();
        }
    }

    function recordCaller() public {
        caller = msg.sender;
        origin = tx.origin;

        if (address(nested) != address(0)) {
            nested.recordCaller();
        }
    }
}

contract PrankTest is Test {
    Target target;

    address prankedSender;
    address prankedOrigin;

    function setUp() public {
        // setup a target with 2 layers of nested targets
        target = new Target(
            new Target(
                new Target(
                    Target(address(0))
                )
            )
        );

        prankedSender = makeAddr("prankedSender");
        prankedOrigin = makeAddr("prankedOrigin");
    }

    function testStartPrank() public {
        vm.startPrank(prankedSender, prankedOrigin);
        target.recordCaller();

        // for the outer call, we should see the pranked sender and origin
        assertEq(target.caller(), prankedSender);
        assertEq(target.origin(), prankedOrigin);

        // for the nested call, we should see the real sender and pranked origin
        assertEq(target.nested().caller(), address(target));
        assertEq(target.nested().origin(), prankedOrigin);

        // same for the double nested call
        assertEq(target.nested().nested().caller(), address(target.nested()));
        assertEq(target.nested().nested().origin(), prankedOrigin);

        // new calls are still pranked
        target.reset();
        target.recordCaller();

        assertEq(target.caller(), prankedSender);
        assertEq(target.origin(), prankedOrigin);

        assertEq(target.nested().caller(), address(target));
        assertEq(target.nested().origin(), prankedOrigin);
    }

    function testPrank() public {
        vm.prank(prankedSender, prankedOrigin);
        target.recordCaller();

        // for the outer call, we should see the pranked sender and origin
        assertEq(target.caller(), prankedSender);
        assertEq(target.origin(), prankedOrigin);

        // for the nested call, we should see the real sender and pranked origin
        assertEq(target.nested().caller(), address(target));
        assertEq(target.nested().origin(), prankedOrigin);  /// @dev <-- is this expected?

        // same for the double nested call
        assertEq(target.nested().nested().caller(), address(target.nested()));
        assertEq(target.nested().nested().origin(), prankedOrigin);  /// @dev <-- is this expected?

        // new calls are no longer pranked
        target.reset();
        target.recordCaller();

        assertEq(target.caller(), address(this));
        assertEq(target.origin(), tx.origin);

        assertEq(target.nested().caller(), address(target));
        assertEq(target.nested().origin(), tx.origin);
    }
}
