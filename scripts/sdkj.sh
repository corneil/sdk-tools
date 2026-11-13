#!/usr/bin/env bash
# Works when sourced from bash or zsh, or when executed directly.
sdkj() {
  local SETUP=false
  local TOOLCHAINS=false
  local IGNORE_RC=false
  local HELP=false
  local ACTION="" VERSION="" CONTAINS=""
  local ARG_COUNT=0
  local arg
  for arg in "$@"; do
    if [ "$arg" = "--setup" ]; then
      SETUP=true
    elif [ "$arg" = "--toolchains" ]; then
      TOOLCHAINS=true
    elif [ "$arg" = "--ignore-rc" ]; then
      IGNORE_RC=true
    elif [ "$arg" = "--help" ] || [ "$arg" = "-h" ]; then
      HELP=true
    else
      ((ARG_COUNT++))
      case "$arg" in
        use|default|current|list|install)
          ACTION="$arg"
          ;;
        [0-9]*)
          VERSION="$arg"
          ;;
        *)
          CONTAINS="$arg"
          ;;
      esac
    fi
  done

  if [ "$HELP" = true ]; then
    cat <<'EOF'
Usage: sdkj [<action>] [<partial-version>] [<partial-distro>] [--setup] [--toolchains] [--ignore-rc] [--help]

Manage Java Development Kits (JDKs) with SDKMAN and update the certificate store.

Actions:
  (no arguments)  Show a numbered list of installed JDKs. Enter a number to use that JDK in the current shell.
  current         Show the default JDK version.
  list            Show available JDK versions without a pager. Filter by optional <partial-version> and <partial-distro>.
  use             Use an installed JDK that matches <partial-version> and optional <partial-distro> in the current shell.
                  This is the default action when <action> is omitted and <partial-version> or <partial-distro> is given.
  default         Set an installed JDK that matches <partial-version> and optional <partial-distro> as the default JDK.
  install         Find an available JDK from SDKMAN that matches <partial-version> and <partial-distro>, then install it.
                  If you do not give <partial-distro>, the default value is "tem" (Temurin).

Arguments:
  <partial-version>  The start of the JDK version number (for example: 21, 17, or 25.0.5).
                     Required when the action is "use", "default", or "install". Optional for "list".
  <partial-distro>   Part of the distribution name (for example: tem, zulu, graal, or amzn, librca).
                     Optional.

Options:
  --setup       Check all installed JDKs. Copy ~/.certs/jdk_cacerts to each JDK lib/security/cacerts file if the file is missing or different.
                If you use only --setup, sdkj updates the certificates and exits.
  --toolchains  When used with "use", "default", or "install", update ~/.m2/toolchains.xml with yq so the matching JDK version points to the selected JDK path.
  --ignore-rc   When used with "use", do not modify the .sdkmanrc file in the current directory if it exists.
  --help        Show these instructions and exit.

Certificate check:
  After "use", "default", or "install", sdkj checks the lib/security/cacerts file of the selected JDK.
  If the file is missing or different from ~/.certs/jdk_cacerts, sdkj copies ~/.certs/jdk_cacerts to the JDK.

Examples:
  sdkj                           Select an installed JDK from a list.
  sdkj current                   Show the current JDK.
  sdkj list                      Show all available JDKs.
  sdkj list 21                   Show available Java 21 JDKs.
  sdkj list 21 zulu              Show available Java 21 Zulu JDKs.
  sdkj 21                        Use an installed Java 21 JDK (default action is "use").
  sdkj use 21                    Use an installed Java 21 JDK.
  sdkj use 25 zulu --toolchains  Use an installed Java 25 Zulu JDK and update ~/.m2/toolchains.xml.
  sdkj default 21 tem            Set the installed Java 21 Temurin JDK as default.
  sdkj install 21                Install the latest Java 21 Temurin JDK.
  sdkj install 21 zulu           Install the latest Java 21 Zulu JDK.
  sdkj --setup                   Update certificates for all installed JDKs.
EOF
    return 0
  fi

  _sdkj_run_sdk() {
    if ! declare -f sdk >/dev/null 2>&1; then
      export SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"
      if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
        source "$SDKMAN_DIR/bin/sdkman-init.sh"
      fi
    fi
    sdk "$@"
  }

  _sdkj_sync_cacerts() {
    local cand="$1"
    local JAVA_DIR="${SDKMAN_DIR:-$HOME/.sdkman}/candidates/java/$cand"
    if [ ! -d "$JAVA_DIR" ]; then
      return 0
    fi
    local SECURITY_DIR="$JAVA_DIR/lib/security"
    local SRC_CACERTS="$HOME/.certs/jdk_cacerts"
    if [ -d "$JAVA_DIR/jre/lib/security" ]; then
      SECURITY_DIR="$JAVA_DIR/jre/lib/security"
    fi
    if [ ! -f "$SRC_CACERTS" ]; then
      echo "Warning: $SRC_CACERTS not found; skipping cacerts check"
    elif [ ! -f "$SECURITY_DIR/cacerts" ] || ! cmp -s "$SRC_CACERTS" "$SECURITY_DIR/cacerts"; then
      mkdir -p "$SECURITY_DIR"
      if cp "$SRC_CACERTS" "$SECURITY_DIR/cacerts"; then
        echo "Copied cacerts to $SECURITY_DIR/cacerts"
      fi
    fi
  }

  _sdkj_sort_tags() {
    awk '
    {
      tag = $0
      distro = ""
      ver = tag
      if (match(tag, /-[^-]+$/)) {
        distro = substr(tag, RSTART + 1)
        ver = substr(tag, 1, RSTART - 1)
      }
      n = split(ver, parts, /[^0-9]+/)
      key = ""
      for (i = 1; i <= 6; i++) {
        val = (i <= n && parts[i] != "") ? parts[i] + 0 : 0
        key = key sprintf("%06d.", val)
      }
      printf "%s\t%s\t%s\n", key, distro, tag
    }' | sort -k1,1 -k2,2 -k3,3 | cut -f3
  }

  _sdkj_toolchains() {
    local cand="$1"
    local do_update="$2"
    if [ -z "$cand" ]; then
      return 0
    fi
    local TOOLCHAINS_FILE="$HOME/.m2/toolchains.xml"
    local JAVA_DIR="${SDKMAN_DIR:-$HOME/.sdkman}/candidates/java/$cand"
    if [ ! -f "$TOOLCHAINS_FILE" ]; then
      if [ "$do_update" = true ]; then
        echo "Warning: $TOOLCHAINS_FILE not found; skipping toolchains update"
      fi
      return 0
    fi
    local MAJOR_VER="${cand%%.*}"
    local TC_VER="${MAJOR_VER%%[^0-9]*}"
    if [ "$TC_VER" = "8" ]; then
      TC_VER="1.8"
    fi
    local YQ_BIN="yq"
    if ! command -v yq >/dev/null 2>&1; then
      local brew_yq
      for brew_yq in "/opt/homebrew/bin/yq" "/home/linuxbrew/.linuxbrew/bin/yq"; do
        if [ -x "$brew_yq" ]; then
          YQ_BIN="$brew_yq"
          break
        fi
      done
    fi
    local EXISTING_JDK_HOME
    EXISTING_JDK_HOME=$(TC_VER="$TC_VER" "$YQ_BIN" -p xml -oy '.toolchains.toolchain[] | select(.provides.version == env(TC_VER)).configuration.jdkHome' "$TOOLCHAINS_FILE")
    if [ "$do_update" = true ]; then
      if [ "$EXISTING_JDK_HOME" = "$JAVA_DIR" ]; then
        echo "Toolchains entry for version $TC_VER already set to $JAVA_DIR"
      else
        TC_VER="$TC_VER" JDK_HOME="$JAVA_DIR" "$YQ_BIN" -i -p xml -o xml '(.toolchains.toolchain[] | select(.provides.version == env(TC_VER)).configuration.jdkHome) = env(JDK_HOME)' "$TOOLCHAINS_FILE"
        echo "Updated toolchains entry for version $TC_VER to $JAVA_DIR"
      fi
    else
      if [ -z "$EXISTING_JDK_HOME" ]; then
        echo "Warning: toolchains.xml has no entry for version $TC_VER (selected: $JAVA_DIR)"
      elif [ "$EXISTING_JDK_HOME" != "$JAVA_DIR" ]; then
        echo "Warning: toolchains.xml jdkHome for version $TC_VER is $EXISTING_JDK_HOME (selected: $JAVA_DIR)"
      fi
    fi
  }

  _sdkj_sync_all_cacerts() {
    local v
    local INSTALLED_LIST=($(ls -tr "${SDKMAN_DIR:-$HOME/.sdkman}/candidates/java/" | grep -v '^current$'))
    for v in "${INSTALLED_LIST[@]}"; do
      _sdkj_sync_cacerts "$v"
    done
  }

  _sdkj_update_sdkmanrc() {
    local cand="$1"
    if [ ! -f ".sdkmanrc" ] || [ -z "$cand" ]; then
      return 0
    fi
    local temp_file
    temp_file=$(mktemp 2>/dev/null || echo ".sdkmanrc.tmp.$$")
    awk -v tag="$cand" '
      /^[[:space:]]*java[[:space:]]*=/ {
        print "java=" tag
        next
      }
      { print }
    ' .sdkmanrc > "$temp_file" && cp "$temp_file" .sdkmanrc
    rm -f "$temp_file"
  }

  local v
  if [ "$SETUP" = true ] && [ "$ARG_COUNT" -eq 0 ]; then
    _sdkj_sync_all_cacerts
    return 0
  fi

  local CANDIDATE=""

  if [ "$ARG_COUNT" -eq 0 ]; then
    ACTION="use"
    local CURRENT_TAG
    CURRENT_TAG=$(_sdkj_run_sdk current java | awk '/Not using any version/ { next } NF { print $NF }')
    local SORTED_LIST=($(ls "${SDKMAN_DIR:-$HOME/.sdkman}/candidates/java/" | grep -v '^current$' | _sdkj_sort_tags))

    local i=0
    for v in "${SORTED_LIST[@]}"; do
      ((i++))
      if [ "$v" = "$CURRENT_TAG" ]; then
        echo "$i) $v *"
      else
        echo "$i) $v"
      fi
    done

    if [ "$i" -eq 0 ]; then
      echo "No installed Java candidates found"
      return 1
    fi

    local SELECTION
    printf "Select candidate [1-%d]: " "$i"
    read -r SELECTION
    if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt "$i" ]; then
      echo "Invalid selection: $SELECTION"
      return 1
    fi

    local idx=0
    for v in "${SORTED_LIST[@]}"; do
      ((idx++))
      if [ "$idx" -eq "$SELECTION" ]; then
        CANDIDATE="$v"
        break
      fi
    done
  else
    if [ -z "$ACTION" ]; then
      ACTION="use"
    fi

    if [ "$ACTION" = "current" ]; then
      local CURRENT_OUT
      CURRENT_OUT=$(_sdkj_run_sdk current java)
      echo "$CURRENT_OUT"
      local CURRENT_TAG
      CURRENT_TAG=$(echo "$CURRENT_OUT" | awk '/Not using any version/ { next } NF { print $NF }')
      _sdkj_toolchains "$CURRENT_TAG" false
      if [ "$SETUP" = true ]; then
        _sdkj_sync_all_cacerts
      fi
      return 0
    fi

    if [ "$ACTION" = "list" ]; then
      if [ -z "$VERSION" ] && [ -z "$CONTAINS" ]; then
        PAGER=cat _sdkj_run_sdk list java
      else
        PAGER=cat _sdkj_run_sdk list java | awk -F'|' -v ver="$VERSION" -v dist="$CONTAINS" '
        NF < 4 || $4 ~ /Identifier/ {
          next
        }
        {
          v = $1; gsub(/^[ \t]+|[ \t]+$/, "", v)
          if (v != "") {
            current_vendor = $1
            vendor_printed = 0
          }
          id = $4; gsub(/^[ \t]+|[ \t]+$/, "", id)
          ver_ok = (ver == "" || id == ver || index(id, ver ".") == 1 || index(id, ver "-") == 1 || index(id, ver "+") == 1)
          dist_ok = (dist == "" || index(id, dist) > 0)
          if (ver_ok && dist_ok) {
            if (!vendor_printed) {
              printf "%s|%s|%s|%s\n", current_vendor, $2, $3, $4
              vendor_printed = 1
            } else {
              print $0
            }
          }
        }'
      fi
      if [ "$SETUP" = true ]; then
        _sdkj_sync_all_cacerts
      fi
      return 0
    fi

    if [ -z "$VERSION" ]; then
      echo "Expected Version prefix"
      return 1
    fi

    local CANDIDATE_LIST=()
    if [ "$ACTION" = "install" ]; then
      if [ -z "$CONTAINS" ]; then
        CONTAINS="tem"
      fi
      CANDIDATE_LIST=($(PAGER=cat _sdkj_run_sdk list java | awk -F'|' 'NF >= 4 { gsub(/^[ \t]+|[ \t]+$/, "", $4); if ($4 != "" && $4 != "Identifier") print $4 }' | _sdkj_sort_tags))
    else
      CANDIDATE_LIST=($(ls "${SDKMAN_DIR:-$HOME/.sdkman}/candidates/java/" | grep -v '^current$' | _sdkj_sort_tags))
    fi

    local EXACT_DISTRO_CANDIDATE=""
    local PARTIAL_DISTRO_CANDIDATE=""
    local DISTRO
    for v in "${CANDIDATE_LIST[@]}"; do
      if [[ "$v" == "$VERSION" ]] || [[ "$v" == "${VERSION}."* ]] || [[ "$v" == "${VERSION}-"* ]] || [[ "$v" == "${VERSION}+"* ]]; then
        if [ -n "$CONTAINS" ]; then
          DISTRO="${v##*-}"
          if [ "$DISTRO" = "$CONTAINS" ]; then
            EXACT_DISTRO_CANDIDATE="$v"
          elif [[ "$v" == *"${CONTAINS}"* ]]; then
            PARTIAL_DISTRO_CANDIDATE="$v"
          fi
        else
          CANDIDATE="$v"
        fi
      fi
    done

    if [ -n "$CONTAINS" ]; then
      if [ -n "$EXACT_DISTRO_CANDIDATE" ]; then
        CANDIDATE="$EXACT_DISTRO_CANDIDATE"
      else
        CANDIDATE="$PARTIAL_DISTRO_CANDIDATE"
      fi
    fi
  fi

  if [ -n "$CANDIDATE" ]; then
    _sdkj_run_sdk "$ACTION" java "$CANDIDATE"
    local SDK_STATUS=$?

    if [ "$ACTION" = "use" ] && [ "$IGNORE_RC" = false ]; then
      _sdkj_update_sdkmanrc "$CANDIDATE"
    fi

    if [ "$SETUP" = true ]; then
      _sdkj_sync_all_cacerts
    else
      _sdkj_sync_cacerts "$CANDIDATE"
    fi

    _sdkj_toolchains "$CANDIDATE" "$TOOLCHAINS"
    return $SDK_STATUS
  else
    echo "Couldn't find a distribution for $*"
    return 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  sdkj "$@"
elif [ -n "$1" ]; then
  sdkj "$@"
fi