<h1 align="center">
  tab-bar-notch
</h1>

<p align="center">
  <strong>
    Adjust tab-bar height for MacBook Pro notch.
  </strong>
</p>

<p align="center">
  <a href="https://github.com/jimeh/tab-bar-notch/releases">
    <img src="https://img.shields.io/github/v/tag/jimeh/tab-bar-notch?label=release" alt="GitHub tag (latest SemVer)">
  </a>
  <a href="https://github.com/jimeh/tab-bar-notch/issues">
    <img src="https://img.shields.io/github/issues-raw/jimeh/tab-bar-notch.svg?style=flat&logo=github&logoColor=white" alt="GitHub issues">
  </a>
  <a href="https://github.com/jimeh/tab-bar-notch/pulls">
    <img src="https://img.shields.io/github/issues-pr-raw/jimeh/tab-bar-notch.svg?style=flat&logo=github&logoColor=white" alt="GitHub pull requests">
  </a>
  <a href="https://github.com/jimeh/tab-bar-notch/blob/main/LICENSE">
    <img src="https://img.shields.io/github/license/jimeh/tab-bar-notch.svg?style=flat" alt="License Status">
  </a>
</p>

When using the non-native fullscreen mode of Emacs on modern MacBook Pro
machines, it ends up rendering buffer content behind the camera notch. This
package attempts to solve this by way of resizing the tab-bar to fill the
vertical space taken up by the camera notch.

Obviously `tab-bar-mode` must be enabled with the tab-bar visible at the top of
the frame for this package to be able to function.

## Non-Native Fullscreen?

The default native fullscreen implementation on macOS can be rather annoying, as
it moves applications over to their own separate desktop Space. This prevents
you from layering windows from other applications on top it, among other things.

Emacs supports both native and non-native fullscreen modes. In the non-native
mode, Emacs just acts like any other window, but stretches itself to cover the
whole screen, and hides the menu bar and dock. Non-native fullscreen is enabled
with:

```elisp
(setq ns-use-native-fullscreen nil)
```

In the non-native fullscreen mode, Emacs is not aware of the physical camera
notch however, so it does not know to avoid rendering things behind it.

## Installation

### use-package + straight.el

```elisp
(use-package tab-bar-notch
  :straight (:host github :repo "jimeh/tab-bar-notch"))
```

### Manual

Place `tab-bar-notch.el` somewhere in your `load-path` and require it. For
example `~/.emacs.d/vendor`:

```elisp
(add-to-list 'load-path "~/.emacs.d/vendor")
(require 'tab-bar-notch)
```

## Usage

You must be using `tab-bar-mode`, with the tab-bar visible at the top of the
frame above all buffers.

Then simply add `tab-bar-notch-spacer` to the `tab-bar-format` variable, for
example:

```elisp
(setq tab-bar-format '(tab-bar-format-history
                       tab-bar-format-tabs
                       tab-bar-separator
                       tab-bar-format-add-tab
                       tab-bar-notch-spacer))
```

To disable the package, simply remove `tab-bar-notch-spacer`, and it will
unregister itself from window resizing hooks.
