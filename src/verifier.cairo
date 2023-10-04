#[starknet::interface]
trait IVerifier<TContractState> {
    fn write_confirmation(
        ref self: TContractState,
        token_id: u128,
        timestamp: u64,
        field: felt252,
        data: felt252,
        sig: (felt252, felt252)
    );
}

#[starknet::contract]
mod Verifier {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::get_block_timestamp;
    use traits::{TryInto, Into};
    use option::OptionTrait;
    use ecdsa::check_ecdsa_signature;

    use identity::interface::identity::{IIdentityDispatcher, IIdentityDispatcherTrait};

    #[storage]
    struct Storage {
        blacklisted_point: LegacyMap::<felt252, bool>,
        _starknetid_contract: ContractAddress,
        _public_key: felt252,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, starknetid_contract: ContractAddress, public_key: felt252
    ) {
        self._starknetid_contract.write(starknetid_contract);
        self._public_key.write(public_key);
    }

    #[external(v0)]
    impl VerifierImpl of super::IVerifier<ContractState> {
        fn write_confirmation(
            ref self: ContractState,
            token_id: u128,
            timestamp: u64,
            field: felt252,
            data: felt252,
            sig: (felt252, felt252)
        ) {
            let caller = get_caller_address();
            let starknetid_contract = self._starknetid_contract.read();
            let owner = IIdentityDispatcher { contract_address: starknetid_contract }
                .owner_of(token_id);
            assert(caller == owner, 'Caller is not owner');

            // ensure confirmation is not expired
            let current_timestamp = get_block_timestamp();
            assert(current_timestamp <= timestamp, 'Confirmation is expired');

            let (sig_0, sig_1) = sig;
            let is_blacklisted = self.blacklisted_point.read(sig_0);
            assert(!is_blacklisted, 'Signature is blacklisted');

            // blacklisting r should be enough since it depends on the "secure random point" it should never be used again
            // to anyone willing to improve this check in the future, please be careful with s, as (r, -s) is also a valid signature
            self.blacklisted_point.write(sig_0, true);

            let message_hash: felt252 = hash::LegacyHash::hash(caller.into(), data);
            let public_key = self._public_key.read();
            let is_valid = check_ecdsa_signature(message_hash, public_key, sig_0, sig_1);
            assert(is_valid, 'Invalid signature');

            IIdentityDispatcher { contract_address: starknetid_contract }
                .set_verifier_data(token_id, field, 1, 0);
        }
    }
}
