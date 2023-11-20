;;; tab-bar-notch.el --- Adjust tab-bar height for MacBook Pro notch -*- lexical-binding: t; -*-

;; Author: Jim Myhrberg <contact@jimeh.me>
;; URL: https://github.com/jimeh/tab-bar-notch
;; Package-Requires: ((emacs "27.1"))
;; Keywords: convenience, hardware
;; x-release-please-start-version
;; Version: 0.0.6
;; x-release-please-end

;; This file is not part of GNU Emacs.

;;; License:
;;
;; Copyright (c) 2023 Jim Myhrberg
;;
;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:
;;
;; When using the non-native fullscreen mode of Emacs on modern MacBook Pro
;; machines, it ends up rendering buffer content behind the camera notch. This
;; package attempts to solve this by way of resizing the tab-bar to fill the
;; vertical space taken up by the camera notch.
;;
;; Obviously `tab-bar-mode' must be enabled with the tab-bar visible at the top
;; of the frame for this package to be able to function.
;;
;; Non-Native Fullscreen?
;;
;; The default native fullscreen implementation on macOS can be rather annoying,
;; as it moves applications over to their own separate desktop Space. This
;; prevents you from layering windows from other applications on top it, among
;; other things.
;;
;; Emacs supports both native and non-native fullscreen modes. In the non-native
;; mode, Emacs just acts like any other window, but stretches itself to cover
;; the whole screen, and hides the menu bar and dock. Non-native fullscreen is
;; enabled with:
;;
;;     (setq ns-use-native-fullscreen nil)
;;
;; In the non-native fullscreen mode, Emacs is not aware of the physical camera
;; notch however, so it does not know to avoid rendering things behind it.
;;
;; Usage
;;
;; You must be using `tab-bar-mode', with the tab-bar visible at the top of the
;; frame above all buffers.
;;
;; Then simply add `tab-bar-notch-spacer' to the `tab-bar-format' variable, for
;; example:
;;
;;     (setq tab-bar-format '(tab-bar-format-history
;;                            tab-bar-format-tabs
;;                            tab-bar-separator
;;                            tab-bar-format-add-tab
;;                            tab-bar-notch-spacer))
;;
;; To disable the package, simply remove `tab-bar-notch-spacer', and it will
;; unregister itself from window resizing hooks.

;;; Code:

(require 'cl-lib)

(defgroup tab-bar-notch nil
  "Adjust the tab bar height for the camera notch on modern MacBook Pro models."
  :group 'convenience
  :prefix "tab-bar-notch-")

(defcustom tab-bar-notch-screen-sizes '((1.539 . 3.513)  ; 14-inch MacBook Pro
                                        (1.547 . 3.088)) ; 16-inch MacBook Pro
  "List of screen size ratios and their relative notch heights.

The car value is the width-to-height ratio, and the cdr value is
the height of camera notch as a percentage (0.0-100.0) of the
screen height.

Due to MacBook Pro models with a camera notch having a very
uniquq aspect ratios, we can use this to determine if an Emacs
frame is in fullscreen and rendered behind the notch."
  :type '(alist :key-type float :value-type float)
  :group 'tab-bar-notch)

(defcustom tab-bar-notch-screen-ratio-tolerance 0.001
  "Tolerance for the target ratio to accommodate minor variations.

Depending on the level of scaling set on the display, the exact
pixels counts reported yield slightly different aspect ratios.
However the variances start at the 4th decimal point, hence a
tolerance down to the 3rd decimal point is suitable."
  :type 'float
  :group 'tab-bar-notch)

(defcustom tab-bar-notch-normal-fullscreen-height 1.0
  "Height multiplier when in fullscreen without a notch.

This allows setting a custom tab-bar height in non-native
fullscreen on a display that does not have a notch, such as an
external monitor."
  :type 'float
  :group 'tab-bar-notch)

(defcustom tab-bar-notch-normal-height 1.0
  "Height multiplier when in not in fullscreen.

This allows setting a custom tab-bar height when not in
fullscreen mode."
  :type 'float
  :group 'tab-bar-notch)

(defcustom tab-bar-notch-max-height 15.0
  "Maximum height multiplier allowed.

This simple serves as a sanity check to prevent the tab-bar from
growing too large. In theory if your text size is so small 15
lines of text fit within the 69 pixel or less that the Notch
takes up, you probably have other issues."
  :type 'float
  :group 'tab-bar-notch)

(defvar tab-bar-notch--next-face-id 1
  "Internal variable to keep track of next face ID.

Used to generate unique face names for each frame.")

;;;###autoload
(defun tab-bar-notch-spacer ()
  "Return an invisible character with a custom face for setting height.

This function is intended to be used as a spacer in
`tab-bar-format'. Upon first call it registers a
`windows-size-change-functions' hook to update the tab-bar height
as needed.

To disable, simply remove from `tab-bar-format', which will also
remove the window size hook next time it fires.

If variable `window-system' is nil, a space character is returned
instead, as we cannot set the height of the tab bar in a
terminal."
  (if (not window-system)
      " "
    (if (not (memq 'tab-bar-notch-adjust-height window-size-change-functions))
        (add-hook 'window-size-change-functions #'tab-bar-notch-adjust-height))

    (propertize " " 'face (tab-bar-notch--face-name))))

;;;###autoload
(defun tab-bar-notch-adjust-height (&optional frame)
  "Adjust the height of the tab bar of FRAME.

This function is used as a `window-size-change-functions' hook,
and is automatically added by `tab-bar-notch-spacer' if needed.

If FRAME is nil, the selected frame is used.  If FRAME is not
nil, the tab bar height is adjusted for that frame.

If `tab-bar-notch-spacer' is not included in `tab-bar-format', this
function will remove itself from `window-size-change-functions'."
  (if (not (memq 'tab-bar-notch-spacer tab-bar-format))
      ;; Remove hook if notch spacer is not included in tab-bar-format.
      (remove-hook 'window-size-change-functions #'tab-bar-notch-adjust-height))

  (let* ((face-name (tab-bar-notch--face-name frame))
         (current-height (face-attribute face-name :height frame))
         (new-height (tab-bar-notch--calculate-face-height frame)))

    (if (not (tab-bar-notch--floateq current-height new-height))
        (set-face-attribute face-name nil :height new-height))))

(defun tab-bar-notch--face-name (&optional frame)
  "Return the name of the face used for the tab bar of FRAME.

If frame has not been assigned a face name yet, a new face will
be created and assigned to the frame. This ensures that different
frames on different screens don't interfere with each other.

The assigned face name for each frame is stored in a frame
parameter."
  (let* ((frame (or frame (selected-frame)))
         (face-name (frame-parameter frame 'tab-bar-notch--face-name)))
    (if face-name
        face-name
      (setq face-name (intern (format "tab-bar-notch--face-%d"
                                      tab-bar-notch--next-face-id))
            tab-bar-notch--next-face-id (1+ tab-bar-notch--next-face-id))
      (make-face face-name)
      (set-face-attribute face-name nil :height 1.0)
      (set-frame-parameter frame 'tab-bar-notch--face-name face-name)
      face-name)))

(defun tab-bar-notch--notch-height (width height)
  "Return the notch height for the given screen WIDTH and HEIGHT.

Returns 0 if no aspect ratio match is found, otherwise returns
the height of the notch in pixels."
  (let* ((ratio (/ (float width) height))
         (matched-pair (cl-find-if (lambda (pair)
                                     (tab-bar-notch--floateq
                                      ratio (car pair)
                                      tab-bar-notch-screen-ratio-tolerance))
                                   tab-bar-notch-screen-sizes)))
    (if matched-pair
        (round (* height (/ (cdr matched-pair) 100)))
      0)))

(defun tab-bar-notch--calculate-face-height (&optional frame)
  "Calculate the face height value of the tab bar of FRAME."
  (let* ((frame (or frame (selected-frame)))
         (face-height (if (tab-bar-notch--fullscreen-p frame)
                          (let ((notch (tab-bar-notch--notch-height
                                        (frame-pixel-width frame)
                                        (frame-pixel-height frame))))
                            (if (> notch 0)
                                (/ notch (float (frame-char-height frame)))
                              tab-bar-notch-normal-fullscreen-height))
                        tab-bar-notch-normal-height)))
    (min (max face-height 1.0) tab-bar-notch-max-height)))

(defun tab-bar-notch--fullscreen-p (&optional frame)
  "Determine if FRAME is in fullscreen mode."
  (and (not ns-use-native-fullscreen)
       (not (eq (frame-parameter (or frame (selected-frame)) 'fullscreen) nil))))

(defun tab-bar-notch--floateq (float1 float2 &optional tolerance)
  "Check if FLOAT1 and FLOAT2 are nearly equal.

TOLERANCE specifies the maximum difference for them to be
considered equal. If TOLERANCE is nil, 0.000001 will be used."
  (< (abs (- (if (floatp float1) float1 0.0)
             (if (floatp float2) float2 0.0)))
     (or tolerance 1e-6)))

(provide 'tab-bar-notch)

;;; tab-bar-notch.el ends here
