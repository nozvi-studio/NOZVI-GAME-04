# SpecKit Constitution: Photo Organizer Engineering Principles

## Preamble
This Constitution sets forth the architectural, quality, testing, and maintainability mandates for the Photo Organizer system. All planning, task breakdown, code generation, and verification phases MUST adhere to these non-negotiable principles.

---

## Principle 1: Code Quality, Modularity & Architecture
1. **Separation of Concerns:**
   - **Frontend:** Pure vanilla JavaScript using standard ES Modules (`import`/`export`), semantic HTML5, and modern responsive CSS. No heavy framework dependencies.
   - **Backend:** Lightweight, headless REST service handling image file streaming, local disk persistence, metadata parsing, and SQLite persistence.
   - **Data Layer:** SQLite relational storage accessed through an isolated repository pattern.
2. **Zero Code Duplication (DRY):** Common logic (date formatting, byte size formatting, DOM creation helpers, API client wrappers) MUST reside in centralized utility modules.
3. **No Mocks or Placeholders in Production:** All code paths must be fully implemented, functional, and self-contained. No `TODO`, `FIXME`, or stubbed fake data in shipping artifacts.
4. **Resilient Error Handling:** All async operations (file system, network I/O, database queries) must employ explicit `try/catch` or error middleware, returning standard structured JSON error responses: `{ error: string, code?: string, details?: any }`.

---

## Principle 2: Rigorous Automated Testing
1. **Test-First Verification:** Core domain logic, database operations, and API contracts must be validated with automated tests using Node's native test runner (`node:test` and `node:assert`).
2. **Coverage Targets:**
   - Database CRUD & date aggregation: 100% of queries tested with clean setup/teardown.
   - REST API endpoints: Upload, list albums by date, retrieve photos, update metadata, and deletion must be verified.
3. **Reproducibility:** Tests must execute in isolation using an in-memory or dedicated test SQLite database without polluting the production uploads directory.

---

## Principle 3: Long-Term Maintainability & Clean Interfaces
1. **Self-Documenting Code:** Code must be clear, concise, and structured with descriptive naming. JSDoc comments must clarify function signatures and complex logic.
2. **Deterministic State Management:** Frontend UI updates must follow a unidirectional data flow (State -> Render -> User Event -> Action -> API Call -> State Update).
3. **Schema Migrations & Integrity:** The SQLite database schema must use strict data types, foreign key constraints, default timestamps, and appropriate indexes on `date_taken` and `album_id` for fast grouping and range queries.

---

## Principle 4: Data Locality & Performance
1. **Local-First Storage:** All binary image assets remain strictly local on disk in the application directory. No remote cloud storage dependency.
2. **SQLite Metadata Storage:** Image metadata (dimensions, mime type, byte size, capture date, title, tags, album grouping) is stored in SQLite for sub-millisecond query performance.
3. **Responsive Image Delivery:** Thumbnails and previews must be rendered efficiently with CSS grid tile mosaics, responsive image sizing, and browser cache headers (`Cache-Control: public, max-age=...`).

---

## Principle 5: Mobile-First Responsive Design & Accessibility (Modern Web Guidance)
1. **Mobile Compliance:** The layout must natively adapt to small mobile screens (down to 320px width), tablet screens, and wide desktop screens using fluid CSS Grid and Flexbox. Touch targets must be at least 44x44px.
2. **Modern Dialog Standards:** Photo viewing dialogs must use the native `<dialog>` element with `closedby="any"` and a click-outside fallback script for light-dismiss.
3. **Scroll Containment:** Dialogs must prevent background scroll chaining using `overscroll-behavior: contain` and `overflow: hidden` on `::backdrop`.
4. **Keyboard Accessibility:** All interactive elements must support keyboard navigation (`Tab`, `Enter`, `Escape`), with focus trapping inside active modals.

