%lang starknet
from starkware.cairo.common.math import assert_nn
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.hash import hash2
from starkware.cairo.common.signature import verify_ecdsa_signature
from starkware.starknet.common.syscalls import get_caller_address, get_block_timestamp
from starkware.cairo.common.math import assert_le_felt

@storage_var
func blacklisted_point(r) -> (blacklisted: felt) {
}

@storage_var
func _starknetid_contract() -> (starknetid_contract: felt) {
}

@storage_var
func _public_key() -> (public_key: felt) {
}

@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    starknetid_contract, public_key
) {
    _starknetid_contract.write(starknetid_contract);
    _public_key.write(public_key);
    return ();
}

@contract_interface
namespace StarknetID {
    func owner_of(token_id: felt) -> (owner: felt) {
    }

    func set_verifier_data(token_id: felt, field: felt, data: felt) {
    }
}

@external
func write_confirmation{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, ecdsa_ptr: SignatureBuiltin*
}(token_id: felt, timestamp: felt, field: felt, data: felt, sig: (felt, felt)) {
    //user address, id 
    let (caller) = get_caller_address();
    let (starknetid_contract) = _starknetid_contract.read();
    let (owner) = StarknetID.owner_of(starknetid_contract, token_id);

    assert caller = owner;

    // ensure confirmation is not expired
    let (current_timestamp) = get_block_timestamp();
    assert_le_felt(current_timestamp, timestamp);

    let (is_blacklisted) = blacklisted_point.read(sig[0]);
    assert is_blacklisted = 0;
    // blacklisting r should be enough since it depends on the "secure random point" it should never be used again
    // to anyone willing to improve this check in the future, please be careful with s, as (r, -s) is also a valid signature
    blacklisted_point.write(sig[0], 1);

    // message_hash = hash2(caller, data)
    let (message_hash) = hash2{hash_ptr=pedersen_ptr}(caller, data);
    let (public_key) = _public_key.read();
    verify_ecdsa_signature(message_hash, public_key, sig[0], sig[1]);
    StarknetID.set_verifier_data(starknetid_contract, token_id, field, 1);
    return ();
}