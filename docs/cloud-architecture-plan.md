# Cloud Auth and Sync Plan

This app currently uses local SQLite for inventory data. To support email/password sign-in, session tokens, and account-scoped data, the app should move to a backend-first architecture with a clean separation between authentication, sync, and UI.

## Recommended backend shape

- Auth: Supabase Auth or an equivalent email/password provider
- Database: PostgreSQL-backed SQL tables
- Session handling: short-lived access token plus refresh token
- Data ownership: every record is scoped to a `user_id`

## Why this fits the app

- Keeps the UI independent from the storage backend
- Preserves loose coupling and high cohesion
- Makes future features easier to add:
  - shared lists
  - cloud sync
  - receipt price lookup
  - item catalog search
  - trip/planning lists

## Core data groups

### Auth data
- Users sign in with email and password
- The backend verifies the credentials
- The app stores only the session token locally
- When the token expires, the app refreshes it or asks the user to sign in again

### Inventory data
- Items, lists, rules, and membership are stored in SQL tables
- All tables include `user_id`
- The app only loads the current signed-in user’s records

### Catalog data
- A separate searchable item catalog stores canonical item names and brand names
- The catalog is used to reduce manual typing when adding items
- Manual items should map to the same shape as catalog items

### Receipt data
- Receipt scans can populate price fields when supported
- Receipt parsing should be isolated from item storage

## Suggested table families

- `users` or auth-managed users table
- `sessions` or refresh-token/session tracking if needed
- `items`
- `custom_lists`
- `list_rules`
- `list_items`
- `catalog_items`
- `receipt_scans`

## Design rules

- Keep auth in a dedicated service
- Keep sync logic in a dedicated repository/service
- Keep UI screens unaware of SQL details
- Keep item and list models independent from transport/auth details
- Use interfaces so the backend can be swapped later if needed

## Next implementation slice

1. Add auth and session models.
2. Define repository interfaces for user-scoped inventory and lists.
3. Add a catalog lookup service for search-as-you-type item selection.
4. Add a receipt-price input path that can prefill an item form.
