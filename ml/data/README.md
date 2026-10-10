# Dataset policy
Training CSV columns: `text,label`; 0 and 1 label meanings must be documented in provenance.
No user-submitted content is added to training. Raw corpora are gitignored and never used as
application seed data. `scripts/prepare_uci_dataset.py` reads a fixed archive member without
extracting archive paths, and prepares the UCI SMS Spam Collection for offline evaluation.

UCI lists CC BY 4.0: https://archive.ics.uci.edu/dataset/228/sms+spam+collection
Attribution: SMS Spam Collection, 2011, DOI https://doi.org/10.24432/C5CC84.
Retain creator attribution from the dataset's DOI record when redistributing derived artifacts.
This dataset labels spam, not independently verified fraud. It is an older English corpus.
Do not deploy its model as a validated multi-channel fraud detector.
