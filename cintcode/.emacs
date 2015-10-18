(defun mouse-wheel-scroll-up ()
  "Enable mouse wheel scrolling under Emacs: scroll-up"
  (interactive)
  (scroll-up 3)
  (forward-line 3))

(defun mouse-wheel-scroll-down ()
  "Enable mouse wheel scrolling under Emacs: scroll-down"
  (interactive)
  (scroll-down  3)
  (forward-line -3))

(global-set-key [mouse-5] 'mouse-wheel-scroll-up)
(global-set-key [mouse-4] 'mouse-wheel-scroll-down)

;; Change the way I lay out C programs
;;
( setq c-argdecl-indent 3 )
( setq c-auto-newline nil )
( setq c-brace-offset 0 )
( setq c-continued-statement-indent 0 )
( setq c-indent-level 1 )
( setq c-label-indent 0 )
( setq c-label-offset -3 )
;;
;; Define TAB to mean tab-to-tab-stop, with tabs at 2, 5, 8, 40 and 80, and
;; auto fill mode on at column 80 if handling C.
;;
( defun init-c-for-jpb ()
  ( progn
    ( setq tab-stop-list '( 3 6 9 41 78 ))
    ( auto-fill-mode 1 )
    ( setq fill-column 79 )))
( setq c-mode-hook 'init-c-for-jpb )
;;
;; Set up the cursor keys
;;
( global-set-key "\eA" 'previous-line )
( global-set-key "\eB" 'next-line )
( global-set-key "\eC" 'forward-char )
( global-set-key "\eD" 'backward-char )


(put 'set-fill-column 'disabled t)
(display-time)
(setq line-number-mode 1)

;;
;; Set colours for my black and white X-terminal
;;

;;(invert-face 'modeline)
;;(set-foreground-color "black")
;;(set-background-color "white")
;;(set-cursor-color "black")



;;; to turn on syntax highlighting

(global-font-lock-mode t)
(setq font-lock-maximum-decoration t)

;;; to get the BCPL mode working properly

(load-library "~/Elisp/bcpl.el")
(setq auto-mode-alist (cons '("\\.b$" . bcpl-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.bcp$" . bcpl-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.bpl$" . bcpl-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.h$" . bcpl-mode) auto-mode-alist))




