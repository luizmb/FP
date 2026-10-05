# Claude skills for FP

Two [Claude skills](https://docs.claude.com/en/docs/claude-code/skills) that teach Claude how this library works today (3.0), so it writes code that compiles against it instead of guessing from Haskell or from older FP versions.

| Skill | For | What it covers |
|---|---|---|
| [`fp-library`](fp-library/SKILL.md) | people using FP in their apps | operators and precedence, tacit helpers, Either / Validation / Reader / Loading, transformer stacks, refactoring imperative code, making your own types work with the operators |
| [`fp-library-contributor`](fp-library-contributor/SKILL.md) | people changing FP itself | the named-function + operator split, flipped operators, the Sendable contract, the four test targets, adding a type's functor / applicative / monad surface, adding a transformer stack through the generator |

Each skill is a folder with a `SKILL.md` (always loaded when the skill triggers) and a `references/` folder that Claude reads only when the task needs it, so installing both costs very little context.

## Installing

Copy the folder(s) to where Claude Code looks for skills, either for you alone:

```bash
cp -R docs/claude-skills/fp-library ~/.claude/skills/
cp -R docs/claude-skills/fp-library-contributor ~/.claude/skills/
```

or for one project (checked in, so everyone on the project gets them):

```bash
mkdir -p .claude/skills
cp -R path/to/FP/docs/claude-skills/fp-library .claude/skills/
```

Then restart Claude Code. The skills trigger on their own when you work with FP code (their `description` says when), or you can ask for them by name ("use the fp-library skill to refactor this").

`fp-library-contributor` assumes you're in a checkout of this repository: it points at files like `Scripts/GenerateTransformers.swift` and `CONTRIBUTING.md`. Library users only need `fp-library`.

## Keeping them honest

Every ```swift block in these files compiles against the current sources when a file's blocks are concatenated top to bottom (illustrative fragments that aren't meant to compile are marked ```swift-sketch). If you change an API that a skill shows, update the skill in the same PR.
