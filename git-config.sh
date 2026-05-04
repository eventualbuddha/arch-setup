#!/usr/bin/env bash
set -euo pipefail

g() { git config --global "$@"; }

# Identity
g user.name  "Brian Donovan"
g user.email "brian@donovans.cc"

# New repos default to 'main'
g init.defaultBranch main

# Editor
g core.editor nvim

# Pull: rebase instead of merge keeps history linear
g pull.rebase true
# Stash dirty working tree automatically before a rebase, restore after
g rebase.autoStash true
# Honour fixup!/squash! commit prefixes during interactive rebase
g rebase.autoSquash true

# Push: set upstream automatically on first push so -u isn't needed
g push.autoSetupRemote true
# Refuse ambiguous pushes; only push the current branch to its tracking branch
g push.default simple

# Fetch: prune stale remote-tracking refs automatically
g fetch.prune     true
g fetch.pruneTags false

# Show zdiff3-style conflict markers (includes the common ancestor hunk)
# Requires git >= 2.35
g merge.conflictStyle zdiff3

# Histogram diff is more accurate than the default Myers algorithm
g diff.algorithm histogram
# Highlight lines that were moved (rather than added+deleted)
g diff.colorMoved default

# Normalise line endings to LF on commit; leave working tree alone
g core.autocrlf input

# Sort branches by most recently committed, not alphabetically
g branch.sort -committerdate

# Sort tags as version numbers (v1.10 > v1.9)
g tag.sort version:refname

# Re-use recorded conflict resolutions across rebases/merges
g rerere.enabled true

# Prompt before auto-correcting a mistyped subcommand (requires git >= 2.37)
g help.autocorrect prompt

echo "Global git config updated."
