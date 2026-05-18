-- ============================================================
-- Finals Dashboard — Supabase Schema
-- Run this in: Supabase → SQL Editor → Run
-- ============================================================

-- 1. Tables
create table if not exists tasks (
  id          text primary key,
  type        text not null check (type in ('exam','hw','reminder')),
  course      text,
  title       text not null,
  notes       text,
  due_date    timestamptz,
  start_date  timestamptz,
  end_date    timestamptz,
  location    text,
  color_var   text,
  tag         text,
  urgency     text,
  completed   boolean default false,
  completed_at timestamptz,
  created_at  timestamptz default now(),
  sort_order  int default 0
);

create table if not exists task_items (
  id          text primary key,   -- format: "task-id:index-or-key"
  task_id     text not null references tasks(id) on delete cascade,
  label       text not null,
  sort_order  int default 0,
  completed   boolean default false,
  completed_at timestamptz
);

-- 2. Enable Row Level Security
alter table tasks      enable row level security;
alter table task_items enable row level security;

-- 3. Policies — anonymous read/write (personal use, no login required)
--    Tradeoff: anyone who has the URL can check/uncheck your tasks.
--    Acceptable for a personal finals dashboard. To restrict access,
--    you'd add Supabase Auth (email magic link) — adds a login step on each device.
create policy "anon read tasks"   on tasks      for select using (true);
create policy "anon update tasks" on tasks      for update using (true) with check (true);

create policy "anon read items"   on task_items for select using (true);
create policy "anon update items" on task_items for update using (true) with check (true);

-- 4. Enable Realtime on both tables
-- (also enable in Supabase dashboard: Database → Replication → tasks + task_items)
alter publication supabase_realtime add table tasks;
alter publication supabase_realtime add table task_items;

-- 5. Seed: Exams
insert into tasks (id, type, course, title, notes, due_date, start_date, end_date, location, color_var, tag, sort_order) values
(
  'env-econ', 'exam', 'ECO 39556', 'Environmental Economics',
  'Non-cumulative — everything since the midterm. <strong>Bring the CBAM presentation deck.</strong>',
  '2026-05-20T11:00:00', '2026-05-20T09:00:00', '2026-05-20T11:00:00',
  'Hunter North · in person', 'var(--c-env-econ)', '10 MC', 1
),
(
  'ind-org', 'exam', 'ECO 245H', 'Industrial Organization',
  'Window opens Mon May 18 12:01 AM, due Tue May 19 11:59 PM.',
  '2026-05-19T23:59:00', '2026-05-18T00:01:00', '2026-05-19T23:59:00',
  'Brightspace', 'var(--c-ind-org)', 'Final exam · online', 2
),
(
  'macro', 'exam', 'ECO 201', 'Macroeconomics',
  'Open since May 15. Due Wed May 20 at 12:00 PM — same morning as the Env Econ final. <strong>Finish Tue night or submit between exams.</strong>',
  '2026-05-20T12:00:00', '2026-05-15T00:01:00', '2026-05-20T12:00:00',
  'Brightspace · online', 'var(--c-macro)', '40–50 MC · no time limit', 3
),
(
  'money-bank', 'exam', 'ECO 250H', 'Money & Banking',
  '<strong>200-min limit, 1 attempt.</strong> Start 7:30 AM SHARP — Astro 110 is at NOON at BMCC the same morning. Plan: M&amp;B 7:30–10:50, eat 11:00–11:30, leave 11:30, BMCC by 11:45.',
  '2026-05-21T11:00:00', '2026-05-21T07:30:00', '2026-05-21T11:00:00',
  'Online', 'var(--c-money-bank)', '200 min · 1 attempt', 4
),
(
  'astro', 'exam', 'ASTRO 110', 'Astronomy Final',
  '<strong>Confirmed with Prof. Zhang.</strong> Check in with Lydia (Science Dept Sec) at Room N699. Prof. Zhang supervises via <a href="https://bmcc-cuny.zoom.us/j/7333921219" target="_blank">Zoom</a>. <strong>Notes allowed.</strong> Bring: laptop + cheat sheet + review sheet + handwritten notes + discussion posts.',
  '2026-05-21T13:30:00', '2026-05-21T12:00:00', '2026-05-21T13:30:00',
  'BMCC Room N699 · 199 Chambers St', 'var(--c-astro)', 'In-person · Zoom supervised · notes allowed', 5
)
on conflict (id) do nothing;

-- 6. Seed: Homework
insert into tasks (id, type, course, title, notes, due_date, color_var, sort_order) values
(
  'honors-paper', 'hw', 'ECO 245H · Industrial Org', 'Honors Paper',
  'Submit via Turnitin · final paper for the honors track',
  '2026-05-17T23:00:00', 'var(--c-ind-org)', 1
),
(
  'lab-hubble', 'hw', 'ASTRO 110', 'Lab 14 — Hubble''s Law',
  'BMCC General Astronomy lab',
  '2026-05-17T23:59:00', 'var(--c-astro)', 2
),
(
  'fed-challenge', 'hw', 'F&B · ECO 250H', 'College Fed Challenge Term Paper',
  'Group paper — monetary policy recs based on case data',
  '2026-05-17T23:59:00', 'var(--c-money-bank)', 3
),
(
  'fnb-catchup', 'hw', 'F&B · ECO 250H', 'Catch-up modules',
  'Mod 4, Mod 5 (h2), Mod 8, Mod 13 (h5)',
  '2026-05-22T23:59:00', 'var(--c-money-bank)', 4
)
on conflict (id) do nothing;

-- 7. Seed: Reminders
insert into tasks (id, type, title, tag, urgency, sort_order) values
('cbam-deck',   'reminder', 'Bring CBAM presentation deck to Env Econ final',               'Wed AM',    'day',  1),
('astro-prep',  'reminder', 'Build Astro cheat sheet — Mon eve, Tue eve, Wed eve',           'This week', 'week', 2),
('thursday-2x', 'reminder', 'Thursday is double-final day: M&B 7:30 AM → Astro at BMCC at noon', 'Thu', 'day',  3),
('macro-grind', 'reminder', 'Macro is open NOW on Brightspace — chip away at it',            'Now',       'now',  4)
on conflict (id) do nothing;

-- 8. Seed: Exam prep items
insert into task_items (id, task_id, label, sort_order) values
('env-econ:0', 'env-econ', 'Review post-midterm lectures', 0),
('env-econ:1', 'env-econ', 'Re-read CBAM deck',            1),
('env-econ:2', 'env-econ', 'Print/load CBAM deck',         2),
('env-econ:3', 'env-econ', 'Sleep — early start',          3),

('ind-org:0', 'ind-org', 'Skim course notes',              0),
('ind-org:1', 'ind-org', 'Review problem sets',            1),
('ind-org:2', 'ind-org', 'Open Brightspace + take exam',   2),
('ind-org:3', 'ind-org', 'Submit before deadline',         3),

('macro:0', 'macro', 'Quick review of all units',          0),
('macro:1', 'macro', 'Knock out 10 questions/day',         1),
('macro:2', 'macro', 'Final pass before submit',           2),

('money-bank:0', 'money-bank', 'Full course review',                       0),
('money-bank:1', 'money-bank', 'Test internet + browser night before',     1),
('money-bank:2', 'money-bank', 'Quiet space, water, snacks ready',         2),
('money-bank:3', 'money-bank', 'Alarm set for 6:45 AM',                   3),
('money-bank:4', 'money-bank', 'In seat by 7:25 AM',                      4),

('astro:0', 'astro', 'Take each weekly quiz, record correct answers',      0),
('astro:1', 'astro', 'Use AI to fill any quiz answer gaps',                1),
('astro:2', 'astro', 'Download every weekly PowerPoint',                   2),
('astro:3', 'astro', 'Extract end-of-deck review questions',               3),
('astro:4', 'astro', 'AI: concise answers from slides + textbook',         4),
('astro:5', 'astro', 'Compile cheat sheet document',                       5),
('astro:6', 'astro', 'Generate AI review sheet',                           6),
('astro:7', 'astro', 'Print cheat sheet + review sheet + discussion posts', 7),
('astro:8', 'astro', 'Pack: laptop, charger, printed notes, water, snack', 8)
on conflict (id) do nothing;

-- 9. Seed: HW subtasks (fnb-catchup)
insert into task_items (id, task_id, label, sort_order) values
('fnb-catchup:mod4',   'fnb-catchup', 'Mod 4',       0),
('fnb-catchup:mod5h2', 'fnb-catchup', 'Mod 5 (h2)',  1),
('fnb-catchup:mod8',   'fnb-catchup', 'Mod 8',       2),
('fnb-catchup:mod13h5','fnb-catchup', 'Mod 13 (h5)', 3)
on conflict (id) do nothing;
