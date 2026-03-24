#!/usr/bin/env python3
"""Compute a SegmentNT rescaling factor from tokens or approximate base-pair length."""

import argparse
import math


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Compute the SegmentNT rescaling factor. If sequence length in base pairs is "
            "used, this assumes 6-mer tokenization with no N characters and includes the "
            "prepended CLS token."
        )
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--num-tokens-inference",
        type=int,
        help="Token count at inference time, including CLS if that matches your setup.",
    )
    group.add_argument(
        "--sequence-length-bp",
        type=int,
        help="Sequence length in base pairs. Assumes 6-mer tokenization with no N.",
    )
    parser.add_argument(
        "--trained-max-tokens",
        type=int,
        default=2048,
        help="Max token count used for the NT backbone during training. Default: 2048.",
    )
    args = parser.parse_args()

    if args.trained_max_tokens <= 0:
        raise SystemExit("trained-max-tokens must be positive")

    if args.num_tokens_inference is not None:
        if args.num_tokens_inference <= 0:
            raise SystemExit("num-tokens-inference must be positive")
        num_tokens = args.num_tokens_inference
        assumption = "provided_token_count"
    else:
        if args.sequence_length_bp <= 0:
            raise SystemExit("sequence-length-bp must be positive")
        num_tokens = math.ceil(args.sequence_length_bp / 6) + 1
        assumption = "estimated_from_bp_using_6mer_plus_cls"

    factor = num_tokens / args.trained_max_tokens
    print(f"num_tokens_inference={num_tokens}")
    print(f"trained_max_tokens={args.trained_max_tokens}")
    print(f"rescaling_factor={factor:.10f}")
    print(f"assumption={assumption}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
