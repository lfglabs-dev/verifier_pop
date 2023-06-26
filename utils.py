from starkware.crypto.signature.fast_pedersen_hash import pedersen_hash
from starkware.crypto.signature.signature import private_to_stark_key, sign

# 1576987121283045618657875225183003300580199140020787494777499595331436496159
def get_public_key(private_key):
    return private_to_stark_key(private_key)


# input: 1, 2**128, 32782392107492722, 707979046952239197, priv_key
# output: (242178274510413660320776612725275530442992398463760124282759555533509261346, 3369339735225989044856582139053547932849348534803432731455132141425388526099)
def generate_signature(token_id, expiration, type, data, private_key):
    hash = pedersen_hash(pedersen_hash(pedersen_hash(token_id, expiration), type), data)
    signed = sign(hash, private_key)
    return signed