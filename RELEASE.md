# Release Process

This document provides step-by-step instructions for releasing new versions of the golang-crossbuild project.

## Overview

This project follows the Golang versioning scheme, creating a GitHub Release for each specific Golang version. The release process ensures backward compatibility by maintaining separate branches for different Go versions.

## 🚀 Primary Release Process: New Go Version

This is the most common release scenario. Follow these steps when a new Go version is released.

### Prerequisites
- New Go version has been officially released
- You have write access to the repository
- You're familiar with the current Go version in use

### Step-by-Step Instructions

#### 1. Prepare Version Branch
Create a branch for the previous Go version to maintain backward compatibility.

**Example**: If upgrading from Go 1.24 to Go 1.25:
```bash
# Create branch for previous version (1.24)
git checkout main
git checkout -b 1.24
git push origin 1.24
```

#### 2. Update Core Version Files
Update the Go version in the main configuration files:

- **File**: `.go-version`
  - Update to the new Go version (e.g., `1.25.0`)

- **File**: `go/Makefile.common` (line 5)
  - Update the Docker tag to match the new version

#### 3. Run Version Bump Script
Execute the automated version bump script:
```bash
.github/updatecli.d/bump-go-release-version.sh "$(cat .go-version)"
```

#### 4. Update Documentation
- **File**: `README.md`
  - Update all version references to the new Go version

#### 5. Update GitHub Workflows
- **File**: `.github/workflows/bump-golang.yml`
  - Update `go-minor` value to new minor version (e.g., `1.25`)

- **File**: `.github/workflows/bump-golang-previous.yml`
  - Update `go-minor` to previous minor version (e.g., `1.24`)
  - Update `branch` value to previous minor version (e.g., `1.24`)

#### 6. Configure Backport Support
- **File**: `.mergify.yml`
  - Add entry for new backport label: `backport-v1.24` (using previous version)

- **GitHub Labels**
  - Create new label at: https://github.com/elastic/golang-crossbuild/labels
  - Label name: `backport-v1.24` (using previous version)

#### 7. Commit and Create Pull Request
```bash
git add -u
git commit -m "Update to Go 1.25.0"  # Use actual version
```

Create a Pull Request with:
- **Title**: `Update to Go 1.25.0`
- **Description**: Brief summary of the Go version update

#### 8. Merge and Release
- Ensure all CI checks pass
- Merge the Pull Request
- The automation will automatically release the Docker images

> **⚠️ Important Note**: Due to changes in Debian package repositories, Docker images for previous Go versions may stop working over time.

### Example Scenario
```
Current State: Go 1.24 on main branch
New Release: Go 1.25

Actions:
1. Create branch "1.24" from main
2. Update main branch to Go 1.25
3. Follow steps 2-8 above
```

---

## 🔧 Specialized Release Processes

### NPCAP Release
For detailed instructions on releasing NPCAP versions, see the dedicated [NPCAP documentation](./NPCAP.md).

### FPM Release
> **📋 Status**: Not actively released (deprecated for several years)  
> **Action**: To be documented when needed

### LLVM Apple Release  
> **📋 Status**: Infrequent releases (approximately every 3 years)  
> **Action**: To be documented when needed

---

## 🔄 Hotfix Process: Update Existing Released Version

Use this process for critical fixes to already-released versions.

### Prerequisites
- Existing release tag (e.g., `v1.25.1`)
- Critical fix that needs backporting
- Understanding of git branching and cherry-picking

### Step-by-Step Instructions

#### 1. Create Hotfix Branch
Create a maintenance branch for the specific version:
```bash
# Example for version 1.25.1
git checkout v1.25.1
git checkout -b 1.25.1.x  # 'x' is literal, not a placeholder
git push upstream 1.25.1.x
```

#### 2. Apply Your Changes

1. Ensure your original PR is merged to main
2. Comment on the PR: `@mergifyio backport 1.25.1.x`
3. Mergify will automatically create a backport PR
4. Review and merge the backport PR when CI passes

#### 3. Release Process
- Merge the hotfix PR
- The automation will handle the release process
- Verify the new images are published

### Example Hotfix Scenario
```
Scenario: Critical security fix needed for Go 1.25.1

Steps:
1. git checkout v1.25.1
2. git checkout -b 1.25.1.x
3. git push upstream 1.25.1.x
4. Apply fix via backport or manual PR
5. Merge when CI passes
```

---

## 📚 Quick Reference

### File Locations
| Component | File Path |
|-----------|-----------|
| Go Version | `.go-version` |
| Docker Tag | `go/Makefile.common` (line 5) |
| Main Workflow | `.github/workflows/bump-golang.yml` |
| Previous Workflow | `.github/workflows/bump-golang-previous.yml` |
| Mergify Config | `.mergify.yml` |
| Version Bump Script | `.github/updatecli.d/bump-go-release-version.sh` |

### Branch Naming Convention
- **Main development**: `main`
- **Version branches**: `1.23`, `1.24` (major.minor format)
- **Hotfix branches**: `1.25.1.x` (major.minor.patch.x format)

### Automation
- **Docker Images**: Released automatically on PR merge
- **Backports**: Available via Mergify (`@mergifyio backport <branch>`)
- **CI/CD**: All releases go through automated testing

---

## ❓ Troubleshooting

### Common Issues
1. **CI Failures**: Ensure all version references are updated consistently
2. **Docker Build Errors**: Check Debian package repository availability
3. **Backport Conflicts**: Resolve manually and create new PR
4. **Missing Labels**: Create GitHub labels before using backport commands

### Support
- Check existing GitHub issues for similar problems
- Review CI logs for specific error messages
- Consult team members for complex release scenarios
