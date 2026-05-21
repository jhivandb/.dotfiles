---
name: create-cr
description: Create an Application Normal Change Request issue in wso2-enterprise/choreo. Use when the user wants to create a change request, CR, or application normal change. Accepts optional title argument (e.g., /create-cr Take full dump of GA_DB). Always applies labels "Application,Normal Change Request".
argument-hint: [title]
disable-model-invocation: false
allowed-tools: Bash(gh api repos/wso2-enterprise/choreo/contents/.github/ISSUE_TEMPLATE/*)
context: fork
---

# Create Application Change Request

## Workflow

### 1. Fetch Template

```bash
gh api repos/wso2-enterprise/choreo/contents/.github/ISSUE_TEMPLATE/10_application_normal_change_request.md --jq '.content' | base64 -d
```

Use this template structure for the issue body.

### 2. Gather Information

If title provided as argument, use it. Otherwise ask for:

**Required:** Title, Description (what/why/scope)

**If applicable:** Execution steps (bash code blocks), Type of Change selections

### 3. Create Issue

```bash
gh issue create --repo wso2-enterprise/choreo \
  --title "TITLE" \
  --label "Application,Normal Change Request" \
  --body "BODY"
```

Escape special characters in body (quotes, backticks).

### 4. Return Results

Provide issue URL and number:
```
Created CR #12345: https://github.com/wso2-enterprise/choreo/issues/12345
```

## Domain Knowledge

- Database operations, infrastructure changes, deployments → mark "Infrastructure or component change"
- Read-only queries, investigations → uncheck "Breaking change"
- Keep titles under 80 characters
