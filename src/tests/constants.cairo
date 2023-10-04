fn OWNER() -> starknet::ContractAddress {
    starknet::contract_address_const::<10>()
}

fn OTHER() -> starknet::ContractAddress {
    starknet::contract_address_const::<20>()
}

fn USER() -> starknet::ContractAddress {
    starknet::contract_address_const::<123>()
}

fn ZERO() -> starknet::ContractAddress {
    Zeroable::zero()
}

fn BLOCK_TIMESTAMP() -> u64 {
    103374042_u64
}

fn PUB_KEY() -> felt252 {
    0x3d5e3c3f8d051d2f57f50e913eabaa6871663ce221faccac31686b7823c40ec
}

fn SIG() -> (felt252, felt252) {
    (
        0x2f2731c575e2b59447ec7664756353848b974a9e6ef85bb9b03a9369ea3ad82,
        0x3c29c957a7a4c14c37c3a8deb7c2416aecf623c5c0669923888f1671eadc3e4
    )
}
