# Sales CRM

Sales CRM is a Flutter application for managing leads, customers, opportunities, activities, products, reports, and team access. It uses Supabase for authentication and database services.

## Features

- Email and password authentication
- Lead and customer management
- Sales pipeline with Kanban board
- Activities and follow-ups
- Product and service catalog
- Dashboard and business reports
- In-app notifications
- Role-based user management

## Tech Stack

- Flutter & Dart
- Provider
- Supabase
- fl_chart
- CSV export

## Getting Started

1. Clone the repository.
2. Create a Supabase project and apply the CRM database schema, including roles, Row Level Security policies, views, and functions.
3. Add your Supabase URL and publishable key in `lib/core/constants.dart`.
4. Install dependencies:

```bash
flutter pub get
```

5. Run the app:

```bash
flutter run
```

## Project Structure

```text
lib/
assets/
```

## Supabase Setup

Configure your project values in:

```text
lib/core/constants.dart
```

Then run the CRM SQL schema in the Supabase SQL Editor before using the app.

## Security

- Supabase Authentication
- Row Level Security (RLS)
- Role-based access for admins, sales managers, and sales representatives
- Server-side database functions for sensitive actions

## License

This project is for educational and personal use.
