# Executed offline baseline evaluation
Executed on 2026-10-10 using Python 3.12.14, scikit-learn 1.6.1.
Dataset: licensed SMS Spam Collection; label 1 means spam, not independently verified fraud.
Source/license: https://archive.ics.uci.edu/dataset/228/sms+spam+collection (CC BY 4.0).
Dataset hash: `e4ff45a2a42d53e0dd0139bef2bb404a88fe897f36a26be27da62255df538494`. Seed 42.
After template deduplication: 5137 examples; split {'train': 3595, 'validation': 771, 'test': 771}.

| Held-out spam metric | Actual value |
|---|---|
| Precision | 0.926316 |
| Recall | 0.946237 |
| F1 | 0.936170 |
| PR-AUC (average precision) | 0.979566 |

Confusion matrix, rows actual ham/spam, columns predicted ham/spam:
`[[671, 7], [5, 88]]`. False positives 7, false negatives 5 on this held-out split.
These values are **SMS spam** evaluation only. They do not establish fraud detection accuracy,
voice/email/URL performance, multilingual performance or protection against current scams.
The model is uncalibrated and disabled by default. Rule risk scores are product heuristics.
Functional training/loading/checksum/version tests passed separately; synthetic tests are not
used to report accuracy. The raw corpus and model artifacts are gitignored; the aggregate
report is in ml/evaluation/baseline-report.json. Representative fraud validation is pending.
