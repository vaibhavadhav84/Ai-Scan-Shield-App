# Accessibility Review
Entry conditions: Components and interactive screens available.
Inspection: Inspect contrast pairs, labels, focus order, control size and risk redundancy.
Implementation: Run Flutter guidelines and semantics assertions; fix failures and recheck.
Quality checks: 4.5:1 normal text, 3:1 large/nontext; 48px targets; reduced motion.
Failure handling: keep diagnostics free of private content; fix the concrete failure, rerun its relevant
check, and mark device/provider absence explicitly. Do not fabricate screenshots or test passes.
Completion: Actual checks recorded; do not equate semantics tests with full TalkBack/VoiceOver validation.
