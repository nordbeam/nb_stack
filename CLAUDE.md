# CLAUDE.md - nb_stack

Developer guidance for Claude Code when working with the nb_stack package.

## Package Overview

**nb_stack** is a meta-package and installer that orchestrates the installation and configuration of the complete nb_ frontend stack for Phoenix applications.

**Repository**: https://github.com/nordbeam/nb_stack

## Purpose

NbStack solves the problem of manually installing and coordinating multiple nb_ packages. Instead of running 5+ separate installers and manually configuring integration points, users run a single command that:

1. Installs all stack packages in the correct order
2. Coordinates configuration across packages
3. Sets up integration points (Vite plugins, TypeScript paths, etc.)
4. Provides a cohesive, well-tested default configuration

## Architecture

### Meta-Package Pattern

NbStack is a **meta-package** - it has no runtime code of its own. Instead:

- **mix.exs** declares optional dependencies on all stack packages
- **Installer** composes other installers via `Igniter.compose_task/2`
- **Module** (`lib/nb_stack.ex`) provides documentation and version constant
- **No runtime dependencies** - users only load the packages they install

### Installation Flow

```
User runs: mix igniter.install nb_stack
    ↓
1. Add all stack dependencies to mix.exs
    ↓
2. Install nb_vite (foundation - build system)
    ↓
3. Generate nb_routes (rich mode with form helpers)
    ↓
4. Install nb_serializer (with TypeScript and camelize)
    ↓
5. Install nb_inertia (also installs nb_ts if TypeScript enabled)
    ↓
6. Configure Vite plugin (nbRoutes for auto-regeneration)
    ↓
7. Print success message with next steps
```

### Dependency Graph

```
nb_stack (meta-package)
    ├─> nb_vite (no dependencies)
    ├─> nb_routes (no dependencies)
    ├─> nb_serializer (no dependencies)
    ├─> nb_ts (optional: nb_serializer)
    └─> nb_inertia (optional: nb_serializer, nb_routes, nb_ts)
```

**Installation order is critical:**
- nb_vite first (sets up build system)
- nb_routes second (can run anytime, useful early)
- nb_serializer third (provides types for nb_inertia)
- nb_inertia last (integrates everything, composes nb_ts)

## Key Files

### lib/nb_stack.ex

Simple module with version constant and documentation. No runtime code.

**Purpose**: Provide @moduledoc that appears in Hex docs and `h NbStack` in IEx.

### lib/mix/tasks/nb_stack.install.ex

The core installer. Uses Igniter.Mix.Task behavior.

**Key Responsibilities:**
1. **Validate options** - Ensure framework is valid
2. **Add dependencies** - All stack packages to mix.exs
3. **Compose installers** - Delegate to package-specific installers
4. **Configure integration** - Vite plugin, coordinated config
5. **Print messages** - Welcome banner, progress, success message

**Important Patterns:**

```elixir
# Compose other installers
Igniter.compose_task(igniter, "nb_vite.install", ["--typescript"])

# Add dependencies
Igniter.Project.Deps.add_dep(igniter, {:nb_vite, "~> 0.2"})

# Configure packages
Igniter.Project.Config.configure(igniter, "config.exs", :nb_routes, [:variant], :rich)

# Add tasks (for non-Igniter installers like nb_routes)
Igniter.add_task(igniter, "nb_routes.gen", ["--variant", "rich", "--with-methods"])

# Update files (for Vite config)
Igniter.update_file(igniter, "assets/vite.config.ts", fn source -> ... end)
```

### mix.exs

Declares all stack dependencies as optional:

```elixir
{:nb_vite, "~> 0.2", optional: true},
{:nb_inertia, "~> 0.2", optional: true},
{:nb_routes, "~> 0.2", optional: true},
{:nb_ts, "~> 0.2", optional: true},
{:nb_serializer, "~> 0.2", optional: true}
```

**Why optional?** So users can:
- Use nb_stack as a development-time installer
- Not load all packages at runtime if not needed
- Keep their dependency tree clean

### README.md

User-facing documentation:
- What NbStack is and why it exists
- Installation instructions
- Quick start guide
- Options and customization
- Comparison with manual installation
- Troubleshooting

### CLAUDE.md (This File)

Developer guidance for:
- Understanding the architecture
- Modifying the installer
- Adding new packages
- Testing changes
- Maintenance tasks

## Configuration Coordination

NbStack ensures consistent configuration across packages:

### Camelize Props

Both nb_inertia and nb_serializer need `camelize_props: true`:

```elixir
# In nb_stack installer
Igniter.compose_task(igniter, "nb_serializer.install", ["--camelize-props"])
Igniter.compose_task(igniter, "nb_inertia.install", ["--camelize-props"])
```

### TypeScript Integration

When `--typescript` is enabled:
- nb_vite gets `--typescript`
- nb_serializer gets `--with-typescript`
- nb_inertia gets `--typescript` (which composes nb_ts.install)

### Rich Routes

Always installed with rich mode:

```elixir
Igniter.Project.Config.configure(igniter, "config.exs", :nb_routes, [:variant], :rich)
Igniter.add_task(igniter, "nb_routes.gen", ["--variant", "rich", "--with-methods", "--with-forms"])
```

### Vite Plugin

Automatically adds nbRoutes plugin to vite.config.ts:

```typescript
import { nbRoutes } from '@nordbeam/nb-vite/nb-routes';

export default defineConfig({
  plugins: [
    phoenix({ input: ['js/app.tsx'] }),
    nbRoutes({ enabled: true })  // Added by nb_stack
  ]
});
```

## Installer Implementation Details

### Option Handling

```elixir
@impl Igniter.Mix.Task
def info(_argv, _parent) do
  %Igniter.Mix.Task.Info{
    schema: [
      framework: :string,
      typescript: :boolean,
      ssr: :boolean,
      yes: :boolean
    ],
    defaults: [
      framework: "react",
      typescript: true,
      ssr: false,
      yes: false
    ],
    composes: ["deps.get"]  # Automatically runs deps.get
  }
end
```

### Igniter Pipeline Pattern

Each step returns an igniter struct, allowing chaining:

```elixir
def igniter(igniter) do
  igniter
  |> print_welcome()
  |> validate_options()
  |> add_stack_dependencies()
  |> install_nb_vite()
  |> install_nb_routes()
  |> install_nb_serializer()
  |> install_nb_inertia()
  |> configure_vite_plugin()
  |> print_success()
end
```

### Progress Messages

Use `Igniter.add_notice/2` for user feedback:

```elixir
Igniter.add_notice(igniter, "→ Installing nb_vite...")
```

### Conditional Logic

Handle different frameworks and options:

```elixir
vite_opts =
  case framework do
    "react" -> if typescript, do: ["--typescript"], else: []
    "vue" -> if typescript, do: ["--typescript"], else: []
    "svelte" -> []
  end
```

## Testing Strategy

### Manual Testing

Create a test Phoenix app and run the installer:

```bash
# Outside monorepo
mix phx.new test_app
cd test_app

# Run installer directly from GitHub
mix igniter.install nb_stack@github:nordbeam/nb_stack
```

**What to verify:**
1. All dependencies added to mix.exs
2. All packages installed successfully
3. Configuration files created (vite.config.ts, tsconfig.json, etc.)
4. Routes generated (assets/js/routes.js)
5. Enhanced components created (assets/js/lib/inertia.ts)
6. Sample page works (assets/js/pages/Home.tsx)
7. Server starts: `mix phx.server`
8. Page loads at http://localhost:4000

### Testing Different Options

```bash
# Test with Vue
mix igniter.install nb_stack --framework vue

# Test without TypeScript
mix igniter.install nb_stack --no-typescript

# Test with SSR
mix igniter.install nb_stack --ssr
```

### Integration Testing

Test that all packages work together:

1. Create a route: `get "/users", UserController, :index`
2. Run `mix nb_routes.gen` (or save router.ex if Vite plugin working)
3. Verify routes.js updated
4. Create a serializer
5. Run `mix ts.gen`
6. Verify types generated
7. Create an Inertia page
8. Use generated routes and types
9. Verify everything compiles and works

## Maintenance Tasks

### Updating Dependencies

When a constituent package releases a new version:

1. Update version in mix.exs:
   ```elixir
   {:nb_vite, "~> 0.3", optional: true}  # Was 0.2
   ```

2. Test the installer with the new version

3. Update CHANGELOG.md with compatible versions

### Adding a New Package

To add a new package to the stack:

1. **Add dependency** to mix.exs:
   ```elixir
   {:nb_new_package, "~> 0.1", optional: true}
   ```

2. **Add installation step** in installer:
   ```elixir
   defp install_nb_new_package(igniter) do
     Igniter.add_notice(igniter, "→ Installing nb_new_package...")
     Igniter.compose_task(igniter, "nb_new_package.install", options)
   end
   ```

3. **Update pipeline**:
   ```elixir
   def igniter(igniter) do
     igniter
     |> ...
     |> install_nb_new_package()
     |> ...
   end
   ```

4. **Update documentation**:
   - README.md: Add to "What's Included" section
   - lib/nb_stack.ex: Update @moduledoc
   - Success message: Add to list

### Changing Installation Order

The order matters! If you need to change it:

1. **Understand dependencies**: Which packages depend on others?
2. **Update pipeline**: Reorder function calls in `igniter/1`
3. **Test thoroughly**: Ensure all packages install correctly

### Updating Success Message

The success message is in `print_success/1`. When updating:

- Keep it concise but informative
- Use ASCII art sparingly
- Include next steps
- Show actual code examples
- Reference generated files

## Common Issues

### Issue: Installer fails with "dependency not found"

**Cause**: User hasn't run `mix deps.get` first

**Fix**: The installer includes `composes: ["deps.get"]` which should handle this automatically, but users may see transient errors.

### Issue: Vite plugin not added correctly

**Cause**: Regex pattern doesn't match their vite.config.ts format

**Solution**: Make plugin addition more robust, or document manual addition.

### Issue: Options not being passed to sub-installers

**Cause**: Option transformation logic may be incorrect

**Fix**: Check option building in each `install_*` function:

```elixir
inertia_opts =
  [
    "--client-framework",
    framework,
    "--camelize-props"
  ] ++
    if typescript, do: ["--typescript"], else: [] ++
    if ssr, do: ["--ssr"], else: []
```

### Issue: Configuration conflicts between packages

**Cause**: Packages may have different default configurations

**Solution**: NbStack explicitly coordinates config:

```elixir
# Both get camelize_props: true
Igniter.compose_task(igniter, "nb_serializer.install", ["--camelize-props"])
Igniter.compose_task(igniter, "nb_inertia.install", ["--camelize-props"])
```

## Design Principles

### 1. Opinionated Defaults

NbStack chooses sensible defaults:
- React (most popular)
- TypeScript (type safety)
- Rich routes (better DX)
- Camelize props (JS convention)

**Why?** Reduces decision fatigue and ensures packages work well together.

### 2. Single Responsibility

NbStack only orchestrates installation. It doesn't:
- Add runtime code
- Override package behavior
- Make architectural decisions beyond "which packages and how to configure them"

### 3. Composability

Each step is a separate function that returns an igniter:

```elixir
igniter
|> install_nb_vite()
|> install_nb_routes()
```

This makes it easy to:
- Test individual steps
- Reorder steps
- Add/remove packages

### 4. Clear Communication

Users should always know:
- What's being installed
- What's being configured
- What they need to do next

Use `Igniter.add_notice/2` liberally for progress updates.

### 5. Fail Gracefully

If a step fails, provide clear error messages:

```elixir
unless framework in ["react", "vue", "svelte"] do
  Igniter.add_warning(igniter, "Invalid framework. Using 'react'.")
end
```

## Future Enhancements

Potential improvements to nb_stack:

1. **Presets**: Add preset configurations like "minimal", "full", "api"
2. **Upgrade command**: `mix nb_stack.upgrade` to update all packages
3. **Health check**: `mix nb_stack.doctor` to verify configuration
4. **Generators**: Add common patterns (CRUD, auth, etc.)
5. **VSCode integration**: Generate `.vscode/settings.json` with recommended extensions

## Related Resources

- **Monorepo CLAUDE.md**: See parent directory's CLAUDE.md
- **Individual package docs**: See each package's CLAUDE.md
- **Igniter docs**: https://hexdocs.pm/igniter
- **Hex publishing**: https://hex.pm/docs/publish

## Development Workflow

### Making Changes

1. **Edit installer**: `lib/mix/tasks/nb_stack.install.ex`
2. **Test manually**: Create test Phoenix app, run installer
3. **Update docs**: README.md and CLAUDE.md
4. **Format code**: `mix format`
5. **Commit changes**: With clear message

### Publishing

When ready to publish:

1. **Update version**: In `mix.exs` and `lib/nb_stack.ex`
2. **Update CHANGELOG.md**: Document changes
3. **Build docs**: `mix docs`
4. **Publish**: `mix hex.publish`

### Version Management

Follow semver:
- **Patch** (0.1.1): Bug fixes, doc updates
- **Minor** (0.2.0): New features, backward compatible
- **Major** (1.0.0): Breaking changes

Keep version in sync with constituent packages when possible (e.g., nb_stack 0.2.0 works with nb_vite 0.2.x, nb_inertia 0.2.x, etc.).
