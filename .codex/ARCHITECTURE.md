# Architecture
Flutter -> versioned HTTPS JSON/multipart API -> authorization -> detection service -> database.
Detection separates rules, scoring, explanations and optional versioned model inference.
Opaque hashed sessions support revocation; hashed one-time email tokens support verification/reset.
External providers are opt-in, bounded and explicit about unavailable configuration.
Audio WAV validation precedes local speech transcription; no destination URL is fetched.
See docs/ARCHITECTURE.md and docs/THREAT_MODEL.md for maintained design.
