# Qurtix UI Implementation Rules

This document converts the visual philosophy in `DESIGN.md` into concrete Flutter implementation rules.

`DESIGN.md` is the creative source of truth.  
This file is the engineering execution guide.

The goal is to upgrade the current Qurtix Flutter app into a premium editorial-style reading product **without breaking existing functionality**.

---

# 1. Core Principle

We are **not rebuilding product logic**.  
We are **upgrading the presentation layer**.

That means:

## Allowed
- design tokens
- color system
- typography system
- reusable UI primitives
- card/chip/button/pill styling
- spacing and layout hierarchy
- toolbar and overlay presentation
- bottom sheet/menu presentation
- safe Hero animations
- visual polish for reader, library, and notes

## Not Allowed
- replacing the PDF engine
- changing EPUB architecture
- redesigning the annotation repository
- breaking jump-to-annotation
- breaking reading progress logic
- removing working features
- large speculative refactors
- introducing risky state changes unless necessary for UI

---

# 2. File Strategy

Create or use a small design layer inside the Flutter project.

Recommended structure:

```text
lib/core/design/
  app_colors.dart
  app_surfaces.dart
  app_typography.dart
  app_spacing.dart
  app_radius.dart
  app_motion.dart
  app_gradients.dart
  app_effects.dart

lib/core/widgets/
  app_card.dart
  app_chip.dart
  app_pill.dart
  app_secondary_button.dart
  app_glass_container.dart
  app_section.dart


  # Qurtix UI Implementation Rules

This document converts the visual philosophy in `DESIGN.md` into concrete Flutter implementation rules.

`DESIGN.md` is the creative source of truth.  
This file is the engineering execution guide.

The goal is to upgrade the current Qurtix Flutter app into a premium editorial-style reading product **without breaking existing functionality**.

---

# 1. Core Principle

We are **not rebuilding product logic**.  
We are **upgrading the presentation layer**.

That means:

## Allowed
- design tokens
- color system
- typography system
- reusable UI primitives
- card/chip/button/pill styling
- spacing and layout hierarchy
- toolbar and overlay presentation
- bottom sheet/menu presentation
- safe Hero animations
- visual polish for reader, library, and notes

## Not Allowed
- replacing the PDF engine
- changing EPUB architecture
- redesigning the annotation repository
- breaking jump-to-annotation
- breaking reading progress logic
- removing working features
- large speculative refactors
- introducing risky state changes unless necessary for UI

---

# 2. File Strategy

Create or use a small design layer inside the Flutter project.

Recommended structure:

```text
lib/core/design/
  app_colors.dart
  app_surfaces.dart
  app_typography.dart
  app_spacing.dart
  app_radius.dart
  app_motion.dart
  app_gradients.dart
  app_effects.dart

lib/core/widgets/
  app_card.dart
  app_chip.dart
  app_pill.dart
  app_secondary_button.dart
  app_glass_container.dart
  app_section.dart