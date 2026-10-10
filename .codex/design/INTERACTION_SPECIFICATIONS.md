# Interaction specifications
Retain GoRouter routes and auth redirect. Tab state should preserve unsent input in memory only; clear
session-owned state on sign-out. Channel changes retain separate drafts so a message is not silently treated
as a URL. Back/result navigation must return to the input. No repeated submit while pending.
Forms validate locally then accept authoritative server errors. Password visibility does not change storage.
Feedback/report forms retain entered text when submission fails; success closes only after server acceptance.
Deletion confirms specific consequences; privacy controls stay in Profile. URL preview is selectable text,
never a link. Fixed provider advisory navigation requires a clear external-navigation confirmation.
