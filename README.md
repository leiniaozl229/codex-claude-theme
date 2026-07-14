# Codex Claude Theme Lab

macOS patch kit for a local, presentation-only Claude-style Codex experiment.

> Unofficial and unaffiliated with OpenAI or Anthropic. Codex and Claude are trademarks of their respective owners.

It copies the installed Codex app, injects the CSS/JS/SVG assets in this folder, and ad-hoc signs the copy. It never alters the original app and does not include an OpenAI or Anthropic client binary.

## Optional custom wordmark

The public kit deliberately ships without third-party logo files. By default, the upper-left label is rendered as text. To use a wordmark you are authorized to redistribute, add both files before running the installer:

- `assets/custom-wordmark-dark.svg` — for dark mode
- `assets/custom-wordmark-light.svg` — for light mode

The installer detects those two files and enables the wordmark automatically. Copy the provided `.example` files to start.

## Install

1. Install Codex for macOS in `/Applications/ChatGPT.app`.
2. Run:

```bash
cd claude-codex-theme
chmod +x install.sh
./install.sh
```

The themed copy is created at `~/Applications/Codex Claude Lab.app`.

Source Serif 4 is bundled as a web font, so no separate font installation is needed. Its original SIL Open Font License is included at `assets/SourceSerif4-OFL.txt`.

## Reapply after updates

Codex updates replace packaged web assets. Keep the original client updated, then run:

```bash
./install.sh --force
```

## Notes

- This is a local visual experiment. It changes no Codex behavior or server-side identity.
- The copy is ad-hoc signed locally; macOS may show the signer as your local machine rather than OpenAI.
- It relies on the current Electron package layout (`Contents/Resources/app.asar`); a future app architecture change can require an installer update.
