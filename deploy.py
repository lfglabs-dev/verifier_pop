from starknet_py.net.models.chains import StarknetChainId
from starknet_py.net.gateway_client import GatewayClient
from starknet_py.net.udc_deployer.deployer import Deployer
from starknet_py.net.signer.stark_curve_signer import KeyPair
from starknet_py.net.account.account import Account

import asyncio
import json
import sys

argv = sys.argv

deployer_account_addr = (
    0xdd300675343f2f15bdc8107cac0b34b7e3194531314f9378110fc9081cbca4
)
deployer_account_private_key = int(argv[1])
# TESTNET: https://alpha4.starknet.io/
network_base_url = "https://alpha4.starknet.io/"
chainid: StarknetChainId = StarknetChainId.TESTNET
max_fee = int(1e16)
deployer = Deployer()
starknetid_contract = 0x783A9097B26EAE0586373B2CE0ED3529DDC44069D1E0FBC4F66D42B69D6850D
public_key = (
    394548025383543352001541730246698399463306544794665262133171506630376730361
)

async def main():
    client: GatewayClient = GatewayClient("testnet")
    account: Account = Account(
        client=client,
        address=deployer_account_addr,
        key_pair=KeyPair.from_private_key(deployer_account_private_key),
        chain=chainid
    )
    print("account", hex(account.address))
    nonce = await account.get_nonce()
    print("account nonce: ", nonce)

    verifier_file = open("./build/verifier.json", "r")
    verifier_content = verifier_file.read()
    verifier_file.close()
    declare_contract_tx = await account.sign_declare_transaction(
        compiled_contract=verifier_content, max_fee=max_fee
    )
    verifier_declaration = await client.declare(transaction=declare_contract_tx)
    verifier_json = json.loads(verifier_content)
    abi = verifier_json["abi"]
    print("verifier class hash:", hex(verifier_declaration.class_hash))
    deploy_call, address = deployer.create_deployment_call(
        class_hash=verifier_declaration.class_hash,
        abi=abi,
        calldata={
            "starknetid_contract": starknetid_contract,
            "public_key": public_key,
        },
    )

    resp = await account.execute(deploy_call, max_fee=int(1e16))
    print("deployment txhash:", hex(resp.transaction_hash))
    print("pop verifier contract address:", hex(address))


if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.run_until_complete(main())