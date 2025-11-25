# NbStack

**Meta-package and installer for the complete nb_ frontend stack**

NbStack provides a single command to install and configure a modern Phoenix frontend development experience with Vite, Inertia.js, type-safe routing, and TypeScript integration.

## What's Included

NbStack orchestrates the installation of:

- **[nb_vite](https://github.com/nordbeam/nb_vite)** - Vite integration for Phoenix with HMR and optimized builds
- **[nb_inertia](https://github.com/nordbeam/nb_inertia)** - Inertia.js integration with declarative page DSL and modal support
- **[nb_routes](https://github.com/nordbeam/nb_routes)** - Type-safe route helpers with rich mode and form helpers
- **[nb_ts](https://github.com/nordbeam/nb_ts)** - TypeScript type generation from Elixir serializers and Inertia pages
- **[nb_serializer](https://github.com/nordbeam/nb_serializer)** - High-performance JSON serialization with declarative DSL

## Installation

Run the installer directly from GitHub:

```bash
mix igniter.install nb_stack@github:nordbeam/nb_stack
```

This single command installs and configures the entire stack with smart defaults optimized for modern Phoenix development.

## What Gets Configured

The installer:

1. ✅ Installs **nb_vite** with TypeScript support and Vite dev server
2. ✅ Generates **type-safe route helpers** with rich mode (returns `{ url, method }` objects)
3. ✅ Configures **nb_serializer** for high-performance JSON with camelized props
4. ✅ Sets up **TypeScript type generation** for props and serializers
5. ✅ Installs **nb_inertia** with your chosen framework and enhanced components
6. ✅ Adds **Vite nbRoutes plugin** for auto-regenerating routes on file save
7. ✅ Coordinates configuration across all packages (camelize_props, TypeScript paths, etc.)

## Default Stack

By default, NbStack installs:

- **React** + **TypeScript**
- **Rich routes** with method variants and form helpers
- **Serializer** with automatic type generation
- **Camelized props** for JavaScript conventions
- **Enhanced Inertia components** with nb_routes integration

## Options

Customize the installation:

```bash
# Install with defaults (React + TypeScript)
mix igniter.install nb_stack

# Install with Vue
mix igniter.install nb_stack --framework vue

# Install with Svelte
mix igniter.install nb_stack --framework svelte

# Install without TypeScript
mix igniter.install nb_stack --no-typescript

# Install with SSR
mix igniter.install nb_stack --ssr

# Skip confirmation prompts
mix igniter.install nb_stack --yes
```

### Available Options

- `--framework` - Client framework: `react` (default), `vue`, or `svelte`
- `--typescript` - Enable TypeScript (default: `true`)
- `--ssr` - Enable server-side rendering (default: `false`)
- `--yes` - Skip confirmation prompts

## Quick Start

After installation, create your first Inertia page:

### 1. Create a Controller

```elixir
# lib/my_app_web/controllers/page_controller.ex
defmodule MyAppWeb.PageController do
  use MyAppWeb, :controller
  use NbInertia.Controller

  inertia_page :home do
    prop :greeting, type: ~TS"string"
  end

  def home(conn, _params) do
    render_inertia(conn, :home,
      greeting: "Hello from NbStack!"
    )
  end
end
```

### 2. Add a Route

```elixir
# lib/my_app_web/router.ex
scope "/", MyAppWeb do
  pipe_through :browser

  get "/", PageController, :home
end
```

### 3. Create a React Component

```tsx
// assets/js/pages/Home.tsx
import React from 'react';
import { Link } from '@/lib/inertia';
import { users_path } from '@/routes';
import type { HomeProps } from '@/types';

export default function Home({ greeting }: HomeProps) {
  return (
    <div>
      <h1>{greeting}</h1>
      <Link href={users_path()}>View Users</Link>
    </div>
  );
}
```

### 4. Start the Server

```bash
mix phx.server
```

Visit http://localhost:4000 to see your Inertia page!

## The Enhanced Stack Experience

NbStack provides a cohesive development experience where all packages work together seamlessly.

### Type-Safe Routing with nb_routes

Routes return `RouteResult` objects containing both URL and HTTP method:

```typescript
import { user_path, update_user_path } from '@/routes';

// Returns: { url: "/users/1", method: "get" }
user_path(1);

// Returns: { url: "/users/1", method: "patch" }
update_user_path.patch(1);
```

### Enhanced Inertia Components

Import enhanced components from `@/lib/inertia` (created by installer):

```typescript
import { router, Link, useForm } from '@/lib/inertia';
import { user_path, update_user_path } from '@/routes';

// Navigation - method automatically detected
router.visit(user_path(1));

// Links - method from RouteResult
<Link href={user_path(1)}>View User</Link>

// Forms - bound to route
const form = useForm(data, update_user_path.patch(1));
form.submit();  // No method or URL needed!
```

### Automatic Type Generation

Define serializers in Elixir, get TypeScript types automatically:

```elixir
# lib/my_app/users/user_serializer.ex
defmodule MyApp.Users.UserSerializer do
  use NbSerializer.Serializer

  field :id, :integer
  field :name, :string
  field :email, :string
end
```

After running `mix ts.gen`:

```typescript
// Generated in assets/js/types/index.ts
export interface User {
  id: number;
  name: string;
  email: string;
}
```

Use in your Inertia pages with full type safety:

```elixir
inertia_page :users_index do
  prop :users, {:array, UserSerializer}
end
```

```typescript
// Type automatically generated
export interface UsersIndexProps {
  users: User[];
}
```

### Auto-Regenerating Routes

The Vite plugin watches your Phoenix router and automatically regenerates route helpers on changes:

1. Add a route to `router.ex`
2. Save the file
3. Routes regenerate instantly
4. HMR updates your browser
5. New route immediately available in frontend

No manual `mix nb_routes.gen` needed during development!

## Type Safety Flow

Here's how the full stack provides end-to-end type safety:

```
┌──────────────────────────────────────────────────────────┐
│                    Phoenix Backend                        │
│                                                            │
│  1. Define routes in router.ex                           │
│  2. Create serializers with NbSerializer                 │
│  3. Define Inertia pages with typed props                │
│                                                            │
│     inertia_page :users_index do                         │
│       prop :users, {:array, UserSerializer}              │
│     end                                                   │
└────────────────────┬─────────────────────────────────────┘
                     │
                     │ Compile-time Code Generation
                     ▼
┌──────────────────────────────────────────────────────────┐
│                     Frontend (Assets)                     │
│                                                            │
│  • routes.js + routes.d.ts (from nb_routes)              │
│  • types/index.ts (from nb_ts)                           │
│  • lib/inertia.ts (enhanced components)                  │
│                                                            │
│  import { user_path } from '@/routes';                   │
│  import { Link } from '@/lib/inertia';                   │
│  import type { User, UsersIndexProps } from '@/types';   │
│                                                            │
│  export default function Index({ users }: UsersIndexProps)│
│    return users.map(user => (                            │
│      <Link href={user_path(user.id)}>{user.name}</Link> │
│    ));                                                    │
│  }                                                        │
└──────────────────────────────────────────────────────────┘
```

## File Structure

After installation, your project will have:

```
my_app/
├── assets/
│   ├── js/
│   │   ├── app.tsx              # Inertia entry point
│   │   ├── routes.js            # Generated route helpers
│   │   ├── routes.d.ts          # TypeScript definitions for routes
│   │   ├── lib/
│   │   │   └── inertia.ts       # Enhanced Inertia components
│   │   ├── pages/
│   │   │   └── Home.tsx         # Sample page component
│   │   └── types/
│   │       └── index.ts         # Generated TypeScript types
│   ├── vite.config.ts           # Vite configuration with nbRoutes plugin
│   ├── tsconfig.json            # TypeScript configuration
│   └── package.json             # npm dependencies
├── config/
│   └── config.exs               # Coordinated nb_ configuration
└── lib/
    └── my_app_web/
        ├── controllers/         # Your controllers with inertia_page
        └── router.ex            # Phoenix routes
```

## Documentation

- **NbStack**: You're reading it!
- **nb_vite**: https://hexdocs.pm/nb_vite
- **nb_inertia**: https://hexdocs.pm/nb_inertia
- **nb_routes**: https://hexdocs.pm/nb_routes
- **nb_ts**: https://hexdocs.pm/nb_ts
- **nb_serializer**: https://hexdocs.pm/nb_serializer
- **Inertia.js**: https://inertiajs.com

## Architecture Principles

NbStack follows these design principles:

1. **Convention over Configuration** - Smart defaults that work together
2. **Coordinated Setup** - All packages configured consistently
3. **Type Safety** - End-to-end types from Elixir to TypeScript
4. **Developer Experience** - Fast feedback loops with HMR and auto-regeneration
5. **Optional Dependencies** - Each package can be used standalone if needed

## Comparison with Manual Installation

### Manual Installation (Before NbStack)

```bash
mix igniter.install nb_vite --typescript
mix nb_routes.gen --variant rich --with-methods --with-forms
mix nb_serializer.install --with-typescript --camelize-props
mix nb_ts.install --output-dir assets/js/types
mix nb_inertia.install --client-framework react --typescript --camelize-props

# Then manually:
# - Add nbRoutes plugin to vite.config.ts
# - Configure camelize_props in both nb_inertia and nb_serializer
# - Set up TypeScript paths
# - Create lib/inertia.ts
```

### With NbStack

```bash
mix igniter.install nb_stack
```

That's it! Everything is installed, configured, and coordinated automatically.

## Troubleshooting

### Types Not Generating

If TypeScript types aren't generating, run:

```bash
mix compile --force
mix ts.gen
```

### Routes Not Auto-Regenerating

Ensure the nbRoutes plugin is in your `vite.config.ts`:

```typescript
import { nbRoutes } from '@nordbeam/nb-vite/nb-routes';

export default defineConfig({
  plugins: [
    phoenix({ input: ['js/app.tsx'] }),
    nbRoutes({ enabled: true })
  ]
});
```

### Camelize Props Not Working

Check that both nb_inertia and nb_serializer have `camelize_props: true`:

```elixir
# config/config.exs
config :nb_inertia, camelize_props: true
config :nb_serializer, camelize_props: true
```

## Contributing

NbStack is part of the [nb_ monorepo](https://github.com/nordbeam/nb). Contributions welcome!

## License

MIT License. See [LICENSE](LICENSE) for details.

## Credits

Built by [Nordbeam](https://nordbeam.io) to make Phoenix frontend development delightful.
