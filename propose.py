from web3 import Web3, HTTPProvider
import argparse
import subprocess
from eth_account.account import Account, LocalAccount

parser = argparse.ArgumentParser()
parser.add_argument("--private-key", required=False)
parser.add_argument("--rpc-url", help="Specify RPC endpoint with https or http if local", required=False)
parser.add_argument("--is-deployment", help="set if you are the deployer", action="store_true", default=False, required=False)
args = parser.parse_args()

w3: Web3 | None = None
account: LocalAccount | None = None
if args.is_deployment:
    w3 =  Web3(HTTPProvider(args.rpc_url))
    account  = Account.from_key(args.private_key)

    assert input(f"Transaction sender address is: {w3.to_checksum_address(account.address)}, type 'yes' to continue: \n") == "yes"

# helper
def decimals(num, dec):
    return str(num) + "0" * dec


# Generate call data to approve FranchiserFactory contract to spend timelock funds
proc: subprocess.CompletedProcess = subprocess.run([
    "cast", "calldata", "approve(address,uint256)", "0xf754A7E347F81cFdc70AF9FbCCe9Df3D826360FA", decimals(10000000,18)
], capture_output=True, check=True)
approve_calldata = str(proc.stdout, 'UTF-8')


# Generate calldata to create Franchiser contract for each delegate
delegate_targets = "[0xE93D59CC0bcECFD4ac204827eF67c5266079E2b5,0xB933AEe47C438f22DE0747D57fc239FE37878Dd1,0x3FB19771947072629C8EEE7995a2eF23B72d4C8A,0xECC2a9240268BC7a26386ecB49E1Befca2706AC9,0x1855f41B8A86e701E33199DE7C25d3e3830698ba,0x8787FC2De4De95c53e5E3a4e5459247D9773ea52,0xAac35d953Ef23aE2E61a866ab93deA6eC0050bcD]"
delegate_amounts = f'[{decimals(2250000, 18)},{decimals(1900000, 18)},{decimals(2250000, 18)},{decimals(2499858, 18)},{decimals(493972, 18)},{decimals(452626, 18)},{decimals(153544,18)}]'

proc: subprocess.CompletedProcess = subprocess.run([
    "cast", "calldata", "fundMany(address[],uint256[])", delegate_targets, delegate_amounts
], capture_output=True, check=True)
franchiser_fund_many_calldata = str(proc.stdout, 'UTF-8')


# Use the above to generate calldata to make a proposal to Governor Bravo
proposal_targets = '[0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984,0xf754A7E347F81cFdc70AF9FbCCe9Df3D826360FA]'
proposal_values ='[0,0]'
# defined in the calldata so this is redundant
proposal_signatures = '["",""]'
proposal_calldatas = f'[{approve_calldata[:len(approve_calldata) - 1]},{franchiser_fund_many_calldata[:len(franchiser_fund_many_calldata) - 1]}]'


proc: subprocess.CompletedProcess = subprocess.run([
    "cast", "calldata", "propose(address[],uint[],string[],bytes[],string)",
    proposal_targets, proposal_values, proposal_signatures, proposal_calldatas, "some description"
], capture_output=True, check=True)
final_calldata  = str(proc.stdout, 'UTF-8')
final_calldata = final_calldata[:len(final_calldata) - 1]

if args.is_deployment: 
    transaction = {
        'from': account.address,
        'to': w3.to_checksum_address("0x408ed6354d4973f66138c91495f2f2fcbd8724c3"),
        'value': 0,
        'nonce': w3.eth.get_transaction_count(account.address),
        'gas': 1000000,
        'gasPrice': w3.eth.gas_price,
        "data": final_calldata
    }


    raw_signed_tx = account.sign_transaction(transaction)
    tx = w3.eth.send_raw_transaction(raw_signed_tx.rawTransaction)
    receipt = w3.eth.wait_for_transaction_receipt(tx)
    print(receipt)
else:
    print("Final Call data that will be sent to propose() call on GovernorBravo: ")
    print(final_calldata)
