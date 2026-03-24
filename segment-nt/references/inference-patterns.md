# Inference Patterns

Use this file for the grounded JAX inference patterns.

## SegmentNT

```python
import haiku as hk
import jax
import jax.numpy as jnp
from nucleotide_transformer.pretrained import get_pretrained_segment_nt_model

jax.config.update("jax_platform_name", "cpu")

devices = jax.devices("cpu")

parameters, forward_fn, tokenizer, config = get_pretrained_segment_nt_model(
    model_name="segment_nt",
    embeddings_layers_to_save=(29,),
    attention_maps_to_save=((1, 4), (7, 10)),
    max_positions=9,
)
forward_fn = hk.transform(forward_fn)
apply_fn = jax.pmap(forward_fn.apply, devices=devices, donate_argnums=(0,))

sequences = [
    "ATTCCGATTCCGATTCCAACGGATTATTCCGATTAACCGATTCCAATT",
    "ATTTCTCTCTCTCTCTGAGATCGATGATTTCTCTCTCATCGAACTATG",
]
tokens_ids = [b[1] for b in tokenizer.batch_tokenize(sequences)]
tokens = jnp.asarray(tokens_ids, dtype=jnp.int32)

random_key = jax.random.PRNGKey(seed=0)
keys = jax.device_put_replicated(random_key, devices=devices)
parameters = jax.device_put_replicated(parameters, devices=devices)
tokens = jax.device_put_replicated(tokens, devices=devices)

outs = apply_fn(parameters, keys, tokens)
logits = outs["logits"]
probabilities = jnp.asarray(jax.nn.softmax(logits, axis=-1))[..., -1]

idx_intron = config.features.index("intron")
probabilities_intron = probabilities[..., idx_intron]
```

## SegmentEnformer

Use `get_pretrained_segment_enformer_model()` with `hk.transform_with_state(...)`, then read features from `FEATURES`.

## SegmentBorzoi

Use `get_pretrained_segment_borzoi_model()` with `hk.transform_with_state(...)`, then read features from `FEATURES`.
