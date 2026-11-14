# SpecKit Tasks: Photo Organizer

## Phase 1: Project Setup & Storage Infrastructure
- [x] **TASK-01:** Initialize `package.json` with Express, Multer, Vite, and development dependencies.
- [x] **TASK-02:** Configure `vite.config.js` with reverse proxy for `/api` and `/uploads` pointing to backend port.
- [x] **TASK-03:** Implement `server/db.js` using Node 22 built-in `node:sqlite` (`DatabaseSync`):
  - Create `albums` and `photos` tables with foreign keys and indexes.
  - Implement `getOrCreateAlbumForDate(dateStr)`.
  - Implement `insertPhoto(photoData)`.
  - Implement `getAlbumsWithPreviews()`.
  - Implement `getAlbumWithPhotos(albumId)`.
  - Implement `deletePhoto(photoId)`.
  - Implement `searchPhotos(query)`.

## Phase 2: Backend REST API & Local File Storage
- [x] **TASK-04:** Implement `server/server.js`:
  - Multer storage engine saving files to `photo-organizer/uploads/` with unique filenames.
  - Metadata parsing: capture date detection (file stat mtime / EXIF), image dimensions.
  - REST endpoints: `GET /api/albums`, `GET /api/albums/:id`, `GET /api/photos`, `POST /api/photos/upload`, `DELETE /api/photos/:id`.
  - Static file serving for `/uploads/` with caching headers.
- [x] **TASK-05:** Implement `server/seed.js`:
  - Generate initial sample photos across distinct dates (e.g., today, yesterday, last week, last month) to ensure albums populate immediately on first run.

## Phase 3: Frontend Client & Components (Vite + Vanilla JS)
- [x] **TASK-06:** Implement `src/api.js`:
  - Fetch client methods: `getAlbums()`, `getAlbum(id)`, `uploadPhotos(files)`, `deletePhoto(id)`, `searchPhotos(query)`.
- [x] **TASK-07:** Implement `src/components/AlbumGrid.js`:
  - Render date-grouped albums in reverse chronological order.
  - Render dynamic tile preview (1 hero, 2 columns, 3 split, or 2x2 grid with "+N" badge).
  - Handle album click to enter gallery view.
- [x] **TASK-08:** Implement `src/components/PhotoGrid.js`:
  - Render high-resolution photo gallery for selected album.
  - Breadcrumb / back button to return to albums list.
  - Actions: open lightbox, delete photo with confirmation.
- [x] **TASK-09:** Implement `src/components/PhotoModal.js`:
  - Native `<dialog>` element with `closedby="any"` and light-dismiss fallback script.
  - CSS scroll containment (`overscroll-behavior: contain`).
  - Next/Previous image buttons and keyboard navigation (`ArrowLeft`, `ArrowRight`, `Escape`).
  - Metadata sidebar/drawer (date taken, dimensions, file size, original name).
- [x] **TASK-10:** Implement `src/components/Uploader.js`:
  - Drag-and-drop dropzone + file input button.
  - Progress indicator and upload status toast.
- [x] **TASK-11:** Implement `src/components/Header.js`:
  - Brand header, search input with live debounced filtering, upload shortcut button, theme toggle.
- [x] **TASK-12:** Implement `src/style.css`:
  - Mobile-first responsive CSS Grid & Flexbox layouts.
  - Mobile touch target compliance (>= 44px).
  - Dark/Light modern theme with smooth transitions.
  - Tile preview CSS grid templates (`.tile-layout-1`, `.tile-layout-2`, `.tile-layout-3`, `.tile-layout-4`).
- [x] **TASK-13:** Implement `src/main.js` and `index.html`:
  - Coordinate application state, route between Albums and Detail views, wire all event listeners.

## Phase 4: Automated Testing & Convergence
- [x] **TASK-14:** Implement `tests/db.test.js`:
  - Unit tests verifying album creation, photo insertion, preview query, date sorting, cascading deletes.
- [x] **TASK-15:** Implement `tests/api.test.js`:
  - Integration tests verifying `GET /api/albums`, `POST /api/photos/upload`, and `DELETE /api/photos/:id`.
- [x] **TASK-16:** Run test suite with `node --test` and ensure 100% pass rate.
- [x] **TASK-17:** Run Vite build (`npm run build`) to ensure bundle compiles without errors.

