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
(unless (package-installed-p 'use-package)
  (package-install 'use-package))


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

;; Show line numbers in programming modes.
(add-hook 'prog-mode-hook #'display-line-numbers-mode)

;; Delete trailing whitespace before saving, unless the file is a
;; schema.rb. This exception is to handle the Sequel (ruby gem) behavior of
;; leaving trailing whitespace in the schema after it is dumped to disk. I
;; shouldn't need to open or edit the file manually, but sometimes I look at and
;; accidentally save, and this prevents a bit of a headache there.
(add-hook
 'before-save-hook
 (lambda ()
   "Delete trailing whitespace unless it's in a schema."
   (unless (s-ends-with? "schema.rb" (buffer-file-name))
       (delete-trailing-whitespace))))

;; Put the cursor in the *Help* window when it opens.
(setq help-window-select t)

;; Allow other-window to go back a window by using shift-o
(global-set-key (kbd "C-x O") (lambda () (interactive) (other-window -1)))

;; Set correct pinentry mode. This allows the gpg key passphrase to be entered
;; in the minibuffer.  See:
;; https://colinxy.github.io/software-installation/2016/09/24/emacs25-easypg-issue.html
(setq epg-pinentry-mode 'loopback)


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

(use-package chruby)

;; Load the PATH environment variable on non-windows systems.
(use-package exec-path-from-shell
  :config
  (when (memq window-system '(mac ns))
    (exec-path-from-shell-initialize)

    ;; Use a default ruby version of 3.1.2. Make sure this happens _after_ the
    ;; exec-path-from-shell initialization so that the chruby part of the path
    ;; comes _after_ the path added by exec-path-from-shell.
    (chruby "3.1.2")))

;; Automatically add matching delimiters, e.g. quotes, parentheses.
(use-package elec-pair
  :config
  (electric-pair-mode +1))

(use-package paren
  :config
  (show-paren-mode +1))

(use-package dumb-jump
  :config
  ;; Remove tags backend, since I don't use it.
  (setq xref-backend-functions (remq 'etags--xref-backend xref-backend-functions))

  ;; Add a dumb-jump backend to xref. This allows for using regular xref
  ;; functions (e.g. M-.) for jumping around.
  (add-to-list 'xref-backend-functions #'dumb-jump-xref-activate t)

  ;; Force dumb-jump to use ripgrep because the default searcher, git-grep, does
  ;; not work when recurse-submodules is enabled. I have, in my ~/.gitconfig,
  ;; submodules set to recurse. So the search fails. Using rg instead allows
  ;; dumb-jump to function, but it would be good to get to the root cause of
  ;; this issue and hopefully fix it, since git-grep should be faster.
  (setq dumb-jump-force-searcher 'rg)


  (setq xref-show-definitions-function #'xref-show-definitions-completing-read))
(use-package fill-column-indicator
  :config
  ;; Panorama usually uses 80 character line limits. This makes that
  ;; the default.
  (setq-default fill-column 80)

  ;; Enable the fill column indicator everywhere.
  (add-hook 'after-change-major-mode-hook 'fci-mode))

;; A nice low-contrast theme. Widely used and well supported.
(use-package zenburn-theme
  :init (load-theme 'zenburn t))

(use-package dired-sidebar
  :bind (("C-x C-n" . dired-sidebar-toggle-sidebar))
  :ensure t
  :commands (dired-sidebar-toggle-sidebar))

(use-package magit
  :bind (("C-x g" . magit-status)
         ("C-c g b" . magit-log-buffer-file))
  :config
  (setq git-commit-summary-max-length 50)
  (setq magit-log-section-commit-count 20) ;; Increase from default of 10
  (setq magit-revision-insert-related-refs nil) ;; Don't show related refs
  (setq magit-diff-refine-hunk t)
  (add-hook 'git-commit-setup-hook (lambda () (set-fill-column 72))))

(use-package forge
  :after magit)

(use-package git-link
  :bind (("C-c g l" . git-link)
         ("C-c g c" . git-link-commit))
  :config (setq git-link-use-commit t))

(use-package docker
  :bind ("C-c d" . docker))

(use-package dockerfile-mode)

(use-package yaml-mode)

(use-package rubocop
  :bind (("C-c r a" . rubocop-autocorrect-current-file)))

(use-package ruby-mode
  :mode "\\(?:\\.rb\\|\\.irbrc\\|ru\\|rake\\|gemspec\\|/\\(?:Gem\\|Rake\\|Guard\\)file\\)\\'"
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

(use-package yard-mode
  :after ruby-mode
  :hook ruby-mode
  :init
  (add-hook
   'yard-mode-hook
   (lambda ()
     (make-local-variable 'paragraph-start)
     (setq paragraph-start
           (if yard-mode
               (concat " *#+[ ]*@"
                       yard-tags-re
                       ".*\\|"
                       (default-value 'paragraph-start))
             (default-value 'paragraph-start))))))

(use-package which-key
  :init
  (which-key-mode))

(use-package lsp-mode
  :init
  (setq lsp-keymap-prefix "C-c p")
  (setq lsp-enable-snippet nil)
  (setq lsp-headerline-breadcrumb-enable nil)

  ;; Performance tweaks, see https://emacs-lsp.github.io/lsp-mode/page/performance/
  (setq read-process-output-max (* 1024 1024)) ;; 1MiB
  (setq gc-cons-threshold 100000000)

  :ensure-system-package
  ((terraform-ls . "brew install hashicorp/tap/terraform-ls"))

  :hook ((ruby-mode . lsp)
         (terraform-mode . lsp)
         (lsp-mode . lsp-enable-which-key-integration))
  :commands lsp)

(use-package lsp-ui)

(use-package rspec-mode
  :config
  ;; At Panorama local development, and specs, are done in docker.
  (setq rspec-use-docker-when-possible t)
  (setq rspec-docker-container "test"))

;; Get flycheck going for syntax checking on start up! This integrates
;; with rubocop.
(use-package flycheck
  :init (global-flycheck-mode))

(use-package markdown-mode
  :ensure t
  :ensure-system-package pandoc
  :mode ("README\\.md\\'" . gfm-mode)
  :init (setq markdown-command "pandoc"))

(use-package pandoc-mode
  :ensure-system-package pandoc)

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

(use-package terraform-mode)

(use-package multiple-cursors
  :bind (("C-M-c"   . 'mc/edit-lines)
         ("C->"     . 'mc/mark-next-like-this)
         ("C-<"     . 'mc/mark-previous-like-this)
         ("C-C C-<" . 'mc/mark-all-like-this)))

(use-package rg
  :ensure-system-package (rg . ripgrep))

;; Completion framework in minibuffer.
(use-package vertico
  :ensure t
  :config
  (vertico-mode))

;; Fuzzy matching and scoring
(use-package orderless
  :ensure t
  :config
  ;; Use flex matching style that I'm used to, no need to separate matches.
  (push 'orderless-flex orderless-matching-styles)
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

(use-package projectile
  :ensure-system-package fd
  :init
  (setq projectile-globally-ignored-file-suffixes
        '(".json" ".min.js" ".log"))
  :config
  (define-key projectile-mode-map (kbd "s-p") 'projectile-command-map)
  (projectile-mode +1))

(use-package swiper
  :config
  (global-set-key "\C-s" 'swiper)
  (global-set-key "\C-r" 'swiper)
  (global-set-key "\C-c s" 'swiper-isearch)
  (global-set-key "\C-c r" 'swiper-isearch))

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

;; Based on https://github.com/org-roam/org-roam#configuration
(use-package org-roam
  :ensure t
  :ensure-system-package graphviz ;; Required for visualizing graph of nodes
  :custom
  (org-roam-directory (file-truename "~/notes/"))
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n f" . org-roam-node-find)
         ("C-c n g" . org-roam-graph)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n c" . org-roam-capture)
         ;; Dailies
         ("C-c n j" . org-roam-dailies-capture-today))
  :config
  ;; If you're using a vertical completion framework, you might want a more informative completion interface
  ;; (setq org-roam-node-display-template (concat "${title:*} " (propertize "${tags:10}" 'face 'org-tag)))

  (org-roam-db-autosync-mode)

  ;; Not yet using
  ;; https://www.orgroam.com/manual.html#org_002droam_002dprotocol, since I'm
  ;; not sure what the use case is. But uncomment this if it would be helpful to
  ;; capture things from other applications!
  ;;
  ;;(require 'org-roam-protocol)
  )

(use-package org-jira
  :ensure-system-package gpg
  :config
  (setq jiralib-url "https://panoramaed.atlassian.net")
  (setq org-jira-working-dir "~/org/jira"))

(use-package tex-site
  :ensure auctex
  :config
  (setq TeX-auto-save t)
  (setq TeX-parse-self t))

(use-package plantuml-mode
  :ensure-system-package plantuml
  :mode "\\.\\(plantuml\\|pum\\|plu\\)\\'"
  :config
  (setq plantuml-default-exec-mode 'executable)
  (setq plantuml-executable-path (executable-find "plantuml")))


;;; Project Management

;; This section contains utilities that make it easier to manage projects.
;; TODO: Determine whether or not this should include things like projectile.

;; I find this quicker than trying to navigate the JIRA UI.
(defun browse-ticket (ticket-id)
  "Open TICKET-ID in a web browser."
  (interactive
   (list
    (let ((str (thing-at-point 'sexp)))
      (if (and (stringp str) (string-match "^\\([A-Z0-9]+-[0-9]+\\)" str))
          (let ((default-ticket (substring-no-properties str (match-beginning 0) (match-end 0))))
          (read-string (format "Ticket ID (Default: %s): " default-ticket)
                       nil nil default-ticket))
        (read-string "Ticket ID: ")))))
  (browse-url
   (concat
    "https://panoramaed.atlassian.net/browse/"
    ticket-id)))

(global-set-key (kbd "C-M-t") 'browse-ticket)



;;; Zoom Accessibility

;; Put the zoom room links in their own file outside version control so that I
;; don't publish private links.
(let ((zoom-rooms-file "~/.zoomrooms.el"))
  (if (file-exists-p zoom-rooms-file)
      (progn
        (load-file zoom-rooms-file)
        (defun zoom-open ()
          "Open a selected zoom room."
          (interactive)
          (shell-command
           (format "open -a /Applications/zoom.us.app %s"
                   (cdr (assoc
                         (completing-read "Choose a room: " zoom/rooms nil t)
                         zoom/rooms)))))

        (global-set-key (kbd "C-x C-z") 'zoom-open))))


;;; Customization

;; Since customization is generated automatically, store it in a separate
;; file. That makes it easier to keep this file organized, consolidating the
;; machine-generated code into a single place.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

(when (file-exists-p custom-file)
  (load custom-file))

;;; init.el ends here
(put 'narrow-to-region 'disabled nil)
