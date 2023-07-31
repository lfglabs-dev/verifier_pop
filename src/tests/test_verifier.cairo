use array::ArrayTrait;
use result::ResultTrait;
use traits::Into;
use option::OptionTrait;

use starknet::ContractAddress;
use starknet::contract_address_const;
use starknet::testing;
use integer::u128_to_felt252;

use super::mocks::starknetid::{
    StarknetID, MockStarknetIDABIDispatcher, MockStarknetIDABIDispatcherTrait
};
use super::utils;
use verifier_contract::verifier::{
    Verifier, IVerifier, IVerifierDispatcher, IVerifierDispatcherTrait
};
use super::constants::{OWNER, USER};

#[cfg(test)]
fn deploy_starknetid() -> MockStarknetIDABIDispatcher {
    let address = utils::deploy(StarknetID::TEST_CLASS_HASH, ArrayTrait::<felt252>::new());
    MockStarknetIDABIDispatcher { contract_address: address }
}

#[cfg(test)]
fn deploy_verifier(starknetid_addr: ContractAddress) -> IVerifierDispatcher {
    let mut calldata = ArrayTrait::<felt252>::new();
    calldata.append(starknetid_addr.into());
    calldata.append(394548025383543352001541730246698399463306544794665262133171506630376730361);

    let address = utils::deploy(Verifier::TEST_CLASS_HASH, calldata);
    IVerifierDispatcher { contract_address: address }
}

#[cfg(test)]
#[test]
#[available_gas(2000000)]
fn test_write_confirmation() {
    // Deploy StarknetId contract
    let starknetid = deploy_starknetid();
    // Deploy verifier contract
    let verifier = deploy_verifier(starknetid.contract_address);

    // mint a starknetID for account USER()
    testing::set_caller_address(USER());
    testing::set_contract_address(USER());
    let token_id = 1;
    starknetid.mint(token_id);

    // Should write confirmation
    let session_id = 17913625103421275213921058733762211084;
    let timestamp = 1717096180;
    let field = 2507652182250236150756610039180649816461897572; // proof_of_personhood
    let sig = (
        1881591246993787286057147333475879907753693413047647254737601007062639214435,
        349142476724544583196435363216250425327171526794190146578211647083703001625
    );
    verifier.write_confirmation(token_id, timestamp, field, session_id, sig);
}

#[cfg(test)]
#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('Caller is not owner', 'ENTRYPOINT_FAILED', ))]
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
    testing::set_caller_address(OWNER());
    testing::set_contract_address(OWNER());
    // Should write confirmation
    let session_id = 17913625103421275213921058733762211084;
    let timestamp = 1717096180;
    let field = 'proof_of_personhood';
    let sig = (
        1881591246993787286057147333475879907753693413047647254737601007062639214435,
        349142476724544583196435363216250425327171526794190146578211647083703001625
    );
    verifier.write_confirmation(token_id, timestamp, field, session_id, sig);
}

#[cfg(test)]
#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('Confirmation is expired', 'ENTRYPOINT_FAILED', ))]
fn test_write_confirmation_failed_expired() {
    // Deploy StarknetId contract
    let starknetid = deploy_starknetid();
    // Deploy verifier contract
    let verifier = deploy_verifier(starknetid.contract_address);

    // mint a starknetID for account USER()
    testing::set_caller_address(USER());
    testing::set_contract_address(USER());
    let token_id = 1;
    starknetid.mint(token_id);

    // Trying to write confirmation with an expired timestamp should revert
    testing::set_block_timestamp(2017096180);
    // Should write confirmation
    let session_id = 17913625103421275213921058733762211084;
    let timestamp = 1717096180;
    let field = 'proof_of_personhood';
    let sig = (
        1881591246993787286057147333475879907753693413047647254737601007062639214435,
        349142476724544583196435363216250425327171526794190146578211647083703001625
    );
    verifier.write_confirmation(token_id, timestamp, field, session_id, sig);
}

#[cfg(test)]
#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('Signature is blacklisted', 'ENTRYPOINT_FAILED', ))]
fn test_write_confirmation_failed_blacklisted() {
    // Deploy StarknetId contract
    let starknetid = deploy_starknetid();
    // Deploy verifier contract
    let verifier = deploy_verifier(starknetid.contract_address);

    // mint a starknetID for account USER()
    testing::set_caller_address(USER());
    testing::set_contract_address(USER());
    let token_id = 1;
    starknetid.mint(token_id);

    // Trying to use the same signature twice should revert
    let session_id = 17913625103421275213921058733762211084;
    let timestamp = 1717096180;
    let field = 'proof_of_personhood';
    let sig = (
        1881591246993787286057147333475879907753693413047647254737601007062639214435,
        349142476724544583196435363216250425327171526794190146578211647083703001625
    );
    verifier.write_confirmation(token_id, timestamp, field, session_id, sig);
    verifier.write_confirmation(token_id, timestamp, field, session_id, sig);   
}

#[cfg(test)]
#[test]
#[available_gas(2000000)]
#[should_panic(expected: ('Invalid signature', 'ENTRYPOINT_FAILED', ))]
fn test_write_confirmation_failed_invalid_sig() {
    // Deploy StarknetId contract
    let starknetid = deploy_starknetid();
    // Deploy verifier contract
    let verifier = deploy_verifier(starknetid.contract_address);

    // mint a starknetID for account USER()
    testing::set_caller_address(USER());
    testing::set_contract_address(USER());
    let token_id = 1;
    starknetid.mint(token_id);

    // Trying to write with an invalid signature should fail
    let session_id = 17913625103421275213921058733762211084;
    let timestamp = 1717096180;
    let field = 'proof_of_personhood';
    let sig = (
        1,
        1
    );
    verifier.write_confirmation(token_id, timestamp, field, session_id, sig);
}
