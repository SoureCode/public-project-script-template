
# public-project-script-template

This is a template for project scripts that can be used in any project.

## Installation

Ensure you have the following lines in your `.gitignore` file:

```gitignore
# Ignore all subdirectories under scripts (script-template folders)
scripts/*/
# Except for the hooks folder (allows to hook into several script-template scripts)
!scripts/hooks/
# Recursively ignore any file ending with .local.sh (local files which you wont want to commit)
scripts/*.local.sh
scripts/**/*.local.sh
```

```bash
# script-template dependencies
git clone --depth 1 -b "master" "git@github.com:chapterjason/public-common-script-template.git" "scripts/public-common"
# the actual script-template
git clone --depth 1 -b "master" "git@github.com:chapterjason/public-project-script-template.git" "scripts/public-project"
```

## Development

Before starting to make changes, ensure you have the latest dependencies running:

```bash
./__dev.sh
```