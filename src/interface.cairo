#[starknet::interface]
trait IStarknetID<TContractState> {
    fn owner_of(self: @TContractState, token_id: felt252) -> starknet::ContractAddress;

    fn set_verifier_data(
        ref self: TContractState, token_id: felt252, field: felt252, data: felt252
    );
}
