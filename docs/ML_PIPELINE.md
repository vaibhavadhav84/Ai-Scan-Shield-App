# Model workflow
Rules work with empty MODEL_PATH and disclose that no trained model is loaded.
Training is a separate CLI with CSV text,label and provenance JSON source/license/label_definition.
Pipeline: NFKC Unicode and whitespace normalization -> remove duplicate/variable-number/URL templates -> discard
conflicting template labels -> deterministic stratified 70/15/15 train/validation/test split ->
TF-IDF word unigrams/bigrams -> class-balanced logistic regression -> held-out evaluation.
No test data fits vocabulary or weights. Hyperparameters are fixed; no test-set tuning.
Inference applies the same NFKC-whitespace-v1 contract and uses the model only for SMS inputs.
Versioned joblib includes its feature pipeline. Manifest includes schema, library version,
SHA-256 and dataset hash; inference fails configured corrupt/incompatible artifacts.

From project root:
```
python scripts/prepare_uci_dataset.py
python ml/training/train.py --dataset ml/data/uci_sms.csv --provenance ml/data/uci_provenance.json --output ml/artifacts/baseline.joblib
```
Downloaded UCI corpus is licensed CC BY 4.0, labels ham/spam, and is for offline SMS evaluation.
Spam is not verified fraud. Model remains disabled by default; do not market its metrics as
multi-channel scam accuracy. A production model needs representative fraud labels, modern
distribution, regional language evaluation, adversarial tests, calibration and drift review.
Never consume joblib artifacts from users. New model deployment requires trusted provisioning,
regression checks and rollback. User feedback is not automatic training input.
