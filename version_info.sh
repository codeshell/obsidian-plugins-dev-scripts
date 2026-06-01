#!/bin/bash

NEW_VERSION=${1:-not provided}
MINIMUM_OBSIDIAN_VERSION=${2:-not provided}

# present the current values of package.json, manifest.json and versions.json to the user and compare them with the new values that will be set by the release script. This is to help the user verify that the new version and minimum obsidian version are correct before running the release script.
# present it in a way that is easy to compare the old and new values, for example by printing them side by side or in a table format.

PACKAGE_JSON="package.json"
MANIFEST_JSON="manifest.json"
VERSIONS_JSON="versions.json"
PACKAGE_LOCK_JSON="package-lock.json"
PARSE_ERROR_MSG="File not found or invalid JSON"

CURRENT_PACKAGE_VERSION=$(node -e "const fs=require('fs'); const p='${PACKAGE_JSON}'; try { const j=JSON.parse(fs.readFileSync(p,'utf8')); console.log(j.version); } catch (e) { console.log('${PARSE_ERROR_MSG}'); }")
CURRENT_MANIFEST_VERSION=$(node -e "const fs=require('fs'); const p='${MANIFEST_JSON}'; try { const j=JSON.parse(fs.readFileSync(p,'utf8')); console.log(j.version); } catch (e) { console.log('${PARSE_ERROR_MSG}'); }")
CURRENT_MANIFEST_MIN_APP_VERSION=$(node -e "const fs=require('fs'); const p='${MANIFEST_JSON}'; try { const j=JSON.parse(fs.readFileSync(p,'utf8')); console.log(j.minAppVersion); } catch (e) { console.log('${PARSE_ERROR_MSG}'); }")
CURRENT_VERSIONS_JSON_FIRST_VERSION=$(node -e "const fs=require('fs'); const p='${VERSIONS_JSON}'; try { const j=JSON.parse(fs.readFileSync(p,'utf8')); console.log(Object.keys(j)[0]); } catch (e) { console.log('${PARSE_ERROR_MSG}'); }")
CURRENT_VERSIONS_JSON_FIRST_MIN_APP_VERSION=$(node -e "const fs=require('fs'); const p='${VERSIONS_JSON}'; try { const j=JSON.parse(fs.readFileSync(p,'utf8')); console.log(Object.values(j)[0]); } catch (e) { console.log('${PARSE_ERROR_MSG}'); }")
CURRENT_PACKAGE_LOCK_VERSION=$(node -e "const fs=require('fs'); const p='${PACKAGE_LOCK_JSON}'; try { const j=JSON.parse(fs.readFileSync(p,'utf8')); console.log(j.version); } catch (e) { console.log('${PARSE_ERROR_MSG}'); }")


TABLE_OUTPUT="| File | Current Version | New Version | Current Min Obsidian Version | New Min Obsidian Version |
| --- | --- | --- | --- | --- |
| ${PACKAGE_JSON} | ${CURRENT_PACKAGE_VERSION} | ${NEW_VERSION} | N/A | N/A |
| ${MANIFEST_JSON} | ${CURRENT_MANIFEST_VERSION} | ${NEW_VERSION} | ${CURRENT_MANIFEST_MIN_APP_VERSION} | ${MINIMUM_OBSIDIAN_VERSION} |
| ${VERSIONS_JSON} | ${CURRENT_VERSIONS_JSON_FIRST_VERSION} | ${NEW_VERSION} | ${CURRENT_VERSIONS_JSON_FIRST_MIN_APP_VERSION} | ${MINIMUM_OBSIDIAN_VERSION} |
| ${PACKAGE_LOCK_JSON} | ${CURRENT_PACKAGE_LOCK_VERSION} | generated | N/A | N/A |
"


if command -v column >/dev/null 2>&1; then
    # normalize the table output by removing extra spaces around pipe delimiters,
    # then format it with column and strip any trailing whitespace from the result.
	echo "$TABLE_OUTPUT" | sed 's/ *| */|/g' | column -t -s '|' -o ' | ' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
elif [ -f "$(dirname "$0")/format_table.sh" ]; then
    # if format_table.sh exists in the same directory as test.sh, use it to format the table output. This is a custom script that formats the table output in a readable way, and it is used as a fallback if the column command is not available on the system.
    # invoke with explicit bash so executable bit isn't required and
    bash "$(dirname "$0")/format_table.sh" "$TABLE_OUTPUT"
else
	"$TABLE_OUTPUT"
fi
