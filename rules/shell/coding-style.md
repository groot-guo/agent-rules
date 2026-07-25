---
paths:
  - "**/*.sh"
  - "**/*.bash"
  - "**/*.zsh"
---

# Shell Script Rules

## Safe Mode (mandatory)

Top of every script:
```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```

- `set -e` — exit on failure
- `set -u` — error on undefined var
- `set -o pipefail` — any pipe segment failure fails the whole
- `IFS=$'\n\t'` — avoid word-splitting traps

Intentional ignore: `cmd || true` — explicit, not by default.

## Variables & Quoting

- Double-quote all refs: `"$var"` / `"${var}"`
  ```bash
  # wrong
  rm -rf $dir/$name
  # right
  rm -rf "${dir}/${name}"
  ```
- Default: `${var:-default}`
- Required: `: "${VAR:?VAR is required}"`
- Locals must use `local`:
  ```bash
  my_func() {
      local input="$1"
      ...
  }
  ```

## Control Flow

- `[[ ]]` not `[ ]` (safer, regex, fewer quotes)
- Strings: `=`/`==`; numbers: `-eq`/`-lt` ...
- Command exists: `command -v xxx >/dev/null` — not `which`
- File checks: `-f` file / `-d` dir / `-e` any

## Functions

- Output via `echo`, status via `return N`
- No globals for args — use `$1` `$2` ...
- Params as `local` first:
  ```bash
  greet() {
      local name="${1:?name required}"
      echo "hello, $name"
  }
  ```

## Logging & Errors

- Errors to stderr: `echo "error: ..." >&2`
- Exit codes: `0` success, `1` generic error, `2` usage error, `127` command not found
- On failure report "what failed + known info" — not just `exit 1`

## Argument Parsing

Simple — positional + validation:
```bash
[[ $# -eq 2 ]] || { echo "usage: $0 <src> <dst>" >&2; exit 2; }
```

Complex — `getopts`:
```bash
while getopts "f:vh" opt; do
    case "$opt" in
        f) file="$OPTARG" ;;
        v) verbose=1 ;;
        h) usage; exit 0 ;;
        *) usage; exit 2 ;;
    esac
done
```

## Tools

- `shellcheck script.sh` must pass
- `printf` over `echo -e` (portable)
- Temp files via `mktemp` + trap cleanup:
  ```bash
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  ```
- Large data in pipes — `awk`/`sed` in one pass; avoid cat | grep | awk

## Complexity Bound

- **>100 lines → consider Python/Go**
- >200 lines → must switch
- Shell is bad at: JSON (use jq), complex data, HTTP (curl ok, parse with jq)

## Portability

- Prefer bash 4+
- macOS default bash is 3.2 — either `#!/usr/bin/env bash` + brew bash, or POSIX shell
- BSD (macOS) vs GNU (Linux): `sed`/`find`/`xargs` differ — note it

## Forbidden

- Scripts without `set -euo pipefail`
- Unquoted variable refs (unless explicit split)
- `eval` on user input (injection)
- Production `rm -rf` without absolute path or existence check
- Skipping `shellcheck`
- 100+ lines of business logic in shell

## Pre-Commit Checklist

- [ ] `set -euo pipefail` at top?
- [ ] All variables quoted?
- [ ] `shellcheck` passes?
- [ ] Errors to stderr?
- [ ] Exit codes semantic?
- [ ] Temp files via mktemp + trap?
- [ ] Under 100 lines?
