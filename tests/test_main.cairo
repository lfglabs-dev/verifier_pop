%lang starknet
from src.main import write_confirmation, _public_key
from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256

@external
func test_write_confirmation{
    syscall_ptr: felt*, range_check_ptr, pedersen_ptr: HashBuiltin*, ecdsa_ptr: SignatureBuiltin*
}() {
    _public_key.write(394548025383543352001541730246698399463306544794665262133171506630376730361);
    let session_id = 17913625103421275213921058733762211084;
    let field = 'proof_of_personhood';
    %{
        stop_prank_callable = start_prank(123)
        stop_mock1 = mock_call(0, "owner_of", [123])
        stop_mock2 = mock_call(0, "set_verifier_data", [])
    %}
    write_confirmation(
        1,
        2 ** 128,
        field,
        session_id,
        (
            1881591246993787286057147333475879907753693413047647254737601007062639214435,
            349142476724544583196435363216250425327171526794190146578211647083703001625,
        ),
    );
    %{
        stop_prank_callable()
        stop_mock1()
        stop_mock2()
    %}
    return ();
}