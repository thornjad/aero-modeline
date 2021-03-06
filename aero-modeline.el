;;; aero-modeline.el --- smooth, informative modeline
;; -*- lexical-binding: t -*-
;;
;; Copyright (c) 2019 Jade Michael Thornton
;;
;; This file is not part of GNU Emacs
;;
;; Permission to use, copy, modify, and/or distribute this software for any
;; purpose with or without fee is hereby granted, provided that the above
;; copyright notice and this permission notice appear in all copies.
;;
;; The software is provided "as is" and the author disclaims all warranties with
;; regard to this software including all implied warranties of merchantability
;; and fitness. In no event shall the author be liable for any special, direct,
;; indirect, or consequential damages or any damages whatsoever resulting from
;; loss of use, data or profits, whether in an action of contract, negligence or
;; other tortious action, arising out of or in connection with the use or
;; performance of this software.
;;
;;; Commentary:
;;
;;; Code:

;; TODO only load stuff like flycheck if it exists
(defvar aero-modeline--current-window)
(defvar flycheck-current-errors)
(declare-function flycheck-count-errors "flycheck" (errors))


;;; Config

(defgroup aero-modeline nil
  "A minimal mode-line configuration inspired by doom-modeline."
  :group 'mode-line)

(defface aero-modeline-status-grayed-out
  '((t (:inherit (font-lock-doc-face) :slant italic)))
  "Face used for neutral or inactive status indicators in the mode-line."
  :group 'aero-modeline)

(defface aero-modeline-status-info
  '((t (:inherit (font-lock-keyword-face) :slant italic)))
  "Face used for generic status indicators in the mode-line."
  :group 'aero-modeline)

(defface aero-modeline-status-success
  '((t (:inherit (success) :slant italic)))
  "Face used for success status indicators in the mode-line."
  :group 'aero-modeline)

(defface aero-modeline-status-warning
  '((t (:inherit (warning) :slant italic)))
  "Face for warning status indicators in the mode-line."
  :group 'aero-modeline)

(defface aero-modeline-status-error
  '((t (:inherit (error) :slant italic)))
  "Face for error stauts indicators in the mode-line."
  :group 'aero-modeline)

(defface aero-modeline-unimportant
  '((t (:inherit (font-lock-doc-face))))
  "Face used for less important mode-line elements."
  :group 'aero-modeline)

(defface aero-modeline-modified
  '((t (:inherit (error))))
  "Face used for the 'modified' indicator symbol in the mode-line."
  :group 'aero-modeline)

(defface aero-modeline-evil-normal
  '((t (:inherit (font-lock-keyword-face))))
  "Face used for Normal Evil state message."
  :group 'aero-modeline)

(defface aero-modeline-evil-insert
  '((t (:inherit (font-lock-keyword-face))))
  "Face used for Insert Evil state message."
  :group 'aero-modeline)

(defface aero-modeline-evil-visual
  '((t (:inherit (font-lock-keyword-face))))
  "Face used for Visual Evil state message."
  :group 'aero-modeline)

(defface aero-modeline-evil-replace
  '((t (:inherit (font-lock-keyword-face))))
  "Face used for Replace Evil state message."
  :group 'aero-modeline)

(defface aero-modeline-evil-emacs
  '((t (:inherit (font-lock-keyword-face))))
  "Face used for Emacs Evil state message."
  :group 'aero-modeline)


;;; Helper functions

(defun aero-info-line-format (left right)
  "Return a string of `window-width' length containing LEFT and RIGHT, aligned respectively."
  (let ((reserve (length right)))
    (concat
     left
     " "
     (propertize  " "
                  'display `((space :align-to (- (+ right right-fringe right-margin) ,(+ reserve 0)))))
     right)))

;; Define a helper function to determine whether or not the current window is active.
(defsubst aero-modeline-is-active ()
  "Return \"t\" if the current window is active, \"nil\" if it is not."
  (eq (selected-window) aero-modeline--current-window))


;;; Update functions

;; Window update function
(defvar-local aero-modeline--current-window (frame-selected-window))
(defun aero-modeline--update-selected-window (&rest _)
  "Update the `aero-modeline--current-window' variable."
  (when (frame-selected-window)
    (let ((win (frame-selected-window)))
      (unless (minibuffer-window-active-p win)
        (setq aero-modeline--current-window win)))))

;; Flycheck update function
(defvar-local aero-modeline--flycheck-text nil)
(defun aero-modeline--update-flycheck-segment (&optional status)
  "Update `aero-modeline--flycheck-text' against the reported flycheck STATUS."
  (setq aero-modeline--flycheck-text
        (pcase status
          ('finished (if flycheck-current-errors
                         (let-alist (flycheck-count-errors flycheck-current-errors)
                           (let ((sum (+ (or .error 0) (or .warning 0))))
                             (propertize (concat " "
                                                 (number-to-string sum)
                                                 " Issues ")
                                         'face (if .error
                                                   'aero-modeline-status-error
                                                 'aero-modeline-status-warning))))
                       (propertize "✔  " 'face 'aero-modeline-status-success)))
          ('running (propertize "Checking  " 'face 'aero-modeline-status-info))
          ('no-checker "")
          ('errored (propertize "✘  " 'face 'aero-modeline-status-error))
          ('interrupted (propertize "⏸  " 'face 'aero-modeline-status-grayed-out)))))


;;; Segments

(defun aero-modeline-segment-evil-state ()
  "Display current evil state. Requires function `evil-mode'."
  (when (require 'evil nil 'noerror)
    (declare-function evil-state-property "evil")
    (defvar evil-state)
    (let* ((state (string-trim (evil-state-property evil-state :tag t)))
           (formed-state (format " %s " state)))
      (cond
       ((string= state "<N>") (propertize formed-state 'face 'aero-modeline-evil-normal))
       ((string= state "<I>") (propertize formed-state 'face 'aero-modeline-evil-insert))
       ((string= state "<V>") (propertize formed-state 'face 'aero-modeline-evil-visual))
       ((string= state "<R>") (propertize formed-state 'face 'aero-modeline-evil-replace))
       ((string= state "<E>") (propertize formed-state 'face 'aero-modeline-evil-emacs))
       (t formed-state)))))

(defun aero-modeline-segment-modified ()
  "Displays a color-coded buffer modification indicator in the mode-line."
  (propertize
   (if (and
        (buffer-modified-p)
        (not (string-match-p "\\*.*\\*" (buffer-name))))
       " ✧ "
     "   ")
   'face 'aero-modeline-modified))

(defun aero-modeline-segment-buffer-name-and-size ()
  "Displays the name and size of the current buffer in the mode-line."
  (concat (propertize "%b (%I)" 'face 'mode-line-buffer-id) "  "))

(defun aero-modeline-segment-position ()
  "Displays the current cursor position in the mode-line."
  (concat "%l:%c"
          " "
          (propertize "%p%%"
                      'face
                      (if (aero-modeline-is-active)
                          'aero-modeline-unimportant
                        'mode-line-inactive))
          (when (use-region-p)
            (concat
             "  " (number-to-string (count-lines (point) (mark)))
             ":" (number-to-string (abs (- (point) (mark))))))
          "  "))

(defun aero-modeline-segment-flycheck ()
  "Displays color-coded flycheck information in the mode-line (if available)."
  aero-modeline--flycheck-text)

(defun aero-modeline-segment-process ()
  "Displays the current value of `mode-line-process' in the mode-line."
  (when mode-line-process
    (list mode-line-process "  ")))

(defun aero-modeline-segment-major-mode ()
  "Displays the current major mode in the mode-line."
  (propertize " %m  "
              'face (if (aero-modeline-is-active)
                        'bold
                      'aero-modeline-status-grayed-out)))

(defun aero-modeline-segment-window-number ()
  "Displays the current window number as provided by `winum'."
  (when (require 'winum nil 'noerror)
    (declare-function winum-get-number "winum")
    (concat (format "|%d| " (winum-get-number)))))


;;; Activation function

;; Store the default mode-line format
(defvar aero-modeline--default-mode-line mode-line-format)

(define-minor-mode aero-modeline-mode
  "Toggle aero-modeline on or off."
  :group 'aero-modeline
  :global t
  :lighter nil
  (progn
    ;; Setup flycheck hooks
    (add-hook 'flycheck-status-changed-functions #'aero-modeline--update-flycheck-segment)
    (add-hook 'flycheck-mode-hook #'aero-modeline--update-flycheck-segment)

    ;; Setup window update hooks
    (add-hook 'window-configuration-change-hook #'aero-modeline--update-selected-window)
    (add-hook 'focus-in-hook #'aero-modeline--update-selected-window)
    (advice-add #'handle-switch-frame :after #'aero-modeline--update-selected-window)
    (advice-add #'select-window :after #'aero-modeline--update-selected-window)

    ;; Set the new mode-line-format
    (setq-default mode-line-format
                  '((:eval
                     (aero-info-line-format
                      ;; Left
                      (format-mode-line
                       '((:eval (aero-modeline-segment-evil-state))
                         (:eval (aero-modeline-segment-modified))
                         (:eval (aero-modeline-segment-buffer-name-and-size))
                         (:eval (aero-modeline-segment-position))))

                      ;; Right
                      (format-mode-line
                       '((:eval (aero-modeline-segment-flycheck))
                         (:eval (aero-modeline-segment-process))
                         (:eval (aero-modeline-segment-major-mode))
                         (:eval (aero-modeline-segment-window-number))
                         " "))))))))


;;; aero-modeline.el ends here

(provide 'aero-modeline)
