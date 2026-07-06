# Repository Guidelines

Guidance for Claude Code / Codex / Gemini when working with code in this repository.

## Recording learnings
When you learn a durable, project-level fact — build/test command, convention,
gotcha, architecture decision — record it in THIS file (AGENTS.md), concisely.
You may still use your own memory for personal or session-local notes, but 
project-level facts must not live only in a tool-specific store — put them here. 
Prune stale entries.

## Project

`LiqPayClient` is a Swift package for integrating with the LiqPay (liqpay.ua) payment platform from **server-side** Swift apps only. It encapsulates LiqPay's request/response and signing routines (base64-encoded payload + signature). It is not intended for use in client-side (iOS/macOS app) targets.

This is an early-stage package — `Package.swift` currently declares a single `LiqPayClient` library target with no dependencies yet; most functionality is still to be built.

## Architecture

- The core `LiqPayClient` module must stay transport-agnostic: it defines the LiqPay domain logic (requests, responses, signing) behind an abstraction, not tied to a specific HTTP client.
- Concrete transport implementations (e.g. an AsyncHTTPClient-backed or URLSession-backed client) belong in separate modules/targets, not in core.
- Framework-specific integrations (e.g. Vapor webhook handlers) belong in their own separate module (e.g. a future `LiqPayClientVapor` target), never folded into core.
- When adding a new transport or framework integration, add a new target/product in `Package.swift` rather than adding conditional code or optional dependencies to the core target.

## Platform

- Must run on Linux (Swift on Server), since this is intended for server-side deployment. Avoid Apple-only APIs (e.g. prefer `swift-crypto`'s `Insecure.SHA1` over `CryptoKit`, which is Apple-platform-only).
- Swift tools version 6.3, `swiftLanguageModes: [.v6]` — Swift 6 strict concurrency checking applies; new code must satisfy it (proper `Sendable` conformance, actor isolation) rather than opting out.

## Testing

- Tests use **swift-testing** (`import Testing`, `@Test`, `#expect`), not XCTest.
- Run tests with `swift test`.

## Repo conventions

- Use feature branches + PR review — do not commit directly to `main`.

## Linting

- Run `swiftlint lint` before committing (config in `.swiftlint.yml`). It is not wired into `Package.swift` as a build plugin so that consumers of this library aren't required to have SwiftLint installed to build it.
