# PRODUCT GUIDELINES

This document defines the product direction, UX principles, and architectural rules.

IMPORTANT:
- This is the single source of truth for AI-assisted development.
- All future changes must respect these principles.
- Do NOT introduce feature bloat.
- Do NOT break simplicity.

---

You are a senior Flutter product engineer working on a production-grade reading app.

The app is now beyond prototype stage. We are around phase 2.5 to 3.0.

Current status:
- Reading is comfortable
- EPUB jumps from notes now seem mostly correct
- EPUB works through an indexing-based logic
- Library / Notes / Reader core structure exists
- But the product still needs refinement to become a scalable, polished app

IMPORTANT PRODUCT DIRECTION:
We do NOT want a bloated feature-heavy product.
We want a simple, functional, highly usable reading app.

The user should not need to learn the app before using it.
UI/UX must stay minimal, intuitive, and practical.

--------------------------------------------------
CURRENT PRODUCT PRIORITIES
--------------------------------------------------

1. Keep the interface simple and functional
2. Improve usability without feature bloat
3. Make reading flow feel natural
4. Make architecture ready for future scale
5. Fix remaining PDF annotation gaps

--------------------------------------------------
KNOWN STATUS
--------------------------------------------------

- EPUB jump/navigation seems improved
- EPUB reading is usable
- EPUB still does not fully feel like natural “book pages”
- PDF annotation / highlighting / drawing still does not work properly
- UI can still be made more functional and cleaner

--------------------------------------------------
SCALING REQUIREMENT
--------------------------------------------------

This product may eventually serve 100k users across many devices.

That does NOT mean we must add a server right now.
But the architecture must become sync-ready and scale-ready.

Design the code so that:
- local-first works now
- server/sync can be added later without rewriting the whole app
- repositories and storage layers stay cleanly separated

--------------------------------------------------
WHAT WE WANT NEXT
--------------------------------------------------

Work like a product-minded engineer, not a feature machine.

Prioritize in this order:

1. PDF annotation foundation
   - highlight visibility
   - note save/read/delete
   - jump from notes to PDF annotation
   - consistent behavior with EPUB where possible

2. Reader UX simplification
   - simplify toolbar/actions
   - reduce cognitive load
   - keep important actions obvious
   - secondary actions can live in overflow / bottom sheets

3. Library / Notes UI polish
   - consistent card layout
   - clean segmented filters
   - stronger hierarchy
   - minimal but polished UI

4. EPUB reading comfort improvements
   - more natural reading rhythm
   - better “page feel”
   - cleaner progress presentation
   - stronger focus after jump

5. Architecture cleanup
   - repository boundaries
   - annotation domain clarity
   - document handling separation
   - local-first, future sync-ready structure

--------------------------------------------------
DO NOT DO
--------------------------------------------------

- Do NOT add random extra features
- Do NOT copy bloated competitors
- Do NOT make the interface crowded
- Do NOT optimize for edge features before core reading quality
- Do NOT overengineer server infrastructure right now

--------------------------------------------------
PRODUCT PRINCIPLES
--------------------------------------------------

The app should feel:
- simple
- fast
- clear
- calm
- dependable

The user should feel:
- “I can use this immediately”
- “reading and note-taking are easy”
- “I trust where my notes and jumps go”

--------------------------------------------------
IMPLEMENTATION RULES
--------------------------------------------------

- Do NOT run dart format
- Do NOT run flutter analyze
- Do NOT run tests
- Do NOT mention verification commands
- Return full updated code for every changed file
- When making UX decisions, choose the simpler option unless complexity is clearly justified

--------------------------------------------------
OUTPUT FORMAT
--------------------------------------------------

Return exactly:

1. Product-phase summary
2. What should be prioritized next
3. Files changed
4. Full updated code for every changed file
5. Why the UX is now simpler and more scalable