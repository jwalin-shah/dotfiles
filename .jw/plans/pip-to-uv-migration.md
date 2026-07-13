# pip -> uv venv migration plan

Source: 108 packages (+ pip itself) currently in shared Homebrew Python 3.14
site-packages (`/opt/homebrew/lib/python3.14/site-packages`), installed via
raw `pip3 install`, captured 2026-07-13 via `pip3 list --format=freeze`.
Nothing has been deleted from the shared environment yet - this plan is
proposal only.

## 1. btw-v1 (existing editable install)

Location: `~/projects/btw-v1` (already exists, currently installed as
`pip3 install -e`)

Packages (FastAPI/typer app stack, inferred from what's installed alongside
the editable install - **captain should verify against btw-v1's actual
imports/requirements before trusting this list**):
fastapi, starlette, uvicorn, pydantic, pydantic_core, h11, httpcore, httpx,
anyio, sniffio, annotated-types, annotated-doc, typing_extensions,
typing-inspection, click, python-dotenv, rich, typer, shellingham

Commands:
```
cd ~/projects/btw-v1
uv venv
uv pip install -e .
uv add fastapi starlette uvicorn 'pydantic' httpx typer rich python-dotenv
```
(If btw-v1 already has a `pyproject.toml`/`requirements.txt`, use
`uv sync` / `uv pip install -r requirements.txt` instead of re-adding by hand.)

## 2. research-toolkit

Proposed location: `~/envs/research-toolkit` (new directory, no existing project)

Packages: arxiv, alphaxiv, scholarly, bibtexparser, free_proxy, fake-useragent, pypdf

Commands:
```
mkdir -p ~/envs/research-toolkit && cd ~/envs/research-toolkit
uv init --no-workdir
uv add arxiv alphaxiv scholarly bibtexparser free_proxy fake-useragent pypdf
```

## 3. browser-automation

Proposed location: `~/envs/browser-automation` (new)

Packages: playwright, selenium, beautifulsoup4, lxml, soupsieve, trio,
trio-websocket, wsproto, outcome, sortedcontainers, PySocks,
websocket-client, pyee, greenlet

Commands:
```
mkdir -p ~/envs/browser-automation && cd ~/envs/browser-automation
uv init --no-workdir
uv add playwright selenium beautifulsoup4 lxml
uv run playwright install   # downloads browser binaries into this venv's cache
```
(trio, trio-websocket, wsproto, outcome, sortedcontainers, PySocks,
websocket-client, pyee, greenlet, soupsieve are transitive deps of
playwright/selenium/bs4 - uv will pull them automatically, no need to
`uv add` explicitly.)

## 4. ml-embedding

Proposed location: `~/envs/ml-embedding` (new)

Packages: torch, transformers, sentence-transformers, faiss-cpu,
huggingface_hub, tokenizers, safetensors, scikit-learn, scipy, onnxruntime,
numpy, joblib, threadpoolctl, hf-xet, filelock, fsspec, networkx, sympy,
mpmath, regex, tqdm, protobuf, flatbuffers, hnswlib, FlashRank

Commands:
```
mkdir -p ~/envs/ml-embedding && cd ~/envs/ml-embedding
uv init --no-workdir
uv add torch transformers sentence-transformers faiss-cpu scikit-learn onnxruntime hnswlib flashrank
```
(numpy, scipy, huggingface_hub, tokenizers, safetensors, joblib,
threadpoolctl, hf-xet, filelock, fsspec, networkx, sympy, mpmath, regex,
tqdm, protobuf, flatbuffers are transitive - let uv resolve them. This is
the heaviest venv by disk size; consider `UV_LINK_MODE=copy` vs default
hardlink if it ever needs to be relocated off this volume.)

## 5. sphinx-docs

Proposed location: `~/envs/sphinx-docs` (new) - or inside whichever repo
actually builds docs with Sphinx, if that's a single project rather than a
shared tool. **Captain: confirm which repo(s) use this before creating a
shared venv** - if only one project builds docs, put the venv there instead.

Packages: Sphinx, sphinx_rtd_theme, sphinxcontrib-applehelp,
sphinxcontrib-devhelp, sphinxcontrib-htmlhelp, sphinxcontrib-jquery,
sphinxcontrib-jsmath, sphinxcontrib-qthelp, sphinxcontrib-serializinghtml,
docutils, alabaster, babel, imagesize, snowballstemmer, roman-numerals

Commands:
```
mkdir -p ~/envs/sphinx-docs && cd ~/envs/sphinx-docs
uv init --no-workdir
uv add sphinx sphinx_rtd_theme
```
(sphinxcontrib-*, docutils, alabaster, babel, imagesize, snowballstemmer,
roman-numerals are transitive deps of Sphinx - uv pulls them automatically.)

## Shared/common utility packages (not migrated - left in place or dropped)

These are transitive deps of many of the above and/or generic stdlib-adjacent
utilities: requests, urllib3, certifi, charset-normalizer, idna, PyYAML,
python-dateutil, six, attrs, packaging, setuptools, wheel, pip, Deprecated,
wrapt, arrow, iniconfig, pluggy, pytest, Pygments, markdown-it-py, mdurl,
Jinja2, MarkupSafe, narwhals, pyparsing, tzdata.

Once all 5 venvs above are created, uv will have re-resolved and installed
whichever of these each venv actually needs. These should NOT be
individually `uv add`ed anywhere - they're pulled in as transitive deps.

## Orphan - needs captain's call

`livelm==2.0.0` - no group above claims it and it's not a recognizable
transitive dependency of the others. Captain should say what this is for
(name suggests "live LM" but there's no clear owning project) before it's
placed anywhere or dropped.

## Not yet covered by this plan

- Deleting the packages from shared `/opt/homebrew/lib/python3.14/site-packages`
  once the venvs above are verified working - separate approval-gated step,
  do not do this until captain confirms each new venv actually works for its
  workflow.
- Whether `~/envs/` is the right convention, or whether these should instead
  live under `~/projects/<tool>` as standalone repos - captain's call, this
  plan used `~/envs/` as a neutral placeholder since none of these 4
  workflows currently have a dedicated project directory.
