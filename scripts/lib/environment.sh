#!/bin/sh

# Resolves a full Xcode installation without changing the machine-wide xcode-select setting.
resolve_xcode_developer_dir() {
    if [ -n "${DEVELOPER_DIR:-}" ] && [ -d "$DEVELOPER_DIR/Platforms/iPhoneSimulator.platform" ]; then
        return
    fi

    selected_developer_dir=$(xcode-select -p 2>/dev/null || true)
    if [ -n "$selected_developer_dir" ] && [ -d "$selected_developer_dir/Platforms/iPhoneSimulator.platform" ]; then
        DEVELOPER_DIR=$selected_developer_dir
        export DEVELOPER_DIR
        return
    fi

    for xcode_app in /Applications/Xcode.app /Applications/Xcode-beta.app; do
        candidate_developer_dir="$xcode_app/Contents/Developer"
        if [ -d "$candidate_developer_dir/Platforms/iPhoneSimulator.platform" ]; then
            DEVELOPER_DIR=$candidate_developer_dir
            export DEVELOPER_DIR
            return
        fi
    done

    echo "A full Xcode installation with iOS Simulator support is unavailable." >&2
    echo "Set DEVELOPER_DIR or install Xcode in /Applications." >&2
    exit 69
}

# Runs the Tuist version pinned by mise.toml. TUIST_BIN remains an explicit CI override.
run_tuist() {
    if [ -n "${TUIST_BIN:-}" ]; then
        if [ ! -x "$TUIST_BIN" ]; then
            echo "TUIST_BIN is not executable: $TUIST_BIN" >&2
            exit 69
        fi
        "$TUIST_BIN" "$@"
        return
    fi

    if ! command -v mise >/dev/null 2>&1; then
        echo "mise is unavailable; install mise and run 'mise install'." >&2
        exit 69
    fi

    if ! mise which tuist >/dev/null 2>&1; then
        echo "The Tuist version pinned in mise.toml is not installed; run 'mise install'." >&2
        exit 69
    fi

    mise exec -- tuist "$@"
}
