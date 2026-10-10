# model-training
Inputs: Licensed labeled CSV and provenance.
Steps: Validate labels; deduplicate; split stratified held-out sets; train baseline; evaluate; serialize and hash.
Validation: No leakage; version checked; held-out report present.
Outputs: Artifact, manifest and honest evaluation.
Failure handling: retain diagnostics without secrets, fix reproducible failures, mark external blockers accurately; do not fabricate success.
