


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE OR REPLACE FUNCTION "public"."admin_add_profile_xp"("target_profile_id" "uuid", "add_xp" integer, "add_stat_points" integer DEFAULT 0) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if not public.is_admin() then
    raise exception 'Not allowed';
  end if;

  if add_xp < 0 or add_stat_points < 0 then
    raise exception 'Negative values are not allowed';
  end if;

  update public.player_profiles
  set xp_total = xp_total + add_xp,
      level = public.level_from_xp(xp_total + add_xp),
      stat_points_total = stat_points_total + add_stat_points
  where id = target_profile_id;
end;
$$;


ALTER FUNCTION "public"."admin_add_profile_xp"("target_profile_id" "uuid", "add_xp" integer, "add_stat_points" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_delete_player_title"("p_id" integer) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if not public.is_admin() then
    raise exception 'Not allowed';
  end if;

  update public.player_profiles
  set selected_title_id = null
  where selected_title_id = p_id;

  delete from public.player_titles
  where id = p_id;
end;
$$;


ALTER FUNCTION "public"."admin_delete_player_title"("p_id" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_delete_special_attack"("p_id" integer) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if not public.is_admin() then
    raise exception 'Not allowed';
  end if;

  update public.player_profiles
  set selected_special_attack_id = null
  where selected_special_attack_id = p_id;

  delete from public.special_attacks
  where id = p_id;
end;
$$;


ALTER FUNCTION "public"."admin_delete_special_attack"("p_id" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_get_player_titles"() RETURNS TABLE("id" integer, "name" "text", "description" "text", "min_level" integer, "req_teamgeist" integer, "req_geschwindigkeit" integer, "req_kraft" integer, "req_technik" integer, "req_ehrgeiz" integer, "req_team_b_games" integer, "sort_order" integer, "active" boolean)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if not public.is_admin() then
    raise exception 'Not allowed';
  end if;

  return query
  select
    t.id,
    t.name,
    t.description,
    t.min_level,
    coalesce(t.req_teamgeist, 0),
    coalesce(t.req_geschwindigkeit, 0),
    coalesce(t.req_kraft, 0),
    coalesce(t.req_technik, 0),
    coalesce(t.req_ehrgeiz, 0),
    coalesce(t.req_team_b_games, 0),
    t.sort_order,
    t.active
  from public.player_titles t
  order by t.sort_order, t.min_level, t.name;
end;
$$;


ALTER FUNCTION "public"."admin_get_player_titles"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_get_special_attacks"() RETURNS TABLE("id" integer, "name" "text", "description" "text", "min_level" integer, "req_teamgeist" integer, "req_geschwindigkeit" integer, "req_kraft" integer, "req_technik" integer, "req_ehrgeiz" integer, "sort_order" integer, "active" boolean)
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if not public.is_admin() then
    raise exception 'Not allowed';
  end if;

  return query
  select
    s.id,
    s.name,
    s.description,
    s.min_level,
    coalesce(s.req_teamgeist, 0),
    coalesce(s.req_geschwindigkeit, 0),
    coalesce(s.req_kraft, 0),
    coalesce(s.req_technik, 0),
    coalesce(s.req_ehrgeiz, 0),
    s.sort_order,
    s.active
  from public.special_attacks s
  order by s.sort_order, s.min_level, s.name;
end;
$$;


ALTER FUNCTION "public"."admin_get_special_attacks"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_grant_stat_points"("target_player_id" "uuid", "points_to_add" integer) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if not public.is_admin() then
    raise exception 'Not allowed';
  end if;

  if coalesce(points_to_add, 0) <= 0 then
    raise exception 'Die Punktzahl muss größer als 0 sein';
  end if;

  update public.player_profiles
  set stat_points_total =
    coalesce(stat_points_total, 0) + points_to_add
  where player_id = target_player_id;

  if not found then
    raise exception 'Für diesen Spieler existiert kein Profil. Testpunkte können nur an registrierte Spieler vergeben werden.';
  end if;
end;
$$;


ALTER FUNCTION "public"."admin_grant_stat_points"("target_player_id" "uuid", "points_to_add" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_save_player_title"("p_id" integer, "p_name" "text", "p_description" "text", "p_min_level" integer, "p_req_teamgeist" integer, "p_req_geschwindigkeit" integer, "p_req_kraft" integer, "p_req_technik" integer, "p_req_ehrgeiz" integer, "p_req_team_b_games" integer, "p_sort_order" integer, "p_active" boolean) RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  saved_id integer;
begin
  if not public.is_admin() then
    raise exception 'Not allowed';
  end if;

  if coalesce(trim(p_name), '') = '' then
    raise exception 'Name fehlt';
  end if;

  if p_id is null then
    insert into public.player_titles (
      name,
      description,
      min_level,
      req_teamgeist,
      req_geschwindigkeit,
      req_kraft,
      req_technik,
      req_ehrgeiz,
      req_team_b_games,
      sort_order,
      active
    )
    values (
      trim(p_name),
      nullif(trim(coalesce(p_description, '')), ''),
      greatest(coalesce(p_min_level, 1), 1),
      greatest(coalesce(p_req_teamgeist, 0), 0),
      greatest(coalesce(p_req_geschwindigkeit, 0), 0),
      greatest(coalesce(p_req_kraft, 0), 0),
      greatest(coalesce(p_req_technik, 0), 0),
      greatest(coalesce(p_req_ehrgeiz, 0), 0),
      greatest(coalesce(p_req_team_b_games, 0), 0),
      coalesce(p_sort_order, 100),
      coalesce(p_active, true)
    )
    returning id into saved_id;

    return saved_id;
  end if;

  update public.player_titles
  set
    name = trim(p_name),
    description = nullif(trim(coalesce(p_description, '')), ''),
    min_level = greatest(coalesce(p_min_level, 1), 1),
    req_teamgeist = greatest(coalesce(p_req_teamgeist, 0), 0),
    req_geschwindigkeit = greatest(coalesce(p_req_geschwindigkeit, 0), 0),
    req_kraft = greatest(coalesce(p_req_kraft, 0), 0),
    req_technik = greatest(coalesce(p_req_technik, 0), 0),
    req_ehrgeiz = greatest(coalesce(p_req_ehrgeiz, 0), 0),
    req_team_b_games = greatest(coalesce(p_req_team_b_games, 0), 0),
    sort_order = coalesce(p_sort_order, 100),
    active = coalesce(p_active, true)
  where id = p_id;

  return p_id;
end;
$$;


ALTER FUNCTION "public"."admin_save_player_title"("p_id" integer, "p_name" "text", "p_description" "text", "p_min_level" integer, "p_req_teamgeist" integer, "p_req_geschwindigkeit" integer, "p_req_kraft" integer, "p_req_technik" integer, "p_req_ehrgeiz" integer, "p_req_team_b_games" integer, "p_sort_order" integer, "p_active" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."admin_save_special_attack"("p_id" integer, "p_name" "text", "p_description" "text", "p_min_level" integer, "p_req_teamgeist" integer, "p_req_geschwindigkeit" integer, "p_req_kraft" integer, "p_req_technik" integer, "p_req_ehrgeiz" integer, "p_sort_order" integer, "p_active" boolean) RETURNS integer
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare new_id integer;
begin
  if not public.is_admin() then
    raise exception 'Not allowed';
  end if;

  if coalesce(trim(p_name), '') = '' then
    raise exception 'Name fehlt';
  end if;

  if p_id is null then
    insert into public.special_attacks (
      name, description, min_level,
      req_teamgeist, req_geschwindigkeit, req_kraft, req_technik, req_ehrgeiz,
      sort_order, active
    )
    values (
      trim(p_name),
      nullif(trim(coalesce(p_description, '')), ''),
      greatest(coalesce(p_min_level, 1), 1),
      greatest(coalesce(p_req_teamgeist, 0), 0),
      greatest(coalesce(p_req_geschwindigkeit, 0), 0),
      greatest(coalesce(p_req_kraft, 0), 0),
      greatest(coalesce(p_req_technik, 0), 0),
      greatest(coalesce(p_req_ehrgeiz, 0), 0),
      coalesce(p_sort_order, 100),
      coalesce(p_active, true)
    )
    returning id into new_id;
    return new_id;
  end if;

  update public.special_attacks
  set
    name = trim(p_name),
    description = nullif(trim(coalesce(p_description, '')), ''),
    min_level = greatest(coalesce(p_min_level, 1), 1),
    req_teamgeist = greatest(coalesce(p_req_teamgeist, 0), 0),
    req_geschwindigkeit = greatest(coalesce(p_req_geschwindigkeit, 0), 0),
    req_kraft = greatest(coalesce(p_req_kraft, 0), 0),
    req_technik = greatest(coalesce(p_req_technik, 0), 0),
    req_ehrgeiz = greatest(coalesce(p_req_ehrgeiz, 0), 0),
    sort_order = coalesce(p_sort_order, 100),
    active = coalesce(p_active, true)
  where id = p_id;

  return p_id;
end;
$$;


ALTER FUNCTION "public"."admin_save_special_attack"("p_id" integer, "p_name" "text", "p_description" "text", "p_min_level" integer, "p_req_teamgeist" integer, "p_req_geschwindigkeit" integer, "p_req_kraft" integer, "p_req_technik" integer, "p_req_ehrgeiz" integer, "p_sort_order" integer, "p_active" boolean) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."allocate_my_stat_points"("add_teamgeist" integer DEFAULT 0, "add_geschwindigkeit" integer DEFAULT 0, "add_kraft" integer DEFAULT 0, "add_technik" integer DEFAULT 0, "add_ehrgeiz" integer DEFAULT 0) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  my_profile_id uuid;
  available_points integer;
  spend_points integer;
begin
  if add_teamgeist < 0
     or add_geschwindigkeit < 0
     or add_kraft < 0
     or add_technik < 0
     or add_ehrgeiz < 0 then
    raise exception 'Negative points are not allowed';
  end if;

  spend_points := add_teamgeist + add_geschwindigkeit + add_kraft + add_technik + add_ehrgeiz;

  select id, greatest(stat_points_total - stat_points_spent, 0)
  into my_profile_id, available_points
  from public.player_profiles
  where user_id = auth.uid();

  if my_profile_id is null then
    raise exception 'No profile found';
  end if;

  if spend_points > available_points then
    raise exception 'Not enough stat points';
  end if;

  update public.player_profiles
  set stat_teamgeist = stat_teamgeist + add_teamgeist,
      stat_geschwindigkeit = stat_geschwindigkeit + add_geschwindigkeit,
      stat_kraft = stat_kraft + add_kraft,
      stat_technik = stat_technik + add_technik,
      stat_ehrgeiz = stat_ehrgeiz + add_ehrgeiz,
      stat_points_spent = stat_points_spent + spend_points
  where id = my_profile_id;
end;
$$;


ALTER FUNCTION "public"."allocate_my_stat_points"("add_teamgeist" integer, "add_geschwindigkeit" integer, "add_kraft" integer, "add_technik" integer, "add_ehrgeiz" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."approve_player"("target_player_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'auth'
    AS $$
declare
  target_user_id uuid;
begin
  if not public.is_admin() then
    raise exception 'Not allowed';
  end if;

  select user_id
  into target_user_id
  from public.players
  where id = target_player_id;

  if not found then
    raise exception 'Spieler nicht gefunden';
  end if;

  update public.players
  set
    approved = true,
    active = true
  where id = target_player_id;

  -- Registrierung gleichzeitig als bestätigt markieren.
  -- email_confirmed_at ist beschreibbar; confirmed_at selbst ist generiert.
  if target_user_id is not null then
    update auth.users
    set
      email_confirmed_at = coalesce(email_confirmed_at, now()),
      updated_at = now()
    where id = target_user_id;
  end if;
end;
$$;


ALTER FUNCTION "public"."approve_player"("target_player_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."block_player"("target_player_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if not public.is_admin() then
    raise exception 'Not allowed';
  end if;

  update public.players
  set approved = false,
      active = false
  where id = target_player_id;
end;
$$;


ALTER FUNCTION "public"."block_player"("target_player_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."delete_match_with_points"("target_match_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if not public.is_admin() then
    raise exception 'Not allowed';
  end if;

  delete from public.matches
  where id = target_match_id;

  if not found then
    raise exception 'Spiel nicht gefunden';
  end if;

  perform public.refresh_profile_progress_from_ledger();
end;
$$;


ALTER FUNCTION "public"."delete_match_with_points"("target_match_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_my_available_special_attacks"() RETURNS TABLE("id" integer, "name" "text", "description" "text", "min_level" integer, "req_teamgeist" integer, "req_geschwindigkeit" integer, "req_kraft" integer, "req_technik" integer, "req_ehrgeiz" integer, "sort_order" integer, "unlocked" boolean)
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select
    sa.id,
    sa.name,
    sa.description,
    sa.min_level,
    coalesce(sa.req_teamgeist, 0),
    coalesce(sa.req_geschwindigkeit, 0),
    coalesce(sa.req_kraft, 0),
    coalesce(sa.req_technik, 0),
    coalesce(sa.req_ehrgeiz, 0),
    sa.sort_order,
    (
      public.level_from_xp(coalesce(pp.xp_total, 0)) >= sa.min_level
      and coalesce(pp.stat_teamgeist, 0) >= coalesce(sa.req_teamgeist, 0)
      and coalesce(pp.stat_geschwindigkeit, 0) >= coalesce(sa.req_geschwindigkeit, 0)
      and coalesce(pp.stat_kraft, 0) >= coalesce(sa.req_kraft, 0)
      and coalesce(pp.stat_technik, 0) >= coalesce(sa.req_technik, 0)
      and coalesce(pp.stat_ehrgeiz, 0) >= coalesce(sa.req_ehrgeiz, 0)
    ) as unlocked
  from public.player_profiles pp
  cross join public.special_attacks sa
  where pp.user_id = auth.uid()
    and sa.active = true
  order by sa.sort_order, sa.name;
$$;


ALTER FUNCTION "public"."get_my_available_special_attacks"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_my_sun_games_count"() RETURNS integer
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select public.get_player_sun_games_count(pp.player_id)
  from public.player_profiles pp
  where pp.user_id = auth.uid()
  limit 1;
$$;


ALTER FUNCTION "public"."get_my_sun_games_count"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_my_unlocked_titles"() RETURNS TABLE("id" integer, "name" "text", "description" "text", "min_level" integer, "req_teamgeist" integer, "req_geschwindigkeit" integer, "req_kraft" integer, "req_technik" integer, "req_ehrgeiz" integer, "req_team_b_games" integer, "current_team_b_games" integer, "sort_order" integer, "unlocked" boolean)
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select
    t.id,
    t.name,
    t.description,
    t.min_level,
    coalesce(t.req_teamgeist, 0),
    coalesce(t.req_geschwindigkeit, 0),
    coalesce(t.req_kraft, 0),
    coalesce(t.req_technik, 0),
    coalesce(t.req_ehrgeiz, 0),
    coalesce(t.req_team_b_games, 0),
    stats.team_b_games,
    t.sort_order,
    (
      public.level_from_xp(coalesce(pp.xp_total, 0)) >= t.min_level
      and coalesce(pp.stat_teamgeist, 0) >= coalesce(t.req_teamgeist, 0)
      and coalesce(pp.stat_geschwindigkeit, 0) >= coalesce(t.req_geschwindigkeit, 0)
      and coalesce(pp.stat_kraft, 0) >= coalesce(t.req_kraft, 0)
      and coalesce(pp.stat_technik, 0) >= coalesce(t.req_technik, 0)
      and coalesce(pp.stat_ehrgeiz, 0) >= coalesce(t.req_ehrgeiz, 0)
      and stats.team_b_games >= coalesce(t.req_team_b_games, 0)
    ) as unlocked
  from public.player_profiles pp
  cross join public.player_titles t
  cross join lateral (
    select count(*)::integer as team_b_games
    from public.matches m
    where m.score_a is not null
      and m.score_b is not null
      and jsonb_typeof(m.team_b) = 'array'
      and m.team_b @> jsonb_build_array(pp.player_id::text)
  ) stats
  where pp.user_id = auth.uid()
    and t.active = true
  order by t.sort_order, t.name;
$$;


ALTER FUNCTION "public"."get_my_unlocked_titles"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_player_cards"() RETURNS TABLE("profile_id" "uuid", "user_id" "uuid", "player_id" "uuid", "real_name" "text", "email" "text", "active" boolean, "approved" boolean, "xp_total" integer, "calculated_level" integer, "current_level_xp" integer, "next_level_xp" integer, "stat_points_total" integer, "stat_points_spent" integer, "stat_points_available" integer, "stat_teamgeist" integer, "stat_geschwindigkeit" integer, "stat_kraft" integer, "stat_technik" integer, "stat_ehrgeiz" integer, "selected_title_id" integer, "selected_title_name" "text", "selected_title_description" "text", "selected_special_attack_id" integer, "selected_special_attack_name" "text", "selected_special_attack_description" "text", "body_color" "text", "head_item" "text", "top_item" "text", "bottom_item" "text", "shorts_item" "text", "accessory_item" "text")
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select
    pp.id as profile_id,
    pp.user_id,
    pp.player_id,
    p.name as real_name,
    p.email,
    p.active,
    p.approved,

    coalesce(pp.xp_total, 0)::integer as xp_total,
    public.level_from_xp(coalesce(pp.xp_total, 0))::integer as calculated_level,
    public.total_xp_for_level(public.level_from_xp(coalesce(pp.xp_total, 0)))::integer as current_level_xp,
    public.total_xp_for_level(public.level_from_xp(coalesce(pp.xp_total, 0)) + 1)::integer as next_level_xp,

    coalesce(pp.stat_points_total, 0)::integer as stat_points_total,
    coalesce(pp.stat_points_spent, 0)::integer as stat_points_spent,
    greatest(coalesce(pp.stat_points_total, 0) - coalesce(pp.stat_points_spent, 0), 0)::integer as stat_points_available,

    coalesce(pp.stat_teamgeist, 0)::integer as stat_teamgeist,
    coalesce(pp.stat_geschwindigkeit, 0)::integer as stat_geschwindigkeit,
    coalesce(pp.stat_kraft, 0)::integer as stat_kraft,
    coalesce(pp.stat_technik, 0)::integer as stat_technik,
    coalesce(pp.stat_ehrgeiz, 0)::integer as stat_ehrgeiz,

    pp.selected_title_id,
    t.name as selected_title_name,
    t.description as selected_title_description,

    pp.selected_special_attack_id,
    sa.name as selected_special_attack_name,
    sa.description as selected_special_attack_description,

    coalesce(pp.body_color, pp.avatar_body, 'black') as body_color,
    coalesce(pp.head_item, 'none') as head_item,
    coalesce(pp.top_item, 'none') as top_item,
    coalesce(pp.bottom_item, pp.shorts_item, 'none') as bottom_item,
    coalesce(pp.shorts_item, pp.bottom_item, 'none') as shorts_item,
    coalesce(pp.accessory_item, 'none') as accessory_item
  from public.player_profiles pp
  join public.players p on p.id = pp.player_id
  left join public.player_titles t on t.id = pp.selected_title_id
  left join public.special_attacks sa on sa.id = pp.selected_special_attack_id;
$$;


ALTER FUNCTION "public"."get_player_cards"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_player_score_totals"() RETURNS TABLE("player_id" "uuid", "total_points" numeric, "games" integer, "wins" integer, "point_diff" integer, "pause_points" integer, "absence_points" integer, "previous_total_points" numeric, "previous_games" integer, "previous_wins" integer, "previous_point_diff" integer, "has_rank_history" boolean)
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  WITH latest_match AS (
    SELECT m.id
    FROM public.matches m
    WHERE m.score_a IS NOT NULL
      AND m.score_b IS NOT NULL
      AND m.mode <> 'tiebreak-2v2'
    ORDER BY m.created_at DESC, m.id DESC
    LIMIT 1
  ),

  adjustment_totals AS (
    SELECT
      player_id,
      COALESCE(SUM(points), 0)::numeric(10,2) AS points
    FROM public.player_point_adjustments
    GROUP BY player_id
  ),

  totals AS (
    SELECT
      p.id AS player_id,

      (
        COALESCE(SUM(a.points), 0)::numeric(10,2)
        + COALESCE(adj.points, 0)
      )::numeric(10,2) AS total_points,

      COALESCE(SUM(a.games), 0)::integer AS games,
      COALESCE(SUM(a.wins), 0)::integer AS wins,
      COALESCE(SUM(a.point_diff), 0)::integer AS point_diff,

      COALESCE(
        SUM(
          CASE
            WHEN a.award_type = 'bench' THEN a.points
            ELSE 0
          END
        ),
        0
      )::integer AS pause_points,

      COALESCE(
        SUM(
          CASE
            WHEN a.award_type = 'absent' THEN a.points
            ELSE 0
          END
        ),
        0
      )::integer AS absence_points,

      (
        COALESCE(
          SUM(a.points) FILTER (
            WHERE a.match_id IS DISTINCT FROM (
              SELECT id
              FROM latest_match
            )
          ),
          0
        )::numeric(10,2)
        + COALESCE(adj.points, 0)
      )::numeric(10,2) AS previous_total_points,

      COALESCE(
        SUM(a.games) FILTER (
          WHERE a.match_id IS DISTINCT FROM (
            SELECT id
            FROM latest_match
          )
        ),
        0
      )::integer AS previous_games,

      COALESCE(
        SUM(a.wins) FILTER (
          WHERE a.match_id IS DISTINCT FROM (
            SELECT id
            FROM latest_match
          )
        ),
        0
      )::integer AS previous_wins,

      COALESCE(
        SUM(a.point_diff) FILTER (
          WHERE a.match_id IS DISTINCT FROM (
            SELECT id
            FROM latest_match
          )
        ),
        0
      )::integer AS previous_point_diff,

      EXISTS(
        SELECT 1
        FROM latest_match
      ) AS has_rank_history

    FROM public.players p

    LEFT JOIN public.match_point_awards a
      ON a.player_id = p.id

    LEFT JOIN adjustment_totals adj
      ON adj.player_id = p.id

    GROUP BY
      p.id,
      adj.points
  )

  SELECT *
  FROM totals;
$$;


ALTER FUNCTION "public"."get_player_score_totals"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_player_sun_games_count"("target_player_id" "uuid") RETURNS integer
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select count(*)::integer
  from public.matches m
  where m.score_a is not null
    and m.score_b is not null
    and jsonb_typeof(m.team_b) = 'array'
    and m.team_b @> jsonb_build_array(target_player_id::text);
$$;


ALTER FUNCTION "public"."get_player_sun_games_count"("target_player_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_point_ledger_data"() RETURNS "jsonb"
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select jsonb_build_object(
    'awards', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'match_id', a.match_id,
            'player_id', a.player_id,
            'award_type', a.award_type,
            'points', a.points,
            'games', a.games,
            'wins', a.wins,
            'point_diff', a.point_diff
          )
        )
        from public.match_point_awards a
      ),
      '[]'::jsonb
    ),
    'adjustments', coalesce(
      (
        select jsonb_agg(
          jsonb_build_object(
            'player_id', pa.player_id,
            'points', pa.points
          )
        )
        from public.player_point_adjustments pa
      ),
      '[]'::jsonb
    )
  );
$$;


ALTER FUNCTION "public"."get_point_ledger_data"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_player_signup"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  new_player_id uuid;
  player_name text;
  player_aka text;
begin
  player_name := coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1));
  player_aka := coalesce(new.raw_user_meta_data->>'aka_name', '');

  insert into public.players (
    name,
    email,
    aka_name,
    user_id,
    approved,
    active
  )
  values (
    player_name,
    new.email,
    player_aka,
    new.id,
    false,
    false
  )
  on conflict (user_id) do update
  set email = excluded.email,
      name = excluded.name,
      aka_name = excluded.aka_name
  returning id into new_player_id;

  insert into public.player_profiles (
    user_id,
    player_id,
    display_name,
    avatar_body,
    avatar_belly,
    body_color,
    belly_color,
    head_item,
    shorts_item,
    accessory_item
  )
  values (
    new.id,
    new_player_id,
    player_name,
    'black',
    'white',
    'black',
    'white',
    'none',
    'none',
    'none'
  )
  on conflict (user_id) do update
  set player_id = excluded.player_id,
      display_name = coalesce(public.player_profiles.display_name, excluded.display_name);

  return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_player_signup"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_admin"() RETURNS boolean
    LANGUAGE "sql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1
    from public.admin_users
    where user_id = auth.uid()
  );
$$;


ALTER FUNCTION "public"."is_admin"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."is_title_unlocked"("profile_id" "uuid", "title_id" "text") RETURNS boolean
    LANGUAGE "sql" STABLE
    AS $$
  select exists (
    select 1
    from public.player_profiles pp
    join public.player_titles t on t.id = title_id
    where pp.id = profile_id
      and t.active = true
      and public.level_from_xp(pp.xp_total) >= t.min_level
      and pp.stat_teamgeist >= t.req_teamgeist
      and pp.stat_geschwindigkeit >= t.req_geschwindigkeit
      and pp.stat_kraft >= t.req_kraft
      and pp.stat_technik >= t.req_technik
      and pp.stat_ehrgeiz >= t.req_ehrgeiz
  );
$$;


ALTER FUNCTION "public"."is_title_unlocked"("profile_id" "uuid", "title_id" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."level_from_xp"("total_xp" integer) RETURNS integer
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
declare
  lvl integer := 1;
  needed integer := 0;
  next_needed integer;
begin
  if total_xp is null or total_xp <= 0 then
    return 1;
  end if;

  loop
    next_needed := needed + (lvl * 15) + 10;

    if total_xp < next_needed then
      return lvl;
    end if;

    needed := next_needed;
    lvl := lvl + 1;

    if lvl >= 99 then
      return 99;
    end if;
  end loop;
end;
$$;


ALTER FUNCTION "public"."level_from_xp"("total_xp" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."recompute_all_profile_progress"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  with earned as (
    select
      player_id,
      sum(points)::integer as earned_points
    from (
      select
        jsonb_array_elements_text(team_a)::uuid as player_id,
        score_a::integer as points
      from public.matches
      where score_a is not null
        and score_b is not null
        and jsonb_typeof(team_a) = 'array'

      union all

      select
        jsonb_array_elements_text(team_b)::uuid as player_id,
        score_b::integer as points
      from public.matches
      where score_a is not null
        and score_b is not null
        and jsonb_typeof(team_b) = 'array'

      union all

      select
        jsonb_array_elements_text(bench_players)::uuid as player_id,
        least(score_a::integer, score_b::integer) as points
      from public.matches
      where score_a is not null
        and score_b is not null
        and jsonb_typeof(bench_players) = 'array'

      union all

      select
        jsonb_array_elements_text(absent_players)::uuid as player_id,
        least(score_a::integer, score_b::integer) as points
      from public.matches
      where score_a is not null
        and score_b is not null
        and jsonb_typeof(absent_players) = 'array'
    ) all_points
    group by player_id
  )
  update public.player_profiles pp
  set
    xp_total = coalesce(e.earned_points, 0),
    level = public.level_from_xp(coalesce(e.earned_points, 0)),
    stat_points_total = greatest(
      coalesce(e.earned_points, 0),
      coalesce(pp.stat_points_spent, 0)
    )
  from public.players p
  left join earned e on e.player_id = p.id
  where pp.player_id = p.id;
end;
$$;


ALTER FUNCTION "public"."recompute_all_profile_progress"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."recompute_all_profile_progress_trigger"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  perform public.recompute_all_profile_progress();
  return null;
end;
$$;


ALTER FUNCTION "public"."recompute_all_profile_progress_trigger"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."refresh_profile_progress_from_ledger"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  with totals as (
    select
      p.id as player_id,
      coalesce(sum(a.points), 0)::integer
        + coalesce(adj.points, 0)::integer as total_points
    from public.players p
    left join public.match_point_awards a
      on a.player_id = p.id
    left join public.player_point_adjustments adj
      on adj.player_id = p.id
    group by p.id, adj.points
  )
  update public.player_profiles pp
  set
    xp_total = totals.total_points,
    level = public.level_from_xp(totals.total_points),
    stat_points_total = greatest(
      totals.total_points,
      coalesce(pp.stat_points_spent, 0)
    )
  from totals
  where pp.player_id = totals.player_id;
end;
$$;


ALTER FUNCTION "public"."refresh_profile_progress_from_ledger"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."rls_auto_enable"() RETURNS "event_trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'pg_catalog'
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$$;


ALTER FUNCTION "public"."rls_auto_enable"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."save_match_score"("target_match_id" "uuid", "new_score_a" integer, "new_score_b" integer) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
DECLARE
  current_match public.matches%rowtype;
  loser_points integer;
  tiebreak_winner_id uuid;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Not allowed';
  END IF;

  IF new_score_a IS NULL OR new_score_b IS NULL THEN
    RAISE EXCEPTION
      'Beide Ergebnisse müssen eingetragen werden';
  END IF;

  IF new_score_a < 0 OR new_score_b < 0 THEN
    RAISE EXCEPTION
      'Ergebnisse dürfen nicht negativ sein';
  END IF;

  SELECT *
  INTO current_match
  FROM public.matches
  WHERE id = target_match_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Spiel nicht gefunden';
  END IF;

  /*
   * Frühere Auswertung vollständig entfernen.
   * Dadurch funktionieren spätere Ergebniskorrekturen.
   */
  DELETE FROM public.match_point_awards
  WHERE match_id = target_match_id;

  DELETE FROM public.player_point_adjustments
  WHERE match_id = target_match_id;

  /*
   * Entscheidungsspiel:
   * - keine regulären Punkte
   * - keine Spiele/Siege
   * - keine Fan-/Abwesenheitspunkte
   * - nur +0,50 für den eigentlichen Duellsieger
   */
  IF current_match.mode = 'tiebreak-2v2' THEN
    IF new_score_a = new_score_b THEN
      RAISE EXCEPTION
        'Ein Entscheidungsspiel darf nicht unentschieden enden';
    END IF;

    IF
      current_match.tiebreak_player_a_id IS NULL OR
      current_match.tiebreak_player_b_id IS NULL
    THEN
      RAISE EXCEPTION
        'Beim Entscheidungsspiel fehlen die beiden Duellspieler';
    END IF;

    IF new_score_a > new_score_b THEN
      tiebreak_winner_id :=
        current_match.tiebreak_player_a_id;
    ELSE
      tiebreak_winner_id :=
        current_match.tiebreak_player_b_id;
    END IF;

    UPDATE public.matches
    SET
      score_a = new_score_a,
      score_b = new_score_b,
      points_processed = true
    WHERE id = target_match_id;

    INSERT INTO public.player_point_adjustments (
      player_id,
      points,
      reason,
      match_id
    )
    VALUES (
      tiebreak_winner_id,
      0.50,
      'Entscheidungsspiel',
      target_match_id
    );

    PERFORM public.refresh_profile_progress_from_ledger();

    RETURN;
  END IF;

  /*
   * Ab hier bleibt die bisherige Verarbeitung
   * für normale Spiele erhalten.
   */
  loser_points := LEAST(new_score_a, new_score_b);

  UPDATE public.matches
  SET
    score_a = new_score_a,
    score_b = new_score_b,
    points_processed = true
  WHERE id = target_match_id;

  INSERT INTO public.match_point_awards (
    match_id,
    player_id,
    award_type,
    points,
    games,
    wins,
    point_diff
  )
  SELECT
    target_match_id,
    player_id,
    award_type,
    points,
    games,
    wins,
    point_diff
  FROM (
    SELECT
      jsonb_array_elements_text(
        current_match.team_a
      )::uuid AS player_id,
      'team_a'::text AS award_type,
      new_score_a AS points,
      1 AS games,
      CASE
        WHEN new_score_a > new_score_b THEN 1
        ELSE 0
      END AS wins,
      new_score_a - new_score_b AS point_diff
    WHERE jsonb_typeof(current_match.team_a) = 'array'

    UNION ALL

    SELECT
      jsonb_array_elements_text(
        current_match.team_b
      )::uuid,
      'team_b'::text,
      new_score_b,
      1,
      CASE
        WHEN new_score_b > new_score_a THEN 1
        ELSE 0
      END,
      new_score_b - new_score_a
    WHERE jsonb_typeof(current_match.team_b) = 'array'

    UNION ALL

    SELECT
      jsonb_array_elements_text(
        current_match.bench_players
      )::uuid,
      'bench'::text,
      loser_points,
      0,
      0,
      0
    WHERE
      jsonb_typeof(current_match.bench_players) = 'array'

    UNION ALL

    SELECT
      jsonb_array_elements_text(
        current_match.absent_players
      )::uuid,
      'absent'::text,
      loser_points,
      0,
      0,
      0
    WHERE
      jsonb_typeof(current_match.absent_players) = 'array'
  ) awards
  ON CONFLICT (match_id, player_id)
  DO UPDATE SET
    award_type = EXCLUDED.award_type,
    points = EXCLUDED.points,
    games = EXCLUDED.games,
    wins = EXCLUDED.wins,
    point_diff = EXCLUDED.point_diff;

  PERFORM public.refresh_profile_progress_from_ledger();
END;
$$;


ALTER FUNCTION "public"."save_match_score"("target_match_id" "uuid", "new_score_a" integer, "new_score_b" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."total_xp_for_level"("target_level" integer) RETURNS integer
    LANGUAGE "plpgsql" IMMUTABLE
    AS $$
declare
  lvl integer := 1;
  needed integer := 0;
begin
  if target_level <= 1 then
    return 0;
  end if;

  while lvl < target_level loop
    needed := needed + (lvl * 15) + 10;
    lvl := lvl + 1;
  end loop;

  return needed;
end;
$$;


ALTER FUNCTION "public"."total_xp_for_level"("target_level" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_my_aka_name"("new_aka_name" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  caller_user_id uuid;
begin
  caller_user_id := auth.uid();

  if caller_user_id is null then
    raise exception 'Not authenticated';
  end if;

  update public.players
  set aka_name = new_aka_name
  where user_id = caller_user_id;
end;
$$;


ALTER FUNCTION "public"."update_my_aka_name"("new_aka_name" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_my_profile_choices"("new_title_id" integer, "new_special_attack_id" integer, "new_body_color" "text", "new_head_item" "text", "new_top_item" "text", "new_bottom_item" "text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  update public.player_profiles
  set
    selected_title_id = new_title_id,
    selected_special_attack_id = new_special_attack_id,
    body_color = coalesce(new_body_color, body_color),
    head_item = coalesce(new_head_item, head_item),
    top_item = coalesce(new_top_item, top_item),
    bottom_item = coalesce(new_bottom_item, bottom_item),
    shorts_item = coalesce(new_bottom_item, shorts_item)
  where user_id = auth.uid();
end;
$$;


ALTER FUNCTION "public"."update_my_profile_choices"("new_title_id" integer, "new_special_attack_id" integer, "new_body_color" "text", "new_head_item" "text", "new_top_item" "text", "new_bottom_item" "text") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."admin_users" (
    "user_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."admin_users" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text",
    "name" "text" NOT NULL,
    "description" "text",
    "icon" "text",
    "item_type" "text" DEFAULT 'equipment'::"text" NOT NULL,
    "strength_modifier" numeric DEFAULT 0 NOT NULL,
    "speed_modifier" numeric DEFAULT 0 NOT NULL,
    "technique_modifier" numeric DEFAULT 0 NOT NULL,
    "ambition_modifier" numeric DEFAULT 0 NOT NULL,
    "team_modifier" numeric DEFAULT 0 NOT NULL,
    "power_modifier" numeric DEFAULT 0 NOT NULL,
    "effect_code" "text",
    "effect_value" numeric DEFAULT 0 NOT NULL,
    "effect_target" "text" DEFAULT 'self'::"text" NOT NULL,
    "effect_scope" "text" DEFAULT 'permanent'::"text" NOT NULL,
    "duration_games" integer DEFAULT 0 NOT NULL,
    "max_uses" integer,
    "min_level" integer DEFAULT 1 NOT NULL,
    "req_teamgeist" integer DEFAULT 0 NOT NULL,
    "req_geschwindigkeit" integer DEFAULT 0 NOT NULL,
    "req_kraft" integer DEFAULT 0 NOT NULL,
    "req_technik" integer DEFAULT 0 NOT NULL,
    "req_ehrgeiz" integer DEFAULT 0 NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL,
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "items_duration_games_check" CHECK (("duration_games" >= 0)),
    CONSTRAINT "items_effect_scope_check" CHECK (("effect_scope" = ANY (ARRAY['permanent'::"text", 'next_match'::"text", 'active_duration'::"text", 'one_time'::"text"]))),
    CONSTRAINT "items_effect_target_check" CHECK (("effect_target" = ANY (ARRAY['self'::"text", 'own_team'::"text", 'opponent'::"text", 'opponent_team'::"text", 'all_players'::"text"]))),
    CONSTRAINT "items_item_type_check" CHECK (("item_type" = ANY (ARRAY['equipment'::"text", 'consumable'::"text", 'trophy'::"text", 'special'::"text"]))),
    CONSTRAINT "items_max_uses_check" CHECK ((("max_uses" IS NULL) OR ("max_uses" >= 1))),
    CONSTRAINT "items_min_level_check" CHECK (("min_level" >= 1)),
    CONSTRAINT "items_requirements_check" CHECK ((("req_teamgeist" >= 0) AND ("req_geschwindigkeit" >= 0) AND ("req_kraft" >= 0) AND ("req_technik" >= 0) AND ("req_ehrgeiz" >= 0)))
);


ALTER TABLE "public"."items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."match_point_awards" (
    "match_id" "uuid" NOT NULL,
    "player_id" "uuid" NOT NULL,
    "award_type" "text" NOT NULL,
    "points" integer DEFAULT 0 NOT NULL,
    "games" integer DEFAULT 0 NOT NULL,
    "wins" integer DEFAULT 0 NOT NULL,
    "point_diff" integer DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "match_point_awards_award_type_check" CHECK (("award_type" = ANY (ARRAY['team_a'::"text", 'team_b'::"text", 'bench'::"text", 'absent'::"text"])))
);


ALTER TABLE "public"."match_point_awards" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."matches" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "mode" "text" NOT NULL,
    "team_a" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "team_b" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "score_a" integer,
    "score_b" integer,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "bench_players" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "absent_players" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "points_processed" boolean DEFAULT false NOT NULL,
    "tiebreak_player_a_id" "uuid",
    "tiebreak_player_b_id" "uuid"
);


ALTER TABLE "public"."matches" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."player_profiles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid",
    "player_id" "uuid",
    "display_name" "text",
    "avatar_body" "text" DEFAULT 'black'::"text" NOT NULL,
    "avatar_belly" "text" DEFAULT 'white'::"text" NOT NULL,
    "head_item" "text" DEFAULT 'none'::"text" NOT NULL,
    "face_item" "text" DEFAULT 'none'::"text" NOT NULL,
    "body_item" "text" DEFAULT 'none'::"text" NOT NULL,
    "back_item" "text" DEFAULT 'none'::"text" NOT NULL,
    "bio" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "body_color" "text" DEFAULT 'black'::"text" NOT NULL,
    "belly_color" "text" DEFAULT 'white'::"text" NOT NULL,
    "shorts_item" "text" DEFAULT 'none'::"text" NOT NULL,
    "accessory_item" "text" DEFAULT 'none'::"text" NOT NULL,
    "unlocked_items" "jsonb" DEFAULT '[]'::"jsonb" NOT NULL,
    "xp_total" integer DEFAULT 0 NOT NULL,
    "level" integer DEFAULT 1 NOT NULL,
    "stat_points_total" integer DEFAULT 0 NOT NULL,
    "stat_points_spent" integer DEFAULT 0 NOT NULL,
    "stat_teamgeist" integer DEFAULT 0 NOT NULL,
    "stat_geschwindigkeit" integer DEFAULT 0 NOT NULL,
    "stat_kraft" integer DEFAULT 0 NOT NULL,
    "stat_technik" integer DEFAULT 0 NOT NULL,
    "stat_ehrgeiz" integer DEFAULT 0 NOT NULL,
    "top_item" "text" DEFAULT 'none'::"text" NOT NULL,
    "bottom_item" "text" DEFAULT 'none'::"text" NOT NULL,
    "selected_title_id" integer,
    "selected_special_attack_id" integer
);


ALTER TABLE "public"."player_profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."player_titles" (
    "id" integer NOT NULL,
    "code" "text",
    "name" "text" NOT NULL,
    "description" "text",
    "min_level" integer DEFAULT 1 NOT NULL,
    "req_teamgeist" integer DEFAULT 0 NOT NULL,
    "req_geschwindigkeit" integer DEFAULT 0 NOT NULL,
    "req_kraft" integer DEFAULT 0 NOT NULL,
    "req_technik" integer DEFAULT 0 NOT NULL,
    "req_ehrgeiz" integer DEFAULT 0 NOT NULL,
    "sort_order" integer DEFAULT 100 NOT NULL,
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "req_team_b_games" integer DEFAULT 0 NOT NULL,
    "strength_modifier" numeric(6,2) DEFAULT 0 NOT NULL,
    "speed_modifier" numeric(6,2) DEFAULT 0 NOT NULL,
    "technique_modifier" numeric(6,2) DEFAULT 0 NOT NULL,
    "ambition_modifier" numeric(6,2) DEFAULT 0 NOT NULL,
    "team_modifier" numeric(6,2) DEFAULT 0 NOT NULL,
    "power_modifier" numeric(6,2) DEFAULT 0 NOT NULL,
    "effect_code" "text",
    "effect_value" numeric DEFAULT 0 NOT NULL,
    "effect_target" "text" DEFAULT 'self'::"text" NOT NULL,
    "effect_scope" "text" DEFAULT 'permanent'::"text" NOT NULL,
    CONSTRAINT "player_titles_effect_scope_check" CHECK (("effect_scope" = ANY (ARRAY['permanent'::"text", 'next_match'::"text", 'active_duration'::"text", 'one_time'::"text"]))),
    CONSTRAINT "player_titles_effect_target_check" CHECK (("effect_target" = ANY (ARRAY['self'::"text", 'own_team'::"text", 'opponent'::"text", 'opponent_team'::"text", 'all_players'::"text"])))
);


ALTER TABLE "public"."player_titles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."players" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "name" "text" NOT NULL,
    "strength" numeric DEFAULT 6 NOT NULL,
    "form" numeric DEFAULT 0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "active" boolean DEFAULT false NOT NULL,
    "user_id" "uuid",
    "email" "text",
    "aka_name" "text",
    "approved" boolean DEFAULT false NOT NULL
);


ALTER TABLE "public"."players" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."special_attacks" (
    "id" integer NOT NULL,
    "code" "text",
    "name" "text" NOT NULL,
    "description" "text",
    "min_level" integer DEFAULT 1 NOT NULL,
    "sort_order" integer DEFAULT 100 NOT NULL,
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "req_teamgeist" integer DEFAULT 0 NOT NULL,
    "req_geschwindigkeit" integer DEFAULT 0 NOT NULL,
    "req_kraft" integer DEFAULT 0 NOT NULL,
    "req_technik" integer DEFAULT 0 NOT NULL,
    "req_ehrgeiz" integer DEFAULT 0 NOT NULL
);


ALTER TABLE "public"."special_attacks" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."player_card_view" AS
 SELECT "pp"."id" AS "profile_id",
    "pp"."user_id",
    "pp"."player_id",
    "p"."name" AS "real_name",
    "p"."email",
    "p"."active",
    "p"."approved",
    COALESCE("pp"."xp_total", 0) AS "xp_total",
    "public"."level_from_xp"(COALESCE("pp"."xp_total", 0)) AS "calculated_level",
    "public"."total_xp_for_level"("public"."level_from_xp"(COALESCE("pp"."xp_total", 0))) AS "current_level_xp",
    "public"."total_xp_for_level"(("public"."level_from_xp"(COALESCE("pp"."xp_total", 0)) + 1)) AS "next_level_xp",
    COALESCE("pp"."stat_points_total", 0) AS "stat_points_total",
    COALESCE("pp"."stat_points_spent", 0) AS "stat_points_spent",
    GREATEST((COALESCE("pp"."stat_points_total", 0) - COALESCE("pp"."stat_points_spent", 0)), 0) AS "stat_points_available",
    COALESCE("pp"."stat_teamgeist", 0) AS "stat_teamgeist",
    COALESCE("pp"."stat_geschwindigkeit", 0) AS "stat_geschwindigkeit",
    COALESCE("pp"."stat_kraft", 0) AS "stat_kraft",
    COALESCE("pp"."stat_technik", 0) AS "stat_technik",
    COALESCE("pp"."stat_ehrgeiz", 0) AS "stat_ehrgeiz",
    "pp"."selected_title_id",
    "t"."name" AS "selected_title_name",
    "t"."description" AS "selected_title_description",
    "pp"."selected_special_attack_id",
    "sa"."name" AS "selected_special_attack_name",
    "sa"."description" AS "selected_special_attack_description",
    COALESCE("pp"."body_color", "pp"."avatar_body", 'black'::"text") AS "body_color",
    COALESCE("pp"."head_item", 'none'::"text") AS "head_item",
    COALESCE("pp"."top_item", 'none'::"text") AS "top_item",
    COALESCE("pp"."bottom_item", "pp"."shorts_item", 'none'::"text") AS "bottom_item",
    COALESCE("pp"."shorts_item", "pp"."bottom_item", 'none'::"text") AS "shorts_item",
    COALESCE("pp"."accessory_item", 'none'::"text") AS "accessory_item"
   FROM ((("public"."player_profiles" "pp"
     JOIN "public"."players" "p" ON (("p"."id" = "pp"."player_id")))
     LEFT JOIN "public"."player_titles" "t" ON (("t"."id" = "pp"."selected_title_id")))
     LEFT JOIN "public"."special_attacks" "sa" ON (("sa"."id" = "pp"."selected_special_attack_id")));


ALTER VIEW "public"."player_card_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."player_items" (
    "player_id" "uuid" NOT NULL,
    "item_id" "uuid" NOT NULL,
    "quantity" integer DEFAULT 1 NOT NULL,
    "equipped" boolean DEFAULT false NOT NULL,
    "uses_remaining" integer,
    "active_games_remaining" integer DEFAULT 0 NOT NULL,
    "obtained_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "equipped_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "player_items_active_games_check" CHECK (("active_games_remaining" >= 0)),
    CONSTRAINT "player_items_quantity_check" CHECK (("quantity" >= 0)),
    CONSTRAINT "player_items_uses_remaining_check" CHECK ((("uses_remaining" IS NULL) OR ("uses_remaining" >= 0)))
);


ALTER TABLE "public"."player_items" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."player_point_adjustments" (
    "player_id" "uuid" NOT NULL,
    "points" numeric(10,2) DEFAULT 0 NOT NULL,
    "reason" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "match_id" "uuid"
);


ALTER TABLE "public"."player_point_adjustments" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."player_skills" (
    "player_id" "uuid" NOT NULL,
    "skill_id" "uuid" NOT NULL,
    "unlocked" boolean DEFAULT false NOT NULL,
    "selected" boolean DEFAULT false NOT NULL,
    "active_games_remaining" integer DEFAULT 0 NOT NULL,
    "cooldown_games_remaining" integer DEFAULT 0 NOT NULL,
    "unlocked_at" timestamp with time zone,
    "activated_at" timestamp with time zone,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "cooldown_started_at" timestamp with time zone,
    CONSTRAINT "player_skills_active_games_check" CHECK (("active_games_remaining" >= 0)),
    CONSTRAINT "player_skills_cooldown_games_check" CHECK (("cooldown_games_remaining" >= 0))
);


ALTER TABLE "public"."player_skills" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."player_stats" (
    "player_id" "uuid" NOT NULL,
    "strength" integer DEFAULT 5 NOT NULL,
    "stamina" integer DEFAULT 5 NOT NULL,
    "speed" integer DEFAULT 5 NOT NULL,
    "wisdom" integer DEFAULT 5 NOT NULL,
    "special_attack" "text" DEFAULT ''::"text" NOT NULL,
    "admin_note" "text",
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "player_stats_speed_check" CHECK ((("speed" >= 1) AND ("speed" <= 12))),
    CONSTRAINT "player_stats_stamina_check" CHECK ((("stamina" >= 1) AND ("stamina" <= 12))),
    CONSTRAINT "player_stats_strength_check" CHECK ((("strength" >= 1) AND ("strength" <= 12))),
    CONSTRAINT "player_stats_wisdom_check" CHECK ((("wisdom" >= 1) AND ("wisdom" <= 12)))
);


ALTER TABLE "public"."player_stats" OWNER TO "postgres";


ALTER TABLE "public"."player_titles" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."player_titles_new_id_seq1"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."settings" (
    "id" "text" NOT NULL,
    "value" "jsonb" NOT NULL
);


ALTER TABLE "public"."settings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."skills" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "code" "text",
    "name" "text" NOT NULL,
    "description" "text",
    "icon" "text",
    "strength_modifier" numeric(6,2) DEFAULT 0 NOT NULL,
    "speed_modifier" numeric(6,2) DEFAULT 0 NOT NULL,
    "technique_modifier" numeric(6,2) DEFAULT 0 NOT NULL,
    "ambition_modifier" numeric(6,2) DEFAULT 0 NOT NULL,
    "team_modifier" numeric(6,2) DEFAULT 0 NOT NULL,
    "power_modifier" numeric(6,2) DEFAULT 0 NOT NULL,
    "duration_games" integer DEFAULT 0 NOT NULL,
    "cooldown_games" integer DEFAULT 0 NOT NULL,
    "sort_order" integer DEFAULT 0 NOT NULL,
    "active" boolean DEFAULT true NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "effect_code" "text",
    "effect_value" numeric DEFAULT 0 NOT NULL,
    "effect_target" "text" DEFAULT 'self'::"text" NOT NULL,
    "effect_scope" "text" DEFAULT 'active_duration'::"text" NOT NULL,
    "min_level" integer DEFAULT 1 NOT NULL,
    "req_teamgeist" integer DEFAULT 0 NOT NULL,
    "req_geschwindigkeit" integer DEFAULT 0 NOT NULL,
    "req_kraft" integer DEFAULT 0 NOT NULL,
    "req_technik" integer DEFAULT 0 NOT NULL,
    "req_ehrgeiz" integer DEFAULT 0 NOT NULL,
    "req_team_b_games" integer DEFAULT 0 NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "skills_cooldown_games_check" CHECK (("cooldown_games" >= 0)),
    CONSTRAINT "skills_duration_games_check" CHECK (("duration_games" >= 0)),
    CONSTRAINT "skills_effect_scope_check" CHECK (("effect_scope" = ANY (ARRAY['permanent'::"text", 'next_match'::"text", 'active_duration'::"text", 'one_time'::"text"]))),
    CONSTRAINT "skills_effect_target_check" CHECK (("effect_target" = ANY (ARRAY['self'::"text", 'own_team'::"text", 'opponent'::"text", 'opponent_team'::"text", 'all_players'::"text"]))),
    CONSTRAINT "skills_min_level_check" CHECK (("min_level" >= 1)),
    CONSTRAINT "skills_requirements_check" CHECK ((("req_teamgeist" >= 0) AND ("req_geschwindigkeit" >= 0) AND ("req_kraft" >= 0) AND ("req_technik" >= 0) AND ("req_ehrgeiz" >= 0) AND ("req_team_b_games" >= 0)))
);


ALTER TABLE "public"."skills" OWNER TO "postgres";


ALTER TABLE "public"."special_attacks" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."special_attacks_new_id_seq1"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



ALTER TABLE ONLY "public"."admin_users"
    ADD CONSTRAINT "admin_users_pkey" PRIMARY KEY ("user_id");



ALTER TABLE ONLY "public"."items"
    ADD CONSTRAINT "items_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."items"
    ADD CONSTRAINT "items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."match_point_awards"
    ADD CONSTRAINT "match_point_awards_pkey" PRIMARY KEY ("match_id", "player_id");



ALTER TABLE ONLY "public"."matches"
    ADD CONSTRAINT "matches_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."player_items"
    ADD CONSTRAINT "player_items_pkey" PRIMARY KEY ("player_id", "item_id");



ALTER TABLE ONLY "public"."player_point_adjustments"
    ADD CONSTRAINT "player_point_adjustments_pkey" PRIMARY KEY ("player_id");



ALTER TABLE ONLY "public"."player_profiles"
    ADD CONSTRAINT "player_profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."player_profiles"
    ADD CONSTRAINT "player_profiles_player_id_key" UNIQUE ("player_id");



ALTER TABLE ONLY "public"."player_profiles"
    ADD CONSTRAINT "player_profiles_user_id_key" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."player_skills"
    ADD CONSTRAINT "player_skills_pkey" PRIMARY KEY ("player_id", "skill_id");



ALTER TABLE ONLY "public"."player_stats"
    ADD CONSTRAINT "player_stats_pkey" PRIMARY KEY ("player_id");



ALTER TABLE ONLY "public"."player_titles"
    ADD CONSTRAINT "player_titles_new_code_key1" UNIQUE ("code");



ALTER TABLE ONLY "public"."player_titles"
    ADD CONSTRAINT "player_titles_new_pkey1" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."players"
    ADD CONSTRAINT "players_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."players"
    ADD CONSTRAINT "players_user_id_key" UNIQUE ("user_id");



ALTER TABLE ONLY "public"."settings"
    ADD CONSTRAINT "settings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."skills"
    ADD CONSTRAINT "skills_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."skills"
    ADD CONSTRAINT "skills_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."special_attacks"
    ADD CONSTRAINT "special_attacks_new_code_key1" UNIQUE ("code");



ALTER TABLE ONLY "public"."special_attacks"
    ADD CONSTRAINT "special_attacks_new_pkey1" PRIMARY KEY ("id");



CREATE INDEX "idx_items_active_sort" ON "public"."items" USING "btree" ("active", "sort_order");



CREATE INDEX "idx_player_items_equipped" ON "public"."player_items" USING "btree" ("player_id", "equipped") WHERE ("equipped" = true);



CREATE INDEX "idx_player_items_item" ON "public"."player_items" USING "btree" ("item_id");



CREATE INDEX "idx_player_items_player" ON "public"."player_items" USING "btree" ("player_id");



CREATE INDEX "idx_player_skills_cooldown" ON "public"."player_skills" USING "btree" ("player_id", "cooldown_games_remaining") WHERE ("cooldown_games_remaining" > 0);



CREATE INDEX "idx_player_skills_player" ON "public"."player_skills" USING "btree" ("player_id");



CREATE INDEX "idx_player_skills_player_id" ON "public"."player_skills" USING "btree" ("player_id");



CREATE INDEX "idx_player_skills_selected" ON "public"."player_skills" USING "btree" ("player_id", "selected") WHERE ("selected" = true);



CREATE INDEX "idx_player_skills_skill" ON "public"."player_skills" USING "btree" ("skill_id");



CREATE INDEX "idx_player_skills_skill_id" ON "public"."player_skills" USING "btree" ("skill_id");



CREATE INDEX "idx_skills_active_sort" ON "public"."skills" USING "btree" ("active", "sort_order");



CREATE INDEX "match_point_awards_player_idx" ON "public"."match_point_awards" USING "btree" ("player_id");



CREATE UNIQUE INDEX "player_point_adjustments_tiebreak_match_unique" ON "public"."player_point_adjustments" USING "btree" ("match_id") WHERE ("match_id" IS NOT NULL);



CREATE OR REPLACE TRIGGER "set_player_profiles_updated_at" BEFORE UPDATE ON "public"."player_profiles" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "set_player_stats_updated_at" BEFORE UPDATE ON "public"."player_stats" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_items_set_updated_at" BEFORE UPDATE ON "public"."items" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_player_items_set_updated_at" BEFORE UPDATE ON "public"."player_items" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_player_skills_set_updated_at" BEFORE UPDATE ON "public"."player_skills" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_skills_set_updated_at" BEFORE UPDATE ON "public"."skills" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



ALTER TABLE ONLY "public"."admin_users"
    ADD CONSTRAINT "admin_users_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."match_point_awards"
    ADD CONSTRAINT "match_point_awards_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."match_point_awards"
    ADD CONSTRAINT "match_point_awards_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "public"."players"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."matches"
    ADD CONSTRAINT "matches_tiebreak_player_a_id_fkey" FOREIGN KEY ("tiebreak_player_a_id") REFERENCES "public"."players"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."matches"
    ADD CONSTRAINT "matches_tiebreak_player_b_id_fkey" FOREIGN KEY ("tiebreak_player_b_id") REFERENCES "public"."players"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."player_items"
    ADD CONSTRAINT "player_items_item_id_fkey" FOREIGN KEY ("item_id") REFERENCES "public"."items"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."player_items"
    ADD CONSTRAINT "player_items_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "public"."players"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."player_point_adjustments"
    ADD CONSTRAINT "player_point_adjustments_match_id_fkey" FOREIGN KEY ("match_id") REFERENCES "public"."matches"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."player_point_adjustments"
    ADD CONSTRAINT "player_point_adjustments_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "public"."players"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."player_profiles"
    ADD CONSTRAINT "player_profiles_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "public"."players"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."player_profiles"
    ADD CONSTRAINT "player_profiles_selected_special_attack_id_fkey" FOREIGN KEY ("selected_special_attack_id") REFERENCES "public"."special_attacks"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."player_profiles"
    ADD CONSTRAINT "player_profiles_selected_title_id_fkey" FOREIGN KEY ("selected_title_id") REFERENCES "public"."player_titles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."player_profiles"
    ADD CONSTRAINT "player_profiles_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."player_skills"
    ADD CONSTRAINT "player_skills_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "public"."players"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."player_skills"
    ADD CONSTRAINT "player_skills_skill_id_fkey" FOREIGN KEY ("skill_id") REFERENCES "public"."skills"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."player_stats"
    ADD CONSTRAINT "player_stats_player_id_fkey" FOREIGN KEY ("player_id") REFERENCES "public"."players"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."players"
    ADD CONSTRAINT "players_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE SET NULL;



CREATE POLICY "admin users read admin" ON "public"."admin_users" FOR SELECT TO "authenticated" USING ("public"."is_admin"());



CREATE POLICY "admin users write admin" ON "public"."admin_users" TO "authenticated" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



ALTER TABLE "public"."admin_users" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."items" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "items admin write" ON "public"."items" TO "authenticated" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "items read" ON "public"."items" FOR SELECT USING (true);



ALTER TABLE "public"."match_point_awards" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."matches" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "matches read" ON "public"."matches" FOR SELECT USING (true);



CREATE POLICY "matches write" ON "public"."matches" TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "player items admin write" ON "public"."player_items" TO "authenticated" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "player items read own or admin" ON "public"."player_items" FOR SELECT TO "authenticated" USING (("public"."is_admin"() OR (EXISTS ( SELECT 1
   FROM "public"."players"
  WHERE (("players"."id" = "player_items"."player_id") AND ("players"."user_id" = "auth"."uid"()))))));



CREATE POLICY "player skills admin write" ON "public"."player_skills" TO "authenticated" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "player skills read own or admin" ON "public"."player_skills" FOR SELECT TO "authenticated" USING (("public"."is_admin"() OR (EXISTS ( SELECT 1
   FROM "public"."players"
  WHERE (("players"."id" = "player_skills"."player_id") AND ("players"."user_id" = "auth"."uid"()))))));



CREATE POLICY "player titles read" ON "public"."player_titles" FOR SELECT TO "authenticated", "anon" USING (true);



ALTER TABLE "public"."player_items" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."player_point_adjustments" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."player_profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "player_profiles_select_all" ON "public"."player_profiles" FOR SELECT USING (true);



ALTER TABLE "public"."player_skills" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."player_stats" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."player_titles" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."players" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "players read" ON "public"."players" FOR SELECT USING (true);



CREATE POLICY "players write" ON "public"."players" TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "profiles delete admin" ON "public"."player_profiles" FOR DELETE TO "authenticated" USING ("public"."is_admin"());



CREATE POLICY "profiles insert admin" ON "public"."player_profiles" FOR INSERT TO "authenticated" WITH CHECK ("public"."is_admin"());



CREATE POLICY "profiles read own or admin" ON "public"."player_profiles" FOR SELECT TO "authenticated" USING ((("user_id" = "auth"."uid"()) OR "public"."is_admin"()));



CREATE POLICY "profiles update own avatar or admin" ON "public"."player_profiles" FOR UPDATE TO "authenticated" USING ((("user_id" = "auth"."uid"()) OR "public"."is_admin"())) WITH CHECK ((("user_id" = "auth"."uid"()) OR "public"."is_admin"()));



ALTER TABLE "public"."settings" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "settings read" ON "public"."settings" FOR SELECT USING (true);



CREATE POLICY "settings write" ON "public"."settings" TO "authenticated" USING (true) WITH CHECK (true);



ALTER TABLE "public"."skills" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "skills admin write" ON "public"."skills" TO "authenticated" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



CREATE POLICY "skills read" ON "public"."skills" FOR SELECT USING (true);



ALTER TABLE "public"."special_attacks" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "stats admin read" ON "public"."player_stats" FOR SELECT TO "authenticated" USING ("public"."is_admin"());



CREATE POLICY "stats admin write" ON "public"."player_stats" TO "authenticated" USING ("public"."is_admin"()) WITH CHECK ("public"."is_admin"());



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_add_profile_xp"("target_profile_id" "uuid", "add_xp" integer, "add_stat_points" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."admin_add_profile_xp"("target_profile_id" "uuid", "add_xp" integer, "add_stat_points" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_add_profile_xp"("target_profile_id" "uuid", "add_xp" integer, "add_stat_points" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_delete_player_title"("p_id" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."admin_delete_player_title"("p_id" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_delete_player_title"("p_id" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_delete_special_attack"("p_id" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."admin_delete_special_attack"("p_id" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_delete_special_attack"("p_id" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_get_player_titles"() TO "anon";
GRANT ALL ON FUNCTION "public"."admin_get_player_titles"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_get_player_titles"() TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_get_special_attacks"() TO "anon";
GRANT ALL ON FUNCTION "public"."admin_get_special_attacks"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_get_special_attacks"() TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_grant_stat_points"("target_player_id" "uuid", "points_to_add" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."admin_grant_stat_points"("target_player_id" "uuid", "points_to_add" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_grant_stat_points"("target_player_id" "uuid", "points_to_add" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_save_player_title"("p_id" integer, "p_name" "text", "p_description" "text", "p_min_level" integer, "p_req_teamgeist" integer, "p_req_geschwindigkeit" integer, "p_req_kraft" integer, "p_req_technik" integer, "p_req_ehrgeiz" integer, "p_req_team_b_games" integer, "p_sort_order" integer, "p_active" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."admin_save_player_title"("p_id" integer, "p_name" "text", "p_description" "text", "p_min_level" integer, "p_req_teamgeist" integer, "p_req_geschwindigkeit" integer, "p_req_kraft" integer, "p_req_technik" integer, "p_req_ehrgeiz" integer, "p_req_team_b_games" integer, "p_sort_order" integer, "p_active" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_save_player_title"("p_id" integer, "p_name" "text", "p_description" "text", "p_min_level" integer, "p_req_teamgeist" integer, "p_req_geschwindigkeit" integer, "p_req_kraft" integer, "p_req_technik" integer, "p_req_ehrgeiz" integer, "p_req_team_b_games" integer, "p_sort_order" integer, "p_active" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."admin_save_special_attack"("p_id" integer, "p_name" "text", "p_description" "text", "p_min_level" integer, "p_req_teamgeist" integer, "p_req_geschwindigkeit" integer, "p_req_kraft" integer, "p_req_technik" integer, "p_req_ehrgeiz" integer, "p_sort_order" integer, "p_active" boolean) TO "anon";
GRANT ALL ON FUNCTION "public"."admin_save_special_attack"("p_id" integer, "p_name" "text", "p_description" "text", "p_min_level" integer, "p_req_teamgeist" integer, "p_req_geschwindigkeit" integer, "p_req_kraft" integer, "p_req_technik" integer, "p_req_ehrgeiz" integer, "p_sort_order" integer, "p_active" boolean) TO "authenticated";
GRANT ALL ON FUNCTION "public"."admin_save_special_attack"("p_id" integer, "p_name" "text", "p_description" "text", "p_min_level" integer, "p_req_teamgeist" integer, "p_req_geschwindigkeit" integer, "p_req_kraft" integer, "p_req_technik" integer, "p_req_ehrgeiz" integer, "p_sort_order" integer, "p_active" boolean) TO "service_role";



GRANT ALL ON FUNCTION "public"."allocate_my_stat_points"("add_teamgeist" integer, "add_geschwindigkeit" integer, "add_kraft" integer, "add_technik" integer, "add_ehrgeiz" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."allocate_my_stat_points"("add_teamgeist" integer, "add_geschwindigkeit" integer, "add_kraft" integer, "add_technik" integer, "add_ehrgeiz" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."allocate_my_stat_points"("add_teamgeist" integer, "add_geschwindigkeit" integer, "add_kraft" integer, "add_technik" integer, "add_ehrgeiz" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."approve_player"("target_player_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."approve_player"("target_player_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."approve_player"("target_player_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."block_player"("target_player_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."block_player"("target_player_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."block_player"("target_player_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."delete_match_with_points"("target_match_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."delete_match_with_points"("target_match_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_match_with_points"("target_match_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_my_available_special_attacks"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_my_available_special_attacks"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_my_available_special_attacks"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_my_sun_games_count"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_my_sun_games_count"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_my_sun_games_count"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_my_unlocked_titles"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_my_unlocked_titles"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_my_unlocked_titles"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_player_cards"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_player_cards"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_player_cards"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_player_score_totals"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_player_score_totals"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_player_score_totals"() TO "service_role";



GRANT ALL ON FUNCTION "public"."get_player_sun_games_count"("target_player_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_player_sun_games_count"("target_player_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_player_sun_games_count"("target_player_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_point_ledger_data"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_point_ledger_data"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_point_ledger_data"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_player_signup"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_player_signup"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_player_signup"() TO "service_role";



GRANT ALL ON FUNCTION "public"."is_admin"() TO "anon";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_admin"() TO "service_role";



GRANT ALL ON FUNCTION "public"."is_title_unlocked"("profile_id" "uuid", "title_id" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."is_title_unlocked"("profile_id" "uuid", "title_id" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."is_title_unlocked"("profile_id" "uuid", "title_id" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."level_from_xp"("total_xp" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."level_from_xp"("total_xp" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."level_from_xp"("total_xp" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."recompute_all_profile_progress"() TO "anon";
GRANT ALL ON FUNCTION "public"."recompute_all_profile_progress"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."recompute_all_profile_progress"() TO "service_role";



GRANT ALL ON FUNCTION "public"."recompute_all_profile_progress_trigger"() TO "anon";
GRANT ALL ON FUNCTION "public"."recompute_all_profile_progress_trigger"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."recompute_all_profile_progress_trigger"() TO "service_role";



GRANT ALL ON FUNCTION "public"."refresh_profile_progress_from_ledger"() TO "anon";
GRANT ALL ON FUNCTION "public"."refresh_profile_progress_from_ledger"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."refresh_profile_progress_from_ledger"() TO "service_role";



GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "anon";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."rls_auto_enable"() TO "service_role";



GRANT ALL ON FUNCTION "public"."save_match_score"("target_match_id" "uuid", "new_score_a" integer, "new_score_b" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."save_match_score"("target_match_id" "uuid", "new_score_a" integer, "new_score_b" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."save_match_score"("target_match_id" "uuid", "new_score_a" integer, "new_score_b" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."total_xp_for_level"("target_level" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."total_xp_for_level"("target_level" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."total_xp_for_level"("target_level" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."update_my_aka_name"("new_aka_name" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."update_my_aka_name"("new_aka_name" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_my_aka_name"("new_aka_name" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_my_profile_choices"("new_title_id" integer, "new_special_attack_id" integer, "new_body_color" "text", "new_head_item" "text", "new_top_item" "text", "new_bottom_item" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."update_my_profile_choices"("new_title_id" integer, "new_special_attack_id" integer, "new_body_color" "text", "new_head_item" "text", "new_top_item" "text", "new_bottom_item" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_my_profile_choices"("new_title_id" integer, "new_special_attack_id" integer, "new_body_color" "text", "new_head_item" "text", "new_top_item" "text", "new_bottom_item" "text") TO "service_role";



GRANT ALL ON TABLE "public"."admin_users" TO "anon";
GRANT ALL ON TABLE "public"."admin_users" TO "authenticated";
GRANT ALL ON TABLE "public"."admin_users" TO "service_role";



GRANT ALL ON TABLE "public"."items" TO "anon";
GRANT ALL ON TABLE "public"."items" TO "authenticated";
GRANT ALL ON TABLE "public"."items" TO "service_role";



GRANT ALL ON TABLE "public"."match_point_awards" TO "anon";
GRANT ALL ON TABLE "public"."match_point_awards" TO "authenticated";
GRANT ALL ON TABLE "public"."match_point_awards" TO "service_role";



GRANT ALL ON TABLE "public"."matches" TO "anon";
GRANT ALL ON TABLE "public"."matches" TO "authenticated";
GRANT ALL ON TABLE "public"."matches" TO "service_role";



GRANT ALL ON TABLE "public"."player_profiles" TO "anon";
GRANT ALL ON TABLE "public"."player_profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."player_profiles" TO "service_role";



GRANT ALL ON TABLE "public"."player_titles" TO "anon";
GRANT ALL ON TABLE "public"."player_titles" TO "authenticated";
GRANT ALL ON TABLE "public"."player_titles" TO "service_role";



GRANT ALL ON TABLE "public"."players" TO "anon";
GRANT ALL ON TABLE "public"."players" TO "authenticated";
GRANT ALL ON TABLE "public"."players" TO "service_role";



GRANT ALL ON TABLE "public"."special_attacks" TO "anon";
GRANT ALL ON TABLE "public"."special_attacks" TO "authenticated";
GRANT ALL ON TABLE "public"."special_attacks" TO "service_role";



GRANT ALL ON TABLE "public"."player_card_view" TO "anon";
GRANT ALL ON TABLE "public"."player_card_view" TO "authenticated";
GRANT ALL ON TABLE "public"."player_card_view" TO "service_role";



GRANT ALL ON TABLE "public"."player_items" TO "anon";
GRANT ALL ON TABLE "public"."player_items" TO "authenticated";
GRANT ALL ON TABLE "public"."player_items" TO "service_role";



GRANT ALL ON TABLE "public"."player_point_adjustments" TO "anon";
GRANT ALL ON TABLE "public"."player_point_adjustments" TO "authenticated";
GRANT ALL ON TABLE "public"."player_point_adjustments" TO "service_role";



GRANT ALL ON TABLE "public"."player_skills" TO "anon";
GRANT ALL ON TABLE "public"."player_skills" TO "authenticated";
GRANT ALL ON TABLE "public"."player_skills" TO "service_role";



GRANT ALL ON TABLE "public"."player_stats" TO "anon";
GRANT ALL ON TABLE "public"."player_stats" TO "authenticated";
GRANT ALL ON TABLE "public"."player_stats" TO "service_role";



GRANT ALL ON SEQUENCE "public"."player_titles_new_id_seq1" TO "anon";
GRANT ALL ON SEQUENCE "public"."player_titles_new_id_seq1" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."player_titles_new_id_seq1" TO "service_role";



GRANT ALL ON TABLE "public"."settings" TO "anon";
GRANT ALL ON TABLE "public"."settings" TO "authenticated";
GRANT ALL ON TABLE "public"."settings" TO "service_role";



GRANT ALL ON TABLE "public"."skills" TO "anon";
GRANT ALL ON TABLE "public"."skills" TO "authenticated";
GRANT ALL ON TABLE "public"."skills" TO "service_role";



GRANT ALL ON SEQUENCE "public"."special_attacks_new_id_seq1" TO "anon";
GRANT ALL ON SEQUENCE "public"."special_attacks_new_id_seq1" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."special_attacks_new_id_seq1" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";







