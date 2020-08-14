# replacer-action

[![testing](https://github.com/unfor19/replacer-action/workflows/testing/badge.svg)](https://github.com/unfor19/replacer-action/actions?query=workflow%3Atesting)

Auto-update README.md file according to the source code.

## Requirements

1. Insert a start tag and stop tag to a text file, for example

```html
<!-- replacer_start -->

<div>User name will appear here instead</div>

<!-- replacer_end -->
```

2. Prepare a file with the text that you want to inject

```bash
$ echo -e '<div>This is the incoming text block</div>\n<div>It worked!</div>' > test_results.log
```

## Usage

### GitHub Action

```yaml
name: Update README.md
on:
  push:
    branches: [master]
    paths-ignore:
      - "README.md"

jobs:
  update-readme:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Prepare source file
        run: |
          echo "<div>$(whoami)</div>" > test_results.log
      - uses: unfor19/replacer-action@v1.0.2
        name: Update README.md file
        with:
          src-file-path: "test_results.log"
          dst-file-path: "README.md"
          start-value: "<!-- replacer_start -->"
          end-value: "<!-- replacer_end -->"
          git-user-name: "GitHub Actions"
          git-user-email: "githubactions@meirg.co.il"
          git-commit-msg: "Updated by GitHub Actions"
          git-skip-commit: false
          git-skip-push: false
          create-backup: true
```

### drone

```yaml
kind: pipeline
type: docker
name: testing-drone

steps:
  - name: Prepare source file
    image: alpine:3.12
    cmd: |
      echo "<div>$(whoami)</div>" > test_results.log
  - name: Dry run
    image: unfor19/replacer-action:latest
    settings:
      src_file_path: "test_results.log"
      dst_file_path: "README.test.md"
      start_value: "<!-- replacer_start -->"
      end_value: "<!-- replacer_end -->"
      git_user_name: "Drone"
      git_user_email: "drone@meirg.co.il"
      git_commit_msg: "Updated by Drone.io"
      git_skip_commit: false
      git_skip_push: false
      create_backup: true
```

## Authors

Created and maintained by [Meir Gabay](https://github.com/unfor19)

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/unfor19/replacer-action/blob/master/LICENSE) file for details
