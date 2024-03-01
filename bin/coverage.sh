#!/bin/bash

set -e

forge coverage --report lcov

# Exclude coverage
# Forge doesn't support libraries yet: https://github.com/foundry-rs/foundry/issues/2567
lcov \
    --ignore-errors unused,unused \
    --rc branch_coverage=1 \
    --remove lcov.info \
    --output-file lcov.info \
    "node_modules/*" "script/*" "test/*" "src/libraries/*"

# Generate summary
lcov \
    --rc branch_coverage=1 \
    --list lcov.info

# Generate HTML report
if [ "$FOUNDRY_PROFILE" != "ci" ]; then
  genhtml \
    --rc branch_coverage=1 \
    --output-directory coverage \
    lcov.info

  echo "Coverage report generated at coverage/index.html"
fi
