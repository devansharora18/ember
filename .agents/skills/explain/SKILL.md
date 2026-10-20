---
name: explain
description: Use when the user wants to understand what was built — for learning, an interview, an exam, or onboarding — calibrated to their level. Not for reference documentation (use docs).
---

# Explain

Understanding is built in layers, not delivered as a wall of prose.

## 1. Calibrate

Ask or infer what they already know. A backend engineer learning React needs different words than a beginner. Default to "smart, new to this codebase".

## 2. Structure

1. **The problem** in one sentence, without jargon.
2. **The shape** — the three to five moving parts, named, and how they connect. A diagram beats a paragraph.
3. **One concrete trace** — follow a single request or click through every part. This is where understanding actually happens.
4. **The decisions** — why this way and not the obvious alternative. Link the ADR if one exists.
5. **Where it breaks** — known limits and the next thing to learn.

## Rules

- Concrete before abstract: show the actual function, request, or file, then name the pattern.
- One analogy maximum, and say where it stops being true.
- Define a term the first time you use it, in parentheses — not in a glossary at the end.
- No marketing adjectives. "Fast" means a number.
- If they asked about a specific line, answer that line first, then zoom out.

## For interviews and exams

End with three questions the material should let them answer, and the short answers. Do not quiz them uninvited.

## Check understanding

Close with one question that tests the core idea ("what happens if the second write fails?"). If the answer is unclear, the explanation wasn't finished.
