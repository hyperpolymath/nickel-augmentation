# SPDX-License-Identifier: MPL-2.0
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# report.ncl — Audit report schema for config-reporter
#
# Defines the structure of a configuration audit report.
# The reporter driver (bin/config-reporter) populates this schema
# after scanning .ncl files in a target directory.
{
  # ═══════════════════════════════════════════════════════════════════════
  # REPORT SCHEMA
  # ═══════════════════════════════════════════════════════════════════════

  # Severity levels for findings
  Severity = [| 'error, 'warning, 'info |],

  # A single finding from the audit
  Finding = {
    file | String,
    line | Number | optional,
    severity | Severity,
    rule | String,
    message | String,
  },

  # Summary statistics for the audit
  Summary = {
    total_files | Number,
    files_passed | Number,
    files_failed | Number,
    errors | Number,
    warnings | Number,
    info | Number,
  },

  # Complete audit report
  Report = {
    version | String | default = "1.0.0",
    timestamp | String,
    target_directory | String,
    findings | Array Finding | default = [],
    summary | Summary,
  },
}
