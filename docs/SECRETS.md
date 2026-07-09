# Secrets

`machine-scratch` defines secret wiring, but never stores secret values.

## Canonical Names

Use one environment variable per provider everywhere.

| Provider | Canonical env var | Infisical path | Field |
|---|---|---|---|
| TokenRouter | `TOKENROUTER_API_KEY` | `/providers/tokenrouter` | `api_key` |
| Pioneer | `PIONEER_API_KEY` | `/providers/pioneer` | `api_key` |
| Pioneer base URL | `PIONEER_BASE_URL` | `/providers/pioneer` | `base_url` |
| Inference.net | `INFERENCE_NET_API_KEY` | `/providers/inference_net` | `api_key` |

Deprecated Claude-specific or generic aliases must not be used in source,
launchers, docs, or generated active config.

## Runtime Flow

```text
Infisical
  -> secret-cache refresh
  -> ~/.cache/quota-core/secrets.json
  -> secret-cache exec -- <launcher>
  -> only the child process receives provider env vars
```

`secret-cache` is intentionally the local adapter. Launchers should not call
Infisical directly when a cached key can be injected by `secret-cache exec`.

## Current Decision

Keep Infisical as the canonical remote store and keep `secret-cache exec` as the
single local launch-time injection surface.

Next hardening target: move local cached values out of plaintext JSON and into
macOS Keychain, while preserving the same `secret-cache refresh`, `status`, and
`exec --` interface.

## Verification

```bash
bin/verify-tokenrouter-secret-naming.sh
secret-cache status
secret-cache refresh
```

`ct` also performs a live TokenRouter preflight. That network check can fail when
DNS/network access is unavailable even if the cached key exists.
