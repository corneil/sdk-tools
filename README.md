# SDK Tools

## Introduction
This project contains scripts and utilities that assist with local development tools

## SKDMAN

### SDKJ

Usage: `sdkj [<action>] [<partial-version>] [<partial-distro>] [--setup] [--toolchains] [--help]`

Manage Java Development Kits (JDKs) with SDKMAN and update the certificate store.
You can add source `<path-to>/sdkj.sh` in `.profile`, `.bashrc` or `.zshrc` or use sdkj.sh directly.

#### Actions
* (no arguments)  Show a numbered list of installed JDKs. Enter a number to use that JDK in the current shell.
* `current`         Show the default JDK version.
* `list`            Show available JDK versions without a pager. Filter by optional <partial-version> and <partial-distro>.
* `use`             Use an installed JDK that matches <partial-version> and optional <partial-distro> in the current shell.
This is the default action when <action> is omitted and <partial-version> or <partial-distro> is given.
* `default`         Set an installed JDK that matches <partial-version> and optional <partial-distro> as the default JDK.
* `install`         Find an available JDK from SDKMAN that matches <partial-version> and <partial-distro>, then install it.
If you do not give <partial-distro>, the default value is `tem` (Temurin).

#### Arguments
* <partial-version>  The start of the JDK version number (for example: 21, 17, or 25.0.5).
Required when the action is `use`, `default`, or `install`. Optional for `list`.
* <partial-distro>   Part of the distribution name (for example: `tem`, `zulu`, `graal`, or `amzn`, `librca`).
Optional.

#### Options
* `--setup`       Check all installed JDKs. Copy `~/.certs/jdk_cacerts` to each JDK `lib/security/cacerts` file if the file is missing or different.
_If you use only `--setup`, `sdkj` updates the certificates and exits._
* `--toolchains`  When used with `use`, `default`, or `install`, update `~/.m2/toolchains.xml` with yq so the matching JDK version points to the selected JDK path.
* `--help`        Show these instructions and exit.

#### Certificate check
After `use`, `default`, or `install`, `sdkj` checks the `lib/security/cacerts` file of the selected JDK.

If the file is missing or different from `~/.certs/jdk_cacerts`, `sdkj` copies `~/.certs/jdk_cacerts` to the JDK.

#### Examples
* `sdkj`                           Select an installed JDK from a list.
* `sdkj current`                   Show the current JDK.
* `sdkj list`                      Show all available JDKs.
* `sdkj list 21`                   Show available Java 21 JDKs.
* `sdkj list 21 zulu`              Show available Java 21 Zulu JDKs.
* `sdkj 21`                        Use latest installed Java 21 JDK (default action is "use").
* `sdkj use 21`                    Use latest installed Java 21 JDK.
* `sdkj use 25 zulu --toolchains`  Use latest installed Java 25 Zulu JDK and update `~/.m2/toolchains.xml.`
* `sdkj default 21 tem`            Set the latest installed Java 21 Temurin JDK as default.
* `sdkj install 21`                Install the latest Java 21 Temurin JDK.
* `sdkj install 21 zulu`           Install the latest Java 21 Zulu JDK.
* `sdkj --setup`                   Update certificates for all installed JDKs.