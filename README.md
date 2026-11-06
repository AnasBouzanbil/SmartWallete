# Pocket

<p align="left">
  <img src="assets/brand/app_logo.png" alt="Pocket logo" width="72" height="72" />
</p>

Your money, on your phone — nothing leaves the device.

Pocket is a simple personal finance app for tracking income, expenses, and debts. No account. No cloud. Just you.

## Demo

<video src="docs/pocket-demo.mp4" controls width="280" playsinline>
  Your browser can’t play this video here — open
  <a href="docs/pocket-demo.mp4">docs/pocket-demo.mp4</a> instead.
</video>

[Watch the demo video](docs/pocket-demo.mp4) · ~36 seconds

## What you can do

- **Home** — balance, this month’s income/spent, quick add
- **Transactions** — income & expenses with category, person, note, optional receipt
- **Debts** — money you owe or lent, payments, due-date reminders
- **Stats** — spending by category / person / month
- **AI tips** — short spending advice from totals only (optional; needs a Gemini key)
- **Backup** — export / import everything as a JSON file
- **Security** — password + optional fingerprint / Face ID

## Run it

```bash
flutter pub get
flutter run
```

Works best on a phone or Android emulator.

### Optional: AI advice

1. Copy `.env.example` → `.env`
2. Add your key: `GEMINI_API_KEY=...`
3. Restart the app (full stop, not hot reload)

Pocket still works fully if the key is missing or the network fails.

## Privacy

All data stays on the device (SQLite + secure storage).  
AI tips send **aggregated totals only** — never names, notes, or receipt images.

## Stack

Flutter · Riverpod · Drift (SQLite) · local notifications · Gemini (optional)

---

Made for everyday use. Keep it in your pocket.
