# Responsive Ui Validation
Entry conditions: Screen implementation available.
Inspection: Identify fixed dimensions, nested scrolls, keyboard insets and text scaling assumptions.
Implementation: Exercise 320/390/430-wide layouts, 1x/2x text and keyboard-visible forms.
Quality checks: No RenderFlex overflow, clipped labels or inaccessible actions.
Failure handling: keep diagnostics free of private content; fix the concrete failure, rerun its relevant
check, and mark device/provider absence explicitly. Do not fabricate screenshots or test passes.
Completion: Passing scoped layout tests and inspected images; physical-device gaps disclosed.
