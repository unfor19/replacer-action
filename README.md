# replacer-action

[![testing](https://github.com/unfor19/replacer-action/workflows/testing/badge.svg)](https://github.com/unfor19/replacer-action/actions?query=workflow%3Atesting)
[![test-action](https://github.com/unfor19/replacer-action-test/workflows/test-action/badge.svg)](https://github.com/unfor19/replacer-action-test/actions?query=workflow%3Atest-action)


Auto-update README.md file according to the source code. When to use this action?

- **CLI Help Menu**: Inject the *help menu* of your CLI to the *README.md* file, see [Help Menu](#help-menu)
- **Test Results**: Share test results in your *README.md* file, see [bargs test suite](https://github.com/unfor19/bargs#usage-output)
- **API Response**: Keep your README.md up-to-date with the response of your APIs

Tested in [unfor19/replacer-action-test](https://github.com/unfor19/replacer-action-test/actions?query=workflow%3Atest-action)

## How It Works

1. Uses [perl](https://marekbosman.com/site/perl-find-and-replace/) to manipulate the destination file - `README.md`
2. Executes [git diff](https://git-scm.com/docs/git-diff) to check if there are any changes in `README.md`
3. If there are no changes, exits successfully
4. If there are changes, executes [git commit](https://git-scm.com/docs/git-commit) followed by [git push](https://git-scm.com/docs/git-push)

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
    # IMPORTANT: Avoids endless loop
    paths-ignore:
      - "README.md"

jobs:
  update-readme:
    runs-on: ubuntu-20.04
    steps:
      - uses: actions/checkout@v2
      - name: Prepare source file
        run: |
          echo "<div>$(whoami)</div>" > test_results.log
      - uses: unfor19/replacer-action@v1
        name: Update README.md file
        with:
          src-file-path: "test_results.log"
          dst-file-path: "README.md"
          start-value: "<!-- replacer_start -->"
          end-value: "<!-- replacer_end -->"
          git-user-name: "replacer-action"
          git-user-email: "replacer-action@meirg.co.il"
          git-commit-msg: "Updated by GitHub Actions"
          git-skip-commit: false
          git-skip-push: false
          create-backup: true
```

### Help Menu

```bash
./entrypoint.sh --help
```

<!-- help_menu_start -->

```bash

Usage: bash entrypoint.sh --help

	--src_file_path    |  -sf   [ENV_VAR]                      Relative path to source file that will be injected
	--dst_file_path    |  -df   [README.md]                    Relative path to destination file
	--start_value      |  -sv   [<!-- replacer_start -->]      From where to start
	--end_value        |  -ev   [<!-- replacer_end -->]        Where to stop
	--git_user_name    |  -gu   [replacer-action]              Actor user name
	--git_user_email   |  -ge   [replacer-action.co.il]  Actor email address
	--git_commit_msg   |  -gm   [Updated by GitHub Actions]    Git commit message
	--git_skip_commit  |  -gsc  [false]                        Skip Git commit
	--git_skip_push    |  -gsp  [false]                        Skip Git push
	--create_backup    |  -cb   [true]                         Create a backup file
```
<!-- help_menu_end -->

_NOTE_: the code block above :point_up: was automatically generated with replacer! See the raw version of this [README.md](https://raw.githubusercontent.com/unfor19/replacer-action/master/README.md) file


### drone.io

<details>

<summary>Expand/Collapse</summary>

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

</details>

## Contributing

Report issues/questions/feature requests on the [Issues](https://github.com/unfor19/replacer-action/issues) section.

Pull requests are welcome! These are the steps:

1. Fork this repo
1. Create your feature branch from master (`git checkout -b my-new-feature`)
1. Build development image
   ```bash
   docker build -t "replacer-action:dev" --target "dev" .
   ```
1. Run development image
   ```bash
   docker run --rm -it -v "$PWD":"/code" --workdir "/code" "replacer-action:dev"
   ```
1. Add the code of your new feature
1. Run tests on your code, feel free to add more tests
   ```bash
   # in container
   ./tests/test.sh
   ... # All good? Move on to the next step
   ```
1. Commit your remarkable changes (`git commit -am 'Added new feature'`)
1. Push to the branch (`git push --set-up-stream origin my-new-feature`)
1. Create a new Pull Request and provide details about your changes

## Authors

Created and maintained by [Meir Gabay](https://github.com/unfor19)

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/unfor19/replacer-action/blob/master/LICENSE) file for details
