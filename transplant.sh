#!/data/data/com.termux/files/usr/bin/bash

set -e

### CONFIG ###
TERMUX_PREFIX="/data/data/com.termux/files/usr"
TERMUX_HOME="/data/data/com.termux/files/home"

SHELL_PREFIX="/data/data/com.android.shell/usr"
SHELL_HOME="/data/data/com.android.shell/home"

STAGE="/sdcard/Download/rish_files"
BIN_STAGE="$STAGE/bin"
LIB_STAGE="$STAGE/lib"
EXTRA_STAGE="$STAGE/extra"
RC_STAGE="$STAGE/rc.sh"

RC_DST="$SHELL_PREFIX/bin/rc.sh"

### EXTRAS DATABASE ###
# format:
# program|type|source|destination
EXTRAS_DB=$(cat <<'EOF'
nvim|dir|/data/data/com.termux/files/usr/share/nvim|/data/data/com.android.shell/usr/share/nvim
htop|dir|/data/data/com.termux/files/usr/share/terminfo|/data/data/com.android.shell/home/.terminfo
nano|dir|/data/data/com.termux/files/usr/share/terminfo|/data/data/com.android.shell/home/.terminfo
EOF
)

### ARG CHECK ###
if [ -z "$1" ]; then
    echo "Usage: $0 <program>"
    exit 1
fi

PROG="$1"

mkdir -p "$BIN_STAGE" "$LIB_STAGE" "$EXTRA_STAGE"

### RESOLVE BINARY ###
BIN_PATH="$(command -v "$PROG" || true)"
if [ -z "$BIN_PATH" ]; then
    echo "Program not found: $PROG"
    exit 1
fi

REAL_BIN="$(realpath "$BIN_PATH")"
echo "[*] Executable: $REAL_BIN"

cp -v "$REAL_BIN" "$BIN_STAGE/"

### LIBRARY RESOLUTION (ldd) ###
echo "[*] Resolving shared libraries..."

ldd "$REAL_BIN" 2>/dev/null \
| awk '/=>/ {print $3}' \
| while read -r LIB; do
    case "$LIB" in
        /system/*|/apex/*)
            echo "  [-] system lib: $LIB"
            ;;
        *)
            echo "  [+] $LIB"
            cp -v "$LIB" "$LIB_STAGE/" 2>/dev/null || true
            ;;
    esac
done

### PROCESS EXTRAS ###
echo "[*] Processing extras..."

echo "$EXTRAS_DB" | while IFS='|' read -r NAME TYPE SRC DST; do
    [ "$NAME" = "$PROG" ] || continue

    echo "  [+] Extra: $TYPE $SRC → $DST"

    mkdir -p "$EXTRA_STAGE$(dirname "$DST")"

    if [ "$TYPE" = "dir" ]; then
        cp -a "$SRC" "$EXTRA_STAGE$DST"
    elif [ "$TYPE" = "file" ]; then
        cp -a "$SRC" "$EXTRA_STAGE$DST"
    fi
done

### STAGE rc.sh (only stage, never auto-install silently) ###
if [ ! -f "$RC_STAGE" ]; then
    cat > "$RC_STAGE" <<'EOF'
#!/system/bin/sh
export HOME=/data/data/com.android.shell/home
export PATH=/data/data/com.android.shell/usr/bin:/system/bin:/system/xbin
export LD_LIBRARY_PATH=/data/data/com.android.shell/usr/lib
export TERM=xterm-256color
export TMPDIR=/data/data/com.android.shell/tmp
mkdir -p "$HOME" "$TMPDIR"
alias ls="ls --color=auto"
exec fish
EOF
    chmod 755 "$RC_STAGE"
fi

### INSTALL INTO SHELL ###
echo "[*] Installing into shell environment..."

rish -c "
mkdir -p $SHELL_PREFIX/bin $SHELL_PREFIX/lib $SHELL_HOME

cp -v $BIN_STAGE/* $SHELL_PREFIX/bin/ 2>/dev/null || true
cp -v $LIB_STAGE/* $SHELL_PREFIX/lib/ 2>/dev/null || true

# Fix executable permissions (sdcard strips them)
chmod 755 $SHELL_PREFIX/bin/* 2>/dev/null || true

# Extras (full paths preserved)
if [ -d $EXTRA_STAGE ]; then
    cp -a $EXTRA_STAGE/* / 2>/dev/null || true
fi

# rc.sh installed only if missing
if [ ! -f $RC_DST ]; then
    mkdir -p $(dirname $RC_DST)
    cp $RC_STAGE $RC_DST
    chmod 755 $RC_DST
fi
"

rm -rf $STAGE

echo "[*] Done."

