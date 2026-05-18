# Finals Dashboard — Claude Code Guide

## Project overview

A live, mobile-friendly finals dashboard for Jacob Wasserman (Spring 2026).
Single HTML file + no build step. Data lives in Supabase; the page is hosted
on GitHub Pages. Checking a box on one device instantly syncs to all others
via Supabase Realtime.

**Live URL:** https://beginn3rer.github.io/finals-dashboard/
**Repo:** https://github.com/beginn3rer/finals-dashboard
**Local clone:** /Users/jacobwasserman/finals-dashboard/

## File map

```
index.html   — the entire app (CSS + HTML + JS, ~1900 lines)
schema.sql   — Supabase schema, RLS policies, and seed data (run once)
CLAUDE.md    — this file
```

There is no `node_modules`, no `package.json`, no build step. Everything runs
from the browser against the CDN-loaded Supabase JS client.

## Supabase

**Project URL:** https://mpwuwyxmfiosoeylxopy.supabase.co
**Publishable key:** sb_publishable_5vLlPrgF5cp_U5NCOJH4zw_xx5p3BYq
(This is the anon/public key — safe to be in source. Never commit the secret key.)

### Tables

**`tasks`** — one row per exam, HW assignment, or reminder
| column | type | notes |
|---|---|---|
| id | text PK | e.g. `env-econ`, `honors-paper` |
| type | text | `'exam'` \| `'hw'` \| `'reminder'` |
| course | text | e.g. `ECO 39556` |
| title | text | display name |
| notes | text | HTML allowed (bold, links) |
| due_date | timestamptz | deadline / window close |
| start_date | timestamptz | exam window open (exams only) |
| end_date | timestamptz | same as due_date for most exams |
| location | text | room or URL |
| color_var | text | CSS variable e.g. `var(--c-env-econ)` |
| tag | text | exam format string OR reminder tag label |
| urgency | text | `now`\|`today`\|`tonight`\|`tomorrow`\|`day`\|`week` (reminders) |
| completed | boolean | false by default |
| completed_at | timestamptz | set when completed |
| created_at | timestamptz | auto |
| sort_order | int | controls display order (lower = higher on page) |

**`task_items`** — prep checklist items (exams) and subtasks (HW)
| column | type | notes |
|---|---|---|
| id | text PK | format: `task_id:index` or `task_id:subtask-key` |
| task_id | text FK | references tasks(id) |
| label | text | display text |
| sort_order | int | order within the parent task |
| completed | boolean | false by default |
| completed_at | timestamptz | set when completed |

### How completion sync works

1. User checks a box → `toggle(bucket, id)` in JS
2. `toggle()` updates `state` (localStorage snapshot) and calls `syncCompletion()`
3. `syncCompletion()` does `sb.from('tasks').update({completed, completed_at}).eq('id', id)`
4. Supabase Realtime fires an `UPDATE` event on all subscribed clients
5. Other devices receive it via `subscribeRealtime()` → re-render automatically
6. A small green dot flashes in the top-right corner on the receiving device

Pomodoro timer and theme preference are localStorage-only (intentionally device-local).

## How to make common updates

### Change a deadline
Run in Supabase SQL Editor:
```sql
update tasks set due_date = '2026-05-21T12:00:00', end_date = '2026-05-21T12:00:00'
where id = 'macro';
```
The page reloads data on next open. Already-open pages won't auto-refresh
static fields (only completion state is realtime). Refresh the tab after data changes.

### Add a new exam
```sql
insert into tasks (id, type, course, title, notes, due_date, start_date, end_date,
                   location, color_var, tag, sort_order)
values (
  'new-exam-id', 'exam', 'COURSE 101', 'Exam Title',
  'Notes here. <strong>HTML allowed.</strong>',
  '2026-05-25T12:00:00', '2026-05-25T09:00:00', '2026-05-25T12:00:00',
  'Room or URL', 'var(--c-blue)', 'Format description', 6
);
-- Add prep items:
insert into task_items (id, task_id, label, sort_order) values
('new-exam-id:0', 'new-exam-id', 'First prep item', 0),
('new-exam-id:1', 'new-exam-id', 'Second prep item', 1);
```
After inserting, also add a color variable if needed (see CSS `:root` block in
`index.html` around line 30).

### Add a new HW item
```sql
insert into tasks (id, type, course, title, notes, due_date, color_var, sort_order)
values ('new-hw-id', 'hw', 'COURSE 101', 'Assignment Name',
        'Description here', '2026-05-25T23:59:00', 'var(--c-blue)', 5);
-- Optional subtasks:
insert into task_items (id, task_id, label, sort_order) values
('new-hw-id:part1', 'new-hw-id', 'Part 1', 0),
('new-hw-id:part2', 'new-hw-id', 'Part 2', 1);
```

### Add a reminder
```sql
insert into tasks (id, type, title, tag, urgency, sort_order)
values ('new-reminder', 'reminder', 'Reminder text here', 'Tag label', 'day', 5);
-- urgency options: now | today | tonight | tomorrow | day | week
```

### Change display order
`sort_order` (integer, lower = first) controls card order. Current values:

**Exams:** env-econ=1, ind-org=2, macro=3, money-bank=4, astro=5
**HW:** honors-paper=1, lab-hubble=2, fed-challenge=3, fnb-catchup=4
**Reminders:** cbam-deck=1, astro-prep=2, thursday-2x=3, macro-grind=4

```sql
update tasks set sort_order = 1 where id = 'ind-org';
update tasks set sort_order = 2 where id = 'env-econ';
```

### Mark something done/undone manually
```sql
update tasks set completed = true,  completed_at = now() where id = 'honors-paper';
update tasks set completed = false, completed_at = null  where id = 'honors-paper';
```

### Reset all completion state (nuclear option)
```sql
update tasks      set completed = false, completed_at = null;
update task_items set completed = false, completed_at = null;
```

## Editing index.html

The file has three sections in order: **CSS** (lines ~1–880), **HTML** (~882–1015),
**JavaScript** (~1015–end).

Key JS sections and their approximate line numbers:
- Supabase credentials: ~1020
- `loadFromSupabase()`: builds EXAMS/HW/REMINDERS arrays from DB rows
- `syncCompletion()`: writes checkbox state back to Supabase
- `subscribeRealtime()`: listens for cross-device changes
- `renderCards()`: renders exam cards (sorts by `sort_order`)
- `renderHW()`: renders HW items (sorts by `sort_order`)
- `renderReminders()`: renders the Critical section
- `renderProgressFooter()`: updates progress bars
- `renderNextUp()`: updates the hero countdown
- `init()`: async entry point — loads Supabase, renders everything, starts timers

**To add a new course color,** edit the `:root` block near the top of the CSS:
```css
--c-new-course: #your-color;
```
And add a dark-mode variant in `[data-theme="dark"]`.

## Deploying changes

GitHub Pages auto-deploys from the `main` branch. Workflow:
1. Edit `index.html` (and/or `schema.sql` if schema changed)
2. Commit and push:
```bash
cd /Users/jacobwasserman/finals-dashboard
git add index.html
git commit -m "describe what changed"
git push origin main
```
3. GitHub Pages rebuilds in ~60 seconds. The live URL updates automatically.

For Supabase data changes (deadlines, new tasks, etc.): run SQL directly in
the Supabase SQL Editor — no deploy needed, data is live immediately.

## Architecture decisions

| Decision | Reason |
|---|---|
| Single HTML file, no build | Works on GitHub Pages without CI/CD; editable anywhere |
| Static exam data in Supabase | Allows future editing without touching code |
| `sort_order` column controls display order | Deadline-sort caused IO to appear before Env Econ unexpectedly |
| Anon RLS policies (no login) | Personal use; adding auth would require login on each device |
| localStorage for pomo/theme | These should be device-local; no cross-device sync needed |
| Supabase Realtime on UPDATE only | INSERT/DELETE not needed for this use case |

## Credentials (do not commit new secrets)

The publishable key in `index.html` is intentionally public (it's the anon key).
Never put the Supabase **secret key** or **database password** in this repo.
