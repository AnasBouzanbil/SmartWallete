# Smart Wallet - Flutter personal finance app

## Constraints
- Flutter, Android first. No backend, no server. Everything is stored locally on the phone.
- Keep code simple and readable. Feature-based folders (lib/features/...).
- State management: Riverpod. Database: Drift (SQLite). Charts: fl_chart.
- Security: password stored as salted hash in flutter_secure_storage. Fingerprint via local_auth.
- Images are copied into the app documents folder; the database stores only the file path.

## Features
1. First launch setup: user name, password, total starting income.
2. Login each time: password or fingerprint.
3. Transactions: income/expense with amount, to whom, why (note), category, date, optional image.
4. Debts (separate table, NOT mixed with transactions): person, amount, direction (I lent / I owe), due date, note, settled yes/no. Local notification reminder on the due date.
5. Statistics: spending by category, by person, by month.
6. Backup: export/import all data as a JSON file.
7. AI advice (later): Gemini API, send only aggregated totals, never names or images. App must work fully if Gemini fails.

## Rules
- Work on ONE task at a time, only what I ask.
- After each task, tell me how to run and test it.
- Do not add packages without telling me why.
