#!/usr/bin/env bash
# Dumps a Drift schema snapshot for the current database version.
# Usage: tool/gen_schema_snapshot.sh <output-dir>
set -euo pipefail
cd "$(dirname "$0")/../packages/vault_persistence"
dart run drift_dev schema dump lib/src/database/app_database.dart drift_schemas/ "$@"
