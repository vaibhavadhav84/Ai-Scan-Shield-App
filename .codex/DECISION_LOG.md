# Decisions
- Repository Markdown role contracts rather than fabricated configuration.
- One process with database-backed throttling for initial service; scale gate before multi-region use.
- Opaque random sessions hashed in storage rather than long-lived irrevocable JWTs.
- Never fetch target URLs: lexical checks avoid SSRF and disclose missing reputation.
- Default metadata-only history. Evidence redacted to indicator categories.
- Rule baseline works without models; training requires documented licensed labeled CSV.
- WAV-only initial audio support permits trustworthy size/duration/decoder validation.
