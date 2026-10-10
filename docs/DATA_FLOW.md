# Data flow
Input -> bounded validation -> Unicode-preserving normalization -> contextual/URL/metadata
feature extraction -> rules plus optional model/reputation -> 0-100 score -> templated
explanation -> persisted generic evidence -> preference-aware in-app alert.

Raw content is kept in process memory during a request and never written to scan history.
The immediate voice response includes its transcript for review; the persisted result excludes
it. WAV temporary files are removed on both success and failure. Original audio selected on
a user's device is not owned by the app; app-created recordings are temporary.
Feedback and report comments are separately stored, bounded, and must not contain secrets.
Reputation, when enabled, sends a URL to the configured provider. No target URL is fetched.
History caches contain result metadata only, expire for display after 24 hours, and clear on
sign-in/out, deletion or retention change. New scans require connectivity.
