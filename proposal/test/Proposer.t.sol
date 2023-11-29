// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2, console} from "forge-std/Test.sol";
import {iGovernorBravo, iVotingToken, IERC20} from "src/UniswapGov.sol";


struct DelegateeData {
    uint96 startingPower;
    uint96 expectedDelegation;
}

contract ProposalTest is Test {
    address wintermuteGov = 0xB933AEe47C438f22DE0747D57fc239FE37878Dd1;
    iGovernorBravo governanceContract;
    address timeLock;
    IERC20 uniswapToken = IERC20(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);
    iVotingToken uniVoting = iVotingToken(address(uniswapToken));


    address[] delegatees = [0xE93D59CC0bcECFD4ac204827eF67c5266079E2b5,0xB933AEe47C438f22DE0747D57fc239FE37878Dd1,0x3FB19771947072629C8EEE7995a2eF23B72d4C8A,0xECC2a9240268BC7a26386ecB49E1Befca2706AC9,0x1855f41B8A86e701E33199DE7C25d3e3830698ba,0x8787FC2De4De95c53e5E3a4e5459247D9773ea52,0xAac35d953Ef23aE2E61a866ab93deA6eC0050bcD];
    uint256[] delegateAmounts = [2250000000000000000000000,1900000000000000000000000,2250000000000000000000000,2499858000000000000000000,493972000000000000000000,452626000000000000000000,153544000000000000000000];
    address[] targets = [0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, 0xf754A7E347F81cFdc70AF9FbCCe9Df3D826360FA];
    uint[] values = [0,0];
    string[] sigs = ["", ""];
    bytes[] data;


    DelegateeData wintermute;
    DelegateeData errorDao;
    DelegateeData pGov;
    DelegateeData stableLab;
    DelegateeData keyrock;
    DelegateeData karpatkey;
    DelegateeData atis;


    function setUp() public {
        console.log("here");
        uint256 mainnetFork = vm.createFork(vm.envString("MAINNET_RPC_URL"),18676941);
        vm.selectFork(mainnetFork);

        governanceContract = iGovernorBravo(0x408ED6354d4973f66138C91495F2f2FCbd8724C3);
        timeLock = 0x1a9C8182C09F50C8318d769245beA52c32BE35BC;

        wintermute = DelegateeData({startingPower: uniVoting.getCurrentVotes(delegatees[1]), expectedDelegation: 1900000 * 10**18});
        errorDao = DelegateeData({startingPower: uniVoting.getCurrentVotes(delegatees[0]), expectedDelegation: 2250000 * 10**18});
        pGov = DelegateeData({startingPower: uniVoting.getCurrentVotes(delegatees[2]), expectedDelegation: 2250000 * 10**18});
        stableLab = DelegateeData({startingPower: uniVoting.getCurrentVotes(delegatees[3]), expectedDelegation: 2499858 * 10**18});
        keyrock = DelegateeData({startingPower: uniVoting.getCurrentVotes(delegatees[4]), expectedDelegation: 493972 * 10**18});
        karpatkey = DelegateeData({startingPower: uniVoting.getCurrentVotes(delegatees[5]), expectedDelegation: 452626 * 10**18});
        atis = DelegateeData({startingPower: uniVoting.getCurrentVotes(delegatees[6]), expectedDelegation: 153544 * 10**18});

        vm.startPrank(timeLock);
        governanceContract._setVotingDelay(1);
        governanceContract._setVotingPeriod(5761);
        uniswapToken.transfer(wintermuteGov, 60000000 * 10**18);
        vm.stopPrank();
        assertGe(uniswapToken.balanceOf(wintermuteGov), 60000000 * 10**18);
    }


    function executeSteps() internal {
        bytes memory approval_data = abi.encodeWithSignature("approve(address,uint256)", 0xf754A7E347F81cFdc70AF9FbCCe9Df3D826360FA, 10000000 * 10**18);
        bytes memory fundmany_data = abi.encodeWithSignature("fundMany(address[],uint256[])", delegatees, delegateAmounts);

        data.push(approval_data);
        data.push(fundmany_data);

        //Delegate from timelock to give Wintermute enough power to make a proposal + win a vote  
        vm.prank(timeLock);
        address(uniswapToken).call(abi.encodeWithSelector(0x5c19a95c, wintermuteGov));
        vm.roll(block.number + 1000);

        // Make the proposal
        vm.prank(wintermuteGov);
        uint256 id = governanceContract.propose(targets, values, sigs, data, "some description");
        
        vm.roll(block.number + 100);

        // Vote for the proposal
        vm.prank(wintermuteGov);
        governanceContract.castVote(id, 1);

        vm.roll(block.number + 5770);

        // Queue + Execute the proposal
        governanceContract.queue(id);
        vm.warp(block.timestamp + 172800);
        governanceContract.execute(id);
    }


    function test_Proposal() public {
        executeSteps();
        // Undo delegation to wintermute from the timelock.
        vm.prank(timeLock);
        address(uniswapToken).call(abi.encodeWithSelector(0x5c19a95c, timeLock));
        vm.roll(block.number + 1000);
        // Check if each delegate received the expected amount of UNI.
        assertEq(uniVoting.getCurrentVotes(delegatees[0]),errorDao.startingPower + errorDao.expectedDelegation );
        assertEq(uniVoting.getCurrentVotes(delegatees[1]),wintermute.startingPower + wintermute.expectedDelegation );
        assertEq(uniVoting.getCurrentVotes(delegatees[2]),pGov.startingPower + pGov.expectedDelegation );
        assertEq(uniVoting.getCurrentVotes(delegatees[3]),stableLab.startingPower + stableLab.expectedDelegation );
        assertEq(uniVoting.getCurrentVotes(delegatees[4]),keyrock.startingPower + keyrock.expectedDelegation );
        assertEq(uniVoting.getCurrentVotes(delegatees[5]),karpatkey.startingPower + karpatkey.expectedDelegation );
        assertEq(uniVoting.getCurrentVotes(delegatees[6]),atis.startingPower + atis.expectedDelegation );
    }
}
