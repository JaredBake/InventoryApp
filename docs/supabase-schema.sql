-- Supabase/Postgres starter schema for a user-scoped inventory app.
-- Adjust table names as needed if you use a different backend.

create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.items (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  barcode text not null,
  name text not null,
  brand text not null default '',
  category text not null default '',
  description text not null default '',
  quantity integer not null default 0,
  price numeric(12,2) not null default 0,
  date_added timestamptz not null default now()
);

create index if not exists idx_items_user_id on public.items(user_id);
create index if not exists idx_items_barcode on public.items(user_id, barcode);
create index if not exists idx_items_name on public.items(user_id, name);
create index if not exists idx_items_brand on public.items(user_id, brand);

create table if not exists public.custom_lists (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  description text not null default ''
);

create index if not exists idx_custom_lists_user_id on public.custom_lists(user_id);

create table if not exists public.list_rules (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  list_id uuid not null references public.custom_lists(id) on delete cascade,
  match_type integer not null,
  value text not null
);

create index if not exists idx_list_rules_user_id on public.list_rules(user_id);
create index if not exists idx_list_rules_list_id on public.list_rules(list_id);

create table if not exists public.list_items (
  user_id uuid not null references auth.users(id) on delete cascade,
  list_id uuid not null references public.custom_lists(id) on delete cascade,
  item_id uuid not null references public.items(id) on delete cascade,
  primary key (list_id, item_id)
);

create index if not exists idx_list_items_user_id on public.list_items(user_id);

create table if not exists public.catalog_items (
  id uuid primary key,
  brand text not null default '',
  name text not null,
  barcode text not null default '',
  category text not null default '',
  source text not null default 'catalog',
  created_at timestamptz not null default now()
);

create index if not exists idx_catalog_items_name on public.catalog_items(lower(name));
create index if not exists idx_catalog_items_brand on public.catalog_items(lower(brand));
create index if not exists idx_catalog_items_barcode on public.catalog_items(barcode);

create table if not exists public.receipt_scans (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  receipt_text text not null,
  extracted_price numeric(12,2),
  extracted_name text,
  extracted_brand text,
  created_at timestamptz not null default now()
);

create index if not exists idx_receipt_scans_user_id on public.receipt_scans(user_id);

-- Enable RLS after table creation.
alter table public.profiles enable row level security;
alter table public.items enable row level security;
alter table public.custom_lists enable row level security;
alter table public.list_rules enable row level security;
alter table public.list_items enable row level security;
alter table public.catalog_items enable row level security;
alter table public.receipt_scans enable row level security;

-- Example policies.
create policy "profiles are owned by the signed-in user"
  on public.profiles for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "items are owned by the signed-in user"
  on public.items for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "custom lists are owned by the signed-in user"
  on public.custom_lists for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "list rules are owned by the signed-in user"
  on public.list_rules for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "list items are owned by the signed-in user"
  on public.list_items for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "catalog items are readable by signed-in users"
  on public.catalog_items for select
  using (auth.uid() is not null);

create policy "receipt scans are owned by the signed-in user"
  on public.receipt_scans for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
