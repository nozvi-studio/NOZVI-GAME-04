# PhotoSphere - Local Photo Organizer

A fast, privacy-respecting local photo organizer built with **Vite**, **vanilla JavaScript**, and **SQLite** (via Node.js `node:sqlite`). Photos remain strictly on your local disk with metadata indexed in SQLite.

---

## Key Features

1. **Date-Grouped Albums:**
   - Automatically groups photos into albums by capture date (EXIF / file timestamp).
   - Albums are presented chronologically with formatted dates (e.g., "November 14, 2026", "Today").

2. **Dynamic Multi-Tile Preview Mosaics:**
   - **1 Photo:** Full-size single hero tile.
   - **2 Photos:** 2 equal vertical split columns.
   - **3 Photos:** 1 large left hero tile + 2 stacked right tiles.
   - **4+ Photos:** Symmetrical 2x2 grid with a blurred `+N` badge indicating remaining photos.

3. **High-Fidelity Photo Gallery & Lightbox:**
   - Click any album card to view its photo grid.
   - Native `<dialog closedby="any">` lightbox modal with background scroll containment.
   - Keyboard navigation (`ArrowLeft`, `ArrowRight`, `Escape`).
   - Detailed metadata inspection drawer (dimensions, file size, date, format, camera model).
   - Single-click download and photo deletion (with disk cleanup & empty album cleanup).

4. **Drag & Drop Local Photo Uploader:**
   - Multi-file drag and drop or file picker.
   - Live client thumbnail previews and real-time upload progress bar.
   - Optional caption and date overrides.

5. **Mobile-First Responsive Design:**
   - Compliant with mobile screens (down to 320px width), tablet, and desktop viewports.
   - All interactive touch targets are $\ge 44 \times 44\text{ px}$.
   - Dark and Light theme toggle with `localStorage` persistence.

---

## Project Structure

```
photo-organizer/
├── .specify/
│   ├── constitution.md     # Engineering principles (quality, testing, maintainability)
│   ├── spec.md             # Functional specification & data model
│   ├── plan.md             # Technical architecture & schema
│   └── tasks.md            # Detailed task breakdown & checklist
├── server/
│   ├── db.js               # SQLite DatabaseSync layer (Node 22 built-in)
│   ├── server.js           # Express REST API, Multer upload engine, static serving
│   └── seed.js             # Realistic sample photo generator
├── src/
│   ├── components/
│   │   ├── AlbumGrid.js    # Date album cards & tile preview mosaics
│   │   ├── PhotoGrid.js    # Album gallery view & card overlays
│   │   ├── PhotoModal.js   # Native <dialog> image viewer & metadata drawer
│   │   ├── Uploader.js     # Drag-and-drop uploader with progress tracking
│   │   └── Header.js       # Search, view switch, theme toggle, brand
│   ├── api.js              # REST client wrapper
│   ├── utils.js            # Date & byte formatting helpers
│   ├── main.js             # App coordinator & state manager
│   └── style.css           # Mobile-first CSS design system
├── tests/
│   ├── db.test.js          # Unit tests for SQLite queries & date grouping
│   └── api.test.js         # Integration tests for REST endpoints & uploads
├── uploads/                # Local photo storage directory
├── index.html              # Vite entry shell
├── package.json            # Scripts & dependencies
└── vite.config.js          # Vite configuration with API reverse proxy
```

---

## Quick Start

### 1. Seed Sample Photos (Optional but recommended for instant preview)
```bash
npm run seed
```

### 2. Run in Development Mode
Start the backend server and Vite dev server:
```bash
# Terminal 1: Start backend API
npm run server

# Terminal 2: Start Vite frontend
npm run dev
```
Open [http://localhost:5173](http://localhost:5173) in your browser.

### 3. Run Production Build
```bash
npm run build
npm run server
```
Open [http://localhost:3001](http://localhost:3001) in your browser.

### 4. Run Automated Tests
```bash
npm test
```
Runs unit tests for the SQLite repository and integration tests for the API server using Node's native test runner (`node:test`).

