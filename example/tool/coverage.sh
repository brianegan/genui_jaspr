#!/usr/bin/env sh
# The example's coverage bar, runnable anywhere Chrome is installed.
#
# The VM suite and the browser suite each reach code the other cannot: the
# server route only runs on the VM, and `chat.dart` only runs in a browser.
# So both runs collect coverage, format_coverage turns them into one lcov file
# (one record per platform), and merge_lcov.dart folds those records together
# and fails below 100%. CI and the local gate both call this script, so there
# is exactly one definition of the bar.
set -e
cd "$(dirname "$0")/.."
rm -rf coverage
dart test --coverage=coverage
dart test -p chrome --coverage=coverage test/browser
dart run coverage:format_coverage --lcov --in=coverage \
  --out=coverage/lcov.info --report-on=lib --check-ignore
dart tool/merge_lcov.dart coverage/lcov.info coverage/merged.info 100
