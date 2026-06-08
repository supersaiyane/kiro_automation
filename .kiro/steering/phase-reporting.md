---
inclusion: fileMatch
fileMatchPattern: "**/docs/phase-*/**"
---

# Phase Reporting Templates

Loaded only when working in phase docs. Contains mandatory report formats.

---

## MANDATORY PER-PHASE REPORTS (6 reports, each with per-sprint sections)

### A. QA Report (`docs/phase-N/QA-REPORT.md`)
```markdown
## QA Report — Phase N
### Sprint N.M
| Metric | Value |
|--------|-------|
| Unit tests run | X |
| Unit tests passed | X |
| Coverage % | X% |
| Integration tests | X pass / Y fail |
| Bugs found | X (TASK IDs) |
| Bugs fixed | X |
| Bugs carried | X |
```

### B. Security Report (`docs/phase-N/SECURITY-REPORT.md`)
```markdown
## Security Report — Phase N
### Sprint N.M
| Check | Result |
|-------|--------|
| npm audit | X critical, Y high, Z moderate |
| Secrets scan | CLEAN / FOUND |
| New deps | X (approved? Y/N) |
| OWASP checks | list |
| Open issues | X |
```

### C. Mapping Report (`docs/phase-N/MAPPING-REPORT.md`)
```
| Phase | Sprint | Task ID | Title | Status | Commit SHA | Branch |
```

### D. Discipline Report (`docs/phase-N/DISCIPLINE-REPORT.md`)
```markdown
### Sprint N.M
| Metric | Value |
|--------|-------|
| Reads | X |
| Tool calls | X |
| Tier | PEAK/GOOD/DEGRADING/CRITICAL |
| Tokens estimated | X |
| Violations | X |
```

### E. Jira Task Report (`docs/phase-N/JIRA-TASK-REPORT.md`)
Per-sprint sections with Epic/Story/Task breakdowns + velocity metrics.

### F. Git Tracking Report (`docs/phase-N/GIT-TRACKING-REPORT.md`)
Per-sprint sections with branch summary, commit log, git discipline checks.

---

## TOKEN ESTIMATION FORMULAS

```
file_read_tokens = lines_read × 4
tool_output_tokens = output_lines × 5
conversation_tokens = messages × 100
steering_tokens = steering_lines × 4
code_written_tokens = lines_written × 4
naive_baseline = files_modified × 2 × 800 (each read twice) + output × 1.5
savings_percent = (naive - actual) / naive × 100
```

---

## BUILD REPORT TEMPLATES

### Mode 3 (after every build)
```
| Metric | Value |
|--------|-------|
| Tests | X pass / Y fail |
| Coverage | X% |
| Reads | X |
| Tool calls | X |
| Tier | PEAK/GOOD/DEGRADING |
| Tokens saved | X% |
| Build verified | YES/NO |
```

### Mode 4 Lite
```
| Metric | Value |
|--------|-------|
| Tests written | X |
| Tests passed | X / Y |
| Coverage | X% |
| Agents used | [list] |
| Reads | X |
| Tool calls | X |
| Planning docs | X |
```

**These 6 reports are NON-NEGOTIABLE at every phase boundary.**
