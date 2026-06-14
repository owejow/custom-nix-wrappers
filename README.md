# Custom Nix Wrappers

This repository contains a collection of custom Nix expressions and wrappers designed to bundle applications with their specific configurations, environment variables, dependencies, and runtimes into predictable, isolated derivations. 

By leveraging the power of the Nix ecosystem, these wrappers allow you to run configured applications consistently across different machines without relying on global state or imperative dotfile orchestration.

## Features

* **Isolated Environments**: Bundle application binaries with strict runtime paths and localized configurations.
* **Flake Support**: Modern Nix flake interface for easy integration into NixOS systems, Home Manager setups, or temporary development shells.
* **Environment Configuration**: Pre-configured environment variables, execution flags, and wrapper logic built natively with Nix.
* **Modular Setup**: Easily customizable templates for extending existing wrapper definitions to match your personal workflow.

## Prerequisites

To use these wrappers, you must have Nix installed on your system with flakes enabled. If you have not enabled flakes yet, add the following configuration to your `nix.conf` file:

```nix
experimental-features = nix-command flakes
```

## Usage

### Using as a Nix Flake

You can run or inspect the wrapped applications directly from this repository using the `nix run` or `nix shell` commands:

```bash
# Run a specific wrapped application directly
nix run github:owejow/custom-nix-wrappers#<wrapper-name>

# Drop into a shell containing a wrapped application
nix shell github:owejow/custom-nix-wrappers#<wrapper-name>
```

### Integrating into an Existing Nix Configuration

To add these wrappers to your system or Home Manager configuration, add this repository as an input to your system `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    custom-wrappers.url = "github:owejow/custom-nix-wrappers";
  };

  outputs = { self, nixpkgs, custom-wrappers, ... }: 
  let
    system = "x86_64-linux"; # Adjust to your system architecture
    pkgs = nixpkgs.legacyPackages.\${system};
  in {
    # Configuration usage logic goes here
  };
}
```

Then reference the package within your environment setup:

```nix
environment.systemPackages = [
  custom-wrappers.packages.\${system}.<wrapper-name>
];
```

## Local Development

If you want to clone this repository and modify or add your own wrappers locally, use the following commands:

1. Clone the repository:
   ```bash
   git clone https://github.com
   cd custom-nix-wrappers
   ```

2. Build a specific wrapper to verify your modifications:
   ```bash
   nix build .#<wrapper-name>
   ```

3. Test your changes by running the local build:
   ```bash
   ./result/bin/<wrapper-binary>
   ```

## Repository Structure

* `flake.nix`: The entrypoint defining package outputs, systems, and dependencies.
* `pkgs/`: Directory housing the standalone Nix expressions for individual application wrappers.
* `wezterm/`: Directory containing bundled Lua layouts and keybindings.

---

## WezTerm Custom Keybindings

The wrapped WezTerm application automatically injects custom key combinations defined in the `wezterm/lua/keybindings/init.lua` schema. This setup implements an isolated, **tmux-like operational paradigm** inside your custom Nix derivation.

* **Leader Prefix**: `CTRL + b`

### Workspaces & Session Management

| Shortcut | Action |
| :--- | :--- |
| `LEADER + $` | Rename current workspace |
| `LEADER + w` | Create new workspace |
| `LEADER + s` | Open interactive workspace selector |
| `LEADER + (` | Go to previous workspace |
| `LEADER + )` | Go to next workspace |
| `LEADER + CTRL + s` | Save current session state |
| `LEADER + CTRL + l` | Load saved session |
| `LEADER + CTRL + r` | Restore active session |

### Tabs Management

| Shortcut | Action |
| :--- | :--- |
| `LEADER + c` | Create a new tab |
| `LEADER + &` | Close the current tab (prompts for confirmation) |
| `LEADER + ,` | Rename the current tab |
| `LEADER + p` | Switch to the previous tab |
| `LEADER + n` | Switch to the next tab |
| `LEADER + [1-9]` | Direct jump to tab index 1 through 9 |
| `LEADER + SHIFT + t` | Activate **Move Tab Mode** (`h`/`l` to shift layout, `Esc` to exit) |

### Panes Management

| Shortcut | Action |
| :--- | :--- |
| `LEADER + |` | Split active pane horizontally |
| `LEADER + -` | Split active pane vertically |
| `LEADER + h` / `j` / `k` / `l` | Move focus Left / Down / Up / Right |
| `LEADER + <` / `>` | Rotate active panes counter-clockwise / clockwise |
| `LEADER + q` | Toggle interactive pane numbers selector |
| `LEADER + z` | Toggle pane zoom state (maximize/minimize) |
| `LEADER + !` | Break active pane out into a standalone window tab |
| `LEADER + x` | Close current pane (prompts for confirmation) |
| `LEADER + Space` | Trigger interactive quick-select mode |

### Modal Keytables

#### 1. Resize Pane Mode (`LEADER + r`)
Enters a temporary, persistent state to shift active pane boundaries:
* `h` / `j` / `k` / `l`: Expand pane Left / Down / Up / Right.
* `Enter` / `Escape`: Exit sizing mode.

#### 2. Window Resize Mode (`LEADER + SHIFT + r`)
Enters a temporary, persistent state to change global terminal pixels:
* `h` / `l`: Decrease / Increase global window width.
* `k` / `j`: Decrease / Increase global window height.
* `Escape`: Exit window size mode.

#### 3. Vi-Copy Mode (`LEADER + [ `)
Enters native scrollback inspection using standard Vi movements:
* **Navigation**: `h`, `j`, `k`, `l` (character), `w` / `b` / `e` (word blocks).
* **Boundaries**: `0` / `^` to jump to line start, `$` to jump to line end.
* **Viewport**: `G` (bottom line), `g` (top line), `H` (screen top), `L` (screen bottom).
* **Selection**: `v` (Character selection), `V` (Line selection), `CTRL + v` (Block visual mode).
* **Clipboard**: Press `y` to yank selections directly into the system clipboard.
* **Search**: `/` for forward searching, `?` for backward searching. Cycle with `n` / `N`.

---

## License

This project is open-source and available under the MIT License. See the LICENSE file for details.

