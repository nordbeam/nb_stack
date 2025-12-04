if Code.ensure_loaded?(Igniter.Mix.Task) do
  defmodule Mix.Tasks.NbStack.Install do
    @moduledoc """
    Installs and configures the complete nb_ frontend stack for Phoenix.

    This installer orchestrates the installation of:
    - nb_vite: Vite integration with HMR
    - nb_routes: Type-safe route helpers (resource style)
    - nb_serializer: High-performance JSON serialization
    - nb_ts: TypeScript type generation
    - nb_inertia: Inertia.js SPA framework with enhanced components
    - nb_flop: Table DSL and Flop serializers

    ## Usage

    ```bash
    mix igniter.install nb_stack@github:nordbeam/nb_stack
    ```

    ## Options

    - `--yes` - Skip confirmation prompts

    ## What Gets Installed

    1. nb_vite with TypeScript support
    2. nb_routes in resource style
    3. nb_serializer with TypeScript integration and camelized props
    4. nb_ts for automatic type generation
    5. nb_inertia with React, TypeScript, and SSR (using DenoRider)
    6. nb_flop with Table DSL and React components
    7. Complete Vite configuration with SSR support
    8. Coordinated configuration across all packages

    ## Examples

    ```bash
    # Install with defaults (React + TypeScript + SSR)
    mix igniter.install nb_stack@github:nordbeam/nb_stack

    # Install without prompts
    mix igniter.install nb_stack@github:nordbeam/nb_stack --yes
    ```
    """

    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _parent) do
      %Igniter.Mix.Task.Info{
        group: :nb,
        schema: [
          yes: :boolean
        ],
        defaults: [
          yes: false
        ],
        positional: [],
        # Declare all tasks we'll compose - enables argument validation
        composes: [
          "deps.get",
          "nb_vite.install",
          "nb_serializer.install",
          "nb_inertia.install"
        ],
        example: "mix igniter.install nb_stack"
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      igniter
      |> print_welcome()
      # Add GitHub dependencies manually (until published to Hex)
      |> add_github_deps()
      # Configure packages directly (sub-installer add_task doesn't merge config back)
      |> configure_nb_routes()
      |> configure_nb_inertia()
      # Compose Igniter installers (runs synchronously within this igniter)
      |> Igniter.compose_task("nb_vite.install", ["--typescript"])
      |> Igniter.compose_task("nb_serializer.install", [
        "--with-phoenix",
        "--camelize-props",
        "--with-typescript"
      ])
      |> Igniter.compose_task("nb_inertia.install", [
        "--client-framework",
        "react",
        "--camelize-props",
        "--typescript",
        "--with-flop",
        "--table",
        "--ssr"
      ])
      # Queue non-Igniter task to run after deps.get
      |> Igniter.add_task("nb_routes.gen", [
        "--style",
        "resource",
        "--output-dir",
        "assets/js/routes"
      ])
      |> create_complete_vite_config()
      |> print_success()
    end

    # Add GitHub dependencies
    defp add_github_deps(igniter) do
      igniter
      |> Igniter.Project.Deps.add_dep({:nb_vite, github: "nordbeam/nb_vite", override: true})
      |> Igniter.Project.Deps.add_dep({:nb_routes, github: "nordbeam/nb_routes", override: true})
      |> Igniter.Project.Deps.add_dep(
        {:nb_serializer, github: "nordbeam/nb_serializer", override: true}
      )
      |> Igniter.Project.Deps.add_dep({:nb_ts, github: "nordbeam/nb_ts", override: true})
      |> Igniter.Project.Deps.add_dep(
        {:nb_inertia, github: "nordbeam/nb_inertia", override: true}
      )
      |> Igniter.Project.Deps.add_dep({:nb_flop, github: "nordbeam/nb_flop", override: true})
    end

    # Configure nb_routes in config.exs
    defp configure_nb_routes(igniter) do
      router = Igniter.Libs.Phoenix.web_module_name(igniter, "Router")

      igniter
      |> Igniter.Project.Config.configure(
        "config.exs",
        :nb_routes,
        [:router],
        router
      )
      |> Igniter.Project.Config.configure(
        "config.exs",
        :nb_routes,
        [:style],
        :resource
      )
    end

    # Configure nb_inertia in config.exs (since sub-installer add_task doesn't merge config)
    defp configure_nb_inertia(igniter) do
      {igniter, endpoint_module} = Igniter.Libs.Phoenix.select_endpoint(igniter)

      igniter
      |> Igniter.Project.Config.configure(
        "config.exs",
        :nb_inertia,
        [:endpoint],
        endpoint_module
      )
      |> Igniter.Project.Config.configure(
        "config.exs",
        :nb_inertia,
        [:camelize_props],
        true
      )
    end

    # Create complete Vite config with SSR support
    defp create_complete_vite_config(igniter) do
      config = """
      import { defineConfig } from "vite";
      import path from "path";
      import phoenix from "@nordbeam/nb-vite";
      import tailwindcss from "@tailwindcss/vite";
      import react from "@vitejs/plugin-react";
      import nodePrefixPlugin from "./vite-plugins/node-prefix-plugin.js";

      export default defineConfig({
        plugins: [
          react({
            babel: {
              plugins: ["babel-plugin-react-compiler"],
            },
          }),
          tailwindcss(),
          nodePrefixPlugin(),
          phoenix({
            input: ["js/app.ts", "js/app.tsx", "css/app.css"],
            publicDirectory: "../priv/static",
            buildDirectory: "assets",
            hotFile: "../priv/hot",
            manifestPath: "../priv/static/assets/manifest.json",
            refresh: true,
            ssr: "js/ssr.tsx",
            ssrOutputDirectory: "../priv/static",
          }),
        ],
        server: {
          host: process.env.VITE_HOST || "127.0.0.1",
          port: parseInt(process.env.VITE_PORT || "5173"),
        },
        resolve: {
          alias: {
            "@": path.resolve(__dirname, "./js"),
          },
        },
      });
      """

      Igniter.create_new_file(igniter, "assets/vite.config.ts", config, on_exists: :overwrite)
    end

    # Print welcome message
    defp print_welcome(igniter) do
      message = """
      ╔═════════════════════════════════════════════════════════════════╗
      ║                    NB Stack Installer                           ║
      ║                                                                 ║
      ║  Installing complete frontend stack for Phoenix:                ║
      ║  • nb_vite      - Vite integration with HMR                     ║
      ║  • nb_routes    - Type-safe route helpers (resource style)      ║
      ║  • nb_serializer - JSON serialization with types                ║
      ║  • nb_ts        - TypeScript type generation                    ║
      ║  • nb_inertia   - Inertia.js with enhanced components           ║
      ║  • nb_flop      - Table DSL and Flop serializers                ║
      ║                                                                 ║
      ║  Configuration:                                                 ║
      ║  • Framework: React                                             ║
      ║  • TypeScript: enabled                                          ║
      ║  • SSR: enabled (DenoRider)                                     ║
      ╚═════════════════════════════════════════════════════════════════╝
      """

      Igniter.add_notice(igniter, message)
    end

    # Print success message with next steps
    defp print_success(igniter) do
      success_message = """

      ╔═══════════════════════════════════════════════════════════════╗
      ║                  Installation Complete!                       ║
      ╚═══════════════════════════════════════════════════════════════╝

      The complete nb_ frontend stack has been installed and configured:

      ✅ nb_vite       - Vite build system with HMR
      ✅ nb_routes     - Type-safe route helpers (resource style)
      ✅ nb_serializer - JSON serialization with camelCase
      ✅ nb_ts         - TypeScript type generation (enabled)
      ✅ nb_inertia    - Inertia.js with React and enhanced components
      ✅ nb_flop       - Table DSL and Flop serializers

      Configuration Summary:
      - Framework: React + TypeScript
      - Props: Automatically camelized for JavaScript conventions
      - Routes: Resource style with type-safe helpers
      - Components: Enhanced Inertia components with nb_routes integration
      - SSR: Enabled with DenoRider for production

      SSR Configuration:
      - Development SSR uses Vite's Module Runner API (built-in)
      - Production SSR uses DenoRider for optimal performance
      - Build SSR bundle with: bun run build:ssr (or npm/pnpm/yarn)
      - SSR entry point: assets/js/ssr.tsx

      Files Created:
      - assets/vite.config.ts (complete Vite configuration with SSR)
      - assets/js/routes/ (type-safe route helpers)
      - assets/js/lib/inertia.ts (enhanced Inertia components)
      - assets/js/pages/Home.tsx (sample page component)
      - assets/js/types/index.ts (TypeScript types for props)
      - config/config.exs (coordinated configuration)

      Next Steps:

      1. Create an Inertia-enabled controller:

         defmodule MyAppWeb.PageController do
           use MyAppWeb, :controller
           use NbInertia.Controller
           import NbTs.Sigil

         inertia_page :home do
             prop :greeting, type: ~TS"string"
           end

           def home(conn, _params) do
             render_inertia(conn, :home, greeting: "Hello!")
           end
         end

      2. Add a route in your router:

         get "/", PageController, :home

      3. Start your Phoenix server:

         mix phx.server

      4. Visit http://localhost:4000 to see your Inertia page!

      5. After making changes to props or serializers, regenerate types:

         mix ts.gen

      Enhanced Component Usage:

      Import enhanced components from @/lib/inertia (not @inertiajs/react):

      ```typescript
      import { router, Link, useForm } from '@/lib/inertia';
      import { users, user } from '@/routes';

      // Navigation with RouteResult objects
      router.visit(user(1));

      // Links with automatic method detection
      <Link href={user(1)}>View User</Link>

      // Forms bound to routes
      const form = useForm(data, user(1).update);
      form.submit();  // No method or URL needed!
      ```

      The enhanced components work seamlessly with nb_routes resource style,
      automatically detecting HTTP methods from RouteResult objects.

      Documentation:
      - nb_vite: https://hexdocs.pm/nb_vite
      - nb_routes: https://hexdocs.pm/nb_routes
      - nb_serializer: https://hexdocs.pm/nb_serializer
      - nb_ts: https://hexdocs.pm/nb_ts
      - nb_inertia: https://hexdocs.pm/nb_inertia
      - nb_flop: https://hexdocs.pm/nb_flop
      - Inertia.js: https://inertiajs.com

      Happy coding!
      """

      Igniter.add_notice(igniter, success_message)
    end
  end
end
