# imported from: https://github.com/hyperlane-xyz/hyperlane-monorepo/blob/e91c3100c29d2913d175df4b3d1790d6a057d36e/solidity/coverage.sh

set -e # exit on error

# generates lcov.info
forge coverage --report lcov

# generates coverage/lcov.info
yarn hardhat coverage

# Foundry uses relative paths but Hardhat uses absolute paths.
# Convert absolute paths to relative paths for consistency.
sed -i -e 's/\/.*solidity.//g' coverage/lcov.info

# Merge lcov files
lcov \
    --rc lcov_branch_coverage=1 \
    --add-tracefile coverage/lcov.info \
    --add-tracefile lcov.info \
    --output-file merged-lcov.info

# Filter out node_modules, test, and mock files
lcov \
    --rc lcov_branch_coverage=1 \
    --remove merged-lcov.info \
    --output-file filtered-lcov.info \
    "*node_modules*" "*test*" "*mock*" "*simulation*" "*lib*"

# Generate summary
lcov \
    --rc lcov_branch_coverage=1 \
    --list filtered-lcov.info

# Open more granular breakdown in browser
if [ "$CI" != "true" ]
then
    genhtml \
        --rc genhtml_branch_coverage=1 \
        --output-directory coverage \
        filtered-lcov.info
    open coverage/index.html
fi
