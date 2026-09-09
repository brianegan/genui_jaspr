#!/usr/bin/env sh
# The package's coverage bar, run the same way CI does.
#
# `very_good dart test`'s own coverage check does not honor `coverage:ignore`
# comments in this package (see tool/check_coverage.dart), so this calls
# `format_coverage --check-ignore` directly instead, the way
# example/tool/coverage.sh already does for its own bar.
set -e
cd "$(dirname "$0")/.."
rm -rf coverage
dart test --coverage=coverage
dart run coverage:format_coverage --lcov --in=coverage \
  --out=coverage/lcov.info --report-on=lib --check-ignore
dart tool/check_coverage.dart coverage/lcov.info 100
