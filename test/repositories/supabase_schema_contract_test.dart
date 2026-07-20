import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Supabase schema contract', () {
    late String schema;

    setUpAll(() {
      final file = File('docs/supabase-schema.sql');
      schema = file.readAsStringSync();
    });

    test('contains required items table definition', () {
      expect(schema, contains('create table if not exists public.items'));
      expect(schema, contains('id uuid primary key'));
      expect(schema, contains('user_id uuid not null references auth.users(id) on delete cascade'));
      expect(schema, contains('barcode text not null'));
      expect(schema, contains('name text not null'));
      expect(schema, contains('category text not null default \'\''));
      expect(schema, contains('description text not null default \'\''));
      expect(schema, contains('quantity integer not null default 0'));
      expect(schema, contains('price numeric(12,2) not null default 0'));
      expect(schema, contains('date_added timestamptz not null default now()'));
    });

    test('contains user-scoped RLS policy for items', () {
      expect(schema, contains('alter table public.items enable row level security;'));
      expect(schema, contains('create policy "items are owned by the signed-in user"'));
      expect(schema, contains('using (auth.uid() = user_id)'));
      expect(schema, contains('with check (auth.uid() = user_id);'));
    });
  });
}