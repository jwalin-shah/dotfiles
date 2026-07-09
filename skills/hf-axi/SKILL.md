---
name: hf-axi
description: >
  HuggingFace Hub AXI — search models/datasets, get model card info, download weights.
  Use when working with HuggingFace models, finding models for a task, or pulling weights locally.
---

# hf-axi

Token-efficient agent interface to HuggingFace Hub.

## Commands

```
hf-axi search <query>              Search models by name/keyword (top 10 by downloads)
hf-axi list <task>                 Top models for a pipeline task
hf-axi info <model-id>             Model card: task, downloads, tags, license, preview
hf-axi download <model-id>         Pull weights to HF cache (~/.cache/huggingface/)
hf-axi download <model-id> --to <dir>   Pull to specific directory
```

## Common tasks

- Find a speech-to-text model: `hf-axi list automatic-speech-recognition`
- Find Moonshine: `hf-axi search moonshine`
- Get model details: `hf-axi info usefulsensors/moonshine-base`
- Pull weights: `hf-axi download usefulsensors/moonshine-base`

## Pipeline task names

`text-generation`, `text-classification`, `automatic-speech-recognition`,
`image-classification`, `object-detection`, `fill-mask`, `question-answering`,
`summarization`, `translation`, `text2text-generation`, `feature-extraction`
