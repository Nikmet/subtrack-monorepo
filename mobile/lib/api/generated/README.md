# Generated API Layer

Files in this folder are treated as generated artifacts for the mobile client.

Source of truth:
- `mobile/openapi/openapi.json`

Regeneration workflow:
1. Update snapshot:
   - `pwsh ./tool/sync_openapi.ps1`
2. Validate snapshot:
   - `dart run tool/generate_openapi_client.dart`
3. Refresh generated client files in this directory.

Do not edit generated files manually unless updating the generation workflow.
