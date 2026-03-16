# SPDX-License-Identifier: PMPL-1.0-or-later
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# prelude.ncl — Re-exports all augmentation library modules
#
# Usage:
#   let aug = import "./lib/prelude.ncl" in
#   { name | aug.rsr.NonEmptyString = "my-project" }
{
  rsr = import "./rsr.ncl",
  security = import "./security.ncl",
  ci = import "./ci.ncl",
  infra = import "./infra.ncl",
}
