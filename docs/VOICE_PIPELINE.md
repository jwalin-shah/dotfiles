# Voice Pipeline

> **Last updated:** 2026-07-02

This document summarizes the voice transcription pipeline status. For full
design details, known issues, and performance metrics, see `docs/DESIGN_NOTES.md`.

---

## Current Status: **Experimental / Pre-Production**

The VoiceEngine Swift app provides real-time voice transcription on this machine
using Moonshine CoreML. It is functional for dictation but has unresolved
issues that prevent production use.

---

## Architecture

```
Mic Input → VAD → Audio (WAV) → Moonshine CoreML → Transcription
                                      │
                              ┌───────┴───────┐
                          Encoder          Decoder
                          (ANE)            (CPU)
```

### Components

| Component | Detail |
|---|---|
| **Model** | UsefulSensors/moonshine-tiny (~105 MB CoreML) |
| **Encoder** | Apple Neural Engine (ANE) — fast, low power |
| **Decoder** | CPU — slower but necessary for beam search |
| **Tokenizer** | SentencePiece Model (SPM) |
| **Load time** | 1.4–1.9 seconds |
| **Latency** | 20–90 ms per utterance |
| **Storage** | WAV files in `~/Library/Logs/voice-engine/audio/` (54 files) |
| **Source** | `~/projects/voice-engine-swift/` (Swift + Python daemon) |

---

## What Works

- ✅ CoreML model loads and runs on ANE + CPU
- ✅ Real-time transcription at 20–90ms latency
- ✅ VAD filters silence from audio stream
- ✅ Audio files saved with matching timestamps to history entries
- ✅ 54 test recordings captured across ~25 sessions

## What's Broken

| Issue | Root Cause | Status |
|---|---|---|
| Accessibility permission denied | CGEvent tap requires System Settings grant | ⬜ Needs user action |
| LFM cleanup daemon crashes | `mlx` not installed in daemon's Python env | ⬜ Fix Python path |
| VAD over-filters short utterances | Threshold tuning needed | ⬜ Parameter optimization |
| Transcription artifacts | Moonshine-tiny model limitations | ⬜ Consider larger model |

---

## Data

- **54 WAV recordings** in `~/Library/Logs/voice-engine/audio/`
- **35 KB runtime log** at `~/Library/Logs/voice-engine/voice-engine.log`
- **15 KB metrics** (65 events) at `~/Library/Logs/voice-engine/metrics.jsonl`
- **5.6 KB history** archived at `docs/archive/voice-history.txt`
- **105 MB model** at `~/.cache/huggingface/hub/models--UsefulSensors--moonshine-tiny`

---

## Related Documents

| Document | Content |
|---|---|
| `docs/DESIGN_NOTES.md` | Full architecture, metrics, timeline, and known issues |
| `docs/archive/voice-history.txt` | Raw dictation transcript history |
| `~/projects/voice-engine-swift/` | VoiceEngine source code |
