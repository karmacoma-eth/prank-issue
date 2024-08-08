# Foundry prank semantics

For the following prank functions:

```solidity
function prank(address) external;
function prank(address sender, address origin) external;
```

The [Foundry Book](https://book.getfoundry.sh/cheatcodes/prank?highlight=prank#prank) has the following description:

```
Sets msg.sender to the specified address for the next call. “The next call” includes static calls as well, but not calls to the cheat code address.

If the alternative signature of prank is used, then tx.origin is set as well for the next call.
```

## The problem

If other calls happen during the "next call" (e.g. test calls A, and A calls B), are these calls also pranked? In other words, are nested calls part of the "next call"?

```solidity
import {Test, console} from "forge-std/Test.sol";

contract B {
    function bar() public {
        // is this pranked?
    }
}

contract A {
    B b;

    constructor(B _b) {
        b = _b;
    }

    function foo() public {
        b.bar(); // is this part of the pranked "next call"?
    }
}

contract TestPrank is Test {
    function testPrank() public {
        A a = new A(new B());

        vm.prank(makeAddr("sender"), makeAddr("origin"));

        // during this call, a calls b
        // are b's sender and origin pranked?
        a.foo();
    }
}
```

## Test

See [PrankTest.t.sol](https://github.com/karmacoma-eth/prank-issue/blob/main/test/PrankTest.t.sol#L91) for a functional test.

Currently, forge:
- pranks the sender and origin for the next outer call
- pranks the origin for all nested calls (i.e. nested calls inherit the origin prank from parent contexts, but not the sender prank)
