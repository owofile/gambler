# Assets Directory

This directory contains all visual and audio assets for the Gambler project.

## Directory Structure

```
assets/
├── ui/                    # UI elements
│   ├── buttons/           # Button textures
│   ├── panels/           # Panel backgrounds
│   └── icons/            # Icon sprites
├── cards/                 # Card-related assets
│   ├── backgrounds/       # Card background images
│   └── frames/           # Card frame/border designs
├── backgrounds/           # Scene background images
├── effects/               # Visual effect textures
└── fonts/                 # Custom fonts
```

## Adding Assets

1. Copy your image files (.png, .jpg, .svg) into the appropriate subdirectory
2. Godot will automatically import them
3. Use the assets in scenes via drag-drop or ExtResource path

## Supported Formats

- Images: PNG, JPG, SVG, WebP
- Fonts: TTF, OTF (place in fonts/ directory)