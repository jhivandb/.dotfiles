---
name: create-cr
description: Create an Application Normal Change Request issue in wso2-enterprise/choreo. Use when the user wants to create a change request, CR, or application normal change.
argument-hint: [title]
disable-model-invocation: false
allowed-tools: Bash(gh api repos/wso2-enterprise/choreo/contents/.github/ISSUE_TEMPLATE/*)
---

# Create Application Change Request

Creates an Application Normal Change Request issue in the wso2-enterprise/choreo repository using the official template.

## Instructions

When this skill is invoked, follow these steps in order:

### Step 1: Fetch the Current Template

First, retrieve the latest application normal change request template to ensure you use the correct format:

```bash
gh api repos/wso2-enterprise/choreo/contents/.github/ISSUE_TEMPLATE/10_application_normal_change_request.md --jq '.content' | base64 -d
```

Review the template structure. It typically contains:
- Description field
- Type of Change checkboxes
- Testing section
- Checklist for environments and code quality

### Step 2: Gather Information

If the user provided arguments with the skill invocation (e.g., `/create-cr Take full dump of GA_DB`), use that as the title. Otherwise, ask the user for:

**Required:**
- **Title**: Clear, concise title for the change request
- **Description**: What needs to be changed, why, and what's the scope

**Important:**
- **Execution Steps**: Specific commands or procedures to execute the change (use code blocks with bash syntax)
- **Type of Change**: Which checkboxes apply:
  - Infrastructure or component change
  - Breaking change
  - Requires documentation update

**Optional:**
- **Testing details**: How to verify the change
- **Dependencies**: Prerequisites or requirements
- **Risk Assessment**: Impact level and mitigation
- **Success Criteria**: What defines success

### Step 3: Format the Issue Body

Structure the issue body following the template format:

```markdown
### Description
[User's description here - include background, purpose, and scope]

### Type of Change
- [x or ] Infrastructure or component change
- [x or ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [x or ] change requires a documentation update

### Execution Steps

[If provided, format execution steps with proper bash code blocks]

Example:
#### 1. Step Name
\`\`\`bash
# Command description
command -option value
\`\`\`

### Testing
[Testing details if provided, otherwise use template placeholder]

### Risk Assessment
[If provided, include risk level and details]

### Checklist
Change tested in below non-production environments
- [ ] Staging
- [ ] Development
- [ ] RND
- [ ] Sandbox

Other
- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published in downstream modules
- [ ] I have checked my code and corrected any misspellings
```

### Step 4: Create the Issue

Use the GitHub CLI to create the issue in the wso2-enterprise/choreo repository:

```bash
gh issue create --repo wso2-enterprise/choreo \
  --title "TITLE_HERE" \
  --label "Application,Normal Change Request" \
  --body "FORMATTED_BODY_HERE"
```

**Important:**
- Always use `--repo wso2-enterprise/choreo`
- Always include labels: `"Application,Normal Change Request"`
- Escape any special characters in the body (quotes, backticks, etc.)

### Step 5: Return Results

After successful creation, provide:
- The issue URL (e.g., https://github.com/wso2-enterprise/choreo/issues/12345)
- The issue number
- A confirmation message

Example output:
```
✅ Created Application Normal Change Request: #12345
🔗 https://github.com/wso2-enterprise/choreo/issues/12345

Title: Take Full Database Dump of GA_DB
```

## Tips

- Keep the title concise (under 80 characters)
- Be specific in execution steps with actual commands
- Check appropriate Type of Change boxes based on the description
- For database operations, infrastructure changes, or deployments, mark "Infrastructure or component change"
- For read-only queries or investigation tasks, uncheck "Breaking change"
- If in doubt about any field, ask the user for clarification

## Example Invocations

```
/create-cr Take full database dump of GA_DB
/create-cr
/create-cr Update memory limits for Global Adapter
```
