# Tokenization And Limits

Use this file when the request depends on exact context size or tokenization behavior.

## 6-mer tokenization

Classic NT tokenizes DNA from left to right in 6-mers.

Examples grounded by the docs:

```python
dna_sequence_1 = "ACGTGTACGTGCACGGACGACTAGTCAGCA"
tokenized_dna_sequence_1 = [<CLS>,<ACGTGT>,<ACGTGC>,<ACGGAC>,<GACTAG>,<TCAGCA>]

dna_sequence_2 = "ACGTGTACNTGCACGGANCGACTAGTCTGA"
tokenized_dna_sequence_2 = [<CLS>,<ACGTGT>,<A>,<C>,<N>,<TGCACG>,<G>,<A>,<N>,<CGACTA>,<GTCTGA>]
```

## Important behavior

- The tokenizer does not group `N` into 6-mers.
- If the sequence length is not a multiple of 6, trailing nucleotides may be tokenized individually.
- This means effective token count depends on sequence content, not just raw length.

## Sequence limits

Grounded maximum nucleotide counts with no `N`:

- NT v1: up to 5,994 nucleotides
- NT v2: up to 12,282 nucleotides

These limits assume no `N` characters appear in the input.

## Practical guidance

- If the user is near the limit, mention that `N` bases may reduce usable context.
- Avoid promising an exact token count when the sequence contains `N` unless you can inspect the real tokenizer output.
