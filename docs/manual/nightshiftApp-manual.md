# NightShift App — User Manual

NightShift App is a macOS app that helps you keep track of important dates, monitor
countdown timers, and store text you need to access repeatedly. Three tabs at the top
of the window give you access to each function.

---

## Tab Bar

The tab bar sits at the top of the window. The active tab is highlighted with a filled
dark circle behind the icon.

| Icon | Tab | Purpose |
|------|-----|---------|
| Clock | **Calculate** | Compute the difference between two points in time |
| @ | **Countdown** | Manage a list of named countdown slots |
| Quote | **Snippets** | Store and copy reusable text snippets |

---

## Calculate Mode

Calculate mode computes the exact time difference between a FROM and a TO date.

### Date steppers

Two rows of steppers are shown: **FROM** and **TO**. Each row has five components:
YEAR, MON, DAY, HOUR, MIN — each with an up and a down chevron button.

- **Single click** moves the value by one step.
- **Click and hold** repeats automatically after a short delay for fast navigation.

The app remembers the last FROM and TO values when you close and reopen it.

### Reset buttons

- **RESET FROM NOW** — sets the FROM date to the current moment.
- **RESET TO NOW** — sets the TO date to the current moment.


### Result display

Below the steppers the app shows the time difference as days, hours, minutes, and seconds.
A toggle button switches between two display modes:

- **DAYS** — total elapsed or remaining days (e.g. "142 days").
- **CAL** — calendar-aware breakdown: years, months, and days as separate values.

The toggle state is remembered across launches.

<!-- group -->
![Calculate View – DAYS mode: total elapsed days between two dates](../../screenshots/01 Calculate View - Calculated Days.png)
*Calculate View in DAYS mode — the result is shown as a single total day count.*
![Calculate View – CAL mode: calendar breakdown into years, months, and days](../../screenshots/01b Calculate View - Calculated Epochs.png)
*Calculate View in CAL mode — the same interval broken down into years, months, and days.*
<!-- /group -->

---

### Named Deadlines

The **SAVE** button (bookmark icon) lets you store the current TO date under a custom name
so you can reload it later without re-entering the date manually.

#### Saving a deadline

1. Set the TO date to the target date.
2. Click the **bookmark icon** (left part of the SAVE button). A sheet slides open.
3. Type a name for this deadline and click **SAVE**. The deadline is stored.

<!-- group -->
![Save Named Deadline sheet – empty name field ready for input](../../screenshots/02 Calculate View - Save Named Duration - empty.png)
*The Save sheet opens with an empty name field. Type a name and click SAVE.*
![Save Named Deadline sheet – name field filled in, ready to save](../../screenshots/02b Calculate View - Save Named Duration - edit.png)
*A deadline name has been entered. SAVE stores it; CANCEL discards the sheet.*
<!-- /group -->


#### Viewing saved deadlines

Click the **chevron (▾)** on the right side of the SAVE button. A popover lists all
saved deadlines with their names and dates.

- **Tap a row** to open its detail sheet.

![Saved Named Deadlines popover – list of stored deadlines](../../screenshots/03 Calculate View - Saved Named Durations.png)

*The deadline list popover shows all saved deadlines. Tap any row to open its detail sheet.*

#### Deadline detail sheet

The detail sheet shows the deadline name and date. From here you can:

- **LOAD AS TO** — copies the deadline date into the TO stepper.
- **Pencil icon** — opens rename mode: the name becomes an editable field.
  Type the new name and click **RENAME** to confirm, or **CANCEL** to discard.
- **Trash icon** — deletes the deadline permanently. A confirmation dialog appears;
  click **Delete** to confirm or **Cancel** to abort.

![Deadline detail sheet – name, date, and action buttons](../../screenshots/03b Calculate View - Saved Named Durations Details.png)

*The detail sheet shows the deadline name and date. LOAD AS TO, rename (pencil), and delete (trash) are available.*

<!-- group -->
![Deadline rename mode – inline name editing with RENAME and CANCEL](../../screenshots/03c Calculate View - Edit Saved Named Durations.png)
*Rename mode: the name becomes an editable text field. Click RENAME to confirm or CANCEL to discard.*
![Deadline delete confirmation dialog](../../screenshots/03d Calculate View - Delete Saved Named Durations.png)
*A confirmation dialog appears before permanent deletion. Click Delete to confirm or Cancel to abort.*
<!-- /group -->

---

### Sun & Moon Data

A sun icon button at the bottom of the Calculate screen opens a panel with
astronomical data for the current date and location. The panel shows:

- **Sunrise and sunset** times.
- **Golden hour** and **blue hour** windows (morning and evening).
- **Moon phase** with phase name and illumination percentage.
- A decorative moon phase strip for the current lunar month.

![Sun and Moon Data panel – sunrise, sunset, golden hour, and moon phase](../../screenshots/04 Calculate View - Sun and Moon Data.png)

*The Sun & Moon panel shows today's sunrise/sunset, golden hour windows, and current moon phase with illumination.*


---

## Countdown Mode

Countdown mode maintains a list of named countdown slots, each tied to a specific deadline.

### The list

Entries appear in two groups:

- **Active entries** — deadline is in the future. Sorted by deadline ascending
  (soonest deadline at top). Shown with an amber timer display.
- **Free slots** — deadline has passed. Shown with a colored **FREE ✓** badge.
  Free slots can be reordered by dragging them into any position within the free slot section.

<!-- group -->
![Countdown list – overview of all active and free slots](../../screenshots/05 CountDown View.png)
*Active entries show an amber timer; free slots show a colored FREE ✓ badge and can be reordered by dragging.*
![Countdown list – entry row in deadline display mode](../../screenshots/05d CountDown View - Deadline.png)
*The right-side toggle switched to deadline mode: the static target date is shown instead of the live countdown.*
<!-- /group -->

### Active entry row

An active row shows a dark pill on the left with the entry label, and a toggle button
on the right that switches between:

- **Remaining time** — DD:HH:MM:SS live countdown.
- **Deadline date** — static date in YYYY.MM.DD HH:mm format.

**Copying the label:** tap the dark pill to copy the label text to the clipboard.
The pill briefly shows "COPIED" as confirmation.

**Note indicator:** if a slot has notes attached, a small eye icon appears in the label
pill to the right of the label text. The icon disappears while "COPIED" is shown.

![Countdown list – entry row with a note indicator](../../screenshots/05e CountDown View - Existing note.png)

*The orange eye icon indicates the slot has notes. Open the detail view and tap the note button to view or edit them.*

### Adding a countdown

Tap the **+ ADD** button at the bottom of the list. A sheet opens with a label field
and deadline steppers. Fill in the details and confirm to create the slot.

![Add New Item sheet – label field and deadline steppers](../../screenshots/06 Add New Item.png)

*The Add sheet: enter a label and set the deadline date, then confirm to create the slot.*

### Deleting a countdown

From the list, tap a card to open its detail view, then use the trash button there.
A confirmation dialog always appears before deletion — click **Delete** to confirm
or **Cancel** to abort.

![Delete confirmation dialog for a countdown slot](../../screenshots/06b Delete Item.png)

*A confirmation dialog appears before any slot is permanently removed.*


---

### Detail view

Tapping any row card opens the full-screen detail view for that entry.

**Label editing:** tap the large label text at the top to edit it inline.
Press Return or click away to confirm.

**Copy button:** the document icon next to the label copies the label to the clipboard.

**Time display:** the countdown or deadline date is shown overlaid on the illustration
in the centre of the screen.

**Toggle pill:** the dark pill button at the bottom of the screen switches between
*Show Remaining* (DD:HH:MM:SS live countdown) and *Show Deadline* (static date).

**Deadline stepper:** five component steppers (YEAR, MON, DAY, HOUR, MIN) let you
adjust the deadline. Click and hold a chevron to repeat quickly. Changes are saved
automatically.

<!-- group -->
![Detail view in countdown mode – live DD:HH:MM:SS display](../../screenshots/07 CountDown Detail View - Countdown.png)
*Detail view in countdown mode: the live remaining time is shown over the illustration.*
![Detail view in deadline mode – static target date display](../../screenshots/07b CountDown Detail View - Deadline.png)
*Detail view in deadline mode: the static target date replaces the live countdown.*
![Detail view for an expired (free) slot](../../screenshots/07c CountDown Detail View - Expired.png)
*An expired slot in the detail view: the FREE state is indicated and the color picker button becomes active.*
<!-- /group -->

#### Action buttons

Four icon buttons appear in a row at the bottom of the detail view:

| Button | Icon | Available when | Action |
|--------|------|----------------|--------|
| Sound | Speaker | Always | Toggles a system sound that plays when this slot's deadline passes |
| Notes | Note | Always | Opens the Notes editor for this slot |
| Color | Paintbrush | Free slots only | Opens the color picker |
| Delete | Trash | Always | Deletes this slot (confirmation required) |


#### Sound toggle

When enabled (speaker wave icon), the app plays a system sound at the moment this
slot's deadline passes. When disabled (speaker slash icon), no sound is played.
The setting is per-slot and remembered across launches.

#### Color picker (free slots only)

The color picker sheet shows twelve accent color swatches plus an **AUTO** option.
Tap any swatch to apply it to the free slot card. AUTO resets to the default color.
The selection is saved immediately.

![Color picker sheet – twelve accent swatches and AUTO option](../../screenshots/08 CountDown Detail View - Color Picker.png)

*The color picker offers twelve accent colors and an AUTO option. The selection is applied immediately.*

#### Delete

The trash button removes the slot permanently. A confirmation dialog appears;
click **Delete** to confirm or **Cancel** to abort. Deletion cannot be undone.

---

### Notes

Each countdown slot has a freeform text notes field, accessible via the note button
in the detail view.

The Notes sheet opens in **Viewer mode** by default, which renders the content as
formatted markdown (headings, lists, code blocks, tables, highlighted text).

#### Switching modes

A toggle button in the sheet header switches between:

- **Viewer mode** — rendered markdown in a scrollable view.
- **Editor mode** — plain text editor for writing or editing markdown directly.

<!-- group -->
![Notes sheet in Editor mode – plain text markdown editor](../../screenshots/09 CountDown Detail View - Note Editor - Editor View.png)
*Editor mode: write or edit raw markdown directly. Changes are reflected immediately in Viewer mode.*
![Notes sheet in Viewer mode – rendered markdown output](../../screenshots/10 CountDown Detail View - Note Editor - Viewer View.png)
*Viewer mode: the markdown is rendered with headings, lists, code blocks, and highlighted text.*
<!-- /group -->


#### Copying notes

The **Copy** button (available in both modes) copies the raw markdown text to the
clipboard, ready to paste into any other app.

#### Deleting notes

The **trash button** in the sheet header clears the entire notes field.
A confirmation dialog appears; click **Delete** to confirm or **Cancel** to abort.

<!-- group -->
![Notes delete confirmation dialog](../../screenshots/11 CountDown Detail View - Note Editor - Confirm Delete.png)
*A confirmation dialog appears before the notes content is permanently cleared.*
![Notes sheet – empty state with placeholder prompt](../../screenshots/12 CountDown Detail View - Note Editor - Empty.png)
*When there are no notes yet, a placeholder is shown. Tap it to jump straight into Editor mode.*
<!-- /group -->

#### Closing with unsaved changes

If you close the Notes sheet with the **✕ button** while there are unsaved edits,
a confirmation dialog appears:

- **Quit without saving** — discards the changes and closes the sheet.
- **Save and quit** — saves the current text and closes.
- **Cancel** — returns to the sheet without closing.

![Notes sheet – unsaved changes confirmation dialog](../../screenshots/11b CountDown Detail View - Note Editor - Confirm Exit.png)

*The prompt only appears when there are unsaved changes. Closing a clean sheet dismisses it immediately.*

---

## Snippets

The Snippets tab is a library of reusable text snippets, organized by project name.
Snippets are completely separate from countdown slots — they do not affect timers or deadlines.

### The list

Snippets are grouped by project in alphabetical order, with **General** always last.
Each row shows the snippet title and a short preview of its content. A **Copy** button
on the right side of each row copies the full snippet text to the clipboard immediately,
without opening the editor.

Tap a row to open the snippet in the editor sheet.

Tap the **+** button in the top-right corner to create a new snippet.

![Snippets list – project groups with snippet rows](../../screenshots/13 Snippets View - Rows.png)

*The Snippets list grouped by project. Each row shows the title, a content preview, and a Copy button.*


### Snippet editor sheet

The editor sheet has two modes, toggled with the button in the header:

- **Viewer mode** — renders the snippet body as formatted markdown.
- **Editor mode** — plain text editor for writing markdown directly.

The header also contains:

- **Copy** — copies the full raw markdown body to the clipboard.
- **Delete** — deletes the snippet permanently after confirmation.

<!-- group -->
![Snippet editor in Viewer mode – rendered markdown](../../screenshots/14 Snippet Edtor - Viewer.png)
*Viewer mode renders the snippet body as formatted markdown — headings, lists, code blocks, and more.*
![Snippet editor in Editor mode – plain text markdown editor](../../screenshots/15 Snippet Edtor - Editor.png)
*Editor mode: edit the title, project, and body directly. The body field supports full markdown.*
<!-- /group -->

#### Fields

| Field | Description |
|-------|-------------|
| Title | Short name for the snippet |
| Project | Groups the snippet in the list; tap to open the project chooser |
| Body | The snippet content (markdown supported) |

#### Project chooser

Tapping the project field opens a dropdown list of existing project names.
Select an existing project to assign the snippet to it, or type a new name
to create a new project group. The list filters as you type.

![Project chooser dropdown – list of existing project names](../../screenshots/16 Snippet Edtor - Projectname choser Dropdown List.png)

*The project chooser shows all existing project names. Select one, or type a new name to create a group.*


#### Project menu

Each project section has a small **chevron (▾) button** next to the project name in the
section header. Clicking it opens a menu with two options:

- **Rename project…** — opens a dialog where you can type a new name. All snippets in
  that project are moved to the new name automatically.
- **Delete project** — removes the project folder. **The snippets inside are not deleted.**
  They are moved to the **General** project and remain fully accessible there. A confirmation
  dialog shows this message before you confirm.

![Project section header menu – Rename and Delete options](../../screenshots/16b Snippets View - Project Editing Context Menu.png)

*The chevron next to the project name opens the project menu. Delete moves all snippets to General — nothing is lost.*

#### Deleting a snippet

The **Delete** button in the editor header removes the snippet permanently after confirmation.
This is different from deleting a project: deleting an individual snippet cannot be undone.

![Snippet delete confirmation dialog](../../screenshots/17 Snippet Edtor - Delete.png)

*A confirmation dialog appears before a snippet is permanently deleted.*

#### Closing with unsaved changes

If you close the snippet editor with the **✕ button** while there are unsaved edits,
a confirmation dialog appears:

- **Quit without saving** — discards the changes and closes the editor.
- **Save and quit** — saves and closes.
- **Cancel** — returns to the editor.

![Snippet editor – unsaved changes confirmation dialog](../../screenshots/17 Snippet Edtor - Exit.png)

*The prompt only appears when there are unsaved changes. Closing a clean editor dismisses it immediately.*


---

## Data Recovery

If the app detects that some stored data could not be loaded at startup — for example
because a file was corrupted or written in an incompatible format — a recovery banner
appears at the top of the affected tab.

### Recovery banner

The banner is shown in all three tabs independently: each tab only shows the banner if
its own data set had a problem. The banner displays the number of items that could not
be loaded and offers two actions.

<!-- group -->
![Recovery banner in Calculate View – 3 items could not be loaded](../../screenshots/18 Calculate View - Corrupted Data Warning.png)
*Calculate View: "3 ITEMS COULD NOT BE LOADED" with Copy Raw Data and Dismiss buttons.*
![Recovery banner in Countdown View – 3 items could not be loaded](../../screenshots/18b Countdown View - Corrupted Data Warning.png)
*Countdown View: the banner colour is slightly darker to contrast with the amber background.*
![Recovery banner in Snippets View – 3 items could not be loaded](../../screenshots/18c Snippets View - Corrupted Data Warning.png)
*Snippets View: the banner sits above the snippet list.*
<!-- /group -->

### Copy Raw Data

Click **Copy Raw Data** to copy the raw JSON of the unreadable items to the clipboard.
The data is formatted as readable JSON so it can be inspected or forwarded to support.
This action does not dismiss the banner.

### Dismiss

Click **Dismiss** to remove the banner. The unreadable items are cleared from the
recovery buffer. If new corruption is detected on a subsequent launch, the banner
will appear again.

> **Note:** Items shown in the recovery banner were not loaded into the app — they are
> not visible in the list and their data is not active. Dismissing the banner after
> copying the raw data is safe; the copy on the clipboard is your only remaining
> reference to those items.


---

## About

The About window shows the app version and credits. Open it from the menu bar:
**NightShift → About NightShift**.

![About window – app icon, name, version, and credits](../../screenshots/19 About.png)

*The About window shows the app icon, version number, developer contact, and image attribution.*

The window contains:

- **App icon and name** — displayed at the top.
- **Version** — the current version and build number, e.g. "Version 1.0 (42)".
- **Developer** — a clickable link that opens a pre-addressed email so you can send
  feedback or a question directly.
- **Images** — credit for the moon and sun artwork used inside the app.
  Clicking the link opens the artist's website.

---

## Help

The Help window provides searchable in-app documentation for all major features.
Open it from the menu bar: **Help → NightShift Help**.

![Help window – sections and searchable help items](../../screenshots/20 Help.png)

*The Help window lists all features in sections. Use the search bar at the top to find a specific topic quickly.*

### Sections

The help content is organized into five sections:

| Section | What it covers |
|---------|---------------|
| Overview | What the app does and how the three tabs fit together |
| Countdown | Adding slots, labels, timers, notes, free slots, and reordering |
| Calculate | Date steppers, result modes, named deadlines, and the Sun & Moon panel |
| Snippets | Creating, editing, organizing, and copying snippets |
| Recovery | What the recovery banner means and what to do when it appears |

### Search

Type any word into the search bar at the top to filter the help items. The search
matches topic names, so typing "notes" shows only items related to notes, and "sun"
shows only items about the sun panel. Clear the search field to see all sections again.


---

## Settings

Open Settings from the menu bar: **NightShift → Settings…** (or press **⌘ ,**).
The Settings window has two tabs.

### Language tab

![Settings – Language tab: interface language and date format pickers](../../screenshots/21 Settings View - Languages.png)

*The Language tab lets you choose the interface language and date format independently.*

Two pickers control how the app displays text and numbers:

- **Interface Language** — choose between *System Default*, English, or Magyar (Hungarian).
  System Default follows the language set in macOS System Settings.
- **Date & Number Format** — choose between *System Default*, English (US), or Magyar (HU).
  This controls how dates and numbers are formatted throughout the app.

> **Important:** Language changes require a restart. When either picker is set to a
> non-default value, a note appears at the bottom of the tab reminding you to restart
> NightShift for the change to take effect. The app continues to run normally until
> you restart it.

### Appearance tab

![Settings – Appearance tab: font size segmented picker](../../screenshots/21b Settings View - Fontsize.png)

*The Appearance tab lets you choose a larger text size. The change takes effect immediately.*

The **Font Size** segmented control has four options:

| Option | Description |
|--------|-------------|
| Default | Standard text size |
| Large | Slightly larger |
| Larger | Noticeably larger |
| Largest | Maximum size |

The selected size applies throughout the app instantly — no restart needed.
If the window feels crowded at *Largest*, the app automatically adjusts its minimum
width to keep the tab labels readable.


---

## Tooltips

Most buttons and interactive elements in the app display a short description when you
hold the mouse cursor over them for a moment without clicking. This hint is called a
**tooltip**.

![Tooltip example – hovering over a button shows a short description](../../screenshots/20b Tooltip System - cropped.png)

*Hovering over a button without clicking shows a brief description of what it does.*

Tooltips are available throughout the app: on the tab bar buttons, the action buttons
in the countdown detail view, the copy buttons in the snippet list, the stepper
chevrons, and more. If you are not sure what a button does, just hover over it
for a second and the tooltip will appear.

---

## Tips

- Named deadlines in Calculate mode are independent of countdown slots —
  they are reference points for the date calculator, not live timers.
- The Notes and Snippet editors both support markdown: headings (`#`), lists (`-`),
  code blocks (` ``` `), tables, and highlighted text (`==text==`).
- Sound plays only at the moment of expiry — if the app is not running when a
  deadline passes, the sound will not play retroactively.
- Free slot order is saved and restored across launches.
- Deleting a **project** in Snippets does not delete any snippets — they are moved
  to the General project. Deleting an individual **snippet** from the editor is permanent.
- All data (countdown slots, named deadlines, snippets, notes) is stored locally
  on this Mac. There is no cloud sync.
- If you are not sure what a button does, hover over it: a tooltip will appear
  with a short description.
