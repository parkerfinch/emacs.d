;;; package --- Summary

;; My Emacs config.

;;; Commentary:

;; This is an attempt at keeping an organized Emacs config.
;; We'll see how it goes...

;; Attribution: This is based on any number of StackOverflow answers, GNU Emacs
;; Wiki pages, and Bozhidar Batsov's config:
;; (https://github.com/bbatsov/emacs.d/blob/master/init.el)

;;; Code:


;;; Package Management

;;; This section handles the setup of package managers.

(require 'package)

(setq package-archives '(("gnu" . "https://elpa.gnu.org/packages/")
                         ("melpa" . "https://melpa.org/packages/")))

(package-initialize)


;;; General Setup

;;; This section handles basic configuration options that typically
;;; apply globally, such as line numbers and bell alerts.

;; Get a more subtle visual bell for the mode line. This is still
;; plenty to draw the eye, but is less obtrusive than the default
;; yellow triangle with an exclamation mark used by the emacs GUI.
(setq visible-bell nil
      ring-bell-function 'flash-mode-line)

(defun flash-mode-line ()
  "Invert the mode line colors for 0.1s."
  (invert-face 'mode-line)
  (run-with-timer 0.1 nil #'invert-face 'mode-line))

;; Remove the scroll bar. I haven't found a good use for it yet other
;; than when I'm screen sharing and walking through code with
;; someone. In that case, temporarily add the scroll bar with
;; (toggle-scroll-bar 1).
(toggle-scroll-bar -1)

;; Disable the startup screen.
(setq inhibit-startup-screen t)

;; Give more info about cursor location in the mode line.
(line-number-mode t)
(column-number-mode t)

;; Always put a newline at the end of a file.
(setq require-final-newline t)

;; Don't use tab literals, use spaces instead.
(setq-default indent-tabs-mode nil)

;; Show line numbers in every file. Especially useful when screen sharing.
(global-display-line-numbers-mode)

;; Delete trailing whitespace before saving.
(add-hook 'before-save-hook 'delete-trailing-whitespace)

;; Put the cursor in the *Help* window when it opens.
(setq help-window-select t)

;; Set correct pinentry mode. This allows the gpg key passphrase to be entered
;; in the minibuffer.  See:
;; https://colinxy.github.io/software-installation/2016/09/24/emacs25-easypg-issue.html
(setq epa-pinentry-mode 'loopback)


;;; Packages

;;; This section handles installation and configuration of packages.

;; Use use-package!
(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-verbose t)

;; Always ensure that each package is installed.
(require 'use-package-ensure)
(setq use-package-always-ensure t)

;; Use extension that allows for ensuring that system requirements are
;; installed.
(use-package use-package-ensure-system-package)

;; Load the PATH environment variable on non-windows systems.
(use-package exec-path-from-shell
  :config
  (when (memq window-system '(mac ns))
    (exec-path-from-shell-initialize)

    ;; Use a default ruby version of 2.5.8. Make sure this happens _after_ the
    ;; exec-path-from-shell initialization so that the chruby part of the path
    ;; comes _after_ the path added by exec-path-from-shell.
    (chruby "2.5.8")))

;; Automatically add matching delimiters, e.g. quotes, parentheses.
(use-package elec-pair
  :config
  (electric-pair-mode +1))

(use-package paren
  :config
  (show-paren-mode +1))

(use-package fill-column-indicator
  :config
  ;; Panorama usually uses 80 character line limits. This makes that
  ;; the default.
  (setq-default fill-column 80)

  ;; Enable the fill column indicator everywhere.
  (add-hook 'after-change-major-mode-hook 'fci-mode))

;; A nice theme that I enjoy.
(use-package tangotango-theme
  :init (load-theme 'tangotango t))

(use-package magit
  :bind (("C-x g" . magit-status))
  :config
  (setq git-commit-summary-max-length 50)
  (add-hook 'git-commit-setup-hook (lambda () (set-fill-column 72))))

(use-package docker
  :bind ("C-c d" . docker))

;; (use-package chruby)

(use-package ruby-mode
  :ensure-system-package
  ((rubocop     . "gem install rubocop"))

  :config
  ;; Do not insert the encoding comment in ruby files.
  (setq ruby-insert-encoding-magic-comment nil)

  ;; Use subword navigation, which makes it easier to change constant
  ;; prefixes, etc. It causes word navigation to occur at the
  ;; "subword" level, where in camelCase the uppercased letters
  ;; indicate a subword.
  (add-hook 'ruby-mode-hook #'subword-mode)

  ;; Use a fill column indicator.
  (add-hook 'ruby-mode-hook 'fci-mode)

  ;; Activate rubocop mode.
  (add-hook 'ruby-mode-hook 'rubocop-mode))

(use-package rspec-mode
  :config
  ;; At Panorama local development, and specs, are done in docker.
  (setq rspec-use-docker-when-possible t)
  (setq rspec-docker-container "test"))

;; Get flycheck going for syntax checking on start up! This integrates
;; with rubocop.
(use-package flycheck
  :init (global-flycheck-mode))

;; Multiple Major Modes (MMM) is used when a buffer has multiple different types
;; of code. It allows, for example, using ruby mode in part of a buffer and
;; markdown in other parts.
(use-package mmm-mode
  :defines (mmm-js-mode-enter-hook mmm-typescript-mode-enter-hook)
  :config
  ;; This gets indenting working properly in vue-mode
  (setq mmm-js-mode-enter-hook (lambda () (setq syntax-ppss-table nil)))
  (setq mmm-typescript-mode-enter-hook (lambda () (setq syntax-ppss-table nil)))

  ;; Create a markdown-ruby submode activated by "```ruby"
  (mmm-add-classes
 '((markdown-ruby
    :submode ruby-mode
    :front "^```ruby[\n\r]+"
    :back "^```$")))
  (mmm-add-mode-ext-class 'markdown-mode nil 'markdown-ruby))

(use-package multiple-cursors
  :bind (("C-M-c"   . 'mc/edit-lines)
         ("C->"     . 'mc/mark-next-like-this)
         ("C-<"     . 'mc/mark-previous-like-this)
         ("C-C C-<" . 'mc/mark-all-like-this)))

;; Fuzzy search result ordering for ivy (?).
(use-package flx)

(use-package ag
  :ensure-system-package ag)

(use-package projectile
  :init
  (setq projectile-completion-system 'ivy)
  :config
  (define-key projectile-mode-map (kbd "s-p") 'projectile-command-map)
  (projectile-mode +1))

(use-package ivy
  :config
  (ivy-mode 1)
  (setq ivy-use-virtual-buffers t)
  (setq enable-recursive-minibuffers t)
  (setq ivy-re-builders-alist
        '((swiper . ivy--regex-plus)
          (t . ivy--regex-fuzzy))))

(use-package counsel
  :config
  (global-set-key (kbd "M-x") 'counsel-M-x)
  (global-set-key (kbd "C-x C-f") 'counsel-find-file))

(use-package swiper
  :config
  (global-set-key "\C-s" 'swiper))

(use-package js
  :config
  (setq js-indent-level 2))

;; Configuration for org-mode.
;; Inspired by doc.norang.ca/org-mode.html.
(use-package org
  :config
  (setq org-directory "~/org/")
  (setq org-default-notes-file (concat org-directory "refile.org"))

  ;; The files/directories that should contribute to the agenda.
  (setq org-agenda-files (quote ("~/org/panorama"
                                 "~/org/personal")))

  (global-set-key (kbd "C-c a") 'org-agenda)

  ;; Task states and flow.
  (setq org-todo-keywords
      '((sequence "TODO(t)" "NEXT(n)" "|" "DONE(d)")
        (sequence "BLOCKED(b@/!)")
        (sequence "|" "CANCELED(c)")))

  (setq org-todo-state-tags-triggers
        (quote (("CANCELED" ("CANCELED" . t))
                ("BLOCKED" ("BLOCKED" . t))
                ("TODO" ("BLOCKED") ("CANCELED"))
                ("NEXT" ("BLOCKED") ("CANCELED"))
                ("DONE" ("BLOCKED") ("CANCELED")))))

  ;; Capture templates
  (setq org-capture-templates
        (quote (("t" "todo" entry (file "")
                 "* TODO %?\n%U\n%a\n" :clock-in t :clock-resume t)
                ("m" "Meeting" entry (file "")
                 "* MEETING with %? :MEETING:\n%U" :clock-in t :clock-resume t)
                ("r" "Reading" entry (file "")
                 "* READING %? :READING:\n%U" :clock-in t :clock-resume t))))

  ;; Refiling config
  ;; Targets include this file and any file contributing to the agenda - up to 9 levels deep
  (setq org-refile-targets (quote ((nil :maxlevel . 9)
                                   (org-agenda-files :maxlevel . 9))))

  ;; Use full outline paths for refile targets
  (setq org-refile-use-outline-path t)

  (global-set-key (kbd "<f11>") 'org-clock-goto)
  (global-set-key (kbd "C-<f11>") 'org-clock-in)
  (global-set-key (kbd "C-c l") 'org-store-link)
  (global-set-key (kbd "C-c c") 'org-capture)
  (global-set-key (kbd "C-c b") 'org-switchb))

(use-package org-jira
  :ensure-system-package gpg
  :config
  (setq jiralib-url "https://panoramaed.atlassian.net")
  (setq org-jira-working-dir "~/org/jira"))


;;; Project Management

;; This section contains utilities that make it easier to manage projects.
;; TODO: Determine whether or not this should include things like projectile.

;; I find this quicker than trying to navigate the JIRA UI.
(defun browse-ticket (ticket-id)
  "Open TICKET-ID in a web browser."
  (interactive "sTicket id: ")
  (browse-url
   (concat
    "https://panoramaed.atlassian.net/browse/"
    ticket-id)))

(global-set-key (kbd "C-M-t") 'browse-ticket)



;;; Customization

;; Since customization is generated automatically, store it in a separate
;; file. That makes it easier to keep this file organized, consolidating the
;; machine-generated code into a single place.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

(when (file-exists-p custom-file)
  (load custom-file))

;;; init.el ends here
