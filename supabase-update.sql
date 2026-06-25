-- Einmalig in Supabase > SQL Editor ausführen.

alter table public.players
add column if not exists active boolean not null default true;

alter table public.players
add column if not exists form numeric not null default 0;

-- Falls Realtime schon aktiviert ist, können diese Zeilen einen Hinweis werfen.
-- Das ist nicht schlimm.
do $$
begin
  begin
    alter publication supabase_realtime add table public.players;
  exception when duplicate_object then null;
  end;

  begin
    alter publication supabase_realtime add table public.matches;
  exception when duplicate_object then null;
  end;

  begin
    alter publication supabase_realtime add table public.settings;
  exception when duplicate_object then null;
  end;
end $$;
