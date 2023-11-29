pragma solidity ^0.8.7;
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
/**
send our address 2.5 million uni
set votingdelay to 1
set delay on timelock to 0 (or min)
start block and end blockshould be changed
proposal should have more for votes than quorom votes
 */
interface iGovernorBravo {
    function propose(address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas, string memory description) external returns (uint);
    //set to 1
    function _setVotingDelay(uint newVotingDelay) external;
    // set to 5760 vote in between (blocks)
    function _setVotingPeriod(uint newVotingPeriod) external;
    function _setProposalThreshold(uint newProposalThreshold) external;
    function castVote(uint proposalId, uint8 support) external;
    function queue(uint proposalId) external;
    // Fast forward by 172801 seconds
    function execute(uint proposalId) external;
}

interface iVotingToken {

    function getCurrentVotes(address account) external view returns (uint96);
}