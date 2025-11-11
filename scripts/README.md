Migration scripts for one-off Firestore fixes

migrate_templates.js
- Purpose: Normalize template docs in the `tasks` collection so that templates which include a `recurrence` map are marked `isRecurring: true` and also have `recurrencePattern` set (a copy of `recurrence`).
- Usage:
  1. Obtain a Firebase service account JSON with appropriate Firestore admin permissions.
  2. In PowerShell (Windows):
    $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\\path\\to\\serviceAccount.json";
    node scripts/migrate_templates.js --dry-run

    If the output looks correct, run:
    node scripts/migrate_templates.js

  Optional: remove the old `recurrence` field after copying. Use the `--prune` (or `-p`) flag to delete `recurrence` from documents as a follow-up step:

    # dry-run preview, no writes
    node scripts/migrate_templates.js --dry-run

    # apply updates and remove legacy `recurrence` field
    node scripts/migrate_templates.js --prune

- Notes:
  - The script queries documents where `recurrence` != null. If your collection is very large, consider adding additional filters (such as `familyId` or `ownerType`), or run the script in batches.
  - This script is a one-off admin tool. Keep your service account JSON secure and delete or rotate it after use if necessary.
