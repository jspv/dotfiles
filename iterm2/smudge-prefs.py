#!/usr/bin/env python3
"""Git smudge filter for iTerm2 preferences plist.

Converts the cleaned JSON (stored in git) back to XML plist format
that iTerm2 can read via NSDictionary dictionaryWithContentsOfFile:.

Used via .gitattributes:

    com.googlecode.iterm2.plist filter=iterm2-clean
"""

import json
import plistlib
import sys


def main():
    raw = sys.stdin.buffer.read()

    # Try JSON first (that's what the clean filter outputs)
    data = None
    try:
        data = json.loads(raw)
    except Exception:
        pass

    if data is None:
        # Already a plist, pass through
        sys.stdout.buffer.write(raw)
        return

    sys.stdout.buffer.write(plistlib.dumps(data, fmt=plistlib.FMT_XML, sort_keys=True))


if __name__ == "__main__":
    main()
