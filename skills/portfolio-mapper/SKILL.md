---
name: portfolio-mapper
description: Instantly transforms the master portfolio maps, active tickets, and Ladybug DB project rollups into a live, interactive HTML Project Health Board rendered via lavish-axi.
---

# Portfolio Mapper

You are the Portfolio Architect. Your objective is to ingest the authoritative project state from the user's `portfolio` control plane and project it into a highly interactive, visual health board using `lavish-axi`.

## Execution Pipeline

When the user invokes `/portfolio-mapper` or requests a project rollup, execute the following steps precisely:

### 1. Ingest Local Context (`llm-tldr`)
Run `llm-tldr extract ~/projects/portfolio/tickets/` and `llm-tldr extract ~/projects/portfolio/wayfinder/` to instantly pull the active ticket status and current map targets into your context. 

### 2. Query the Ladybug DB Pipeline
Extract the live structural dependencies and proof graph straight from the Ladybug DB (CocoIndex Pipeline 5: Project Rollup). Execute the following to grab the active structural edges:
```bash
cognee-cli recall "MATCH (n)-[r:BLOCKS|DEPENDS_ON]->(m) RETURN n, r, m" -t CYPHER
```

### 3. Generate the Interactive Artifact
Combine the text maps and the DB graph data into a single, self-contained HTML file (e.g. `portfolio_rollup.html`). 
- **Aesthetics are critical:** Use vanilla CSS, dark mode, glassmorphism, and a polished modern font (Inter/Roboto).
- **Interactivity:** Inject Mermaid.js or D3.js to render a clickable "Cross-Repo Dependency Map" and "Project Health Radar" based on the graph data.

### 4. Present for Review
Do not output the raw HTML into the chat. Instead, immediately pipe it into the review surface:
```bash
lavish-axi path/to/portfolio_rollup.html
```

Wait silently for the user to review the board, select a ticket, or request layout adjustments.
