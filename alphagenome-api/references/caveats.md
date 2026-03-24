# Caveats And Troubleshooting

Use this file to keep responses grounded in the bundled AlphaGenome README.

## Capability and scale limits

- Treat AlphaGenome as suitable for small to medium analyses.
- Expect the API to handle thousands of predictions more comfortably than very large production-scale workloads.
- Push back on plans that require more than 1,000,000 predictions, because the README says the API is likely not suitable at that scale.
- Keep each DNA sequence request at or below 1,000,000 base pairs.

## Licensing and access

- Assume non-commercial use unless the user says they have another arrangement.
- Remind the user that the API requires an API key.
- Point the user to official terms or documentation when the task has compliance implications.

## Common failure checks

Run these checks in order:

1. Verify the package is installed in the active Python environment.
2. Verify the API key is present and passed to `dna_client.create(...)`.
3. Verify chromosome names, coordinates, and allele strings.
4. Reduce `requested_outputs` to the smallest needed set.
5. Re-check whether an `ontology_terms` value is required for the selected assay.

## Conservative guidance

- Do not invent unsupported helper functions or output enums.
- Confirm symbols that are not listed in the skill's grounded API surface before using them.
- Prefer a short working example over a broad but speculative code sample.
