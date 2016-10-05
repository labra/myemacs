;;; init.el --- Emacs configuration -*- lexical-binding: t; -*-

;; Copyright (C) 2014 - 2015 Sam Halliday (fommil)
;; License: http://www.gnu.org/licenses/gpl.html

;; URL: https://github.com/fommil/dotfiles/blob/master/.emacs.d/init.el

;;; Commentary:
;;
;; Personalised Emacs configuration for the following primary uses;
;;
;;   - Scala
;;   - R
;;   - Java
;;   - C
;;   - elisp
;; This file is broken into sections which gather similar features or
;; modes together.  Sections are delimited by a row of semi-colons
;; (stage/functional sections) or a row of dots (primary modes).

;;; Code:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; User Site Local
(load (expand-file-name "local-preinit.el" user-emacs-directory) 'no-error)
(unless (boundp 'package--initialized)
  ;; don't set gnu/org/melpa if the site-local or local-preinit have
  ;; done so (e.g. firewalled corporate environments)
  (require 'package)
  (setq package-archives '(("gnu" . "http://elpa.gnu.org/packages/")
                           ("org" . "http://orgmode.org/elpa/")
                           ("melpa" . "http://melpa.org/packages/"))))
(package-initialize)
(when (not package-archive-contents)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This section is for global settings for built-in emacs parameters
(setq
 inhibit-startup-screen t
 initial-scratch-message nil
 enable-local-variables t
 create-lockfiles nil
 make-backup-files nil
 load-prefer-newer t
 custom-file (expand-file-name "custom.el" user-emacs-directory)
 column-number-mode t
 scroll-error-top-bottom t
 scroll-margin 15
 gc-cons-threshold 20000000
 user-full-name "Jose Emilio Labra Gayo")

;; buffer local variables
(setq-default
 indent-tabs-mode nil
 tab-width 4)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This section is for global settings for built-in packages that autoload
(setq
 help-window-select t
 show-paren-delay 0.5
 dabbrev-case-fold-search nil
 tags-case-fold-search nil
 tags-revert-without-query t
 tags-add-tables nil
 compilation-scroll-output 'first-error
 source-directory (getenv "EMACS_SOURCE")
 org-confirm-babel-evaluate nil
 nxml-slash-auto-complete-flag t
 sentence-end-double-space nil
 browse-url-browser-function 'browse-url-generic
 ediff-window-setup-function 'ediff-setup-windows-plain)

(setq-default
 c-basic-offset 4)

(add-hook 'prog-mode-hook
          (lambda () (setq show-trailing-whitespace t)))

;; protects against accidental mouse movements
;; http://stackoverflow.com/a/3024055/1041691
(add-hook 'mouse-leave-buffer-hook
          (lambda () (when (and (>= (recursion-depth) 1)
                           (active-minibuffer-window))
                  (abort-recursive-edit))))

;; *scratch* is immortal
(add-hook 'kill-buffer-query-functions
          (lambda () (not (member (buffer-name) '("*scratch*" "scratch.el")))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This section is for setup functions that are built-in to emacs
(defalias 'yes-or-no-p 'y-or-n-p)
(menu-bar-mode t)
(tool-bar-mode t)
(scroll-bar-mode -1)
(global-auto-revert-mode t)

(electric-indent-mode 0)
(remove-hook 'post-self-insert-hook
             'electric-indent-post-self-insert-function)
(remove-hook 'find-file-hooks 'vc-find-file-hook)

(global-auto-composition-mode 0)
(auto-encryption-mode 0)
(tooltip-mode 0)

(make-variable-buffer-local 'tags-file-name)
(make-variable-buffer-local 'show-paren-mode)

(add-to-list 'auto-mode-alist '("\\.log\\'" . auto-revert-tail-mode))
(defun add-to-load-path (path)
  "Add PATH to LOAD-PATH if PATH exists."
  (when (file-exists-p path)
    (add-to-list 'load-path path)))
(add-to-load-path (expand-file-name "lisp" user-emacs-directory))

(add-to-list 'auto-mode-alist '("\\.xml\\'" . nxml-mode))
;; WORKAROUND http://debbugs.gnu.org/cgi/bugreport.cgi?bug=16449
(add-hook 'nxml-mode-hook (lambda () (flyspell-mode -1)))

(use-package ibuffer
  :ensure nil
  :bind ("C-x C-b". ibuffer))

(use-package subword
  :ensure nil
  :diminish subword-mode
  :config (global-subword-mode t))

(use-package dired
  :ensure nil
  :config
  ;; a workflow optimisation too far?
  (bind-key "C-c c" 'sbt-command dired-mode-map)
  (bind-key "C-c e" 'next-error dired-mode-map))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This section is for generic interactive convenience methods.
;; Arguably could be uploaded to MELPA as package 'fommil-utils.
;; References included where shamelessly stolen.
(defun indent-buffer ()
  "Indent the entire buffer."
  (interactive)
  (save-excursion
    (delete-trailing-whitespace)
    (indent-region (point-min) (point-max) nil)
    (untabify (point-min) (point-max))))

(defun unfill-paragraph (&optional region)
  ;; http://www.emacswiki.org/emacs/UnfillParagraph
  "Transforms a paragraph in REGION into a single line of text."
  (interactive)
  (let ((fill-column (point-max)))
    (fill-paragraph nil region)))

(defun unfill-buffer ()
  "Unfill the buffer for function `visual-line-mode'."
  (interactive)
  (let ((fill-column (point-max)))
    (fill-region 0 (point-max))))

(defun revert-buffer-no-confirm ()
  ;; http://www.emacswiki.org/emacs-en/download/misc-cmds.el
  "Revert buffer without confirmation."
  (interactive)
  (revert-buffer t t))

(defun contextual-backspace ()
  "Hungry whitespace or delete word depending on context."
  (interactive)
  (if (looking-back "[[:space:]\n]\\{2,\\}" (- (point) 2))
      (while (looking-back "[[:space:]\n]" (- (point) 1))
        (delete-char -1))
    (cond
     ((and (boundp 'smartparens-strict-mode)
           smartparens-strict-mode)
      (sp-backward-kill-word 1))
     (subword-mode
      (subword-backward-kill 1))
     (t
      (backward-kill-word 1)))))

(defun exit ()
  "Short hand for DEATH TO ALL PUNY BUFFERS!"
  (interactive)
  (if (daemonp)
      (message "You silly")
    (save-buffers-kill-emacs)))

(defun safe-kill-emacs ()
  "Only exit Emacs if this is a small session, otherwise prompt."
  (interactive)
  (if (daemonp)
      ;; intentionally not save-buffers-kill-terminal as it has an
      ;; impact on other client sessions.
      (delete-frame)
    ;; would be better to filter non-hidden buffers
    (let ((count-buffers (length (buffer-list))))
      (if (< count-buffers 11)
          (save-buffers-kill-emacs)
        (message-box "use 'M-x exit'")))))

(defun declare-buffer-bankruptcy ()
  "Declare buffer bankruptcy and clean up everything using `midnight'."
  (interactive)
  (let ((clean-buffer-list-delay-general 0)
        (clean-buffer-list-delay-special 0))
    (clean-buffer-list)))


(defvar ido-buffer-whitelist
  '("^[*]\\(notmuch\\-hello\\|unsent\\|ag search\\|grep\\|eshell\\).*")
  "Whitelist regexp of `clean-buffer-list' buffers to show when switching buffer.")
(defun midnight-clean-or-ido-whitelisted (name)
  "T if midnight is likely to kill the buffer named NAME, unless whitelisted.
Approximates the rules of `clean-buffer-list'."
  (require 'midnight)
  (require 'dash)
  (cl-flet* ((buffer-finder (regexp) (string-match regexp name))
             (buffer-find (regexps) (-partial #'-find #'buffer-finder)))
    (and (buffer-find clean-buffer-list-kill-regexps)
         (not (or (buffer-find clean-buffer-list-kill-never-regexps)
                  (buffer-find ido-buffer-whitelist))))))

(defun company-or-dabbrev-complete ()
  "Force a `company-complete', falling back to `dabbrev-expand'."
  (interactive)
  (if company-mode
      (company-complete)
    (call-interactively 'dabbrev-expand)))

(defun company-backends-for-buffer ()
  "Calculate appropriate `company-backends' for the buffer.
For small projects, use TAGS for completions, otherwise use a
very minimal set."
  (projectile-visit-project-tags-table)
  (cl-flet ((size () (buffer-size (get-file-buffer tags-file-name))))
    (let ((base '(company-keywords company-dabbrev-code company-yasnippet)))
      (if (and tags-file-name (<= 20000000 (size)))
          (list (push 'company-etags base))
        (list base)))))

(defun sp-restrict-c (sym)
  "Smartparens restriction on `SYM' for C-derived parenthesis."
  (sp-restrict-to-pairs-interactive "{([" sym))

(defun plist-merge (&rest plists)
  "Create a single property list from all PLISTS.
Inspired by `org-combine-plists'."
  (let ((rtn (pop plists)))
    (dolist (plist plists rtn)
      (setq rtn (plist-put rtn
                           (pop plist)
                           (pop plist))))))

(defun dot-emacs ()
  "Go directly to .emacs, do not pass Go, do not collect $200."
  (interactive)
  (message "Stop procrastinating and do some work!")
  (find-file "~/.emacs.d/init.el"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This section is for global modes that should be loaded in order to
;; make them immediately available.
(use-package midnight
  :init
  (setq
   clean-buffer-list-kill-regexps '("^[*].*")
   clean-buffer-list-kill-never-regexps
   '("^[*]\\(scratch\\|sbt\\|Messages\\|ENSIME\\|eshell\\|compilation\\|magit\\(:\\|-revision\\|-staging\\)\\).*")))

(use-package persistent-scratch
  :config (persistent-scratch-setup-default))

(use-package undo-tree
  :diminish undo-tree-mode
  :config (global-undo-tree-mode)
  :bind ("s-/" . undo-tree-visualize))

(use-package flx-ido
  :demand
  :init
  (setq
   ido-enable-flex-matching t
   ido-use-faces nil ;; ugly
   ido-case-fold nil ;; https://github.com/lewang/flx#uppercase-letters
   ido-ignore-buffers '("\\` " midnight-clean-or-ido-whitelisted)
   ido-show-dot-for-dired nil ;; remember C-d
   ido-enable-dot-prefix t)
  :config
  (ido-mode t)
  (ido-everywhere t)
  (flx-ido-mode t))

(use-package projectile
  :demand
  ;; nice to have it on the modeline
  :init
  (setq projectile-use-git-grep t)
  :config
  (projectile-global-mode)
  (add-hook 'projectile-grep-finished-hook
            ;; not going to the first hit?
            (lambda () (pop-to-buffer next-error-last-buffer)))
  :bind
  (("s-f" . projectile-find-file)
   ("s-F" . projectile-ag)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This section is for loading and tweaking generic modes that are
;; used in a variety of contexts, but can be lazily loaded based on
;; context or when explicitly called by the user.
(use-package highlight-symbol
  :diminish highlight-symbol-mode
  :commands highlight-symbol
  :bind ("s-h" . highlight-symbol))

(use-package expand-region
  :commands 'er/expand-region
  :bind ("C-=" . er/expand-region))

(use-package goto-chg
  :commands goto-last-change
  ;; complementary to
  ;; C-x r m / C-x r l
  ;; and C-<space> C-<space> / C-u C-<space>
  :bind (("C-." . goto-last-change)
         ("C-," . goto-last-change-reverse)))

(use-package visual-regexp-steroids
  :commands vr/isearch-forward vr/query-replace
  :init (setq vr/engine 'pcre2el)
  :bind (("C-S-s" . vr/isearch-forward)
         ("s-S" . vr/query-replace)))

(use-package popup-imenu
  :commands popup-imenu
  :bind ("M-i" . popup-imenu))

(use-package git-gutter
  :diminish git-gutter-mode
  :commands git-gutter-mode)

(use-package magit
  :commands magit-status magit-blame
  :init (setq
         magit-revert-buffers nil)
  :bind (("s-g" . magit-status)
         ("s-b" . magit-blame)))

(use-package git-timemachine
  :commands git-timemachine
  :init (setq
         git-timemachine-abbreviation-length 4))

(use-package etags-select
  :commands etags-select-find-tag)

(use-package ag
  :commands ag
  :init
  (setq ag-reuse-window 't)
  :config
  (add-hook 'ag-search-finished-hook
            (lambda () (pop-to-buffer next-error-last-buffer))))

(use-package tidy
  :commands tidy-buffer)

(use-package company
  :diminish company-mode
  :commands company-mode
  :init
  (setq
   company-dabbrev-ignore-case nil
   company-dabbrev-code-ignore-case nil
   company-dabbrev-downcase nil
   company-idle-delay 0
   company-minimum-prefix-length 4)
  :config
  ;; dabbrev is too slow, use C-TAB explicitly
  (delete 'company-dabbrev company-backends)
  ;; disables TAB in company-mode, freeing it for yasnippet
  (define-key company-active-map [tab] nil)
  (define-key company-active-map (kbd "TAB") nil))

(use-package rainbow-mode
  :diminish rainbow-mode
  :commands rainbow-mode)

;(use-package flycheck
;  :diminish flycheck-mode
;  :commands flycheck-mode)

(use-package yasnippet
  :diminish yas-minor-mode
  :commands yas-minor-mode
  :config
  (yas-reload-all)
  (define-key yas-minor-mode-map [tab] #'yas-expand))

(use-package yatemplate
  :defer 2 ;; WORKAROUND https://github.com/mineo/yatemplate/issues/3
  :config
  (auto-insert-mode t)
  (setq auto-insert-alist nil)
  (yatemplate-fill-alist))

(use-package writeroom-mode
  ;; BUGs to be aware of:
  ;; https://github.com/joostkremers/writeroom-mode/issues/18
  ;; https://github.com/company-mode/company-mode/issues/376
  ;;:diminish writeroom-mode
  :commands writeroom-mode)

(use-package whitespace
  :commands whitespace-mode
  :diminish whitespace-mode
  :init
  ;; BUG: https://emacs.stackexchange.com/questions/7743
  (put 'whitespace-line-column 'safe-local-variable #'integerp)
  (setq whitespace-style '(face trailing tabs lines-tail)
        ;; github source code viewer overflows ~120 chars
        whitespace-line-column 120))
(defun whitespace-mode-with-local-variables ()
  "A variant of `whitespace-mode' that can see local variables."
  ;; WORKAROUND https://emacs.stackexchange.com/questions/7743
  (add-hook 'hack-local-variables-hook 'whitespace-mode nil t))

(use-package flyspell
  :commands flyspell-mode
  :diminish flyspell-mode
  :init (setq
         ispell-dictionary "british"
         flyspell-prog-text-faces '(font-lock-doc-face))
  :config
  (put 'text-mode
       'flyspell-mode-predicate
       'flyspell-ignore-http-and-https))

(defun flyspell-ignore-http-and-https ()
  ;; http://emacs.stackexchange.com/a/5435
  "Ignore anything starting with 'http' or 'https'."
  (save-excursion
    (forward-whitespace -1)
    (when (looking-at " ")
      (forward-char)
      (not (looking-at "https?\\b")))))

(use-package rainbow-delimiters
  :diminish rainbow-delimiters-mode
  :commands rainbow-delimiters-mode)

(use-package smartparens
  :diminish smartparens-mode
  :commands
  smartparens-strict-mode
  smartparens-mode
  sp-restrict-to-pairs-interactive
  sp-local-pair
  :init
  (setq sp-interactive-dwim t)
  :config
  (require 'smartparens-config)
  (sp-use-smartparens-bindings)
  (sp-pair "(" ")" :wrap "C-(") ;; how do people live without this?
  (sp-pair "[" "]" :wrap "s-[") ;; C-[ sends ESC
  (sp-pair "{" "}" :wrap "C-{")
  (sp-pair "<" ">" :wrap "C-<")

  ;; nice whitespace / indentation when creating statements
  (sp-local-pair '(c-mode java-mode) "(" nil :post-handlers '(("||\n[i]" "RET")))
  (sp-local-pair '(c-mode java-mode) "{" nil :post-handlers '(("||\n[i]" "RET")))
  (sp-local-pair '(java-mode) "<" nil :post-handlers '(("||\n[i]" "RET")))

  ;; WORKAROUND https://github.com/Fuco1/smartparens/issues/543
  (bind-key "C-<left>" nil smartparens-mode-map)
  (bind-key "C-<right>" nil smartparens-mode-map)

  (bind-key "s-{" 'sp-rewrap-sexp smartparens-mode-map)

  (bind-key "s-<delete>" 'sp-kill-sexp smartparens-mode-map)
  (bind-key "s-<backspace>" 'sp-backward-kill-sexp smartparens-mode-map)
  (bind-key "s-<home>" 'sp-beginning-of-sexp smartparens-mode-map)
  (bind-key "s-<end>" 'sp-end-of-sexp smartparens-mode-map)
  (bind-key "s-<left>" 'sp-beginning-of-previous-sexp smartparens-mode-map)
  (bind-key "s-<right>" 'sp-next-sexp smartparens-mode-map)
  (bind-key "s-<up>" 'sp-backward-up-sexp smartparens-mode-map)
  (bind-key "s-<down>" 'sp-down-sexp smartparens-mode-map))

(use-package hydra
  :commands defhydra
  :bind ("C-M-s" . hydra-splitter/body))

(defun hydra-splitter/body ()
  "Defines a Hydra to resize the windows."
  ;; overwrites the original function and calls it
  ;; https://github.com/abo-abo/hydra/issues/149
  (interactive)
  (require 'hydra-examples)
  (funcall
   (defhydra hydra-splitter nil "splitter"
     ("<left>" hydra-move-splitter-left)
     ("<down>" hydra-move-splitter-down)
     ("<up>" hydra-move-splitter-up)
     ("<right>" hydra-move-splitter-right))))

(defun hydra-smerge/body ()
  "Defines a Hydra to give ediff commands in `smerge-mode'."
  (interactive)
  (funcall
   (defhydra hydra-smerge nil "smerge"
     ("p" smerge-prev)
     ("n" smerge-next)
     ("e" smerge-ediff)
     ("a" smerge-keep-mine)
     ("b" smerge-keep-other))))
(add-hook 'smerge-mode-hook (lambda () (hydra-smerge/body)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This section is for overriding common emacs keybindings with tweaks.
(global-unset-key (kbd "C-z")) ;; I hate you so much C-z
(global-set-key (kbd "C-x C-c") 'safe-kill-emacs)
(global-set-key (kbd "C-<backspace>") 'contextual-backspace)
(global-set-key (kbd "RET") 'newline-and-indent)
(global-set-key (kbd "M-.") 'projectile-find-tag)
(global-set-key (kbd "M-,") 'pop-tag-mark)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; This section is for defining commonly invoked commands that deserve
;; a short binding instead of their packager's preferred binding.
(global-set-key (kbd "C-<tab>") 'company-or-dabbrev-complete)
(global-set-key (kbd "s-s") 'replace-string)
(global-set-key (kbd "<f5>") 'revert-buffer-no-confirm)
(global-set-key (kbd "M-Q") 'unfill-paragraph)
(global-set-key (kbd "<f6>") 'dot-emacs)

;;..............................................................................
;; elisp
(use-package lisp-mode
  :ensure nil
  :commands emacs-lisp-mode
  :config
  (bind-key "RET" 'comment-indent-new-line emacs-lisp-mode-map)
  (bind-key "C-c c" 'compile emacs-lisp-mode-map)

  ;; barf / slurp need some experimentation
  (bind-key "M-<left>" 'sp-forward-slurp-sexp emacs-lisp-mode-map)
  (bind-key "M-<right>" 'sp-forward-barf-sexp emacs-lisp-mode-map))

(use-package eldoc
  :ensure nil
  :diminish eldoc-mode
  :commands eldoc-mode)

(use-package focus
  :commands focus-mode)

(use-package pcre2el
  :commands rxt-toggle-elisp-rx
  :init (bind-key "C-c / t" 'rxt-toggle-elisp-rx emacs-lisp-mode-map))

(use-package re-builder
  :ensure nil
  ;; C-c C-u errors, C-c C-w copy, C-c C-q exit
  :init (bind-key "C-c r" 're-builder emacs-lisp-mode-map))

(add-hook 'emacs-lisp-mode-hook
          (lambda ()
            (setq show-trailing-whitespace t)

            (show-paren-mode t)
            (whitespace-mode-with-local-variables)
            (focus-mode t)
            (rainbow-mode t)
            (prettify-symbols-mode t)
            (eldoc-mode t)
            ; (flycheck-mode t)
            (yas-minor-mode t)
            (company-mode t)
            (smartparens-strict-mode t)
            (rainbow-delimiters-mode t)))


;;..............................................................................
;; Scala

;; Java / Scala support for templates
(defun mvn-package-for-buffer ()
  "Calculate the expected package name for the buffer;
assuming it is in a maven-style project."
  ;; see https://github.com/fommil/dotfiles/issues/66
  (let* ((kind (file-name-extension buffer-file-name))
         (root (locate-dominating-file default-directory kind)))
    (when root
      (require 'subr-x) ;; maybe we should just use 's
      (replace-regexp-in-string
       (regexp-quote "/") "."
       (string-remove-suffix "/"
                             (string-remove-prefix
                              (expand-file-name (concat root "/" kind "/"))
                              default-directory))
       nil 'literal))))

(defun scala-mode-newline-comments ()
  "Custom newline appropriate for `scala-mode'."
  ;; shouldn't this be in a post-insert hook?
  (interactive)
  (newline-and-indent)
  (scala-indent:insert-asterisk-on-multiline-comment))

(defun c-mode-newline-comments ()
  "Newline with indent and preserve multiline comments."
  (interactive)
  (c-indent-new-comment-line)
  (indent-according-to-mode))

(use-package scala-mode
  :defer t
  :init
  (setq
   scala-indent:use-javadoc-style t
   scala-indent:align-parameters t)
  :config

  ;; prefer smartparens for parents handling
  (remove-hook 'post-self-insert-hook
               'scala-indent:indent-on-parentheses)

  (sp-local-pair 'scala-mode "(" nil :post-handlers '(("||\n[i]" "RET")))
  (sp-local-pair 'scala-mode "{" nil :post-handlers '(("||\n[i]" "RET") ("| " "SPC")))

  (bind-key "RET" 'scala-mode-newline-comments scala-mode-map)
  (bind-key "s-<delete>" (sp-restrict-c 'sp-kill-sexp) scala-mode-map)
  (bind-key "s-<backspace>" (sp-restrict-c 'sp-backward-kill-sexp) scala-mode-map)
  (bind-key "s-<home>" (sp-restrict-c 'sp-beginning-of-sexp) scala-mode-map)
  (bind-key "s-<end>" (sp-restrict-c 'sp-end-of-sexp) scala-mode-map)
  ;; BUG https://github.com/Fuco1/smartparens/issues/468
  ;; backwards/next not working particularly well

  ;; i.e. bypass company-mode
  (bind-key "C-<tab>" 'dabbrev-expand scala-mode-map)

  (bind-key "C-c c" 'sbt-command scala-mode-map)
  (bind-key "C-c e" 'next-error scala-mode-map))

(defun ensime-edit-definition-with-fallback ()
  "Variant of `ensime-edit-definition' with ctags if ENSIME is not available."
  (interactive)
  (unless (and (ensime-connection-or-nil)
               (ensime-edit-definition))
    (projectile-find-tag)))

(use-package ensime
  :defer t
  :init
  (put 'ensime-auto-generate-config 'safe-local-variable #'booleanp)
  (setq
   ensime-startup-snapshot-notification nil)
  :config
  (require 'ensime-expand-region)
  (add-hook 'git-timemachine-mode-hook (lambda () (ensime-mode 0)))

  (bind-key "s-n" 'ensime-search ensime-mode-map)
  (bind-key "s-t" 'ensime-print-type-at-point ensime-mode-map)
  (bind-key "M-." 'ensime-edit-definition-with-fallback ensime-mode-map))

(use-package sbt-mode
  :commands sbt-start sbt-command
  :init
  (setq
   sbt:prefer-nested-projects t
   sbt:scroll-to-bottom-on-output nil
   sbt:default-command ";compile ;test:compile ;it:compile")
  :config
  ;; WORKAROUND: https://github.com/hvesalai/sbt-mode/issues/31
  ;; allows using SPACE when in the minibuffer
  (substitute-key-definition
   'minibuffer-complete-word
   'self-insert-command
   minibuffer-local-completion-map)

  (bind-key "C-c c" 'sbt-command sbt:mode-map)
  (bind-key "C-c e" 'next-error sbt:mode-map))

(defcustom
  scala-mode-prettify-symbols
  '(("->" . ?→)
    ("<-" . ?←)
    ("=>" . ?⇒)
    ("<=" . ?≤)
    (">=" . ?≥)
    ("==" . ?≡)
    ("!=" . ?≠)
    ;; implicit https://github.com/chrissimpkins/Hack/issues/214
    ("+-" . ?±))
  "Prettify symbols for scala-mode.")

(add-hook 'scala-mode-hook
          (lambda ()
            (whitespace-mode-with-local-variables)
            (show-paren-mode t)
            (smartparens-mode t)
            (yas-minor-mode t)
            (git-gutter-mode t)
            (company-mode t)
            (setq prettify-symbols-alist scala-mode-prettify-symbols)
            (prettify-symbols-mode t)
            (scala-mode:goto-start-of-code)))

(add-hook 'ensime-mode-hook
          (lambda ()
            (let ((backends (company-backends-for-buffer)))
              (setq company-backends (push '(ensime-company company-yasnippet) backends)))))

;;..............................................................................
;; Java
(use-package cc-mode
  :ensure nil
  :config
  (bind-key "C-c c" 'sbt-command java-mode-map)
  (bind-key "C-c e" 'next-error java-mode-map)
  (bind-key "RET" 'c-mode-newline-comments java-mode-map))

(add-hook 'java-mode-hook
          (lambda ()
            (whitespace-mode-with-local-variables)
            (show-paren-mode t)
            (smartparens-mode t)
            (yas-minor-mode t)
            (git-gutter-mode t)
            (company-mode t)
            (ensime-mode t)))


;;..............................................................................
;; C
(add-hook 'c-mode-hook (lambda ()
                         (yas-minor-mode t)
                         (company-mode t)
                         (smartparens-mode t)))

;;..............................................................................
;; org-mode
(add-hook 'writeroom-mode-hook
          (lambda ()
            ;; NOTE weird sizing bug in writeroom
            (delete-other-windows)))

(add-hook 'org-mode-hook
          (lambda ()
            (yas-minor-mode t)
            (company-mode t)
            (visual-line-mode t)
            (local-set-key (kbd "C-c c") 'pandoc)
            (local-set-key (kbd "s-c") 'picture-mode)
            (org-babel-do-load-languages
             'org-babel-load-languages
             '((ditaa . t)))))

(use-package markdown-mode
  :commands markdown-mode)
(add-hook 'markdown-mode-hook
          (lambda ()
            (yas-minor-mode t)
            (company-mode t)
            (visual-line-mode t)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; OS specific
(pcase system-type
  (`gnu/linux
   (load (expand-file-name "init-gnu.el" user-emacs-directory))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; User Site Local
(load (expand-file-name "local.el" user-emacs-directory) 'no-error)

;;; init.el ends here
;; End of https://github.com/fommil/dotfiles/blob/master/.emacs.d/init.el

;(use-package ensime
;  :pin melpa-stable)


(add-to-list 'exec-path "/semWeb/bin/sbt/bin/sbt.bat")
(global-set-key [s-left] 'windmove-left)
(global-set-key [s-right] 'windmove-right)
(global-set-key [s-up] 'windmove-up)
(global-set-key [s-down] 'windmove-down)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 ;; '(ensime-sbt-perform-on-save "compile")
 )

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
)

;; Maximize window on start-up:
;; http://emacs.stackexchange.com/questions/2999/how-to-maximize-my-emacs-frame-on-start-up
(add-to-list 'default-frame-alist '(fullscreen . maximized))

(desktop-save-mode 1)

(defun toggle-window-split ()
  (interactive)
  (if (= (count-windows) 2)
      (let* ((this-win-buffer (window-buffer))
         (next-win-buffer (window-buffer (next-window)))
         (this-win-edges (window-edges (selected-window)))
         (next-win-edges (window-edges (next-window)))
         (this-win-2nd (not (and (<= (car this-win-edges)
                     (car next-win-edges))
                     (<= (cadr this-win-edges)
                     (cadr next-win-edges)))))
         (splitter
          (if (= (car this-win-edges)
             (car (window-edges (next-window))))
          'split-window-horizontally
        'split-window-vertically)))
    (delete-other-windows)
    (let ((first-win (selected-window)))
      (funcall splitter)
      (if this-win-2nd (other-window 1))
      (set-window-buffer (selected-window) this-win-buffer)
      (set-window-buffer (next-window) next-win-buffer)
      (select-window first-win)
      (if this-win-2nd (other-window 1))))))

(global-set-key (kbd "C-x º") 'toggle-window-split)


;; Customizations from Labra

(delete-selection-mode 1)
(global-linum-mode t)
(require 'dirtree)
(autoload 'dirtree "dirtree" "Add directory to tree view" t)
(require 'which-key)
(which-key-mode)


(add-to-list 'load-path "~/.emacs.d/vendor")

(autoload 'shexc-mode "shexc-mode" "Major mode for ShEx Compact syntax files" t)
(add-hook 'shexc-mode-hook    ; Turn on font lock when in ttl mode
          (show-paren-mode t)
          'turn-on-font-lock)
(setq auto-mode-alist
      (append
       (list
        '("\\.shex" . shexc-mode)
        '("\\.ttl" . shexc-mode)
        '("\\.n3" . shexc-mode)
        '("\\.shexc" . shexc-mode))
       auto-mode-alist))

(autoload 'sparql-mode "sparql-mode.el"
    "Major mode for editing SPARQL files" t)
(add-to-list 'auto-mode-alist '("\\.sparql$" . sparql-mode))
(add-to-list 'auto-mode-alist '("\\.rq$" . sparql-mode))
(global-set-key (kbd "C-x g") 'magit-status)

(require 'recentf)
(recentf-mode 1)
(setq recentf-max-menu-items 25)
(global-set-key "\C-x\ \C-r" 'recentf-open-files)

;; Winner-mode allows to restore previous windows configuration
(when (fboundp 'winner-mode)
      (winner-mode 1))

(windmove-default-keybindings 'meta)
(global-set-key (kbd "C-x k") 'kill-this-buffer)

;; Configuration for latex
;;
;;This configuration has been taken from:
;;  https://github.com/nasseralkmim/.emacs.d/blob/master/config.org
;;
(use-package tex-site
  :ensure auctex
  :mode ("\\.tex\\'" . latex-mode)
  :config
  (setq TeX-auto-save t)
  (setq TeX-parse-self t)
  (setq-default TeX-master nil)
  (add-hook 'LaTeX-mode-hook
            (lambda ()
              (magic-latex-buffer)
              (LaTeX-math-mode)
              (rainbow-delimiters-mode)
              (flyspell-mode)
              (company-mode)
              (smartparens-mode)
              (turn-on-reftex)
              (setq reftex-plug-into-AUCTeX t)
              (reftex-isearch-minor-mode)
              (setq TeX-PDF-mode t)
              (setq global-font-lock-mode t)
              (setq TeX-source-correlate-method 'synctex)
              (setq TeX-source-correlate-start-server t)))

(add-hook 'TeX-after-compilation-finished-functions #'TeX-revert-document-buffer)

;; to use pdfview with auctex
(add-hook 'LaTeX-mode-hook 'pdf-tools-install)
;; nil beacuse I don't want the pdf to be opened again in the same frame after C-c C-a
;; (setq TeX-view-program-selection nil)
;; (setq TeX-view-program-selection '((output-pdf "pdf-tools")))
;; (setq TeX-view-program-list '(("pdf-tools" "TeX-pdf-tools-sync-view")))

;add org ref into auctex
;; https://github.com/jkitchin/org-ref/issues/216
(add-hook 'LaTeX-mode-hook (lambda () (require 'org-ref)))

;; https://github.com/politza/pdf-tools/pull/60
(setq pdf-sync-forward-display-action
      '(display-buffer-reuse-window (reusable-frames . t)))
;; same thing, now I can jump from pdf in another frame into source
(setq pdf-sync-backward-display-action
      '(display-buffer-reuse-window (reusable-frames . t)))
)

(use-package company-auctex
  :ensure t
  :defer t
  :config
  (company-auctex-init))

(use-package latex-preview-pane
  :disabled t
  :bind ("M-p" . latex-preview-pane-mode)
  :config
  (setq doc-view-ghostscript-program "gswin64c")

  (custom-set-variables
   '(shell-escape-mode "-shell-escape")
   '(latex-preview-pane-multifile-mode (quote auctex))))

(use-package reftex
  :ensure t
  :defer t
  :config
  (setq reftex-cite-prompt-optional-args t)); Prompt for empty optional arguments in cite

(use-package magic-latex-buffer
  :load-path ("C:/Users/Labra/.emacs.d/elpa/magic-latex-buffer-master")
  :config
  (add-hook 'LaTeX-mode-hook 'magic-latex-buffer)
  (setq magic-latex-enable-block-highlight nil
      magic-latex-enable-suscript        t
      magic-latex-enable-pretty-symbols  t
      magic-latex-enable-block-align     nil
      magic-latex-enable-inline-image    nil))
