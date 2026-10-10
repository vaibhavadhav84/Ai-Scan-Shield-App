# Screen Redesign
Entry conditions: Known screen owner and shared component contract.
Inspection: Inspect API calls, controllers, navigation, privacy and busy/error states.
Implementation: Restructure hierarchy using shared components; retain working actions and add recovery.
Quality checks: No fake data, lost actions, duplicate requests or inaccessible controls.
Failure handling: keep diagnostics free of private content; fix the concrete failure, rerun its relevant
check, and mark device/provider absence explicitly. Do not fabricate screenshots or test passes.
Completion: Screen works with actual responses and relevant behavior tests.
