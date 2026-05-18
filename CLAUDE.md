# Finals Dashboard — Claude Code Cowork Guide

This file is written for Claude Code. When Jacob opens a session on this repo,
read this file first, run the orientation steps, then wait for his request.

---

## Who this is for

**Jacob Wasserman** — undergraduate econ/astro student at Hunter/BMCC.
This is his live finals-week dashboard. It tracks exams, homework, and reminders
across his phone and iPad in real time via Supabase.

---

## Orientation (do this at the start of every session)

```bash
cd /Users/jacobwasserman/finals-dashboard
git status          # make sure working tree is clean
git pull origin main  # get any remote changes first
```

Then read the current state of `index.html` if the request involves code changes.
For data-only changes (deadlines, new tasks), you only need the SQL snippets below.

---

## Project snapshot

| Thing | Value |
|---|---|
| Live URL | https://beginn3rer.github.io/finals-dashboard/ |
| Repo | https://github.com/beginn3rer/finals-dashboard |
| Local path | /Users/jacobwasserman/finals-dashboard/ |
| Stack | Single `index.html` — CSS + HTML + JS. No build step, no npm. |
| Database | Supabase (Postgres). Project: `mpwuwyxmfiosoeylxopy.supabase.co` |
| Hosting | GitHub Pages, auto-deploys from `main` branch |
| Auth | None — anon RLS policies, personal use only |

**Files:**
```
index.html   — the entire app (~1900 lines: CSS → HTML → JS)
schema.sql   — Supabase schema + seed SQL (already run; keep for reference)
CLAUDE.md    — this file
```

---

## Supabase credentials (safe to use, never replace with secret key)

```
URL:  https://mpwuwyxmfiosoeylxopy.supabase.co
KEY:  sb_publishable_5vLlPrgF5cp_U5NCOJH4zw_xx5p3BYq
```

These are already wired into `index.html`. Only change them if the project is recreated.

---

## What Jacob typically asks for

### "Update [exam/hw] date/time"
Run SQL directly in Supabase SQL Editor (no code change needed):
```sql
-- Change a deadline
update tasks
set due_date = '2026-05-21T14:00:00', end_date = '2026-05-21T14:00:00'
where id = 'astro';

-- Change an exam window open time
update tasks set start_date = '2026-05-18T08:00:00' where id = 'ind-org';
```
Tell Jacob to refresh the page after — data changes are live immediately but
already-open tabs don't auto-reload static fields (only checkboxes are realtime).

### "Add a reminder"
```sql
insert into tasks (id, type, title, tag, urgency, sort_order)
values ('reminder-id', 'reminder', 'Reminder text here', 'Tag label', 'day', 5);
```
`urgency` controls the color: `now` (green) · `today`/`tonight` (red) · `tomorrow` (orange) · `day` (amber) · `week` (blue)

### "Add a new exam"
```sql
insert into tasks (id, type, course, title, notes, due_date, start_date, end_date,
                   location, color_var, tag, sort_order)
values (
  'exam-id', 'exam', 'COURSE 101', 'Exam Title',
  'Notes here. <strong>HTML ok.</strong>',
  '2026-05-25T12:00:00',   -- deadline
  '2026-05-25T09:00:00',   -- window opens
  '2026-05-25T12:00:00',   -- window closes (usually = deadline)
  'Location or URL', 'var(--c-blue)', 'Format e.g. 40 MC', 6
);
-- Prep checklist items (optional):
insert into task_items (id, task_id, label, sort_order) values
('exam-id:0', 'exam-id', 'First prep step', 0),
('exam-id:1', 'exam-id', 'Second prep step', 1);
```

### "Add a homework item"
```sql
insert into tasks (id, type, course, title, notes, due_date, color_var, sort_order)
values ('hw-id', 'hw', 'COURSE 101', 'Assignment Name',
        'Notes here', '2026-05-25T23:59:00', 'var(--c-blue)', 5);
-- Optional subtasks:
insert into task_items (id, task_id, label, sort_order) values
('hw-id:part1', 'hw-id', 'Part 1', 0),
('hw-id:part2', 'hw-id', 'Part 2', 1);
```

### "Change the order cards appear"
`sort_order` (int, lower = higher on page) controls card sequence.

Current order:
- **Exams:** env-econ=1, ind-org=2, macro=3, money-bank=4, astro=5
- **HW:** honors-paper=1, lab-hubble=2, fed-challenge=3, fnb-catchup=4
- **Reminders:** cbam-deck=1, astro-prep=2, thursday-2x=3, macro-grind=4

```sql
update tasks set sort_order = 1 where id = 'new-priority-exam';
update tasks set sort_order = 2 where id = 'other-exam';
```

### "Mark X as done/undone"
```sql
-- Done:
update tasks set completed = true,  completed_at = now() where id = 'task-id';
-- Undo:
update tasks set completed = false, completed_at = null  where id = 'task-id';
-- Undo a prep item:
update task_items set completed = false, completed_at = null where id = 'env-econ:0';
```

### "Reset everything" (nuclear)
```sql
update tasks      set completed = false, completed_at = null;
update task_items set completed = false, completed_at = null;
```

### "Change a note / fix text on a card"
```sql
update tasks set notes = 'New note text. <strong>HTML ok.</strong>' where id = 'astro';
update tasks set title = 'New title' where id = 'env-econ';
update tasks set location = 'New room' where id = 'money-bank';
```

### "Fix something visual / add a feature"
Edit `index.html` directly. Structure:
- **CSS:** lines ~1–880 (`:root` color vars, component styles)
- **HTML:** lines ~882–1015 (layout, static elements)
- **JavaScript:** lines ~1017–end

Key JS functions:
```
loadFromSupabase()    — fetches tasks + task_items, builds EXAMS/HW/REMINDERS arrays
syncCompletion()      — writes checkbox toggle back to Supabase
subscribeRealtime()   — listens for cross-device changes, re-renders on UPDATE
renderCards()         — exam cards, sorted by sort_order
renderHW()            — HW items, sorted by sort_order
renderReminders()     — Critical section reminders
renderProgressFooter()— progress bars + motivational line
renderNextUp()        — hero countdown to next deadline
init()                — async entry point; calls all of the above
```

After editing `index.html`, deploy:
```bash
git add index.html
git commit -m "brief description of change"
git push origin main
```
GitHub Pages rebuilds in ~60 seconds.

---

## Course roster (for context)

| ID | Course | Color var |
|---|---|---|
| `env-econ` | ECO 39556 — Environmental Economics | `--c-env-econ` (green) |
| `ind-org` | ECO 245H — Industrial Organization | `--c-ind-org` (violet) |
| `macro` | ECO 201 — Macroeconomics | `--c-macro` (blue) |
| `money-bank` | ECO 250H — Money & Banking | `--c-money-bank` (orange) |
| `astro` | ASTRO 110 — Astronomy | `--c-astro` (blue) |

To add a new course color, add to the `:root` block and the `[data-theme="dark"]`
block near the top of `index.html`:
```css
--c-new-course: #16a34a;   /* light mode */
/* in [data-theme="dark"]: */
--c-new-course: #4ade80;   /* dark mode */
```

---

## Hard rules — do not violate these

- **No build step.** No `npm install`, no bundler, no `package.json`. Everything
  must run as a plain HTML file loaded directly in a browser.
- **Single file.** Keep all CSS, HTML, and JS in `index.html`. Do not split into
  separate files unless Jacob explicitly asks.
- **No auth.** Do not add Supabase Auth or any login flow without being asked.
  The anon RLS policy is intentional.
- **No framework.** No React, Vue, Alpine, etc. Vanilla JS only.
- **Preserve the design.** Jacob's CSS is carefully tuned. Don't touch color
  variables, font sizing, or layout unless the request is specifically visual.
- **Never commit secrets.** The publishable key is fine. Never add the Supabase
  secret key or database password to any file.
- **Always pull before pushing.** Run `git pull origin main` before any commit
  to avoid rejected pushes.

---

## How completion sync works (for debugging)

1. User checks a box → `toggle(bucket, id)` updates local `state` + calls `syncCompletion()`
2. `syncCompletion()` → `sb.from('tasks').update({completed, completed_at}).eq('id', id)`
3. Supabase broadcasts an UPDATE event to all subscribed clients
4. `subscribeRealtime()` receives it → calls `applyTaskUpdate()` or `applyItemUpdate()` → re-renders
5. A green dot flashes top-right on the receiving device

If realtime isn't working: check Supabase → Database → Replication — `tasks`
and `task_items` must both be toggled on.

---

## Deploy checklist (if something seems broken)

1. Is the SQL schema applied? (Supabase → Table Editor — do `tasks` and `task_items` exist?)
2. Is Realtime enabled? (Supabase → Database → Replication — both tables toggled?)
3. Is GitHub Pages on? (repo → Settings → Pages → Source: main, folder: /)
4. Did the push go through? (`git log origin/main` should show your latest commit)
5. Hard-reload the page (`Cmd+Shift+R`) — Pages caches aggressively
