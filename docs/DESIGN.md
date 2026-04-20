# Design System Strategy: The Curated Sanctuary

## 1. Overview & Creative North Star
The Creative North Star for this design system is **"The Digital Curator."** 

We are not building a utility; we are crafting a sanctuary for the mind. While most reading apps feel like databases of text, this system treats digital content with the reverence of a physical limited-edition book. To move beyond a "template" look, we embrace **Intentional Asymmetry** and **Tonal Depth**. 

Instead of a rigid, centered grid, we use wide margins and staggered element placement to guide the eye. We break the "boxed-in" feel of mobile apps by layering surfaces like fine vellum paper, allowing the interface to breathe through expansive whitespace and sophisticated typographic scales.

---

## 2. Color & Surface Philosophy
The palette is rooted in low-strain, "paper-like" neutrals, punctuated by an authoritative slate primary and a botanical green secondary.

### The "No-Line" Rule
**Explicit Instruction:** Traditional 1px solid borders are prohibited for sectioning. Structural boundaries must be defined solely through background color shifts or tonal transitions. To separate a header from a body, transition from `surface` to `surface-container-low`. We define space through mass, not lines.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers—like stacked sheets of frosted glass.
*   **Base:** `surface` (#f9f9f7) – The foundation.
*   **Sections:** `surface-container-low` (#f4f4f2) – Used for grouping secondary content.
*   **Elevated Elements:** `surface-container-lowest` (#ffffff) – Used for primary cards or reading panes to create a "lifted" feel against the cream background.

### The "Glass & Gradient" Rule
To avoid a flat, "out-of-the-box" feel, use **Glassmorphism** for floating navigation bars or overlays. Apply a 20px `backdrop-blur` to a 70% opaque `surface` token. For CTAs, use a subtle linear gradient from `primary` (#455565) to `primary_container` (#5d6d7e) at a 135-degree angle to add "soul" and a tactile, satin-finish quality.

---

## 3. Typography: The Editorial Voice
Typography is our primary tool for immersion. We pair the intellectual weight of a serif with the invisible efficiency of a sans-serif.

*   **The Reading Experience (Noto Serif):** All long-form content, headlines, and titles use Noto Serif. It provides the "academic" authority required for a premium reading app.
    *   *Display-LG (3.5rem):* Used for book titles and major chapter breaks.
    *   *Body-LG (1rem / 1.6 line-height):* Optimized for the "flow state" of reading.
*   **The Utility Layer (Inter):** All UI labels, metadata (e.g., "5 mins left"), and buttons use Inter. This creates a clear mental distinction between *the content* (the book) and *the tool* (the app).

---

## 4. Elevation & Depth
We convey hierarchy through **Tonal Layering** rather than structural shadows.

*   **The Layering Principle:** Depth is achieved by "stacking." Place a `surface-container-lowest` (#ffffff) card on a `surface-container-low` (#f4f4f2) background. This creates a soft, natural lift that mimics heavy cardstock.
*   **Ambient Shadows:** If an element must float (e.g., a "Back to Top" button), use a shadow with a 32px blur and 4% opacity. The shadow color must be a tinted version of `on-surface` (#1a1c1b), never pure black.
*   **The "Ghost Border" Fallback:** For high-density components where separation is critical for accessibility, use a "Ghost Border": the `outline-variant` token at **15% opacity**.

---

## 5. Components

### Cards & Lists
*   **Standard:** Use `surface-container-lowest` for the card background. 
*   **Forbid:** Never use divider lines between list items. Use 16px of vertical whitespace or a 4px `surface-container` vertical gutter to separate items.
*   **Radius:** Cards use `md` (1.5rem) to maintain a soft, approachable feel.

### Buttons
*   **Primary:** A satin-finish gradient (Primary to Primary-Container). Fully rounded (Pill) for high contrast against rectangular text blocks.
*   **Secondary:** Ghost style using the `secondary` (#36684e) text with no background, or a subtle `secondary-container` (#b8efce) background.

### Reading Progress & Chips
*   **Chips:** Use `secondary-fixed` (#b8efce) for active states. Radius: `md` (1.5rem).
*   **Progress Bars:** Thin (4px), using `primary` for the fill and `surface-variant` for the track. No rounded ends on the track—keep it architectural and clean.

### Annotation Overlays (Contextual)
When a user highlights text, the popover should use the **Glassmorphism** rule. This ensures the reader never loses sight of the text they are interacting with, maintaining immersion.

---

## 6. Do’s and Don’ts

### Do
*   **Do** use asymmetrical margins (e.g., 24px left, 32px right) for display headlines to mimic high-end magazine layouts.
*   **Do** prioritize line-height. Notes and body text must never drop below a 1.5 ratio to ensure the "Calm" personality is maintained.
*   **Do** use "Surface Bright" for the active reading pane to draw the eye's focus naturally.

### Don’t
*   **Don't** use pure black (#000000). Always use `on-surface` (#1a1c1b) to reduce eye strain and maintain the "soft" aesthetic.
*   **Don't** use standard Material shadows. They are too aggressive for this system. If you can clearly see where the shadow ends, it's too dark.
*   **Don't** use icons without labels in the primary navigation. We value clarity and professionalism over minimalist ambiguity.