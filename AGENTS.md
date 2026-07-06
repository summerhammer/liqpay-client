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

The domain logic (signing, `pay`/`status` request/response models, status-outcome classification, webhook verification) was extracted from `fitnessart-backend`'s ad-hoc LiqPay integration, and the module/facade shape (`Client` → `.payments`/`.webhooks`, `LiqPayTransport` protocol, `LiqPayAction` protocol) was modeled after the sibling `CloverClient` package. See [ENDPOINTS.md](ENDPOINTS.md) for what's implemented vs. still to add.

## Architecture

- The core `LiqPayClient` module must stay transport-agnostic: it defines the LiqPay domain logic (requests, responses, signing) behind an abstraction, not tied to a specific HTTP client.
- Concrete transport implementations (e.g. an AsyncHTTPClient-backed or URLSession-backed client) belong in separate modules/targets, not in core.
- Framework-specific integrations (e.g. Vapor webhook handlers) belong in their own separate module (e.g. a future `LiqPayClientVapor` target), never folded into core.
- When adding a new transport or framework integration, add a new target/product in `Package.swift` rather than adding conditional code or optional dependencies to the core target.
- `Client` (this package's facade) and `Vapor.Client` share a name. Any file importing both `Vapor` and `LiqPayClient` must qualify as `LiqPayClient.Client` / `Vapor.Client` — don't rely on bare `Client` resolving correctly.

## Adding a new LiqPay action

1. Add an unchecked row to [ENDPOINTS.md](ENDPOINTS.md) if one doesn't already exist.
2. Model the action as a `Sources/LiqPayClient/Actions/<Name>Request.swift` type conforming to
   `LiqPayAction`, with a manual `CodingKeys`/`encode(to:)` matching LiqPay's exact wire field
   names (see `PayRequest`/`StatusRequest`). Reuse `LiqPayResponse`/`LiqPayOutcome` as the
   `Response` unless the action's payload genuinely differs.
3. If the action introduces a new terminal status (LiqPay's `status` field), extend
   `LiqPayOutcome`'s classification in `Responses/LiqPayOutcome.swift` — don't make callers
   re-derive LiqPay's status vocabulary themselves.
4. Expose it on the right `Client.*` sub-facade (add a method to `Client+Payments.swift`, or a new
   `Client+<Feature>.swift` extension file for a new feature area), following the "struct holding a
   back-reference, instantiated on demand via a computed property" pattern — see `Client.Payments`.
5. Add `TestFactories`/`MockTransport`-based tests asserting the exact wire field names/omissions
   (see `PayRequestEncodingTests`) and the facade method's signing/outcome behavior (see
   `ClientPaymentsChargeTests`).
6. Flip the checkbox in ENDPOINTS.md.

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
