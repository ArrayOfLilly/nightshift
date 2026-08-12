# countdownApp — Teljes Audit Prompt Gyűjtemény

> **Használat:** Minden promptot add át sorban a helyi Qwen modellnek (Qwen 2.5 32B / Qwen 3.6 27B).  
> A szögletes zárójelek (`[PASTE ... HERE]`) helyére illeszd be az érintett fájlok teljes tartalmát, egyértelműen jelölt fejlécekkel (`// === FILE: XYZ.swift ===`).  
> Minden prompt **csak leleteket kér** — javítási javaslatot nem. A refaktor-terv a lelet-összesítés után következik.

---

## Prompt 1 — Codable Correctness & Adatveszteség (DONE)

```
You are auditing a Swift/SwiftUI macOS app called countdownApp for Codable correctness and data loss risk. I want the result in a markdown code block as raw markdown. Since the code blocks break the outer markdown, please, break it down into pieces, especially tables are important to be alone in a new markdown block. I want a detailed report, not a high level description.

Rule: Every stored property in every Codable struct must appear in CodingKeys AND in init(from decoder:) using decodeIfPresent + ?? default. The synthesized Decodable does NOT use Swift default property values — a missing key in JSON causes decode failure and silent data loss (e.g., items reset to empty array).

Files to audit:
- CountdownItem.swift
- Snippet.swift
- NamedDeadline.swift

Report:
1. Every property missing from CodingKeys.
2. Every property using direct `try container.decode()` instead of `decodeIfPresent` + `?? default`.
3. Every property with a semantically wrong or unsafe default value.
4. UserDefaults save/load safety: Is full round-trip safe? Any silent return of empty arrays on decode failure?
5. `updatedAt` field handling on Snippet: Is it mutated on every write path or only on creation?

Format: List every issue found. Be specific: quote the exact file name, line numbers, property name, and the problem. Findings only — do not offer solutions yet.

[PASTE CountdownItem.swift HERE]
[PASTE Snippet.swift HERE]
[PASTE NamedDeadline.swift HERE]
```

---

## Prompt 2 — DRY: NotesSheet vs. SnippetEditSheet (DONE)

```
You are auditing a Swift/SwiftUI macOS app called countdownApp for DRY (Don't Repeat Yourself) violations between parallel sheet components.  I want the result in a markdown code block as raw markdown. Since the code blocks break the outer markdown, please, break it down into pieces, especially tables are important to be alone in a new markdown block. I want a detailed report, not a high level description.

NotesSheet.swift and SnippetEditSheet.swift share structural and functional UI patterns. Your task is to identify all duplicated logic and layout.

Files to audit:
- NotesSheet.swift
- SnippetEditSheet.swift

Report:
1. Identical or near-identical @State variables (e.g., sheetWidth, windowMargin, isEditing, showDeleteAlert, copyFeedback).
2. Identical or near-identical methods (updateSheetWidth(), header view builder, copy-to-clipboard, dismiss logic).
3. Duplicated structural layout patterns (header row, VIEW/EDIT state toggles, PlainTextEditor usage, MarkdownWebView usage).
4. Hardcoded numbers/margins shared across both files (clamp bounds 450/900, margins 24, minHeight 520 vs 680).
5. Behavioral divergences between the two sheets that appear unintentional.

Format: For each finding, quote the relevant code from both files side by side with line numbers and file names. Findings only — no fixes yet.

[PASTE NotesSheet.swift HERE]
[PASTE SnippetEditSheet.swift HERE]
```

---

## Prompt 3 — Magic Numbers, Magic Strings & Hardcoded Constants (DONE)

```
You are auditing a Swift/SwiftUI macOS app called countdownApp for magic numbers and hardcoded values that should be centralized constants.  I want the result in a markdown code block as raw markdown. Since the code blocks break the outer markdown, please, break it down into pieces, especially tables are important to be alone in a new markdown block. I want a detailed report, not a high level description.

Files to audit:
- All Swift files in the codebase (AppTheme.swift, CountdownView.swift, CountdownDetailView.swift, CalculateView.swift, NotesSheet.swift, SnippetEditSheet.swift, SharedEditorComponents.swift, AddCountdownSheet.swift, ColorPickerSheet.swift, SnippetsView.swift, SunPanel.swift)

Report every instance of:
1. Numeric layout literals (widths, heights, padding, corner radii, font sizes, opacity levels, animation delays) used without named constants, especially if repeated across files.
2. Hardcoded hex color strings (e.g., "#F5A623", "#060503", RGB component literals like 0x59/255) that should reference AppTheme.
3. Hardcoded font name strings (e.g., "Alien League", "AlienLeagueBold", "Mozilla Headline", "Menlo") scattered in UI code.
4. Hardcoded UserDefaults key strings (e.g., "countdownItems", "freeSlotOrder", "snippets", "namedDeadlines", "calculateFromDate") that should be static constants.
5. Hardcoded CSS px and color values inside markdownCSS in SharedEditorComponents.swift
   disconnected from AppTheme.
6. Inline hardcoded system sound names (e.g., NSSound(named: "Funk")).

Format: Quote the value, the exact file name, line numbers, and occurrences count across files. Findings only.

[PASTE ALL FILES HERE, clearly labeled]
```

---

## Prompt 4 — Single Responsibility Principle & God Views (DONE)

```
You are auditing a Swift/SwiftUI macOS app called countdownApp for Single Responsibility Principle (SRP) violations and oversized View entities.  I want the result in a markdown code block as raw markdown. Since the code blocks break the outer markdown, please, break it down into pieces, especially tables are important to be alone in a new markdown block. I want a detailed report, not a high level description.

Files to audit:
- CountdownView.swift
- CountdownDetailView.swift
- CalculateView.swift
- NotesSheet.swift
- SnippetEditSheet.swift
- SharedEditorComponents.swift

Report every instance where a View or struct takes on non-UI responsibilities:
1. Views containing direct persistence logic (UserDefaults read/write inside view body or view helper methods).
2. Views containing date arithmetic or domain business logic that belongs in model/service extensions.
3. Views or components constructing raw HTML or CSS strings inline.
4. Views managing resource bundle lookups directly (font file loading, etc.).
5. Large views handling too many distinct responsibilities (e.g., CountdownView managing UI layout AND cache management AND expiry sound playback AND drag-and-drop state).
6. Methods longer than ~30 lines doing multiple unrelated actions.
7. Local @State in views representing persistent application state.

Format: Quote the method or block, reference the file name and line numbers, and explain the mixed responsibilities. Findings only.

[PASTE FILES HERE, clearly labeled]
```

---

## Prompt 5 — Performance, Main-Thread Overhead & Concurrency (Done)

```
You are auditing a Swift/SwiftUI macOS app called countdownApp for performance bottlenecks and Swift Concurrency / Threading issues.  I want the result in a markdown code block as raw markdown. Since the code blocks break the outer markdown, please, break it down into pieces, especially tables are important to be alone in a new markdown block. I want a detailed report, not a high level description.


Files to audit:
- CountdownView.swift
- SharedEditorComponents.swift
- NotesSheet.swift
- SnippetEditSheet.swift
- SunTimesService.swift
- CalculateView.swift

Report:
1. MarkdownWebView.updateNSView: Does it reload WKWebView unconditionally on every SwiftUI render cycle without checking if `markdown` changed?
2. UserDefaults write patterns: Are edits (e.g., notes or text input bindings) written on every keystroke without debouncing?
3. Use of DispatchQueue.main.asyncAfter or arbitrary delays (e.g., 0.05s / 1.0s / 1.2s feedback timers): Are these race-condition-prone timing hacks?
4. Cache rebuilds vs. rendering (crossingTask / rebuildCache in CountdownView): Potential race conditions or main-thread stalls during list updates.
5. Callbacks & Closures: Any async closure or evaluation callback touching SwiftUI state from background threads without @MainActor guarantees?
6. Memory / Closure captures: Any async tasks capturing self strongly where weak references or structured tasks are needed.
7. Swift Concurrency modernization opportunities: Legacy DispatchQueue calls that can be cleaned up using async/await or @MainActor.

Format: Specific findings only. Reference file names and line ranges for every issue.

[PASTE FILES HERE, clearly labeled]
```

---

## Prompt 6 — AppTheme Centralizáció & CSS/SwiftUI Téma-szinkron (DONE)

```
You are auditing a Swift/SwiftUI macOS app called countdownApp for visual theme centralization and styling consistency.  I want the result in a markdown code block as raw markdown. Since the code blocks break the outer markdown, please, break it down into pieces, especially tables are important to be alone in a new markdown block. I want a detailed report, not a high level description.


The app uses AppTheme.swift for SwiftUI and markdownCSS (in SharedEditorComponents.swift) for WKWebView rendering. These two systems are currently disconnected — CSS hardcodes hex values that duplicate AppTheme colors.

Files to audit:
- AppTheme.swift
- SharedEditorComponents.swift
- CountdownDetailView.swift
- NotesSheet.swift
- SnippetEditSheet.swift
- CalculateView.swift

Report:
1. Colors in AppTheme vs. markdownCSS: Which hex values in CSS duplicate AppTheme, and which are orphaned/hardcoded?
2. Inline hardcoded colors in Swift UI files (Color.white.opacity(...), Color(red: ...) in ProjectField or CalculateView) that bypass AppTheme.
3. Font definition consistency: Are font names defined centrally in AppTheme or scattered as string literals in various components?
4. Spacing, padding, and corner radii: Are layout dimensions centralized in AppTheme or defined ad-hoc per view?
5. Impact of theme changes: If AppTheme.background or AppTheme.dark changes, list every location in code that requires manual updates.

Format: Itemized list with exact file names, line numbers, and quoted code snippets. Findings only.

[PASTE FILES HERE, clearly labeled]
```

---

## Prompt 7 — SwiftUI State Management & Lifecycle Best Practices (DONE)

```
You are auditing a Swift/SwiftUI macOS app called countdownApp for SwiftUI state lifecycle and view architecture best practices.  I want the result in a markdown code block as raw markdown. Since the code blocks break the outer markdown, please, break it down into pieces, especially tables are important to be alone in a new markdown block. I want a detailed report, not a high level description.

Files to audit:
- CountdownView.swift
- CountdownDetailView.swift
- CalculateView.swift
- NotesSheet.swift
- SnippetEditSheet.swift
- SharedEditorComponents.swift

Report:
1. @State variable sprawl: Views with numerous individual boolean flags (isEditing, showDeleteAlert, copyFeedback, showSaveSheet, etc.) that could be modeled cleanly as state machine enums or local structs.
2. Sheet lifecycle and state leakage: When sheets dismiss, are local @State properties cleaned up, or can  stale state persist across presentations?
3. .focusable(false) usage: Is .focusable(false) applied repeatedly on individual buttons, and can it be wrapped in a cleaner modifier or ButtonStyle?
4. NSViewRepresentable updateNSView completeness: Missing guards or unnecessary state updates causing AppKit view redraw loops.
5. Identity tracking (ForEach keys, .id() modifiers): Unnecessary view redraws or identity loss during updates.

Format: Detailed findings with exact line references and file names. Findings only.

[PASTE FILES HERE, clearly labeled]
```

---

## Prompt 8 — File Headers, Documentation & Hungarian Text (DONE)

```
You are auditing a Swift/SwiftUI macOS app called countdownApp for documentation accuracy and language consistency.  I want the result in a markdown code block as raw markdown. Since the code blocks break the outer markdown, please, break it down into pieces, especially tables are important to be alone in a new markdown block. I want a detailed report, not a high level description.

Files to audit:
- All Swift files in the project repository.

Report:
1. Header comments describing outdated or removed functionality.
2. Header comments omitting key features added to the file.
3. Swift files lacking header documentation.
4. Non-English text (e.g., Hungarian words or comments) in identifiers, variable names, or comments. Convention requires English throughout.
5. Obsolete inline comments describing deprecated logic or removed code paths.

Then read spec.md and compare it against the actual implementation. Report:
6. Features in spec.md that are not yet implemented.
7. Features implemented in source that are not in spec.md.
8. Architectural descriptions in spec.md that no longer match reality.

Format: File name, line range, quoted text, and nature of the documentation flaw. Findings only.

[PASTE ALL SWIFT FILES AND SPEC.MD HERE, clearly labeled]
```

---

## Prompt 9 — freeColors Tömb & Szemantikus Szín-mapping (DONE)

```
You are auditing a Swift/SwiftUI macOS app called countdownApp for indexed array usage for visual colors (freeColors array antipattern).  I want the result in a markdown code block as raw markdown. Since the code blocks break the outer markdown, please, break it down into pieces, especially tables are important to be alone in a new markdown block. I want a detailed report, not a high level description.

The codebase defines AppTheme.freeColors as an array of 14 hex colors, accessed by index (e.g., freeColors[index % freeColors.count], fallback accentColorIndex ?? 6).

Files to audit:
- AppTheme.swift + all files


Report:
1. Location and current items in AppTheme.freeColors (list all 14 values).
2. Every location in code where freeColors or freeColor(for:) is accessed by index — quote surrounding context to determine the semantic meaning of each slot.
3. Are specific color indices assigned inconsistent semantic meanings across different views?
4. Iteration vs. direct access: How is the array used in ColorPickerSheet vs. CountdownRowView?
5. Bounds-safety and fallback logic: Are index accesses guarded against out-of-bounds or unexpected user data?

Format: Detailed mapping of freeColors index usages across all files with line numbers. Findings only.

[PASTE FILES HERE, clearly labeled]
```

---

## Prompt 10 — NotificationCenter & Memory Leaks (DONE)

```
You are auditing a Swift/SwiftUI macOS app called countdownApp for NotificationCenter lifecycle leaks and unremoved observers.  I want the result in a markdown code block as raw markdown. Since the code blocks break the outer markdown, please, break it down into pieces, especially tables are important to be alone in a new markdown block. I want a detailed report, not a high level description.

Background: CountdownDetailView.swift contains a FocusedNSTextField whose Coordinator subscribes to NSWindow.didResignKeyNotification via NotificationCenter.default.addObserver. There is no corresponding removeObserver in deinit or dismantling phase. Every time the detail view is opened, a new observer is registered, leading to memory leaks and zombie callbacks.

Files to audit:
- CountdownDetailView.swift (FocusedNSTextField / Coordinator)
- All other NSViewRepresentable wrappers in the project

Report:
1. Every instance of NotificationCenter.default.addObserver without a corresponding removeObserver in deinit or a dismantling lifecycle method.
2. Any missing storage for NotificationCenter observation tokens (AnyCancellable, NSObjectProtocol).
3. Strong reference captures inside NotificationCenter callback closures.

Format: Quote exact file, lines, and method name. Findings only.

[PASTE FILES HERE, clearly labeled]
```

---

## Prompt 11 — Custom Font Registration Lifecycle & PostScript Name Accuracy (DONE)

```
You are auditing a Swift/SwiftUI macOS app called countdownApp for custom font registration correctness and PostScript name accuracy.  I want the result in a markdown code block as raw markdown. Since the code blocks break the outer markdown, please, break it down into pieces, especially tables are important to be alone in a new markdown block. I want a detailed report, not a high level description.

Background: countdownAppApp.swift registers bundled fonts at launch via CTFontManagerRegisterFontsForURL. If PostScript names do not exactly match the Font.custom() strings in AppTheme.swift and the @font-face declarations in markdownCSS, SwiftUI silently falls back to the system font (San Francisco), causing visual layout drift on countdowns and display elements.

Files to audit:
- countdownAppApp.swift (registerBundledFonts)
- AppTheme.swift
- SharedEditorComponents.swift (markdownCSS @font-face declarations)
and all other files

Report:
1. Discrepancies between physical TTF font filenames, registration strings in registerBundledFonts, and Font.custom() string identifiers in AppTheme.
2. Potential silent fallbacks to system fonts if CoreText registration fails or PostScript names mismatch.
3. Font definitions duplicated across Swift code and WebView CSS @font-face declarations — any inconsistency between the two?

Format: Quote exact file, line numbers, and font strings side by side. Findings only.

[PASTE FILES HERE, clearly labeled]
```

---

## Prompt 12 — Storage Persistence Architecture & UserDefaults Key Consistency (DONE)

```
You are auditing a Swift/SwiftUI macOS app called countdownApp for storage persistence architecture and key consistency.  I want the result in a markdown code block as raw markdown. Since the code blocks break the outer markdown, please, break it down into pieces, especially tables are important to be alone in a new markdown block. I want a detailed report, not a high level description.

Background: The app mixes @AppStorage (CalculateView, SunTimesService) with manual UserDefaults.standard.data(forKey:) + JSONDecoder (CountdownView, Snippet, NamedDeadline). UserDefaults key strings are scattered as hardcoded literals throughout View and model files with no centralized key registry and no schema migration strategy.

Files to audit:
- CalculateView.swift (@AppStorage usage)
- SunTimesService.swift (@AppStorage & UserDefaults cache)
- Snippet.swift (UserDefaults extension)
- CountdownView.swift (UserDefaults save/load)
- NamedDeadline.swift
and all other files

Report:
1. All @AppStorage usages vs. manual UserDefaults read/write paths — are they consistent in approach?
2. Every hardcoded key string in View or model files that should be a static constant (e.g., "snippets", "namedDeadlines", "freeSlotOrder", "calculateFromDate").
3. Missing data migration or fallback handling for breaking model changes across app updates.

Format: Quote exact keys, files, and lines. Findings only.

[PASTE FILES HERE, clearly labeled]
```

---

## Prompt 13 — UI Layout Overflow & Clipping Risks on Small Windows (DONE)

```
You are auditing a Swift/SwiftUI macOS app called countdownApp for hardcoded layout frame bounds and responsiveness / clipping risks at small window sizes. I want the result in a markdown code block as raw markdown. Since the code blocks break the outer markdown, please, break it down into pieces, especially tables are important to be alone in a new markdown block. I want a detailed report, not a high level description.

Background: ContentView sets a minimum window width of 460pt. Several sub-views use fixed frame dimensions (e.g., CalculateView moon phases HStack with fixed moonSize and spacing: 12, SunPanel
minWidth: 360, CountdownDetailView tomato image maxWidth: 500). At small window sizes or high Accessibility text scales, content may clip or overflow.

Files to audit:
- ContentView.swift
- CalculateView.swift
- CountdownDetailView.swift
- SunPanel.swift
- NotesSheet.swift
- SnippetEditSheet.swift
and all other files

Report:
1. Fixed frame(width:) / frame(height:) or rigid minWidth/minHeight constraints that could break UI on low-resolution displays or scaled windows.
2. Missing minimumScaleFactor on primary text labels that could clip at large text sizes.
3. ScrollView omissions where content could easily overflow the container height at minimum window size.

Format: Quote exact lines, frame dimensions, and affected files. Findings only.

[PASTE FILES HERE, clearly labeled]
```

---

## Prompt 14 — JavaScript Injection & Template Literal Escaping in MarkdownWebView (DONE)

```
You are auditing a Swift/SwiftUI macOS app called countdownApp for JavaScript injection risks in the WKWebView markdown rendering layer.  I want the result in a markdown code block as raw markdown. Since the code blocks break the outer markdown, please, break it down into pieces, especially tables are important to be alone in a new markdown block. I want a detailed report, not a high level description. You tried once, but didn't succeed well, do it thoroughly, please, and cover all details.


Background: SharedEditorComponents.swift contains a MarkdownWebView (NSViewRepresentable) whose reload() method constructs a JavaScript string by interpolating the markdown content directly into a
JS template literal. The current escaping only handles backslash and backtick characters. This is insufficient: ${...} JavaScript template expressions and </script> tags within the markdown string
can break out of the JS context, causing rendering corruption or unexpected script execution (even within a sandboxed WKWebView, this breaks correct display behavior).

Files to audit:
- SharedEditorComponents.swift (MarkdownWebView, reload(), updateNSView) and all the other files in the project

Report:
1. Exact location and code of the JS template literal interpolation in reload().
2. Which characters are currently escaped and which are not (specifically: ${, </script>, \`, \, newlines, null bytes, Unicode edge cases).
3. Any other place in the codebase where user-controlled text is injected into JS or HTML strings without full escaping.

Format: Quote the exact code block(s), file name, and line numbers. Findings only.

[PASTE SharedEditorComponents.swift HERE]
[PASTE any other file with JS/HTML string construction HERE]
```

---

## Prompt 15 — Accessibility (VoiceOver & Semantic Labels) (DONE)

```
You are auditing a Swift/SwiftUI macOS app called countdownApp for accessibility completeness on macOS.  I want the result in a markdown code block as raw markdown. Since the code blocks break the outer markdown, please, break it down into pieces, especially tables are important to be alone in a new markdown block. I want a detailed report, not a high level description.

Report:
1. Interactive controls (buttons, toggles, pickers, custom gesture targets) missing .accessibilityLabel or .accessibilityHint modifiers.
2. CountdownRowView and CountdownDetailView: Are countdown values (days remaining, crossing time, date) exposed as readable accessibility text, or are they rendered as non-semantic decorative views?
3. ColorPickerSheet swatches: Are individual color options distinguishable to VoiceOver (labels like "Amber", "Teal") or are they all announced identically?
4. Custom NSViewRepresentable components: Do they propagate accessibility information to AppKit, or are they opaque to the accessibility tree?
5. Any use of decorative images without .accessibilityHidden(true).
6. Any dynamic content (live countdown ticking) without .accessibilitySortPriority or .accessibilityLiveRegion equivalent.

Files to audit: All Swift files, with focus on CountdownRowView.swift, CountdownDetailView.swift, ColorPickerSheet.swift, CalculateView.swift, SharedEditorComponents.swift.
and all the other files

Format: File name, line range, element description, and specific missing accessibility modifier. Findings only.

[PASTE FILES HERE, clearly labeled]
```

---

## Prompt 16 — App Lifecycle & Data Flush on Termination (DONE)

```
You are auditing a Swift/SwiftUI macOS app called countdownApp for data persistence safety at app termination.  I want the result in a markdown code block as raw markdown. Since the code blocks break the outer markdown, please, break it down into pieces, especially tables are important to be alone in a new markdown block. I want a detailed report, not a high level description.

Background: The app uses both @AppStorage and manual UserDefaults.standard.set() calls for persistence. While UserDefaults generally synchronizes automatically, force-quit (SIGKILL) or unexpected crashes can lose buffered writes. Additionally, if any in-memory state is not flushed to UserDefaults before applicationWillTerminate fires, data written in the last interaction may be silently lost.

Files to audit:
- countdownAppApp.swift (AppDelegate / lifecycle hooks)
- CountdownView.swift (UserDefaults write paths)
- CalculateView.swift
- SunTimesService.swift
and all the other files

Report:
1. Is applicationWillTerminate (or scene-based equivalent) implemented? If so, does it explicitly call UserDefaults.standard.synchronize() or flush any pending writes?
2. Is there any in-memory state (e.g., a pending edit in a text field, a drag-and-drop reorder in progress) that is NOT immediately written to UserDefaults and could be lost on force-quit?
3. Are there any DispatchQueue.async write operations that might not complete before termination?
4. Is UserDefaults.standard.synchronize() called anywhere, or is the app relying entirely on automatic sync (which is not guaranteed on force-quit)?

Format: Quote exact file, lines, and code path. Findings only.

[PASTE FILES HERE, clearly labeled]
```

---

## Összefoglaló — Prioritási Mátrix

| Prioritás | Témakörök |
| ----------- | ----------- |
| 🔴 P1 — Adatveszteség / correctness / biztonság | 1 (Codable), 14 (JS injection), 16 (lifecycle flush), 10 (memory leak) |
| 🟠 P2 — Architectural drift / jövőbeli bugok | 4 (SRP), 5 (concurrency), 12 (storage arch), 11 (font reg) |
| 🟡 P3 — Minőség / karbantarthatóság | 2 (DRY), 3 (magic numbers), 6 (theme sync), 7 (SwiftUI state), 9 (freeColors), 13 (layout) |
| 🟢 P4 — Dokumentáció / stílus / hozzáférhetőség | 8 (headers/spec), 15 (accessibility) |

---

*Összesen: 16 audit témakör. Futtatás sorrendje: P1 → P2 → P3 → P4.*
