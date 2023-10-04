use array::ArrayTrait;
use result::ResultTrait;
use traits::Into;
use option::OptionTrait;

use starknet::ContractAddress;
use starknet::{contract_address_const, get_block_timestamp};
use starknet::testing;
use super::utils;
use verifier_contract::verifier::{
    Verifier, IVerifier, IVerifierDispatcher, IVerifierDispatcherTrait
};
use super::constants::{OWNER, USER, PUB_KEY, SIG};
use identity::interface::identity::{IIdentityDispatcher, IIdentityDispatcherTrait};
use identity::identity::main::Identity;

fn deploy_starknetid() -> IIdentityDispatcher {
    let address = utils::deploy(Identity::TEST_CLASS_HASH, ArrayTrait::<felt252>::new());
    IIdentityDispatcher { contract_address: address }
}

fn deploy_verifier(starknetid_addr: ContractAddress) -> IVerifierDispatcher {
    let address = utils::deploy(
        Verifier::TEST_CLASS_HASH, array![starknetid_addr.into(), PUB_KEY()]
    );
    IVerifierDispatcher { contract_address: address }
}

#[test]
#[available_gas(2000000)]
fn test_write_confirmation() {
    // Deploy StarknetId contract
    let starknetid = deploy_starknetid();
    // Deploy verifier contract
    let verifier = deploy_verifier(starknetid.contract_address);

    // mint a starknetID for account USER()
    testing::set_contract_address(USER());
    let token_id = 1;
    starknetid.mint(token_id);

    // Should write confirmation
    let session_id = 17913625103421275213921058733762211084;
    let field = 2507652182250236150756610039180649816461897572; // proof_of_personhood
    verifier.write_confirmation(token_id, get_block_timestamp(), field, session_id, SIG());
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('Caller is not owner', 'ENTRYPOINT_FAILED',))]
fn test_write_confirmation_failed_not_owner() {
    // Deploy StarknetId contract
    let starknetid = deploy_starknetid();
    // Deploy verifier contract
    let verifier = deploy_verifier(starknetid.contract_address);

    // mint a starknetID for account USER()
    testing::set_caller_address(USER());
    testing::set_contract_address(USER());
    let token_id = 1;
    starknetid.mint(token_id);

    // Trying to write confirmation from a non-owner account should revert
    testing::set_contract_address(OWNER());
    let session_id = 17913625103421275213921058733762211084;
    let field = 'proof_of_personhood';
    verifier.write_confirmation(token_id, get_block_timestamp(), field, session_id, SIG());
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('Confirmation is expired', 'ENTRYPOINT_FAILED',))]
fn test_write_confirmation_failed_expired() {
    // Deploy StarknetId contract
    let starknetid = deploy_starknetid();
    // Deploy verifier contract
    let verifier = deploy_verifier(starknetid.contract_address);

    // mint a starknetID for account USER()
    testing::set_contract_address(USER());
    let token_id = 1;
    starknetid.mint(token_id);

    // Trying to write confirmation with an expired timestamp should revert
    testing::set_block_timestamp(2017096180);
    let session_id = 17913625103421275213921058733762211084;
    let field = 'proof_of_personhood';
    verifier.write_confirmation(token_id, 0, field, session_id, SIG());
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('Signature is blacklisted', 'ENTRYPOINT_FAILED',))]
fn test_write_confirmation_failed_blacklisted() {
    // Deploy StarknetId contract
    let starknetid = deploy_starknetid();
    // Deploy verifier contract
    let verifier = deploy_verifier(starknetid.contract_address);

    // mint a starknetID for account USER()
    testing::set_contract_address(USER());
    let token_id = 1;
    starknetid.mint(token_id);

    // Trying to use the same signature twice should revert
    let session_id = 17913625103421275213921058733762211084;
    let field = 'proof_of_personhood';
    verifier.write_confirmation(token_id, get_block_timestamp(), field, session_id, SIG());
    verifier.write_confirmation(token_id, get_block_timestamp(), field, session_id, SIG());
}

#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('Invalid signature', 'ENTRYPOINT_FAILED',))]
fn test_write_confirmation_failed_invalid_sig() {
    // Deploy StarknetId contract
    let starknetid = deploy_starknetid();
    // Deploy verifier contract
    let verifier = deploy_verifier(starknetid.contract_address);

    // mint a starknetID for account USER()
    testing::set_contract_address(USER());
    let token_id = 1;
    starknetid.mint(token_id);

    // Trying to write with an invalid signature should fail
    let session_id = 17913625103421275213921058733762211084;
    let field = 'proof_of_personhood';
    let sig = (1, 1);
    verifier.write_confirmation(token_id, get_block_timestamp(), field, session_id, sig);
}
