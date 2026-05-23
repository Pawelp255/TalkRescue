# App Store screenshot export

Converts iPhone screenshots in `appstore/raw/` into the three portrait sizes App Store Connect accepts, with aspect ratio preserved and black letterboxing when needed.

| Size | Typical use |
|------|-------------|
| 1290×2796 | 6.7" display (e.g. iPhone 15 Pro Max) |
| 1284×2778 | 6.5" display |
| 1242×2688 | 5.5" / legacy 6.5" slot |

Exports are written as PNG to:

```
appstore/export/
  1290x2796/
  1284x2778/
  1242x2688/
```

No frames, captions, or other overlays are added.

## Setup

1. Put source screenshots in:

   ```
   ~/Projects/iOS/TalkRescue/appstore/raw/
   ```

   Supported formats: `.png`, `.jpg`, `.jpeg`, `.webp`, `.heic`, `.heif`

2. Choose Node (recommended) or Python.

### Node.js (sharp)

```bash
cd ~/Projects/iOS/TalkRescue/tools
npm install
```

### Python (Pillow)

```bash
cd ~/Projects/iOS/TalkRescue/tools
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Run

From the **repository root**:

```bash
cd ~/Projects/iOS/TalkRescue
npm run screenshots
```

Or from `tools/`:

```bash
cd ~/Projects/iOS/TalkRescue/tools
npm run screenshots
```

Python alternative:

```bash
cd ~/Projects/iOS/TalkRescue/tools
source .venv/bin/activate   # if using a venv
python export_screenshots.py
```

## Output

Each source file `IMG_0001.png` becomes three files, for example:

- `appstore/export/1290x2796/IMG_0001.png`
- `appstore/export/1284x2778/IMG_0001.png`
- `appstore/export/1242x2688/IMG_0001.png`

Re-running the script overwrites existing exports in those folders.

## Notes

- EXIF orientation is applied before resize (portrait screenshots stay upright).
- Resizing uses high-quality Lanczos sampling; images are not sharpened or blurred artificially.
- Upload the folder that matches your App Store Connect device slot; you usually only need one size family per localization, not all three, unless Connect asks for multiple.
