# Claude Skills for FP Library

This directory contains Claude AI skills designed to help developers use the FP (Functional Programming) library effectively.

## What are Claude Skills?

Claude skills are reusable prompts that guide Claude to perform specific tasks. When you invoke a skill, Claude uses the detailed instructions to help you with that particular aspect of functional programming.

## Available Skills

### 1. **add-monad-support.md**
Help implement Functor, Applicative, and Monad type classes for custom Swift types.

**Use when:**
- Creating a new container type that should support FP operations
- Adding functional programming support to existing types
- Need to implement operators like `<£>`, `<*>`, `>>-` for your type

**Example invocation:**
```
Use the add-monad-support skill to help me implement Functor, Applicative,
and Monad for my AsyncResult<T, E> type.
```

### 2. **create-readert-transformer.md**
Help implement ReaderT (Reader Transformer) for composing Reader with custom monads.

**Use when:**
- Need to combine Reader monad with another effect (State, Validation, etc.)
- Building layered applications with dependency injection
- Want environment-aware computations with additional effects

**Example invocation:**
```
Use the create-readert-transformer skill to help me create ReaderT for
my Validation monad.
```

### 3. **convert-to-functional.md**
Help convert imperative Swift code to functional style using FP library operators.

**Use when:**
- Refactoring nested if-let chains to monadic binds
- Converting loops to map/flatMap operations
- Eliminating mutation and mutable state
- Want more composable, testable code

**Example invocation:**
```
Use the convert-to-functional skill to help me refactor this imperative
function to functional style: [paste your code]
```

### 4. **explain-operators.md**
Help understand and debug complex operator compositions.

**Use when:**
- Getting type errors with operator chains
- Don't understand how operators are grouping
- Need to trace types through a composition
- Want to learn precedence and associativity

**Example invocation:**
```
Use the explain-operators skill to help me understand this composition:
array <£> { $0 * 2 } >>- { [$0, $0 + 1] }
```

### 5. **reader-monad-guide.md**
Help understand and effectively use the Reader monad for dependency injection.

**Use when:**
- Learning Reader monad pattern
- Implementing dependency injection without manual parameter passing
- Need configuration-based computations
- Want to combine Reader with other effects using ReaderT

**Example invocation:**
```
Use the reader-monad-guide skill to help me implement a service layer
with Reader monad for dependency injection.
```

## How to Use Skills

### In Claude Code CLI

Simply mention the skill in your conversation:

```
Use the [skill-name] skill to help me with [specific task]
```

Claude will load the skill instructions and guide you through the process.

### Direct Skill Invocation

You can also read the skill file directly and ask specific questions:

```
I'm looking at the add-monad-support skill. How do I implement Applicative
for a type that represents asynchronous computations?
```

## Skill Structure

Each skill file contains:

1. **Overview**: What the skill helps with
2. **Instructions**: Step-by-step guidance for Claude
3. **Patterns**: Code templates and examples
4. **Best Practices**: Guidelines and recommendations
5. **Common Pitfalls**: What to avoid
6. **Questions**: What Claude should ask to clarify requirements

## Creating Custom Skills

You can create your own skills for your team's specific needs:

1. Create a new `.md` file in this directory
2. Structure it similar to existing skills:
   - Title and purpose
   - Detailed instructions
   - Code patterns and examples
   - Edge cases and best practices
3. Use the skill by referencing its name in conversations

Example custom skill structure:

```markdown
# My Custom Skill

Help developers with [specific task].

## Skill Prompt

You are helping a developer [what they're trying to do].

### Instructions:

1. [Step 1]
2. [Step 2]
...

### Pattern to Follow:

\`\`\`swift
// Example code pattern
\`\`\`

### Ask the developer:
1. [Question 1]
2. [Question 2]
```

## Contributing

If you create useful skills for working with the FP library, consider contributing them back:

1. Ensure the skill is well-documented
2. Include practical examples
3. Test with various scenarios
4. Submit via pull request

## Tips for Effective Skill Usage

1. **Be specific**: Tell Claude exactly what you're trying to do
2. **Provide context**: Share relevant code, types, and constraints
3. **Ask follow-ups**: Skills are starting points - ask for clarifications
4. **Iterate**: Refine the generated code based on your needs
5. **Learn**: Use skills as learning tools, not just code generators

## Skill Development Guidelines

When creating skills for this library:

1. **Follow FP library conventions**: Match existing patterns and naming
2. **Include type signatures**: Haskell-style comments are helpful
3. **Show law verification**: Demonstrate Functor/Applicative/Monad laws
4. **Provide tests**: Include XCTest examples
5. **Consider edge cases**: Platform support, Sendable constraints, etc.

## Resources

- [FP Library Documentation](../README.md)
- [Implementation Summary](../IMPLEMENTATION_SUMMARY.md)
- [Operator Precedence Guide](../PRECEDENCE_CORRECTIONS.md)
- [Haskell Type Class Reference](https://wiki.haskell.org/Typeclassopedia)

## Feedback

If you have suggestions for new skills or improvements to existing ones, please open an issue or submit a pull request!
