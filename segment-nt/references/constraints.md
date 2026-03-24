# Constraints

Use this file when the request depends on length handling or tokenizer assumptions.

## SegmentNT-specific constraints

- SegmentNT models were trained on sequences of `30,000` nucleotides.
- The docs state that SegmentNT generalizes up to `50,000` bp.
- SegmentNT does not handle `N` in the input sequence.
- The number of DNA tokens, excluding the prepended CLS token, must be divisible by `4`.

## Rescaling

For inference between `30 kb` and `50 kb`, the docs instruct the user to pass a `rescaling_factor` to `get_pretrained_segment_nt_model(...)`.

Use [scripts/compute_rescaling_factor.py](../scripts/compute_rescaling_factor.py) when the user gives a concrete sequence length. The helper assumes 6-mer tokenization with no `N` when converting base pairs to token count.

## SegmentEnformer and SegmentBorzoi examples

Grounded example sequence lengths in the docs:

- SegmentEnformer: `196_608`
- SegmentBorzoi: `524_288`
