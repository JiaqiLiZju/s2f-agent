#!/usr/bin/env python3
"""Check whether an NTv3 sequence length satisfies the downsampling constraint."""

import argparse


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Validate NTv3 sequence lengths. Main 7-downsample models require "
            "length divisible by 128; 5-downsample models require length divisible by 32."
        )
    )
    parser.add_argument("length", type=int, help="Sequence length in nucleotides.")
    parser.add_argument(
        "--num-downsamples",
        type=int,
        default=7,
        help="Number of downsampling layers. Default: 7.",
    )
    args = parser.parse_args()

    if args.length <= 0:
        raise SystemExit("length must be positive")
    if args.num_downsamples < 0:
        raise SystemExit("num-downsamples must be non-negative")

    divisor = 2 ** args.num_downsamples
    remainder = args.length % divisor

    if remainder == 0:
        print(
            f"valid: length={args.length} is divisible by {divisor} "
            f"(num_downsamples={args.num_downsamples})"
        )
        return 0

    lower = args.length - remainder
    upper = lower + divisor
    print(
        f"invalid: length={args.length} is not divisible by {divisor} "
        f"(num_downsamples={args.num_downsamples})"
    )
    print(f"nearest_lower_valid={lower}")
    print(f"nearest_upper_valid={upper}")
    print("guidance=crop_to_lower_or_pad_with_N_to_upper")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
