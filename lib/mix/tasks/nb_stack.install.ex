if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.NbStack.Install do
    @moduledoc """
    Installs and configures the complete nb_ frontend stack for Phoenix.

    This installer orchestrates the installation of:
    - nb_vite: Vite integration with HMR
    - nb_routes: Type-safe route helpers (rich mode)
    - nb_serializer: High-performance JSON serialization
    - nb_ts: TypeScript type generation
    - nb_inertia: Inertia.js SPA framework with enhanced components

    ## Usage

    ```bash
    mix igniter.install nb_stack@github:nordbeam/nb_stack
    ```

    ## Options

    - `--framework` - Client framework: react (default), vue, or svelte
    - `--typescript` - Enable TypeScript (default: true)
    - `--ssr` - Enable server-side rendering (default: false)
    - `--yes` - Skip confirmation prompts

    ## What Gets Installed

    1. nb_vite with TypeScript support
    2. nb_routes in rich mode with method variants and form helpers
    3. nb_serializer with TypeScript integration and camelized props
    4. nb_ts for automatic type generation
    5. nb_inertia with your chosen framework and enhanced components
    6. Vite plugin configuration for auto-regenerating routes
    7. Coordinated configuration across all packages

    ## Examples

    ```bash
    # Install with defaults (React + TypeScript)
    mix igniter.install nb_stack@github:nordbeam/nb_stack

    # Install with Vue
    mix igniter.install nb_stack@github:nordbeam/nb_stack --framework vue

    # Install without TypeScript
    mix igniter.install nb_stack@github:nordbeam/nb_stack --no-typescript

    # Install with SSR
    mix igniter.install nb_stack@github:nordbeam/nb_stack --ssr
    ```
    """

    use Igniter.Mix.Task

    @impl Igniter.Mix.Task
    def info(_argv, _parent) do
      %Igniter.Mix.Task.Info{
        group: :nb,
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
        positional: [],
        # When published to Hex, use installs: to declare dependencies
        # For now (GitHub only), we manually add deps and compose installers
        composes: ["deps.get"],
        example: "mix igniter.install nb_stack --framework react --typescript"
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      framework = igniter.args.options[:framework] || "react"
      typescript = igniter.args.options[:typescript] || true
      ssr = igniter.args.options[:ssr] || false

      igniter
      |> print_welcome()
      |> validate_options()
      # Add GitHub dependencies manually (until published to Hex)
      |> add_github_deps()
      # Configure nb_routes (doesn't have an Igniter installer, uses Mix task)
      |> configure_nb_routes()
      # Queue tasks to run after deps.get (composes: ["deps.get"] ensures deps are fetched first)
      |> Igniter.add_task("nb_vite.install", build_vite_opts(framework, typescript))
      |> Igniter.add_task("nb_serializer.install", build_serializer_opts(typescript))
      |> Igniter.add_task("nb_inertia.install", build_inertia_opts(framework, typescript, ssr))
      |> Igniter.add_task("nb_routes.gen", [
        "--variant",
        "rich",
        "--with-methods",
        "--with-forms",
        "--output",
        "assets/js/routes.js"
      ])
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
    end

    # Build options for nb_vite installer
    defp build_vite_opts(framework, typescript) do
      case framework do
        "react" -> if typescript, do: ["--typescript"], else: []
        _ -> if typescript, do: ["--typescript"], else: []
      end
    end

    # Build options for nb_serializer installer
    defp build_serializer_opts(typescript) do
      ["--with-phoenix", "--camelize-props"] ++
        if typescript, do: ["--with-typescript"], else: []
    end

    # Build options for nb_inertia installer
    defp build_inertia_opts(framework, typescript, ssr) do
      ["--client-framework", framework, "--camelize-props"] ++
        if typescript,
          do: ["--typescript"],
          else:
            [] ++
              if(ssr, do: ["--ssr"], else: [])
    end

    # Print welcome message
    defp print_welcome(igniter) do
      framework = igniter.args.options[:framework] || "react"
      typescript = igniter.args.options[:typescript] || true
      ssr = igniter.args.options[:ssr] || false

      message = """
      ╔═════════════════════════════════════════════════════════════════╗
      ║                    NB Stack Installer                           ║
      ║                                                                 ║
      ║  Installing complete frontend stack for Phoenix:                ║
      ║  • nb_vite      - Vite integration with HMR                     ║
      ║  • nb_routes    - Type-safe route helpers (rich mode)           ║
      ║  • nb_serializer - JSON serialization with types                ║
      ║  • nb_ts        - TypeScript type generation                    ║
      ║  • nb_inertia   - Inertia.js with enhanced components           ║
      ║                                                                 ║
      ║  Configuration:                                                 ║
      ║  • Framework: #{String.pad_trailing(framework, 10)}             ║
      ║  • TypeScript: #{if typescript, do: "enabled", else: "disabled"}║
      ║  • SSR: #{if ssr, do: "enabled", else: "disabled"}              ║
      ╚═════════════════════════════════════════════════════════════════╝
      """

      Igniter.add_notice(igniter, message)
    end

    # Validate options
    defp validate_options(igniter) do
      framework = igniter.args.options[:framework]

      unless framework in ["react", "vue", "svelte"] do
        Igniter.add_warning(
          igniter,
          "Invalid framework '#{framework}'. Must be 'react', 'vue', or 'svelte'. Using 'react'."
        )
      else
        igniter
      end
    end

    # Configure nb_routes in config.exs
    defp configure_nb_routes(igniter) do
      igniter
      |> Igniter.Project.Config.configure(
        "config.exs",
        :nb_routes,
        [:variant],
        :rich
      )
      |> Igniter.Project.Config.configure(
        "config.exs",
        :nb_routes,
        [:with_methods],
        true
      )
      |> Igniter.Project.Config.configure(
        "config.exs",
        :nb_routes,
        [:with_forms],
        true
      )
    end

    # Print success message with next steps
    defp print_success(igniter) do
      framework = igniter.args.options[:framework] || "react"
      typescript = igniter.args.options[:typescript] || true
      ssr = igniter.args.options[:ssr] || false

      extension = if typescript, do: "tsx", else: "jsx"

      ssr_info =
        if ssr do
          """

          SSR Configuration:
          - SSR has been enabled and configured for development and production
          - Development SSR uses Vite's Module Runner API (built-in)
          - Production SSR uses DenoRider for optimal performance
          - Build SSR bundle with: bun run build:ssr (or npm/pnpm/yarn)
          - SSR entry points created:
            • assets/js/ssr_dev.#{extension}
            • assets/js/ssr_prod.#{extension}
          """
        else
          ""
        end

      success_message = """

      ╔═══════════════════════════════════════════════════════════════╗
      ║                  Installation Complete! 🎉                     ║
      ╚═══════════════════════════════════════════════════════════════╝

      The complete nb_ frontend stack has been installed and configured:

      ✅ nb_vite       - Vite build system with HMR
      ✅ nb_routes     - Type-safe route helpers (rich mode)
      ✅ nb_serializer - JSON serialization with camelCase
      ✅ nb_ts         - TypeScript type generation #{if typescript, do: "(enabled)", else: "(disabled)"}
      ✅ nb_inertia    - Inertia.js with #{framework} and enhanced components

      Configuration Summary:
      - Framework: #{String.capitalize(framework)} #{if typescript, do: "+ TypeScript", else: ""}
      - Props: Automatically camelized for JavaScript conventions
      - Routes: Rich mode with method variants and form helpers
      - Components: Enhanced Inertia components with nb_routes integration
      - Vite Plugin: Auto-regenerates routes on router changes#{ssr_info}

      Files Created:
      - assets/vite.config.#{if typescript, do: "ts", else: "js"} (updated with nbRoutes plugin)
      - assets/js/routes.js + routes.d.ts (type-safe route helpers)
      - assets/js/lib/inertia.#{if typescript, do: "ts", else: "js"} (enhanced Inertia components)
      - assets/js/pages/Home.#{extension} (sample page component)#{if typescript, do: "\n      - assets/js/types/index.ts (TypeScript types for props)", else: ""}
      - config/config.exs (coordinated configuration)

      Next Steps:

      1. Create an Inertia-enabled controller:

         defmodule MyAppWeb.PageController do
           use MyAppWeb, :controller
           use NbInertia.Controller#{if typescript, do: "\n         import NbTs.Sigil", else: ""}

           inertia_page :home do
             prop :greeting, #{if typescript, do: "type: ~TS\"string\"", else: ":string"}
           end

           def home(conn, _params) do
             render_inertia(conn, :home, greeting: "Hello!")
           end
         end

      2. Add a route in your router:

         get "/", PageController, :home

      3. Start your Phoenix server:

         mix phx.server

      4. Visit http://localhost:4000 to see your Inertia page!#{if typescript, do: "\n\n      5. After making changes to props or serializers, regenerate types:\n\n         mix ts.gen", else: ""}

      Enhanced Component Usage:

      Import enhanced components from @/lib/inertia (not @inertiajs/#{framework}):

      ```#{if typescript, do: "typescript", else: "javascript"}
      import { router, Link, useForm } from '@/lib/inertia';
      import { users_path, user_path } from '@/routes';

      // Navigation with RouteResult objects
      router.visit(user_path(1));

      // Links with automatic method detection
      <Link href={user_path(1)}>View User</Link>

      // Forms bound to routes
      const form = useForm(data, update_user_path.patch(1));
      form.submit();  // No method or URL needed!
      ```

      The enhanced components work seamlessly with nb_routes rich mode,
      automatically detecting HTTP methods from RouteResult objects.

      Documentation:
      - nb_vite: https://hexdocs.pm/nb_vite
      - nb_routes: https://hexdocs.pm/nb_routes
      - nb_serializer: https://hexdocs.pm/nb_serializer#{if typescript, do: "\n      - nb_ts: https://hexdocs.pm/nb_ts", else: ""}
      - nb_inertia: https://hexdocs.pm/nb_inertia
      - Inertia.js: https://inertiajs.com

      Happy coding! 🚀
      """

      Igniter.add_notice(igniter, success_message)
    end
  end
end
