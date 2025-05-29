# Slither Issue Proof of Concept

This repository contains a simplified version of a larger portfolio management contract that demonstrates a potential issue with token removal.

## Overview

`IssuePoC.sol` is a minimal implementation of a contract that:
- Manages a collection of ERC20 tokens as "components"
- Allows adding and removing components
- Includes a "force" removal option that attempts to burn tokens by sending them to a dead address

## Setup

This project uses Foundry for testing:

```
forge install openzeppelin/openzeppelin-contracts@v5.2.0
forge build
forge test --match-test test_issue -vvvv
```

Note: The test includes a timestamp warp to prevent underflow in the constructor when initializing `lastRebalance`.

## The Issue

The `removeComponent` function with `force=true` attempts to burn any remaining token balance by transferring tokens to the dead address (`0x000000000000000000000000000000000000dEaD`). 

Slither ran perfectly on all development until the nested try catch was added to this function

```solidity
function removeComponent(address component, bool force) external onlyOwner onlyWhenNotRebalancing {
        if (!_isComponent(component)) revert ErrorsLib.NotSet();
        if (!force && IRouter(componentAllocations[component].router).getComponentAssets(component, false) > 0) {
            revert ErrorsLib.NonZeroBalance();
        }

        if (force) {
            try IERC20(component).balanceOf(address(this)) returns (uint256 balance) {
                if (balance > 0) {
                    try IERC20(component).transfer(0x000000000000000000000000000000000000dEaD, balance) returns (bool) {}
                        catch {}
                }
            } catch {}
        }
```


## Error
Running ```slither . ``` produces the following error message

```shell
➜  slither-issue git:(main) slither .
'forge clean' running (wd: /Users/cormacdaly/Documents/Projects/slither-issue)
'forge config --json' running
'forge build --build-info --skip */test/** */script/** --force' running (wd: /Users/cormacdaly/Documents/Projects/slither-issue)
ERROR:SlitherSolcParsing:
Failed to convert IR to SSA for IssuePoC contract. Please open an issue https://github.com/crytic/slither/issues.
 
Traceback (most recent call last):
  File "/opt/homebrew/bin/slither", line 8, in <module>
    sys.exit(main())
             ^^^^^^
  File "/opt/homebrew/lib/python3.11/site-packages/slither/__main__.py", line 776, in main
    main_impl(all_detector_classes=detectors, all_printer_classes=printers)
  File "/opt/homebrew/lib/python3.11/site-packages/slither/__main__.py", line 882, in main_impl
    ) = process_all(filename, args, detector_classes, printer_classes)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/opt/homebrew/lib/python3.11/site-packages/slither/__main__.py", line 107, in process_all
    ) = process_single(compilation, args, detector_classes, printer_classes)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/opt/homebrew/lib/python3.11/site-packages/slither/__main__.py", line 80, in process_single
    slither = Slither(target, ast_format=ast, **vars(args))
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/opt/homebrew/lib/python3.11/site-packages/slither/slither.py", line 202, in __init__
    self._init_parsing_and_analyses(kwargs.get("skip_analyze", False))
  File "/opt/homebrew/lib/python3.11/site-packages/slither/slither.py", line 221, in _init_parsing_and_analyses
    raise e
  File "/opt/homebrew/lib/python3.11/site-packages/slither/slither.py", line 217, in _init_parsing_and_analyses
    parser.analyze_contracts()
  File "/opt/homebrew/lib/python3.11/site-packages/slither/solc_parsing/slither_compilation_unit_solc.py", line 593, in analyze_contracts
    self._convert_to_slithir()
  File "/opt/homebrew/lib/python3.11/site-packages/slither/solc_parsing/slither_compilation_unit_solc.py", line 835, in _convert_to_slithir
    raise e
  File "/opt/homebrew/lib/python3.11/site-packages/slither/solc_parsing/slither_compilation_unit_solc.py", line 830, in _convert_to_slithir
    contract.convert_expression_to_slithir_ssa()
  File "/opt/homebrew/lib/python3.11/site-packages/slither/core/declarations/contract.py", line 1571, in convert_expression_to_slithir_ssa
    func.generate_slithir_ssa(all_ssa_state_variables_instances)
  File "/opt/homebrew/lib/python3.11/site-packages/slither/core/declarations/function_contract.py", line 140, in generate_slithir_ssa
    add_ssa_ir(self, all_ssa_state_variables_instances)
  File "/opt/homebrew/lib/python3.11/site-packages/slither/slithir/utils/ssa.py", line 206, in add_ssa_ir
    fix_phi_rvalues_and_storage_ref(
  File "/opt/homebrew/lib/python3.11/site-packages/slither/slithir/utils/ssa.py", line 526, in fix_phi_rvalues_and_storage_ref
    fix_phi_rvalues_and_storage_ref(
  File "/opt/homebrew/lib/python3.11/site-packages/slither/slithir/utils/ssa.py", line 526, in fix_phi_rvalues_and_storage_ref
    fix_phi_rvalues_and_storage_ref(
  File "/opt/homebrew/lib/python3.11/site-packages/slither/slithir/utils/ssa.py", line 526, in fix_phi_rvalues_and_storage_ref
    fix_phi_rvalues_and_storage_ref(
  [Previous line repeated 7 more times]
  File "/opt/homebrew/lib/python3.11/site-packages/slither/slithir/utils/ssa.py", line 496, in fix_phi_rvalues_and_storage_ref
    variables = [
                ^
  File "/opt/homebrew/lib/python3.11/site-packages/slither/slithir/utils/ssa.py", line 497, in <listcomp>
    last_name(dst, ir.lvalue, init_local_variables_instances) for dst in ir.nodes
    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/opt/homebrew/lib/python3.11/site-packages/slither/slithir/utils/ssa.py", line 363, in last_name
    assert candidates
AssertionError
➜  slither-issue git:(main)
```
