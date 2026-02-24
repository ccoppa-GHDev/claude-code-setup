---
description: Comprehensive code review with security, performance, and quality checks
argument-hint: [file path, PR number, or 'staged' for staged changes]
allowed-tools: Read, Grep, Glob, Bash
---

# Code Review: $ARGUMENTS

Perform a thorough code review covering all critical aspects.

## Scope Determination

First, determine what to review:
- If `$ARGUMENTS` is a file path → review that file
- If `$ARGUMENTS` is a PR number → `gh pr diff $ARGUMENTS`
- If `$ARGUMENTS` is 'staged' → `git diff --staged`
- If `$ARGUMENTS` is empty → `git diff HEAD`

## Review Checklist

### 1. 🔒 Security (CRITICAL)

- [ ] **Input Validation**
  - All user inputs are validated
  - No SQL injection vulnerabilities
  - No XSS vulnerabilities

- [ ] **Authentication/Authorization**
  - Proper auth checks on protected routes
  - No hardcoded credentials
  - Secrets not logged or exposed

- [ ] **Data Protection**
  - Sensitive data encrypted
  - PII handled properly
  - No data leaks in error messages

### 2. ⚡ Performance

- [ ] **Efficiency**
  - No N+1 query problems
  - Appropriate use of caching
  - No unnecessary computations

- [ ] **Resource Management**
  - Memory leaks avoided
  - Connections properly closed
  - Large datasets paginated

- [ ] **Async Operations**
  - Proper error handling in promises
  - No blocking operations
  - Appropriate timeouts set

### 3. ✅ Correctness

- [ ] **Logic**
  - Code does what it claims
  - Edge cases handled
  - Error states managed

- [ ] **Types**
  - Type safety maintained
  - No unsafe type assertions
  - Proper null/undefined checks

### 4. 🧹 Maintainability

- [ ] **Code Quality**
  - Single responsibility principle
  - DRY (no duplicate code)
  - Clear naming conventions

- [ ] **Documentation**
  - Complex logic commented
  - Public APIs documented
  - README updated if needed

- [ ] **Testing**
  - New code has tests
  - Tests are meaningful
  - Coverage maintained

### 5. 🏗️ Architecture

- [ ] **Design Patterns**
  - Consistent with codebase patterns
  - Appropriate abstractions
  - No tight coupling

- [ ] **Dependencies**
  - No unnecessary dependencies
  - Dependencies are maintained
  - Version constraints appropriate

## Output Format

Provide findings categorized as:

### 🚨 CRITICAL (Must fix before merge)
- [Issue]: [File:Line] - [Description]
  - **Why:** [Explanation]
  - **Fix:** [Suggested solution]

### ⚠️ WARNING (Should address)
- [Issue]: [File:Line] - [Description]
  - **Why:** [Explanation]
  - **Fix:** [Suggested solution]

### 💡 SUGGESTION (Nice to have)
- [Improvement]: [File:Line] - [Description]
  - **Benefit:** [Why it's better]

### ✨ PRAISE (Good patterns observed)
- [Good practice]: [Description]

## Summary

- Total issues found: [N]
- Critical: [N] | Warnings: [N] | Suggestions: [N]
- **Recommendation:** APPROVE / REQUEST_CHANGES / NEEDS_DISCUSSION
