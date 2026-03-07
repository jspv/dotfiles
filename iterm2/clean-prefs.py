#!/usr/bin/env python3
"""Git clean filter for iTerm2 preferences plist.

Strips noise keys (UI state, internal state, profiles) so only
intentional preferences are committed. Used via .gitattributes:

    com.googlecode.iterm2.plist filter=iterm2-clean

Reads plist from stdin, writes cleaned JSON to stdout (for readable diffs).
The smudge filter converts back to XML plist for iTerm2.
"""

import json
import plistlib
import sys

NOISE_PREFIXES = (
    "NSWindow Frame ",
    "NSNav",
    "NSSplit",
    "NSTable",
    "NSToolbar",
    "NSQuoted",
    "NSRepeat",
    "NSScroll",
    "NoSync",
    "kCPK",
)

NOISE_KEYS = {
    "LoadPrefsFromCustomFolder",
    "PMPrintingExpandedStateForPrint2",
    "PrefsCustomFolder",
    "SUFeedURL",
    "SUHasLaunchedBefore",
    "SULastCheckTime",
    "SUUpdateRelaunchingMarker",
    "findMode_iTerm",
    "iTerm Version",
}


def is_noise(key):
    if key in NOISE_KEYS:
        return True
    for prefix in NOISE_PREFIXES:
        if key.startswith(prefix):
            return True
    return False


def main():
    raw = sys.stdin.buffer.read()

    # Try plist first (XML or binary), fall back to JSON
    data = None
    try:
        data = plistlib.loads(raw)
    except Exception:
        pass

    if data is None:
        try:
            data = json.loads(raw)
        except Exception:
            # Can't parse — pass through unchanged
            sys.stdout.buffer.write(raw)
            return

    cleaned = {k: v for k, v in data.items() if not is_noise(k)}
    json.dump(cleaned, sys.stdout, indent=2, sort_keys=True, ensure_ascii=False, default=str)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
