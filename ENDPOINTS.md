# LiqPay API coverage

LiqPay's entire API is a single endpoint, distinguished by an `action` field in the signed
payload — not one path per operation like a typical REST API:

```
POST https://www.liqpay.ua/api/request
Content-Type: application/x-www-form-urlencoded
Body: data=<base64 JSON>&signature=<base64 SHA1>
```

## Actions

- [x] `action=pay` — Charge a payment (`Client.Payments.charge`)
  - [x] ПРРО fiscalization — `rro_info` payload on `pay` (`LiqPayRROInfo`)
  - [x] Apple Pay — `paytype=apay` + `applepay_token` on `pay`
  - [x] Google Pay — `paytype=gpay` + `gpay_token` on `pay` (`LiqPayGooglePayToken`)
- [x] `action=status` — Query payment status by `order_id` (`Client.Payments.status`)
- [ ] `action=hold` — Hold funds for later capture
- [ ] `action=refund` — Refund a completed payment
- [ ] `action=subscribe` — Start a recurring subscription (`pay` with `subscribe=1` + periodicity params)
- [ ] `action=unsubscribe` — Cancel a recurring subscription
- [ ] `action=reports` — Fetch transaction reports for a date range
- [ ] `action=data` — Attach additional data to an existing order
- [ ] Checkout widget / button (client-rendered signed form via `https://www.liqpay.ua/api/3/checkout`, no server call) — hosted checkout

## Webhooks

- [x] Server callback (`server_url`) — verify signature, decode payment result (`Client.Webhooks.decode`)

## Known limitations

- LiqPay fiscalizes UAH payments only; `rro_info` is ignored for other currencies.
- Item `cost`/goods `id` consistency is validated by LiqPay server-side, not by this client.
- `LiqPayOutcome` doesn't yet have a dedicated case for `status: "reversed"` (a payment refunded
  out-of-band) — it currently falls through to `.pending`. Revisit once `refund` is implemented.
- Apple Pay token unwrapping (turning a full ApplePayJS wrapper into the `applepay_token` field
  LiqPay expects) is intentionally out of scope — that's an application-side concern, not a LiqPay
  API detail. `PayRequest.applePayToken` models the wire field only.
- Google Pay's decrypted-token flow (`paytype=gpay_tavv` with `tavv`/`card`/`card_exp_*`/`eci`/`cavv`)
  requires PCI DSS certification and is intentionally not modelled; only the encrypted-token flow
  (`gpay_token`, decrypted by LiqPay) is supported.
- LiqPay's Google Pay page documents `version: 7`; this client sends `Client.apiVersion` (3), which
  LiqPay accepts for `pay` — revisit if LiqPay starts rejecting it.

## Adding a new action

See the recipe in [AGENTS.md](AGENTS.md).
