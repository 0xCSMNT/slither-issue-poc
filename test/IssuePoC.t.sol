// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "lib/openzeppelin-contracts/lib/forge-std/src/mocks/MockERC20.sol";
import {IssuePoC} from "../src/IssuePoC.sol";

contract IssuePoCTest is Test {
    IssuePoC public issuePoC;
    MockERC20 public token;

    function setUp() public {
        // Warp to a timestamp higher than rebalanceWindow (1 hour = 3600 seconds)
        vm.warp(3600 * 2); // Set timestamp to 2 hours
        
        issuePoC = new IssuePoC();
        token = new MockERC20();
        token.initialize("Test Token", "TT", 18);
    }

    function test_issue() public {
        // First, add the token as a component
        issuePoC.addComponent(address(token));
        
        // Check if component was added correctly
        address[] memory components = issuePoC.getComponents();
        assertEq(components.length, 1);
        assertEq(components[0], address(token));
        
        // Send tokens to the contract
        deal(address(token), address(issuePoC), 1e18);
        assertEq(token.balanceOf(address(issuePoC)), 1e18);

        // Remove the component with force=true to burn tokens
        issuePoC.removeComponent(address(token), true);
        
        // Verify tokens were sent to dead address
        assertEq(token.balanceOf(address(issuePoC)), 0);
        assertEq(token.balanceOf(address(0x000000000000000000000000000000000000dEaD)), 1e18);
        
        // Verify component was removed from the list
        components = issuePoC.getComponents();
        assertEq(components.length, 0);
    }
}