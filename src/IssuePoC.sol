// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// A simple contract to manage components (ERC20 tokens)
contract IssuePoC {
    address public owner;
    // Array to track all component addresses
    address[] internal components;
    // Mapping to store allocation data for each component
    mapping(address => ComponentAllocation) internal componentAllocations;
    // Timestamp of last rebalance
    uint64 public lastRebalance;
    // Duration window during which rebalancing is allowed
    uint64 public rebalanceWindow = 1 hours;
    
    // Struct to store component configuration
    struct ComponentAllocation {
        uint64 targetWeight;     // Target allocation percentage (scaled)
        uint64 maxDelta;         // Maximum allowed deviation from target
        address router;          // Router contract for this component
        bool isComponent;        // Flag to verify if address is a component
    }
    
    // Restricts function access to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    // Prevents actions during rebalancing periods
    modifier onlyWhenNotRebalancing() {
        require(block.timestamp >= lastRebalance + rebalanceWindow, "Rebalancing");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        // Initialize lastRebalance to allow immediate operations
        lastRebalance = uint64(block.timestamp - rebalanceWindow);
    }
    
    // Adds a new component to the portfolio
    function addComponent(address component) external onlyOwner {
        components.push(component);
        componentAllocations[component] = ComponentAllocation({
            targetWeight: 0,
            maxDelta: 0,
            router: address(0),
            isComponent: true
        });
    }
    
    // Removes a component from the portfolio
    // If force=true, burns any remaining balance by sending to dead address
    function removeComponent(address component, bool force) external onlyOwner onlyWhenNotRebalancing {
        // Check if component exists
        if (!componentAllocations[component].isComponent) revert("Not set");
        
        // If force is true, attempt to burn any remaining tokens
        if (force) {
            try IERC20(component).balanceOf(address(this)) returns (uint256 balance) {
                if (balance > 0) {
                    try IERC20(component).transfer(0x000000000000000000000000000000000000dEaD, balance) returns (bool) {}
                    catch {} // Ignore any transfer failures
                }
            } catch {} // Ignore any balanceOf failures
        }

        // Find and remove component from array
        uint256 length = components.length;
        for (uint256 i = 0; i < length; i++) {
            if (components[i] == component) {
                // Replace with last element (unless it is the last element)
                if (i != length - 1) {
                    components[i] = components[length - 1];
                }
                // Remove last element and delete allocation data
                components.pop();
                delete componentAllocations[component];
                return;
            }
        }
    }
    
    // Returns the list of all components
    function getComponents() external view returns (address[] memory) {
        return components;
    }
}