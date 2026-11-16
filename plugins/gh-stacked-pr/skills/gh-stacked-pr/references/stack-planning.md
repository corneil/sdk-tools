# Stack planning

How to group uncommitted changes into layers and order them.

## Group into layers

- One layer is one coherent, reviewable concern: one feature step, one fix,
  one refactor, or one docs update.
- Files that only make sense together stay in the same layer. A type and the
  code that consumes it can be split only if the type layer still works on
  its own.
- Prefer 2 to 5 layers. If the work is one concern, make it a single PR and
  tell the user a stack is not needed.
- Do not split a layer just to make more layers. Do not merge unrelated
  concerns into one layer to make fewer.

## Order the layers

Order layers bottom to top so that a layer only depends on layers below it.

1. Shared foundations first: types, interfaces, constants, database schemas,
   configuration.
2. Core logic next: services, handlers, business rules built on the
   foundations.
3. Consumers last: UI, CLI, API endpoints, documentation, tests that cover
   the layers above.

Check each layer against these questions:

- Does it import, extend, or reference anything from a layer above it? If
  yes, the order is wrong.
- Does it compile and pass its tests with only the layers below it applied?
  If no, the order is wrong or the grouping is wrong.

Detect dependencies by reading imports, build files, schema definitions, and
call sites. When two layers are truly independent, keep them in separate
stacks or pick a stable order and say so in the plan.

## Name the layers

Branch names are `<reference>-<position>-<topic>`:

```
user-auth-1-schema
user-auth-2-backend
user-auth-3-ui
```

The topic is one to three lowercase words. Positions run 1 to N from the
bottom.

## Describe dependencies

Each commit message and pull request body names the layers it depends on and
what they provide. Example:

```
Depends on: user-auth-1-schema (User table and session model).
```

A layer with no dependencies says `Depends on: none.`
