# FOREVERHUD | BRAND SYSTEM

> Version 1.0 • 2026-11-07 • One master. One brand. Pure white. Transparent.

## Master identity

- **Canonical symbol**: `assets/logo.svg` (identical to `brand/masters/foreverhud-symbol-white.svg`).
- **Colour**: `#FFFFFF` only; no metallic gradient, shadow, glow, gold, stroke colour variants or coloured backgrounds baked into the symbol.
- **Background**: 100% transparent. The master SVG contains no background rectangle.
- **Signature**: shield + bilateral central rune + diamond. These three elements must remain unchanged in all uses.
- **Name**: `ForeverHUD` in text, `FOREVERHUD` in display treatments.
- **Associated tagline**: `YOUR COMBAT. IN FOCUS.` (optional; never include in a 32px icon).
- **Relationship**: independent fan-made addon; never use Blizzard/WoW logos as the ForeverHUD brand symbol.

## Files

| Use | Canonical file |
| --- | --- |
| Master icon, vector and transparent | `assets/logo.svg` |
| 512px transparent icon for repository | `assets/icon.png` |
| WoW addon icon 128px TGA alpha | `ForeverHUD/Media/icon.tga` |
| Complete horizontal logo | `brand/masters/foreverhud-lockup-horizontal-white.svg` |
| Complete stacked logo | `brand/masters/foreverhud-lockup-stacked-white.svg` |
| White text-only wordmark | `brand/masters/foreverhud-wordmark-white.svg` |
| GitHub banner with dark background | `assets/banner.svg` |
| GitHub social-preview 1200x630 | `brand/social/open-graph-1200x630.png` |
| Social avatar | `brand/social/avatar-dark-tile-512.png` |
| White transparent cover | `brand/social/cover-transparent-white.svg` |
| Raster icon variants | `brand/exports/foreverhud-symbol-white-*.png` |

## Grid and safe zone

The icon is drawn within a 512×512 viewBox. Leave at least **12.5% of the icon's 512px box** of clear space on all four sides around the complete symbol; at display sizes smaller than 32 px, use 32px or above where possible.

The main symbol includes explicit white silhouettes with internal negative space; its border, rune and gem must never be recoloured independently. It is fully legible on dark neutral or photographic backgrounds when contrast is adequate.

## Colour specification

- Logo white: `#FFFFFF` (the *only* master logo paint).
- Ink (presentation only): `#080B12`.
- Dark surface: `#101824`.
- Raised panel: `#1A2432`.
- Text secondary: `#A7B5C6`.

The dark surfaces appear only in showcase banners, website cards or avatar tiles — not in transparent master logo assets.

## Typography

- Display: **Inter Display Black** (outlined as SVG paths in the supplied vector wordmarks).
- UI/headings: **Inter Display SemiBold**, or an equivalent modern sans serif.
- Body: **Inter**, or system sans serif fallback.
- All logo wordmarks here are converted to paths: they render identically without installing any fonts.
- Do not bake any third-party font files into the repository.

## Use rules

DO: preserve proportions; keep transparent artwork unflattened; use pure white on dark backgrounds; maintain empty space; use the same master in SVG/PNG/TGA; use provided wordmark lockups.

DON'T: add neon glows, outlines, textures, 3D embossing, gold fills, Warcraft logos, gradients inside the mark, drop shadows, rotations, nonuniform scaling, extraneous runes or substitutions to the emblem.

## Repository integration

The ZIP contains files rooted at the *repository root*. Copy/extract them into `smouj/forever-hud` preserving folders to replace exactly these legacy paths:

- `assets/logo.svg`
- `assets/banner.svg`
- `assets/icon.png`
- `ForeverHUD/Media/icon.tga`
- `scripts/make_icon.py`

The WoW `.toc` already points to `Interface\AddOns\ForeverHUD\Media\icon.tga`, so no `.toc` change is necessary.

Recommended: add to the existing README header an illustration of `assets/banner.svg`; the current README already links that exact path. Use the `brand/social/open-graph-1200x630.png` file in repository Settings → General → Social preview (a manual GitHub setting).

## Rebuild

`python3 scripts/make_icon.py` requires Pillow and CairoSVG and reconstructs the two runtime raster icons from `assets/logo.svg`. The original build script may have regenerated a different golden symbol; the replacement is source-driven, not hand-drawn.

## Copyright / relationship

ForeverHUD is an independent interface addon. World of Warcraft and associated names are owned by their respective rights holders. Brand assets supplied here are original icon geometry and wordmarks with no official Blizzard artwork or logos.
