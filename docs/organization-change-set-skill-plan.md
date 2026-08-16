# Organization Change Set skill plan

Status: Complete

Tracking: [folderbase-skills#14](https://github.com/chalkagents/folderbase-skills/issues/14)

## Outcome

Extend the single portable `work-with-folderbase` skill so an agent can work in
one already-authorized ordinary checkout, organize it with a small number of
consequential human questions, and return an exact Core Change Set plus staging
directory for separate review in the Folderbase App.

This is the public agent side of the reviewed-work workflow:

```text
App or Cloud authorization layer
  -> ordinary least-authority checkout
  -> Codex, Claude, Hermes, OpenClaw, OpenCode, or another compatible agent
  -> immutable Change Set plus provider-neutral staging
  -> separate App review, assessment, and apply
```

## Boundaries

- Use exact Folderbase Core `v0.7.2` at immutable commit
  `7439babec74242d9d162ab09f12f2f1b1b2c5cbe`.
- Discover the stable `folderbase.change-set@0.1.0` capability before using it.
- Accept an already-materialized checkout. Do not manufacture share grants,
  Folder Scope authority, checkout requests, or Cloud state in the skill.
- Keep every file type as ordinary opaque bytes. Read large or non-text files
  metadata-first and never pretend to text-merge them.
- Ask only when an answer changes grouping, retention, or ownership. Ask one
  question at a time with two or three clear choices and an Other path.
- A precise user task authorizes additive and no-clobber work inside the
  disposable checkout. Require a separate decision for deletion, overwrite,
  ambiguous grouping, or destructive conversion.
- Show a concise before/after tree and explain each proposed grouping before a
  consequential restructure.
- The working agent may run `change-set propose`. Read-only assessment may be
  run by a reviewer with source access, but it never grants approval. The
  working agent must not apply its own proposal; publication belongs to the
  source owner and App.
- Never edit `.folderbase/checkout.json` or invent a Change Set document.

## Red-green execution

1. Add acceptance assertions for the v0.7.2 profile, stable capability
   discovery, question UX, tree rationale, all-file-type behavior, and strict
   propose-only handoff.
2. Observe the acceptance RED before changing the skill.
3. Add an exact-source Core contract mode that creates a scoped checkout,
   changes text and opaque binary files, proposes one Change Set, and proves a
   separate assessment accepts the returned artifacts without exposing a
   private sibling.
4. Update the skill and protocol reference without copying Core schemas or
   implementation rules.
5. Add the exact-source gate to CI and document local evidence.
6. Validate Agent Skills format, all existing acceptance/distribution gates,
   the new Core contract, formatting, and public-repository privacy.

## Non-claims

This slice does not implement App checkout creation, Live Folder links, Cloud
transport, synchronization, Keep Local, Archive, hosted VM lifecycle, or
automatic conflict resolution. It prepares portable agent work that those
surfaces can later transport and review.
