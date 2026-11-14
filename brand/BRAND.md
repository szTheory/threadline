# Threadline brand

Version 1.0, November 3, 2026. This is the complete text of the brand book (`threadline-brand-book.html`), page by page, for people and AI assistants. The same rules as structured data are in `brand.json`; colors and type values in `tokens.json`; every file is explained in `assets/README.md`.

**Read this first.** An audit trail library for Phoenix apps. Threadline records every insert, update and delete in your PostgreSQL database, so you can open any record’s history and see what changed, who changed it and when. Dark is the default theme and light is a full theme. The logo is the spool and the word together, with no shape behind it and no tagline. Every operation, status and masked value is a word first and a color second. The contrast pairs have stable ids (body, descriptor, caption, application-copy, hero, link, focus, artwork) in both themes.

## Brand at a glance

Follow what happened.An audit trail library for Phoenix apps. Threadline records every insert, update and delete in your PostgreSQL database, so you can open any record’s history and see what changed, who changed it and when.

### Color

**Paper** #F7F9FC **Card White** #FFFFFF **Ink** #0F1728 **Thread Blue Deep** #1557C0 **Hairline** #C9D3E2 **Stitch Blue** #4781E6, the thread in the logo

Insert Update Delete Redacted

### Type

Familjen Grotesk for the name and headlines, Geist for reading and tables, IBM Plex Mono for ids and code.

### Voice

A calm senior engineer walking you through what changed in your database, who changed it and when.

### Three rules

1. The name is Threadline: one word, capital T. In code it is `threadline`.
2. Never run the thread through the word, and never put a shape behind the spool.
3. Insert, Update, Delete and Redacted are always written out. Their semantic colors back up the word; they never replace it.

## Positioning and values

**An audit trail library for Phoenix apps. Threadline records every insert, update and delete in your PostgreSQL database, so you can open any record’s history and see what changed, who changed it and when.**

### Elixir and phoenix developers

Add an audit trail to my Phoenix app without rewriting it.

A setup that fits a normal Phoenix app: add `{:threadline, "~> 1.1.0"}`, run one migration that adds audit triggers to the tables they choose, and check which tables are audited.

### Support and admin staff

See who changed a record, what they changed and when.

One place, Threadline Admin, to filter changes by database table, person or job, and date, open a record’s full history and copy its id into a support ticket.

### Security and compliance reviewers

Find out whether Threadline records the changes we need to audit, and how we can review and export them.

A plain account of what is recorded, which personal data is redacted or left out, how long audit history is kept and how to export it, and no claim Threadline can’t back up.

**Plain**

Name what people look for: the database table, the record, what changed, who changed it and when. Not “evidence plane” or “posture”.

**Exact**

Show the real id, the real timestamp and the real value. An audit trail that rounds a number up or down, or sums up a change, is not a true record.

**Honest**

Say what Threadline records and what it does not. Never “tamper-proof”, “immutable” or “compliant”.

**Calm**

People open Threadline Admin when something has gone wrong. Be steady and brief.

**Yours**

Audit history lives in the host app’s own database, and the host app decides who can open Threadline Admin. Threadline’s name and logo are never shown to the host app’s customers.

## Messaging

### Elevator pitch

**Threadline is an audit trail library for Phoenix apps. It records every insert, update and delete in your PostgreSQL database, with who made each change and when, and adds Threadline Admin, where your team can follow what happened.**

### Key messages

**Every change, in order.**

A PostgreSQL trigger on each audited table records every insert, update and delete in the same transaction that saves it.

**Any record’s history.**

Open any record to see every change ever made to it, or see the record as it was at any point in the past.

**Your database, your access.**

Audit history is stored in your own PostgreSQL database. Threadline Admin runs inside your app, and you decide who can open it and how they sign in.

### Tagline

**Follow what happened.**

Sentence case, with the period. It sits beside the logo, never in it.

### About threadline: approved descriptions

One line: Hex, GitHub and package listings

An audit trail library for Phoenix that records every row change in PostgreSQL, so you can follow what happened.

Short: README opening, talk bios

Threadline is an open-source audit trail library for Elixir and Phoenix apps. It records each insert, update and delete in PostgreSQL, with who made it and when, and includes Threadline Admin, where your team can look up a record and see every change made to it, who made it and when.

Do not say

Tamper-proof, immutable, compliant, certified, “audit log”, “powerful”, “seamless”, “next-generation”. Threadline records changes; whether that meets a regulation is for your team to decide.

## The idea

**Why a spool of thread**

By default, a database keeps only a record’s current values. It doesn’t remember what a value was before, or who changed it. Threadline puts every change on one timeline, in order, each tied to its actor: a person, or a part of your system such as a background job.

The mark is a spool with its loose end running free. The wound thread is the history already recorded; the loose end is where you start pulling. The name is the instruction: follow the line.

The spool is built from a few plain parts: a round disc at each end (the flanges) in Ink, a barrel between them, and the Stitch Blue thread wound on it. Nothing in it is a lock, a shield or an eye. Threadline helps people find what happened; it does not guard or watch.

## Where the brand shows

**Full brand on Threadline’s own sites and packages. A quiet guest in your app.**

### Threadline’s own

**README, Hex page, docs site, social card**

Everyone who is deciding whether to use it.

**What shows.** The full lockup, Stitch Blue thread, both themes, code colors.

### Inside the host app

**Threadline Admin, at a path or subdomain the host app chooses**

Support and admin staff, inside the host app.

**What shows.** The lockup in the top bar, the semantic colors of Insert, Update, Delete and Redacted, and the type. A host app may replace the lockup with its own name and logo.

### In other people’s writing

**Blog posts, talks, newsletters, other READMEs**

People writing about Threadline.

**What shows.** The lockup, unchanged, with the rules in this book. Nothing added.

The host app’s customers never see Threadline: it is for the host app’s own team. The host app chooses where Threadline Admin runs and who can open it, and may put its own name and logo in the top bar in place of Threadline’s.

## Logo: on dark, the default theme

**One color.** Fog on Threadline Black. One color is the same drawing in a single color: the gaps between the end discs, the turns and the loose thread carry the form, so nothing is redrawn. Ink on light, Fog on dark.

**Mark.** The spool alone, for favicons and stickers. Where the name needs to show, use the lockup version instead.

**Drawn for small sizes.** Below 64 px the spool has its own simpler drawing: fewer turns of thread and wider gaps, so it still reads at small sizes, such as in a browser tab. The 16 and 32 px favicons use that simpler drawing, placed so its main edges land on whole pixels and its curves stay smooth. Below 16 px, do not use the mark.

**Dark is the default theme.** The logo has a version for each theme. On light, the spool’s end discs and the word are Ink; on dark, they are Fog. The thread is Stitch Blue on both. Use the version made for the background; do not make one by inverting the colors of the other. The spool and the word are one lockup. Do not rearrange them, resize one against the other or place the spool anywhere but at the left of the word.

## Logo: on light

**One color.** Ink on Paper. One color is the same drawing in a single color: the gaps between the end discs, the turns and the loose thread carry the form, so nothing is redrawn. Ink on light, Fog on dark.

**Mark.** The spool alone, for favicons and stickers. Where the name needs to show, use the lockup version instead.

**Drawn for small sizes.** Below 64 px the spool has its own simpler drawing: fewer turns of thread and wider gaps, so it still reads at small sizes, such as in a browser tab. The 16 and 32 px favicons use that simpler drawing, placed so its main edges land on whole pixels and its curves stay smooth. Below 16 px, do not use the mark.

**Light is a full theme.** The logo has a version for each theme. On light, the spool’s end discs and the word are Ink; on dark, they are Fog. The thread is Stitch Blue on both. Use the version made for the background; do not make one by inverting the colors of the other. The spool and the word are one lockup. Do not rearrange them, resize one against the other or place the spool anywhere but at the left of the word.

## Mark and favicon

**A simpler spool for small sizes.**

Below 64 px the spool has its own simpler drawing: fewer turns of thread and wider gaps, so it still reads at small sizes, such as in a browser tab. The 16 and 32 px favicons use that simpler drawing, placed so its main edges land on whole pixels and its curves stay smooth. Below 16 px, do not use the mark.

The browser tab follows the theme: `favicon.svg` draws the spool in Ink on a light device and in Fog on a dark one. The `.ico` is the light drawing only, because an ICO can’t change with the theme.

## Clear space and minimum size

Keep clear space on every side equal to a quarter of the lockup’s height, measured from the outermost edge of the lockup. Nothing enters it: no text, edge or other logo. The square is that quarter.

### On screenshots and photographs

- Place the lockup on a calm area at least as wide as the lockup and its clear space.
- Use the light drawing on a light area and the dark drawing on a dark one. If neither reads well, move the logo.
- Do not put a shape or a shadow behind it to make it read.

### Minimum size

|   | Screen | Print |
| --- | --- | --- |
| **Lockup** | 96 px wide | 25 mm wide |
| **Mark, drawn for its size** | 16 px | Not specified |

On screen, the lockup is never narrower than 96 px and the mark never smaller than 16 px. In print, never narrower than 25 mm.

### Retired

The arch mark is retired. It was an earlier attempt at a Threadline logo: an arc over a bar, and an arc between the d and the l in the wordmark. This edition replaces it with the spool, so do not use it. It read as a padlock shackle, a magnet or a staple, which is the wrong promise for an audit trail library.

## Logo: misuse

✕Don’t stretch, squeeze or rotate the lockup.

✕Don’t recolor the thread or the word, or use Thread Blue for the thread.

✕Don’t put a tile, badge or any other shape behind the spool.

✕Don’t add the tagline, the descriptor or any text to the lockup.

✕Don’t run a line through the word, or draw the thread through the letters.

✕Don’t use the dark drawing on a light page, or the light drawing on a dark one.

## Color: dark, the default

**Threadline Black**

#0B1020 RGB 11 16 32

The default background. Dark is the default theme.

About 62% of a dark screen.

**Graphite**

#141B2D RGB 20 27 45

Rows, cards and panels on Threadline Black.

About 24% of a dark screen.

**Fog**

#D7DEEA RGB 215 222 234

Text on dark, and the lockup on dark.

About 8% of a dark screen.

**Thread Blue**

#4F8CFF RGB 79 140 255

Links, focus rings, selection and the main button on dark.

About 3% of a dark screen.

**Slate Line**

#23304A RGB 35 48 74

Dividing lines on dark.

About 3% of a dark screen.

**Stitch Blue**

#4781E6 RGB 71 129 230

The thread in the logo, on light and on dark. Never for text, links or controls: Thread Blue and Thread Blue Deep do that work.

**Steel Lift**

#A3AFC2

Secondary text on Threadline Black and Graphite.

**Steel**

#73819C

Input and button borders on dark (4.4:1 on Graphite).

## Color: light

**Paper**

#F7F9FC RGB 247 249 252

The light background.

About 64% of a light screen.

**Card White**

#FFFFFF RGB 255 255 255

Rows, cards and panels on Paper.

About 22% of a light screen.

**Ink**

#0F1728 RGB 15 23 40

Text on light, and the lockup on light.

About 8% of a light screen.

**Thread Blue Deep**

#1557C0 RGB 21 87 192

Links, focus rings, selection and the main button on light.

About 3% of a light screen.

**Hairline**

#C9D3E2 RGB 201 211 226

Dividing lines on light.

About 3% of a light screen.

**Stitch Blue**

#4781E6 RGB 71 129 230

The thread in the logo, on light and on dark. Never for text, links or controls: Thread Blue and Thread Blue Deep do that work.

**Slate Text**

#56647E

Secondary text on Paper and Card White.

**Control Edge**

#76849F

Input and button borders on light (3.6:1 on Paper). Dark uses Steel at #73819C.

## Color: accents and operations

### Semantic colors

**Each kind of change has its own color.**

Insert, Update, Delete and Redacted are always written out. Their semantic colors back up the word; they never replace it.

Insert, Update and Delete are the three kinds of change. Redacted marks a value that was replaced before it was stored. In a timeline, the colored word is how a long list is scanned. The word always says what happened.

### Accent colors

Accents are not semantic colors. They don’t mean insert, update, delete or redacted. Each one points at one kind of thing, so the eye can find it.

**Signal Cyan**

Light #0B6F67 Dark #4EDFD1

The correlation id: one id shared by every change made in the same request or background job.

**Iris**

Light #5B49D6 Dark #8A7CFF

Keywords in code and the selected saved view in a list of changes. Never a status.

Use an accent only for the thing it marks, never as decoration, so it keeps its meaning.

## Color: contrast pairs

| Role | Where it is used | Light | Dark | Minimum |
| --- | --- | --- | --- | --- |
| **Body text** | README, docs, Threadline Admin and this book. | Aa16.97:1 | Aa14.00:1 | 4.5:1 |
| **Descriptor and secondary text** | The words “audit trail library” beside the logo, and metadata under a title. | Aa5.66:1 | Aa8.54:1 | 4.5:1 |
| **Caption and table metadata** | Captions, timestamps and column labels on a card or row. | Aa5.97:1 | Aa7.73:1 | 4.5:1 |
| **Copy inside an application** | Text on a card in Threadline Admin, the README or a slide. | Aa17.90:1 | Aa12.68:1 | 4.5:1 |
| **Display accent** | A large headline word or figure in the accent. 24 px and up. | Aa6.31:1 | Aa5.89:1 | 3:1 |
| **Link** | Links in running text and the main button’s edge. | Aa6.65:1 | Aa5.33:1 | 4.5:1 |
| **Focus ring** | The 2 px ring on a focused control. | 6.31:1 | 5.89:1 | 3:1 |
| **Logo thread** | Stitch Blue against the page, read as a shape, not as text. | 3.59:1 | 5.00:1 | 3:1 |

### About these ratios

Ratios are WCAG 2.2 contrast, computed from the hex values. A pair that passes here says nothing about a whole product built with it. Stitch Blue on Paper is 3.6:1: enough for a shape, not for text. Hairline and Slate Line only divide space and are never used for text.

### Never

- **Stitch Blue** as text of any size on Paper or Card White
- **Slate Line** as the only boundary of a control
- **Thread Blue** as text on Paper or Card White (use Thread Blue Deep)
- **Thread Blue Deep** as text on Threadline Black (use Thread Blue)

## Type

SemiBold (600) for the name and headlines; Regular (400) never for display.

The wordmark, headlines in books, slides and social cards, and page titles in docs.

The wordmark is outlined using this typeface, and headlines set in it match the logo. Narrow and plain, with flat shoulders, it reads as an engineering tool.

Regular (400), Medium (500) and SemiBold (600).

Body text, Threadline Admin, tables, buttons and labels.

Chosen for dense audit tables: tabular numerals so timestamps and counts align, and plain letterforms that hold at 13 px. Threadline Admin already uses it.

Regular (400) and Medium (500).

Anything copied or compared: ids, database table and field names, commands and code.

Every character is distinct (0 and O, 1 and l), narrow enough to fit a UUID in a table column. It is the monospace face Threadline Admin already uses.

All three families are SIL Open Font License 1.1, from Google Fonts. The license texts are in the assets fonts folder.

## Type: the hierarchy

- Display: Familjen Grotesk 600, 56 px on 59 px, tracking -0.015em. Use: Covers, slides and social cards. One line, two at most.
- Heading: Familjen Grotesk 600, 28 px on 34 px, tracking -0.01em. Use: Page titles and section heads in docs and Threadline Admin.
- Body: Geist 400, 16 px on 25 px, tracking 0. Use: README, docs and paragraphs in Threadline Admin. 62 to 72 characters a line.
- Dense text: Geist 400, 13 px on 18 px, tracking 0. Use: Lists of changes in Threadline Admin. Always with tabular numerals.
- Label: Geist 600, 12 px on 14 px, tracking 0.12em, capitals. Use: Navigation groups and column heads. Capitals only at this size and weight.
- Code and ids: IBM Plex Mono 400, 13 px on 20 px, tracking 0. Use: Ids, table and field names, commands. Don’t wrap an id: shorten it in the middle. Clicking it copies the whole id.

## Type: in a dense table

13 px Geist with tabular numerals; ids and names in 13 px IBM Plex Mono. The field counts line up by digit.

### Made for tables people read closely

- Figures in a column use tabular numerals (`font-variant-numeric: tabular-nums`) so digits stack.
- Every id, table name and field name is set in IBM Plex Mono, so it can be compared by eye.
- Shorten a long id in the middle, never at the end. Clicking an id copies the whole id and shows a short “Copied to clipboard” message; the id itself never moves or changes.
- Headlines are sentence case. Capitals appear only in 12 px labels.
- No type is lighter than 400 or smaller than 12 px.

## Voice: the tone dial

**A calm senior engineer walking you through what changed in your database, who changed it and when.**

- Threadline Admin: errors and empty states: 0 of 4 toward lively. “No changes match these filters. Try a wider date range or clear a filter.”
- Docs and README: 1 of 4 toward lively. “Add audit triggers to the tables you choose, run the migration, then check which tables are audited.”
- Release notes: 1 of 4 toward lively. “A record’s history can now show the record as it was at any point in the past.”
- Talks and social posts: 2 of 4 toward lively. “Somebody changed that record on Tuesday. Here is how to find out who.”

The voice never changes; the tone shifts with where the words appear. Threadline stays plain everywhere and gets only a little looser in a talk or a post. It is never loose where something has gone wrong, because people open Threadline Admin when they need an answer.

## Voice: this, not that

- Say: “Open a record’s history.” Not: “Leverage our powerful audit platform.”
- Say: “See who changed this record, and when.” Not: “Gain visibility into user activity.”
- Say: “Threadline records every change to the tables you choose.” Not: “Threadline makes your data tamper-proof.”
- Say: “Redacted: the value was replaced with [REDACTED].” Not: “The value is obfuscated for compliance.”
- Say: “Check which tables are audited.” Not: “Verify your audit posture.”
- Say: “Delete history older than your retention period.” Not: “Purge your audit log.”
- Say: “No changes match these filters. Try a wider date range.” Not: “Oops! We couldn’t find anything.”
- Say: “Export this record’s history as JSON.” Not: “Generate your compliance evidence pack.”

### Write for the people reading

- **Write for support staff who don’t read code.** Name the database table, who made the change and when, before any id.
- **Say what they can do next.** Every empty and error state ends with a next step.
- **Spell out the time zone.** Write “7:08 PM UTC”, never a bare time.

## How to write our name

**Threadline**

Threadline, one word with a capital T, in running text. In code, packages and commands it is `threadline`, `:threadline` and `mix threadline.install`.

### Not like this

- ~~ThreadLine, Thread Line~~: one word, one capital
- ~~THREADLINE~~: except as a 12 px label in capitals
- ~~threadline~~: in running text (code only)
- ~~the Threadline platform~~: Threadline is a library

### Describing it

Call it an “audit trail library”. Call what people read “history”.

## Key terms

**The words Threadline depends on.**

| Term | What it means here | Instead of |
| --- | --- | --- |
| **Audit trail** | The category: the recorded history of changes. “Log” suggests text logs. | ~~audit log~~ |
| **History** | What you read in Threadline Admin: every change to a record, in order. | ~~evidence~~, ~~proof~~ |
| **Record** | One row in a database table, such as one support ticket. Say “row” only in SQL terms. | ~~entity~~, ~~object~~ |
| **Change** | One insert, update or delete of one record. | ~~event~~, ~~activity~~ |
| **Transaction** | The changes your app saved together, in one database transaction. | ~~audit transaction~~ |
| **Action** | What your app says it did, such as `ticket_replied_and_closed`. | ~~intent~~ |
| **Actor** | Who made the change: a person, a service account or a job. | ~~principal~~, ~~actor ref~~ |
| **Redacted** | A value replaced with `[REDACTED]` before it is stored. A field left out is not recorded at all. | ~~masked~~, ~~obfuscated~~, ~~scrubbed~~ |
| **Audited table** | A database table with a Threadline trigger, so its changes are recorded. | ~~covered~~, ~~coverage~~, ~~posture~~, ~~drift~~ |
| **Retention period** | How long audit history is kept before it is deleted. | ~~purge~~, ~~prune~~ |
| **Host app** | The Phoenix app that uses Threadline. Its database holds the audit history. | ~~reader~~, ~~consumer~~, ~~parent app~~ |
| **Threadline Admin** | The admin UI Threadline adds to the host app, at a path it chooses. | ~~operator surface~~, ~~the /audit pages~~ |

These are only the words the brand depends on; the product docs define the rest.

## Imagery: the real thing

**Show the real thing.**

Threadline’s pictures show the product at work, with its real labels: a timeline of changes, one record’s history and a command. They need no stock photography.

The product pictures in this book are illustrations drawn from the product’s real labels and structure. They show the layout this book recommends, not screenshots of the current product, and the data in them is invented.

### Never

**Also never:** fingerprints, police tape, server racks and node clouds, stock people at screens, neon grids and glowing data.

Threadline helps people find what happened. These pictures say it guards, watches or certifies, and Threadline does none of those.

## Imagery: code colors

**Quiet code colors that never look like a status.**

| Role | Light | Dark | Colors |
| --- | --- | --- | --- |
| **Text** | #0F1728 | #D7DEEA | Names and punctuation. Module names in weight 600. |
| **Comment** | #56647E | #8F9DB5 | Comments, in a quiet slate. |
| **Keyword** | #5B49D6 | #8A7CFF | def, do, end, fn, SELECT. Iris. |
| **String** | #9C2F6B | #F0A6C8 | A muted rose, kept apart from the status colors. |
| **Atom, key and number** | #1D4FA8 | #8DB4FF | Atoms, keys, numbers and SQL names. |
| **Command and flag** | #0B6F67 | #4EDFD1 | The prompt, commands and flags, in Signal Cyan. |
| **Code background** | #EEF3FA | #080D1B | Behind every code block. |

- No status colors in code: no green, amber or red, so nothing in code looks like an insert, a delete, a redacted value or a changed field.
- Module names and function heads stand out by weight (600), not by another color.
- Syntax colors are for code blocks only. Inline code in a sentence is plain IBM Plex Mono on a chip, in every medium.
- Use these colors where Threadline styles code: slides, social cards, blog posts and screenshots. GitHub and ExDoc color their own code; leave that alone.
- Show code that matches the current release, not pseudo-code.

# mix.exs ⏎ {:threadline, "~> 1.1.0"} ⏎ ⏎ # when your app saves a change ⏎ opts = [audit_context: ctx, action: :post_created_via_api] ⏎ Threadline.Audit.transaction(Repo, opts, fn -> ⏎ Repo.insert!(changeset) ⏎ end)

$ mix threadline.gen.triggers --tables posts ⏎ $ mix ecto.migrate ⏎ $ mix threadline.verify_coverage

SELECT table_name, captured_at ⏎ FROM audit_changes ⏎ WHERE table_name = 'posts' ⏎ ORDER BY captured_at DESC;

## Graphic elements

**One line that connects things: the thread.**

The thread is the brand’s only graphic device. It is a thin Stitch Blue line that links items in order, the way a history links changes. It is used sparingly, and only where it links one item to the next.

- **The thread line.** A 2 px Stitch Blue vertical line with a small knot at each item, and no curl at the end. It joins the changes in one record’s history, or the steps on a docs page. Entries start on one grid, so the words beside each operation line up.
- **The loose end.** The thread’s last stretch: the line lifts slightly and ends in a flat cut, as the logo’s thread does leaving the spool. It closes the divider under a page header or a banner, once.

The thread never runs through text, never loops decoratively, never fills a background and never replaces the logo. One thread line per view.

## Themes: dark, light and system

**Dark is the default. Light is complete. System follows the device.**

### Dark, the default

Threadline Black behind Graphite rows, Fog text, Thread Blue links. The default for Threadline Admin and this book.

### Light

Paper behind Card White rows, Ink text, Thread Blue Deep links. Every text and background pair is contrast-checked.

### System

The page follows the device’s setting from the moment it loads, and the logo uses the drawing for whichever theme is showing. Choosing a theme applies it at once, with no confirm button.

## Applications: Threadline Admin

Threadline Admin’s timeline, in dark. The lockup is in the top bar, and each change names its operation in a colored word. Ids are in IBM Plex Mono, shortened in the middle, and every time has its time zone. An illustration of the layout this book recommends, using the product’s real labels.

### What carries the brand

The lockup in the top bar, the operation words and their colors, and the type: Geist for reading, IBM Plex Mono for every id.

### What stays the host app’s

Where Threadline Admin runs (a path or subdomain), who can open it and how they sign in. A host app may put its own name and logo in the top bar instead of Threadline’s.

### What never changes

The operation named in words, not only in color; a time zone on every time; ids in IBM Plex Mono that copy when clicked.

## Applications: one transaction



## Applications: README and docs

The README: the lockup on Paper, the descriptor and tagline as plain text under it, never inside it. The dark lockup goes in a `picture` element for GitHub’s dark theme.

The docs site: the lockup in the sidebar (the docs generator’s `logo` option). The generator keeps its own code colors; leave them alone.

### Package listing

An audit trail library for Phoenix that records every row change in PostgreSQL, so you can follow what happened.

### Readme first screen

The lockup, the descriptor, then the install snippet. No badges row above the lockup.

### Docs site

The lockup in the sidebar and the favicon in the tab. The generator’s own colors for everything else.

## Applications: link preview and terminal

The link preview, 1280 by 640 px: the one full-bleed dark canvas, because a preview has no page behind it. The headline sits beside the lockup, never in it.

The terminal, in the code colors: the command and its flags in Signal Cyan, output in Fog. Output is plain words, with no status color. The output is illustrative.

### Link preview

One canvas, 1280 by 640: the lockup at left, the tagline set as a headline, the descriptor under it. No thread line, no screenshot.

### Terminal and slides

The code colors, on the code background. The commands are ones Threadline really provides. The output is plain words, with no status colors.

### Not made yet

An avatar or an app icon, which needs an opaque square. The logo files have no background shape.

## Brand assets: which file to use

| You need | Use (in assets/) |
| --- | --- |
| Logo on a light background | `logo/threadline-lockup-light.svg` `logo/threadline-mark-light.svg` `logo/threadline-lockup-light-2048.png` |
| Logo on a dark background | `logo/threadline-lockup-dark.svg` `logo/threadline-mark-dark.svg` `logo/threadline-lockup-dark-2048.png` |
| One color: print and single-color jobs | `logo/threadline-lockup-mono-ink.svg` `logo/threadline-lockup-mono-fog.svg` `logo/threadline-mark-mono-ink.svg` `logo/threadline-mark-mono-fog.svg` |
| Favicon and small sizes | `icon/favicon.svg` `icon/favicon-light.svg` `icon/favicon-dark.svg` `icon/favicon.ico` `icon/favicon-32-light.png` `icon/favicon-16-light.png` |
| Link preview and social card | `social/threadline-social-card-1280x640.png` |
| Fonts | `fonts/web/fonts.css` `fonts/variable/FamiljenGrotesk[wght].ttf` `fonts/variable/Geist[wght].ttf` `fonts/static/IBMPlexMono-Regular.ttf` `fonts/OFL-FamiljenGrotesk.txt` |

### Retired with version 1.0

- The earlier arch mark and the arc between the d and the l, replaced by the spool.
- The Thread Blue logo in the product: the logo thread is Stitch Blue.
- The tagline inside a lockup.
- The words “audit platform”, “evidence plane”, “operator surface”, “audit log”, “masked” and “Find, Verify, Prove”.

## Contact, approval and legal

**Who to ask, and what’s ours.**

### Contact and approval

- Questions about the brand and requests to use it: the Threadline maintainers, through the project’s issue tracker.
- Approval: the maintainers approve any use that changes the logo or colors; unchanged use under these rules needs no approval.

### Use by others

- Hex packages, blogs, newsletters and conference sites may use the lockup unchanged to refer to Threadline.
- Do not use it to suggest that Threadline endorses, certifies or audits another product.
- Do not alter the logo, or build a new logo that uses the spool.

### Legal

- Threadline is released under the MIT license. The logo and this brand book are covered by the same license unless the repository says otherwise.
- No trademark registration is claimed in this book, and none was searched. Use ™, not ®, only if the maintainers decide to claim the name.
- Fonts are SIL Open Font License 1.1; their license texts ship in the assets folder.

### Revision history

**Version 1.0**, November 3, 2026. First edition of this brand book. The mark is a spool of thread, drawn from the name; the arch mark that came before it is retired. Adds a complete light theme, code colors, contrast pairs and the applications.

## Considered and not needed

**Mascot**

Considered, not proposed. An audit trail library is trusted for being exact and calm, and a character pulls the other way.

**Patterns and textures**

The thread is the only graphic device. A pattern would compete with dense tables, where the data is the picture.

**Stock photography**

There is no honest photograph of “what happened in a database”. Real product pictures say it better.

**A second typeface for the logo**

The wordmark and the headlines are both set in Familjen Grotesk, so no other display face is needed.

**Brand-colored tables**

In a dense table the data should carry the color. Rows stay on Graphite or Card White; color marks only the operation word.

**Logo animation and sound**

Not defined in this edition. The brand has no motion or sound rules yet; see To review.

## To review

**Choices made in this edition that are easy to change**

1. **Terms are a working vocabulary.** Key terms (record, redacted, audited table, host app, Threadline Admin) are recommendations for the product’s own words too. Tell the maintainers which to change.
2. **The logo blue is Stitch Blue everywhere.** The product draws its logo with the accent color. This book states the rule; the product’s logo component would need to change.
3. **Light-theme values come from the product’s light mode.** Thread Blue Deep, Card White and Hairline were read from the product at the time of writing. Slate Text is new in this book and was never in the product.
4. **No motion and no sound yet.** The logo has no animation and the brand has no sound. Both are possible next editions; neither is required to use this identity.
5. **An opaque square icon is not made.** GitHub organization avatars and some platform icons need an opaque square. The logo files have no background shape, so the choice is left open.
6. **How people sign in, and the Admin logo.** This book says the host app decides who can open Threadline Admin and how they sign in (its own login, single sign-on or a set username and password), and that a host app may replace the lockup with its own name and logo. The product lets the host app authorize access; it documents no logo setting, so that would need to be built.
7. **Threadline Admin is a new name.** The product calls its UI the operator surface and mounts it at `/audit` in its examples. This book names it Threadline Admin; the product would need to follow.

**Not checked:** Name and trademark clearance were not searched; the name was kept. Code samples follow the README and were not run. Logo legibility was checked on one test sheet, not with people. Contrast is computed for the pairs listed here, not for a whole product. Print color was not proofed.
