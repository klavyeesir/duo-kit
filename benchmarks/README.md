# Benchmark

Measures whether the agent skill changes what a coding agent produces.

Method: one task file plus a fixed prompt, given to the same model in six fresh
chats — three without the skill, three with the skill text pasted into context
first. Output scored by `scripts/score.sh`, which reports whether DuoLint still
flags the rules listed in the task's `expect.json`.

## Results

| Task | Model | Without skill | With skill |
| --- | --- | --- | --- |
| photo-grid | Fable 5.1 | 3/3 | 3/3 |

**Reading of the photo-grid result:** no measurable difference. Both rules in this
task (cached screen bounds, odd grid columns) describe patterns a current model
already avoids when asked to make a layout adaptive, so the task does not isolate
Duo-specific knowledge. Harder tasks are needed before any claim about the skill's
value is justified.

## Limitations

- Scoring checks lint rules only. It does not compile the output or judge SwiftUI quality.
- The skill is pasted into context rather than loaded by a skill runtime, which may change how the model treats it.
- Three runs per arm is small; it detects large effects, not small ones.
