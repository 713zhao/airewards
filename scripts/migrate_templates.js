#!/usr/bin/env node
// One-off admin migration script to normalize template recurrence fields in Firestore.
// Usage:
//   Set GOOGLE_APPLICATION_CREDENTIALS to your service account JSON, then:
//     node scripts/migrate_templates.js --dry-run
//     node scripts/migrate_templates.js         # actually applies changes

const admin = require('firebase-admin');

if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
  console.error('ERROR: Set GOOGLE_APPLICATION_CREDENTIALS to your service account JSON file before running.');
  console.error('Example (powershell): $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\\path\\to\\serviceAccount.json"; node scripts/migrate_templates.js --dry-run');
  process.exit(1);
}

admin.initializeApp();
const db = admin.firestore();

const args = process.argv.slice(2);
const dryRun = args.includes('--dry-run') || args.includes('-d');
const prune = args.includes('--prune') || args.includes('-p');

(async function main() {
  console.log('Starting migration (normalize template recurrence fields)');
  console.log(`Dry run: ${dryRun}`);

  try {
    // Query tasks that contain a recurrence object. Firestore does not have a simple "exists" operator,
    // but `where('recurrence', '!=', null)` will return docs where field is present and not null.
    const q = db.collection('tasks').where('recurrence', '!=', null);
    const snapshot = await q.get();
    console.log(`Found ${snapshot.size} task documents with a 'recurrence' field.`);

    let toUpdate = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      // Determine if we need to set isRecurring to true, or populate recurrencePattern from recurrence
      const needsIsRecurring = data.isRecurring !== true;
      const needsRecurrencePattern = !data.recurrencePattern && !!data.recurrence;

      if (needsIsRecurring || needsRecurrencePattern) {
        const updates = {};
        if (needsIsRecurring) updates.isRecurring = true;
        if (needsRecurrencePattern) updates.recurrencePattern = data.recurrence;
        toUpdate.push({ id: doc.id, updates });
      }
    });

    console.log(`Documents to update: ${toUpdate.length}`);
    for (let i = 0; i < toUpdate.length; i++) {
      const { id, updates } = toUpdate[i];
      console.log(`[${i+1}/${toUpdate.length}] ${id} ->`, updates);
      if (!dryRun) {
        // Apply the updates
        await db.collection('tasks').doc(id).update(updates);
        // If requested, prune the old `recurrence` field
        if (prune) {
          console.log(`    -> pruning 'recurrence' field from ${id}`);
          await db.collection('tasks').doc(id).update({ recurrence: admin.firestore.FieldValue.delete() });
        }
      }
    }

    console.log('Migration finished.');
    if (dryRun) console.log('Dry run: no changes were written. Re-run without --dry-run to apply.');
    console.log(`Updated ${dryRun ? 0 : toUpdate.length} documents (dryRun=${dryRun}).`);
  } catch (err) {
    console.error('Migration failed:', err);
    process.exit(2);
  }
})();
