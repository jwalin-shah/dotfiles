# End-to-End Testing Plan for Agent Configuration

## Objective
Verify that all tools, permissions, proxies, and MCPs work as intended.

## Prerequisites
- ✓ MCPs disabled (empty registrations)
- ✓ Headroom running (port 8788)
- ✓ TokenRouter running (port 18999)
- ✓ Permissions declared in nix
- ✓ All configs in dotfiles/symlinked

## Test Phases

### Phase 1: Baseline Verification
- [ ] Verify headroom is healthy
- [ ] Verify tokenrouter is responding
- [ ] Verify headroom stats are clean (0 requests before tests)
- [ ] Verify MCPs are truly disabled in all tools

### Phase 2: Launcher Tests
- [ ] `ct --version` works (claude via tokenrouter)
- [ ] `ca --version` works (claude direct)
- [ ] `cx --version` works (codex)
- [ ] `ot --version` works (opencode)
- [ ] `agy --version` works (gemini)

### Phase 3: Headroom Integration (ct only)
- [ ] ct makes a request through headroom@8788
- [ ] Request flows: ct → headroom → tokenrouter → model
- [ ] Headroom compresses the request
- [ ] Response comes back through headroom
- [ ] Monitor stats/latency/overhead

### Phase 4: Permission Enforcement
- [ ] Claude allows `Bash(*)` but asks for destructive commands
- [ ] Codex has sandbox_permissions set
- [ ] OpenCode allows write but asks for sudo
- [ ] Cursor denies specific commands
- [ ] Gemini allows investigation tools

### Phase 5: Full Integration
- [ ] Run a real task with ct and watch headroom compress it
- [ ] Compare token savings vs uncompressed
- [ ] Monitor all services stay healthy
- [ ] Check no errors in logs

## Metrics to Collect
- Headroom uptime
- Requests processed
- Tokens compressed
- Compression ratio
- Cost savings
- Response latency
- Any permission denials

## Expected Outcomes
- All tools launch cleanly
- Headroom processes requests without errors
- Permissions are enforced as declared
- MCPs remain disabled
- Services stay healthy under load
