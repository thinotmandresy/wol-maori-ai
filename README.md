<h1 align="center">Wars of Liberty</h1>

<p align="center">
  <img alt="Wars of Liberty logo" width="400" src="./wol_logo.png" />
</p>

<h2 align="center">Te Rauparaha &mdash; Maori AI</h2>

This repository hosts the development of the Maori AI for
[Wars of Liberty](https://aoe3wol.com/), a mod for the game Age of Empires III.
The Maori AI is written from the ground up, so this repository has been made
public to let the community contribute, either by playtesting or by helping with the
AI code.

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Installation](#installation)
  - [Backup Existing Files](#backup-existing-files)
  - [Download and Extract the Maori AI](#download-and-extract-the-maori-ai)
- [Uninstallation](#uninstallation)
  - [Remove AI Files](#remove-ai-files)
  - [Restore Backup Files](#restore-backup-files)
- [Feedback](#feedback)

---

## Installation

### Backup Existing Files

Before installing the Maori AI, go to your **Age of Empires III** game folder (`AI3` folder) and backup the following files:

- `_aiArrays.xs`
- `_aiForecasts.xs`
- `_aiHeader.xs`
- `_aiPlans.xs`
- `_aiQueries.xs`
- `_TeRauparaha.xs`

Simply move these files to a safe location.

### Download and Extract the Maori AI

1. Download the latest version of the Maori AI from [here](https://github.com/thinotmandresy/wol-maori-ai/archive/refs/heads/main.zip).
2. Extract the contents of the downloaded file into your **Age of Empires III** game folder (where the original AI files are located).

## Uninstallation

### Remove AI Files

To uninstall, simply **delete** the following file from the **AI3** folder:

- `_TeRauparaha.xs`

### Restore Backup Files

Restore your backup files to their original location in the **AI3** folder.

## Feedback

If you encounter any issues or have feedback, please join the [Wars of Liberty Discord](https://discord.gg/Jpjm9Ja) and discuss it in the **#ai-issues** channel. You can also [open an issue](https://github.com/thinotmandresy/wol-maori-ai/issues) on this repository.
