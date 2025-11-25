defmodule NbStack do
  @moduledoc """
  Meta-package and installer for the complete nb_ frontend stack.

  NbStack orchestrates the installation and configuration of:

  - **nb_vite**: Vite integration for Phoenix with HMR and optimized builds
  - **nb_inertia**: Inertia.js integration with declarative page DSL and modal support
  - **nb_routes**: Type-safe route helpers with rich mode and form helpers
  - **nb_ts**: TypeScript type generation from Elixir serializers and Inertia pages
  - **nb_serializer**: High-performance JSON serialization with declarative DSL

  ## Installation

  Add to your Phoenix application's `mix.exs`:

  ```elixir
  def deps do
    [
      {:nb_stack, "~> 0.1"}
    ]
  end
  ```

  Then run the installer:

  ```bash
  mix igniter.install nb_stack
  ```

  This will install and configure the entire stack with smart defaults:
  - React + TypeScript
  - Rich routes with form helpers
  - Serializer with type generation
  - Camelize props for JavaScript conventions

  ## Options

  - `--framework` - Client framework: `react` (default), `vue`, or `svelte`
  - `--typescript` - Enable TypeScript (default: true)
  - `--ssr` - Enable server-side rendering (default: false)
  - `--yes` - Skip confirmation prompts

  ## Examples

  ```bash
  # Install with defaults (React + TypeScript)
  mix igniter.install nb_stack

  # Install with Vue
  mix igniter.install nb_stack --framework vue

  # Install without TypeScript
  mix igniter.install nb_stack --no-typescript

  # Install with SSR
  mix igniter.install nb_stack --ssr
  ```

  ## What Gets Installed

  1. **nb_vite**: Frontend build system with Vite
  2. **nb_routes**: Type-safe route helpers (rich mode with form helpers)
  3. **nb_serializer**: JSON serialization with TypeScript integration
  4. **nb_ts**: TypeScript type generation (if --typescript)
  5. **nb_inertia**: Inertia.js SPA framework with enhanced components

  The installer also:
  - Coordinates configuration across packages (camelize_props, TypeScript paths)
  - Adds the nbRoutes Vite plugin for auto-regeneration
  - Generates initial route helpers and types
  - Creates example page component

  ## Type Safety Flow

  When using the full stack:

  1. Define routes in Phoenix router
  2. Create serializers for your data
  3. Define Inertia pages with typed props
  4. Types and route helpers auto-generate
  5. Use in React/Vue with full type safety

  See individual package documentation for detailed usage.
  """

  @version "0.1.0"

  @doc """
  Returns the current version of NbStack.
  """
  def version, do: @version
end
