# SPDX-License-Identifier: PMPL-1.0-or-later
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# rules.ncl — Audit rules for config-reporter
#
# Each rule checks a specific aspect of RSR compliance in Nickel configs.
# Rules are referenced by ID in the reporter driver script.
{
  # Rule metadata: ID, description, severity, how to check
  rules = [
    {
      id = "SPDX-001",
      name = "SPDX header present",
      description = "Every .ncl file must have an SPDX-License-Identifier comment in the first 5 lines",
      severity = "error",
      pattern = "SPDX-License-Identifier:",
    },
    {
      id = "SPDX-002",
      name = "SPDX license is approved",
      description = "SPDX identifier must be PMPL-1.0-or-later or MPL-2.0 (or third-party preserved)",
      severity = "warning",
      pattern = "SPDX-License-Identifier: (PMPL-1.0-or-later|MPL-2.0|MIT|Apache-2.0|BSD-[23]-Clause)",
    },
    {
      id = "SEC-001",
      name = "No HTTP URLs",
      description = "All URLs must use HTTPS, never plain HTTP",
      severity = "error",
      pattern = "http://",
      inverted = true,
    },
    {
      id = "SEC-002",
      name = "No weak hashes",
      description = "MD5 and SHA-1 must not be used for security purposes",
      severity = "warning",
      pattern = "(md5:|sha1:)[a-fA-F0-9]+",
      inverted = true,
    },
    {
      id = "LANG-001",
      name = "No banned languages in build targets",
      description = "Build targets must not reference typescript, go, python, java, kotlin, swift, or dart",
      severity = "error",
      pattern = "language\\s*=\\s*\"(typescript|go|python|java|kotlin|swift|dart)\"",
      inverted = true,
    },
    {
      id = "K9-001",
      name = "K9 magic header",
      description = "K9 contractile files (.k9.ncl) must start with K9! on the first line",
      severity = "error",
      pattern = "^K9!",
      applies_to = "*.k9.ncl",
    },
    {
      id = "K9-002",
      name = "K9 pedigree present",
      description = "K9 files must have a pedigree section with schema_version and security",
      severity = "error",
      pattern = "pedigree\\s*=",
      applies_to = "*.k9.ncl",
    },
    {
      id = "META-001",
      name = "Copyright header present",
      description = "Files should have a copyright header",
      severity = "info",
      pattern = "Copyright.*Jonathan D\\.A\\. Jewell|SPDX-FileCopyrightText:",
    },
  ],
}
