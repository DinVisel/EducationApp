---
name: Liquid Glass Education
colors:
 surface: "#f7f9fb"
 surface-dim: "#d8dadc"
 surface-bright: "#f7f9fb"
 surface-container-lowest: "#ffffff"
 surface-container-low: "#f2f4f6"
 surface-container: "#eceef0"
 surface-container-high: "#e6e8ea"
 surface-container-highest: "#e0e3e5"
 on-surface: "#191c1e"
 on-surface-variant: "#3d4947"
 inverse-surface: "#2d3133"
 inverse-on-surface: "#eff1f3"
 outline: "#6d7a77"
 outline-variant: "#bcc9c6"
 surface-tint: "#006a61"
 primary: "#00685f"
 on-primary: "#ffffff"
 primary-container: "#008378"
 on-primary-container: "#f4fffc"
 inverse-primary: "#6bd8cb"
 secondary: "#9d4300"
 on-secondary: "#ffffff"
 secondary-container: "#fd761a"
 on-secondary-container: "#5c2400"
 tertiary: "#4648d4"
 on-tertiary: "#ffffff"
 tertiary-container: "#6063ee"
 on-tertiary-container: "#fffbff"
 error: "#ba1a1a"
 on-error: "#ffffff"
 error-container: "#ffdad6"
 on-error-container: "#93000a"
 primary-fixed: "#89f5e7"
 primary-fixed-dim: "#6bd8cb"
 on-primary-fixed: "#00201d"
 on-primary-fixed-variant: "#005049"
 secondary-fixed: "#ffdbca"
 secondary-fixed-dim: "#ffb690"
 on-secondary-fixed: "#341100"
 on-secondary-fixed-variant: "#783200"
 tertiary-fixed: "#e1e0ff"
 tertiary-fixed-dim: "#c0c1ff"
 on-tertiary-fixed: "#07006c"
 on-tertiary-fixed-variant: "#2f2ebe"
 background: "#f7f9fb"
 on-background: "#191c1e"
 surface-variant: "#e0e3e5"
typography:
 display:
  fontFamily: Inter
  fontSize: 48px
  fontWeight: "700"
  lineHeight: 56px
  letterSpacing: -0.02em
 headline-lg:
  fontFamily: Inter
  fontSize: 32px
  fontWeight: "700"
  lineHeight: 40px
  letterSpacing: -0.01em
 headline-lg-mobile:
  fontFamily: Inter
  fontSize: 24px
  fontWeight: "700"
  lineHeight: 32px
 headline-md:
  fontFamily: Inter
  fontSize: 24px
  fontWeight: "600"
  lineHeight: 32px
 title-lg:
  fontFamily: Inter
  fontSize: 20px
  fontWeight: "600"
  lineHeight: 28px
 body-lg:
  fontFamily: Inter
  fontSize: 18px
  fontWeight: "400"
  lineHeight: 28px
 body-md:
  fontFamily: Inter
  fontSize: 16px
  fontWeight: "400"
  lineHeight: 24px
 label-md:
  fontFamily: Inter
  fontSize: 14px
  fontWeight: "500"
  lineHeight: 20px
  letterSpacing: 0.01em
 label-sm:
  fontFamily: Inter
  fontSize: 12px
  fontWeight: "600"
  lineHeight: 16px
  letterSpacing: 0.04em
rounded:
 sm: 0.25rem
 DEFAULT: 0.5rem
 md: 0.75rem
 lg: 1rem
 xl: 1.5rem
 full: 9999px
spacing:
 unit: 4px
 xs: 4px
 sm: 8px
 md: 16px
 lg: 24px
 xl: 32px
 gutter: 16px
 margin-mobile: 20px
 margin-desktop: 40px
---

## Brand & Style

This design system targets primary school educators, balancing the high-utility needs of a professional tool with the warmth and vibrancy of a learning environment. The brand personality is encouraging, organized, and light.

The aesthetic is rooted in **Glassmorphism**, utilizing translucent layers to create a sense of physical depth without visual clutter. The "Liquid Glass" effect is achieved through high-diffusion background blurs and subtle border gradients that mimic light catching the edge of a pane. The interface should feel fluid and responsive, utilizing soft transitions and organic movement to reduce the cognitive load on teachers during busy classroom hours.

## Colors

The palette is anchored by **Teal** (Primary) for stability and focus, **Soft Orange** (Secondary) for energy and student-related alerts, and **Indigo** (Tertiary) for specialized academic features or high-level navigation.

Neutral tones are cool-weighted to keep the "glass" looking crisp. For accessibility, text colors must maintain a contrast ratio of at least 4.5:1 against the frosted glass backgrounds. Use `glass_background` for container surfaces, ensuring the background behind these containers features organic, colorful shapes or gradients to make the "liquid" effect visible.

## Typography

**Inter** is utilized for its exceptional legibility and modern, systematic feel. Headlines use tight letter-spacing and bold weights to provide strong visual anchors atop semi-transparent backgrounds.

Body text is optimized for long-form reading of lesson plans and student reports. For mobile views, display sizes scale down aggressively to ensure clear information hierarchy on handheld devices. All labels should use medium or semi-bold weights to remain legible when placed over blurred background elements.

## Layout & Spacing

The design system employs a **fluid grid** model with a base-8 spacing scale for primary layout and a base-4 scale for micro-interactions.

On mobile, the layout uses a 4-column structure with 20px side margins. On tablet and desktop, this expands to a 12-column grid. Components should use generous padding (min 16px) to maintain the "lightweight" feel. Glass containers often overlap or stack, so use the `lg` (24px) spacing unit to define clear separation between distinct functional blocks.

## Elevation & Depth

Depth is not communicated through heavy shadows, but through **Tonal Layers** and **Backdrop Blurs**.

1. **Level 0 (Base):** Background with soft, colorful gradients.
2. **Level 1 (Surface):** Glass containers with a 16px blur and a 1px semi-transparent white border to simulate an edge-light.
3. **Level 2 (Float):** Popovers and active cards use a subtle, extra-diffused shadow (Color: `primary_color`, Opacity: 8%, Blur: 20px) to indicate they are "floating" higher above the base.

Avoid solid-color containers. Always use transparency and blur to maintain the "liquid" theme.

## Shapes

The shape language is **Rounded**, reflecting a friendly and safe environment for education.

Standard components use a `0.5rem` (8px) radius. Larger glass panels and containers should utilize the `rounded-xl` (1.5rem / 24px) setting to create a soft, "pill-like" appearance that feels approachable. Interactive elements like buttons should feel tactile; avoid sharp corners entirely.

## Components

### Buttons

Primary buttons use a solid Teal fill with white text and a subtle inner-glow. Secondary buttons use the "Glass" style: a translucent background with a primary-colored border and text.

### Chips

Used for student tags or subject categories. Chips should be highly rounded (pill-shaped) with low-opacity versions of the accent colors (e.g., 10% Teal background with 100% Teal text).

### Cards

All cards are glass-morphic. They must feature a 1px top-left highlight border (white at 40% opacity) and a bottom-right lowlight border (white at 10% opacity) to create a 3D glass effect.

### Input Fields

Inputs are semi-transparent with a 2px bottom border that glows in the primary teal color when focused. Use high-contrast placeholder text for accessibility.

### Lists

List items are separated by subtle 1px glass dividers. Use "Active" states that apply a slight scale-up (1.02x) and increase the background blur intensity.

### Progress Bars (Specialty)

For tracking student progress. Use a "liquid" fill—a gradient of the primary color moving from left to right, housed within a frosted glass track.
