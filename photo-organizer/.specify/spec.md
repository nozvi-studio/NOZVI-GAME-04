# SpecKit Specification: Photo Organizer

## 1. Executive Summary
The **Photo Organizer** is a high-performance, local-first web application designed to catalog, organize, and view photos. It automatically groups photos into albums based on their capture or upload dates and displays each album with a dynamic **tile preview** (a multi-thumbnail mosaic displaying the most recent photos from that album).

All photo files are stored securely on the local filesystem, and comprehensive metadata (dimensions, timestamps, EXIF info, titles, descriptions) is managed in an embedded SQLite database.

---

## 2. User Stories

### US-1: Date-Grouped Album Catalog
- **As a user**, I want my photos automatically grouped into albums by date (e.g., Year, Month, or specific Day: "2026-11-14", "November 2026"), so that I can easily navigate my photos chronologically.
- **Acceptance Criteria:**
  - The main screen lists albums in reverse chronological order (newest dates first).
  - Each album header clearly displays the formatted date and the photo count.

### US-2: Multi-Tile Album Preview
- **As a user**, I want to see a tile preview (mosaic of 1 to 4 thumbnail images) for each album card, so that I can visually identify the album's contents at a glance.
- **Acceptance Criteria:**
  - Albums with 1 photo show a single hero image tile.
  - Albums with 2 photos show a 2-column split tile.
  - Albums with 3 photos show 1 large tile + 2 stacked small tiles.
  - Albums with 4 or more photos show a balanced 2x2 grid preview with a "+N more" badge if photos exceed 4.

### US-3: Album Detail & Photo Gallery
- **As a user**, I can click any album card to open its full photo grid, showing all photos taken on that date in high fidelity.
- **Acceptance Criteria:**
  - Smooth transition to the album's photo gallery view.
  - Ability to navigate back to the albums list with one click.

### US-4: Full-Resolution Lightbox / Modal Viewer
- **As a user**, I can click on any photo to open a full-resolution viewer with metadata details (date, file name, dimensions, file size).
- **Acceptance Criteria:**
  - Implemented using native `<dialog>` with `closedby="any"` and light-dismiss support.
  - Previous / Next buttons or keyboard arrows (`ArrowLeft`, `ArrowRight`) to navigate between photos in the album.
  - Close button and Escape key dismiss.
  - Delete button to remove a photo from both SQLite and local disk.

### US-5: Drag & Drop / File Upload
- **As a user**, I can drag and drop photos or click an "Upload Photos" button to add local image files (`.jpg`, `.jpeg`, `.png`, `.webp`, `.gif`).
- **Acceptance Criteria:**
  - Upload drawer or drop zone with immediate visual feedback and upload progress.
  - Backend extracts capture date (EXIF `DateTimeOriginal` if available, falling back to file `lastModified` or current date).
  - Automatically associates photos into existing date albums or creates a new date album dynamically.

### US-6: Responsive Mobile Experience
- **As a mobile user**, I can seamlessly use the app on mobile devices (portrait and landscape) without overflow, awkward scrolling, or tiny click targets.
- **Acceptance Criteria:**
  - Album cards and photo grids scale cleanly from 320px mobile viewports up to 4K displays.
  - Bottom-anchored or compact top actions on mobile.
  - Touch targets >= 44px.

---

## 3. Data Model

### Table: `albums`
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique album ID |
| `date_key` | TEXT | UNIQUE NOT NULL | Canonical date string (e.g. `YYYY-MM-DD`) |
| `title` | TEXT | NOT NULL | Human-friendly title (e.g. "November 14, 2026") |
| `created_at` | TEXT | DEFAULT CURRENT_TIMESTAMP | Timestamp of creation |

### Table: `photos`
| Column | Type | Constraints | Description |
|---|---|---|---|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT | Unique photo ID |
| `album_id` | INTEGER | REFERENCES albums(id) ON DELETE CASCADE | Associated date album |
| `filename` | TEXT | NOT NULL | Stored filename on disk in `uploads/` |
| `original_name`| TEXT | NOT NULL | Original uploaded filename |
| `mime_type` | TEXT | NOT NULL | e.g. `image/jpeg`, `image/png` |
| `size_bytes` | INTEGER | NOT NULL | File size in bytes |
| `width` | INTEGER | DEFAULT 0 | Image width in pixels |
| `height` | INTEGER | DEFAULT 0 | Image height in pixels |
| `date_taken` | TEXT | NOT NULL | ISO date string or `YYYY-MM-DD HH:MM:SS` |
| `camera_model`| TEXT | DEFAULT '' | EXIF camera model if present |
| `caption` | TEXT | DEFAULT '' | Optional user caption |
| `created_at` | TEXT | DEFAULT CURRENT_TIMESTAMP | Timestamp of upload |

---

## 4. API Endpoints Contract

- `GET /api/albums`: Returns list of all albums with photo count and preview photo URLs (up to 4 preview thumbnails per album).
- `GET /api/albums/:id`: Returns album details and full list of photos in the album.
- `GET /api/photos`: Query photos with optional `album_id`, `search`, `limit`, and `offset`.
- `GET /api/photos/:id`: Returns single photo metadata.
- `POST /api/photos/upload`: Multipart upload endpoint (`photos` field, supports single/multiple files).
- `PATCH /api/photos/:id`: Update photo caption or title.
- `DELETE /api/photos/:id`: Deletes photo record from SQLite and unlinks file from local disk.
- `GET /uploads/:filename`: Serves static image with proper mime-type and cache headers.

