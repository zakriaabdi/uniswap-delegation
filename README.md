## Proposer.py
- This script serves two purposes, firstly for the deployer to send a proposal and for other delegates / Uniswap foundation to vet the call data submitted.
- For the latter purpose omit all flags/arguments when running i.e only do `python3 ./proposer.py`.
- Currently the proposal description, which is passed as a parameter to the proposal call is set as "some description" as a placeholder, but can be updated after everyone comes to an agreement for this arg.
- Uses Cast (part of Foundry) so Foundry must be installed


## Proposer directory
- Contains Forge project which tests the calldata.
- We check that after the proposal has been executed, the delegates should have the right amount of delegation we expected.
- Its a good idea to vet that the expectation itself is correct, i.e. the `delegatees` array (ln 21) and the `delegateAmounts` array (ln 22) are correct in `proposal/test/Proposer.t.sol`.
  
## Dependencies
- `pip install web3`
- `pip install eth-account`
- [Forge/Foundry](https://book.getfoundry.sh/getting-started/installation)

## How to test
- Ensure Foundry is intalled.
- `cd` into the proposal directory.
- Run `forge install`.
- Run `forge test -vv`. This will print the executed calldata to the terminal. Then you can compare this output with the output of the python script and see if they are identical.

