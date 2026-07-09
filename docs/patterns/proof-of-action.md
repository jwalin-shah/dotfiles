# proof-of-action: Privacy Boundary with Typed Projections

**Source repo**: NOT FOUND (not under jwalin-shah, jwalinshah, or any GitHub account; not in local ~/projects)

**Pattern reconstructed from the description**: "privacy boundary with typed projections"

## Problem

Internal data models carry full fidelity (all fields, all relationships), but
consumers at API/module boundaries should only see purpose-specific subsets.
Without typed projections, sensitive or irrelevant fields leak across boundaries
through shared structs, serialization defaults, or "just pass the whole object"
habits.

## How It Works

1. Define an internal type with the full data shape (e.g., `UserRecord` with
   password hash, email, preferences, auth tokens).
2. For each consumer boundary, define a typed projection struct that carries
   only the fields that boundary needs (e.g., `UserProfile` with display_name
   and avatar_url).
3. The projection is the only type exported or serialized at that boundary.
   Internal code works with the full type; external consumers only see the
   projection.
4. Conversion is explicit (a `From` impl or a constructor), so every field
   that crosses the boundary is a conscious decision.

## Interface / Contract

```rust
// Internal — never serialized directly
struct UserRecord {
    id: UserId,
    display_name: String,
    email: String,
    password_hash: String,
    preferences: Preferences,
}

// Public projection for profile display
struct UserProfile {
    display_name: String,
    avatar_url: Option<String>,
}

// Explicit, auditable conversion
impl From<&UserRecord> for UserProfile {
    fn from(u: &UserRecord) -> Self {
        UserProfile {
            display_name: u.display_name.clone(),
            avatar_url: u.preferences.avatar_url.clone(),
        }
    }
}
```

## Applying to jw-*

- **jw-sentry**: Define typed projection types for event data crossing the
  collection -> storage -> query pipeline. Internal event representations carry
  full machine context; storage projections carry only the fields that audit
  and query need.
- **jw-core**: Projection boundary between daemon-internal state and the
  control socket / CLI surface. Internal state structs stay rich; CLI responses
  are narrow typed projections.
- **jw-agentd / jw-sessiond**: Session data crossing from daemon memory to
  on-disk persistence or to the TUI should go through explicit projection types
  rather than serializing internal structs directly.
