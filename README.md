# GitPalette

macOS menu bar app for Gitmoji and a small Git launcher. Open it from the menu bar or **⌘⇧G**.

<p align="center">
  <img src="post.png" alt="GitPalette" width="520" />
</p>

## Features

- **Gitmoji** — search the bundled catalog offline, copy emoji, `:code:`, or a custom template
- **Recent picks** — jump back to Gitmoji you copied last
- **`/git`** — link repos, then run `status`, `add`, `commit`, `repos`, `use`, `unlink` from the launcher
- **Commit preview** — `/git commit` plus Space or Return shows the history graph; known shortcodes such as `:bug:` render as emoji
- **Global hotkey** — default **⌘⇧G** (configurable). Accessibility is optional and only helps steal keyboard focus from other apps
- **Languages** — UI, Gitmoji codes, and descriptions can be English or Simplified Chinese independently

Gitmoji data is bundled from [gitmoji.dev](https://gitmoji.dev/).

## Requirements

macOS 13.0+ · Xcode 15+

Open `GitPalette.xcodeproj`, run the **GitPalette** scheme on **My Mac**. Quit any leftover menu bar process before Run.

## License

Copyright © 2026 ZhiH2333. [AGPL-3.0](LICENSE).
