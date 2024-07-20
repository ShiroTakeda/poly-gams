;;; poly-gams.el --- polymode for GAMS -*- lexical-binding: t -*-
;;
;; Author: Shiro Takeda
;; Maintainer: Shiro Takeda
;; Copyright (C) Shiro Takeda
;; Version: 0.9
;; First created: 2022-06-25
;; Package-Requires: ((emacs "25") (polymode "0.2.2"))
;; URL: 
;; Keywords: languages, multi-modes, GAMS
;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This file is *NOT* part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.
;;
;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

(eval-and-compile
  (require 'gams-mode)
  (require 'polymode))

(define-hostmode poly-gams-hostmode
  :mode 'gams-mode)

(defvar poly-gams-head-regexp
  "Regular expression for the start part of embedded codes."
      "^[ \t]*\\($on\\|continue\\)*embeddedcode[^ \t\n:]*[ \t:]+")

(defvar poly-gams-tail-regexp
  "Regular expression for the end part of embedded codes."
      "^\\($[ \t]*off\\|[ \t]*end\\|[ \t]*pause\\)+embeddedcode.*")

(defvar poly-gams-head-regexp-alt
  "Regular expression for the start part of embedded codes."
      "^[ \t]*embeddedcode[^ \t]*[ \t]+\\(python\\|connect\\)")

(setq poly-gams-head-regexp
      "^[ \t]*\\($on\\|continue\\)*embeddedcode[^ \t\n:]*[ \t:]+")

(setq poly-gams-tail-regexp
      "^\\($[ \t]*off\\|[ \t]*end\\|[ \t]*pause\\)+embeddedcode.*")

(setq poly-gams-head-regexp-alt
      "^[ \t]*embeddedcode[^ \t]*[ \t]+\\(python\\|connect\\)")

(defun poly-gams-head-matcher-function-sub (type)
  "Fucntion used for specifying the start part of embedded codes"
  (let (matched-str flag)
    (save-excursion
      (when (re-search-backward poly-gams-head-regexp-alt nil t)
        (setq matched-str (gams-buffer-substring (match-beginning 1)
                                                 (match-end 1)))
        (when (string-match type matched-str)
          (setq flag t))))
    flag))

(defun poly-gams-python-head-matcher-function (ahead)
  "Fucntion used for specifying the start part of python embedded codes"
  (save-excursion
    (if (re-search-forward poly-gams-head-regexp nil t ahead)
        (let ((head (cons (match-beginning 0) (match-end 0)))
              matched-str)
          (setq matched-str
                (gams-buffer-substring (match-beginning 0)
                                       (match-end 0)))
          (if (string-match "continue" matched-str)
              (progn
                (when (poly-gams-head-matcher-function-sub "python")
                  (save-match-data head)))
            (save-match-data
              (and
               (goto-char (cdr head))
               (looking-at "python")
               head)))))))

(defun poly-gams-python-tail-matcher-function (ahead)
  "Fucntion used for specifying the end part of python embedded codes"
  (save-excursion
    (if (re-search-forward poly-gams-tail-regexp nil t ahead)
        (let ((head (cons (match-beginning 0) (match-end 0))))
          (save-match-data
            (goto-char (car head))
            (and (not (looking-at "[[:digit:]]"))
                 (not (looking-back "[_[:word:]]" nil))
                 head))))))

(defun poly-gams-connect-head-matcher-function (ahead)
  "Fucntion used for specifying the start part of connect embedded codes"
  (save-excursion
    (if (re-search-forward poly-gams-head-regexp nil t ahead)
        (let ((head (cons (match-beginning 0) (match-end 0)))
              matched-str)
          (setq matched-str
                (gams-buffer-substring (match-beginning 0)
                                       (match-end 0)))
          (if (string-match "continue" matched-str)
              (progn
                (when (poly-gams-head-matcher-function-sub "connect")
                  (save-match-data head)))
            (save-match-data
              (and
               (goto-char (cdr head))
               (looking-at "connect")
               head)))))))

(defun poly-gams-connect-tail-matcher-function (ahead)
  "Fucntion used for specifying the end part of connect embedded codes"
  (save-excursion
    (if (re-search-forward poly-gams-tail-regexp nil t ahead)
        (let ((head (cons (match-beginning 0) (match-end 0))))
          (save-match-data
            (goto-char (car head))
            (and (not (looking-at "[[:digit:]]"))
                 (not (looking-back "[_[:word:]]" nil))
                 head))))))

(define-innermode poly-gams-python-innermode
  :mode 'python-mode
  :head-matcher 'poly-gams-python-head-matcher-function
  :tail-matcher 'poly-gams-python-tail-matcher-function
  :head-mode 'host
  :tail-mode 'host)

(define-innermode poly-gams-connect-innermode
  :mode 'yaml-mode
  :head-matcher 'poly-gams-connect-head-matcher-function
  :tail-matcher 'poly-gams-connect-tail-matcher-function
  :head-mode 'host
  :tail-mode 'host)

;;;###autoload  (autoload 'poly-gams-mode "poly-gams" "GAMS polymode. t)
(define-polymode poly-gams-mode
  :hostmode 'poly-gams-hostmode
  :innermodes '(poly-gams-python-innermode
                poly-gams-connect-innermode))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.gms\\'" . poly-gams-mode))

(provide 'poly-gams)

;;; poly-gams.el ends here
