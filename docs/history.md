# countdownApp — History

## Session O — 2026-08-11 (Mozilla Headline font bundle + @font-face)

Commit `1267ac1`.

## Session N — 2026-08-11 (SnippetEditSheet + NotesSheet width fix)

- SnippetEditSheet + NotesSheet dinamikus sheetWidth
- PlainTextEditor lineSpacing param
- VIEW mód betűméret 13→14px
- Font-csere: Roboto Flex → Urbanist (rendszerszintű, nem bundle)

## Session M — 2026-08-11 (font diagnosis + CSS code monospace fix)

## Session L — 2026-08-11 (Roboto Flex @font-face fix)

## Session K — 2026-08-11 (snippet editor title selection fix)

- SnippetEditSheet: `.focusable(false)` a root ZStack-en, `@FocusState titleFocused` eltávolítva
- Header gombok: `white 0.07` bg → `white 0.12`, ikon tint `white 0.7` → `white 1.0`
- ProjectField dropdown + popover háttér finomítva
- `ContentView.swift`: `.frame(minWidth: 460)` hozzáadva

## Session J — 2026-08-11 (selection fix CountdownDetailView + PlainTextEditor)

## Session I–E — 2026-08-11

- PlainTextEditor NSViewRepresentable — pixel-exact padding control
- NotesSheet draftNotes persistent buffer bug fix
- Amber-on-amber visibility fix
- NotesSheet + SnippetEditSheet sheet width clamping

## Session D — 2026-08-11 (SNIPPETS sort fix)

## Session C — 2026-08-11 (SNIPPETS implementáció)

5 új fájl: `Snippet.swift`, `SnippetsView.swift`, `SnippetEditSheet.swift`, `NotesSheet.swift`, `SharedEditorComponents.swift`

## Session B — 2026-08-11 (SLOT-NOTES EDIT mód padding fix)

Commit `7f47511`.

## Session 37 és korábbiak — 2026-08-11

- SLOT-NOTES: per-slot notes/handoff mező, marked.js markdown render, WKWebView
- SOUND-1: per-slot expiry sound (`NSSound(named: "Funk")`)
- SUN-1-A/B/C: SunTimes.swift, SunTimesService.swift, SunPanel popover
- CALC-SAVE: Named deadline persistence, split SAVE gomb, deadline list popover
- Beachball fix: LazyVStack → VStack, single TimelineView, NavigationLink(value:), RowEntry wrapper
- Free-slot accent color picker (ColorPickerSheet, 12 szín)
- LongPressStepperButton
- Drag-to-reorder free slots

Commit referenciák: `07861a9` (beachball), `e3648e1`, `922e299` (CalculateView), `bf41007` (SUN-1-C), `892f1ed` (SOUND-1), `c04d4a6` (SOUND-1 model), `c84bb39` (CALC-SAVE), `525ed86` (CALC-1), `8b2035b` (LongPressStepper)
