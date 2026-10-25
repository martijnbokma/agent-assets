---
name: design-advisor
description: >-
  Industry-specific UI/UX recommendations before building: palettes, font
  pairings, page structure patterns and anti-pattern warnings from bundled
  design data. Use when starting or restyling a product UI.
metadata:
  author: Martijn Bokma
---

# Design Advisor

## Overview
A design advisor skill that gives industry-specific UI/UX recommendations before building. It searches local design data files and returns actionable guidance with hex palettes, font pairings, page structure patterns, interaction effects, and anti-pattern warnings.

## Workflow
1. Identify the industry, product type, and primary goal from the user request.
2. Normalize intent to tags (for example: saas, b2b, ecommerce, coaching, healthcare, local-services).
3. Search relevant CSV files in /data/ and filter rows by category_tags first.
4. If matching rows are sparse, fallback to rows containing all plus closest-domain rows.
5. Cross-reference terms with design vocabulary to keep recommendations precise and implementation-ready.
6. Search 21st.dev for concrete component examples when MCP is available.
7. Return a structured recommendation with clear rationale and implementation hints.

## Data Files
Search these CSV files based on user needs:
- colors.csv: Industry color palettes with role-based hex values and color direction.
- typography.csv: Font pairings, mood, best-fit use cases, and Google Fonts links.
- ui-reasoning.csv: Product-specific style logic, key effects, anti-patterns, and severity.
- styles.csv: Reusable visual style systems and implementation playbooks.
- landing.csv: Landing page section order, CTA strategies, and conversion tips.
- ux-guidelines.csv: UX do and do-not rules with practical code-oriented examples.
- charts.csv: Chart selection guidance, accessibility notes, and usage constraints.
- tag-taxonomy.csv: Canonical tag definitions and aliases used for routing consistency.

## Tag Selection Rules
- Prefer exact category_tags matches.
- When exact matches are unavailable, include rows tagged all.
- Prefer quality_tier=core first, then expand to extended, then experimental only when diversity is needed.
- Combine at least 1 row from colors, typography, landing, and ux-guidelines for every recommendation.
- For data-heavy products, include at least 1 charts row and 1 ui-reasoning row.

## Data Quality Guardrails
- Keep all CSV content and rule text in English.
- Ensure category_tags only use canonical tags from tag-taxonomy.csv.
- Ensure quality_tier is set to one of: core, extended, experimental.
- Run the following commands from .claude/skills/design:
- Preview retrieval ranking before composing advice: ruby rank-design-data.rb --tags "saas|b2b|analytics" --limit 3
- Normalize tag aliases before validation: ruby normalize-tags.rb --dry-run
- Apply normalization when needed: ruby normalize-tags.rb
- Run data validation after edits: ruby validate-data.rb

## Smoke Test Prompts
- "Design a conversion-focused landing for a B2B SaaS analytics tool."
- "Create a premium visual direction for a real estate listing site."
- "Recommend UX and chart patterns for a fintech dashboard."

## Output Format
Structure the response as:
- Style Direction: Recommended visual direction and why it fits the product and audience.
- Color Palette: Hex values with semantic roles (primary, secondary, CTA, background, text, border).
- Typography: Heading/body pairing with Google Fonts link and rationale.
- Page Structure: Section order and CTA placement strategy.
- Key Effects: Purposeful animations/interactions that support conversion and clarity.
- Anti-Patterns: What to avoid, with severity.
- 21st.dev Examples: Real component references when MCP is available.
- Next Step: Implementation handoff (ui-ux-designer) with a ready-to-paste prompt containing style direction, palette, typography, page structure, key effects, and anti-pattern constraints.
