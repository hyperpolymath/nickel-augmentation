; SPDX-License-Identifier: MPL-2.0
;; guix.scm — GNU Guix package definition for squisher-corpus
;; Usage: guix shell -f guix.scm

(use-modules (guix packages)
             (guix build-system gnu)
             (guix licenses))

(package
  (name "squisher-corpus")
  (version "0.1.0")
  (source #f)
  (build-system gnu-build-system)
  (synopsis "nickel-augmentation")
  (description "nickel-augmentation — part of the hyperpolymath ecosystem.")
  (home-page "https://github.com/hyperpolymath/nickel-augmentation")
  (license mpl2.0))
