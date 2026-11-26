# Cheerful Garden Typography

Official Google Fonts originals, unmodified:

| Family | Runtime use | Official source | License |
| --- | --- | --- | --- |
| Lilita One | Large titles, popup/menu titles | https://github.com/google/fonts/tree/main/ofl/lilitaone | lilitaone/OFL.txt |
| Fredoka | Bold 700: buttons, headings, names, prices/numbers. SemiBold 600: tabs/subtitles/labels | https://github.com/google/fonts/tree/main/ofl/fredoka | fredoka/OFL.txt |
| Nunito | SemiBold 600: descriptions, instructions, tooltips, supporting text | https://github.com/google/fonts/tree/main/ofl/nunito | nunito/OFL.txt |

Noto Sans Symbols 2 is bundled only as a glyph fallback for symbols such as checkmarks, diamonds and play buttons. It is not a fourth body/UI typeface. Official source: https://github.com/google/fonts/tree/main/ofl/notosanssymbols2 ; license: symbols/OFL.txt.

All four use SIL Open Font License 1.1; complete original licenses and copyright notices are included. Export presets explicitly include each OFL.txt. SOURCES.json records SHA-256 checksums and source locations. Font files are about 1.7 MB total including the symbol fallback; no runtime download or operating-system font dependency is required for game typography.

`garden_theme.tres` is configured as the project-wide Theme. `styles/` contains shared FontVariation resources. OpenType weights use the integer tag `2003265652` (`wght`). This is deliberate: tests inspect the TextServer RID coordinates, rather than trusting base font names (which still say Light/ExtraLight for these variable fonts).

`res://scripts/typography.gd` is an autoload that assigns Theme type variations to existing and dynamically added controls. It reacts to control creation and layout changes; it does not scan the entire UI each frame. It preserves existing color/stylebox overrides, illustrations, click targets and callbacks. Sizes belong to component layout; small text has a 16-unit floor and oversized captions can wrap, with at most 15% fitting reduction. The existing 720-wide canvas scaling handles portrait density/aspect changes.

Reusable roles: GardenTitle, GardenHeading, GardenSubtitle, GardenBody, GardenPrice, GardenButton, GardenTab. Set a role explicitly with `control.set_meta("typography_role", "title")` before adding the control; or call `preload("res://scripts/typography.gd").role(control,"title")`. Labels made by the main factory retain their intended rectangle as typography_extent, allowing accurate wrapping instead of expanding outside their panel. For custom absolute-positioned labels, supply that metadata. Container labels remain container-managed.

Title outline/shadow are centralized in GardenTitle. Canvas world labels use the same Fredoka Bold resource for BOTH measurement and drawing. RichTextLabel, LineEdit, TextEdit, tooltip, popup menu, item list, progress bar and native tab defaults are provided by the global Theme.

Text baked into the existing logo, illustrations and intro video is intentionally untouched; this system covers rendered UI text. Third-party AdMob editor/sample assets are not modified.
