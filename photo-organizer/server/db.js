import { DatabaseSync } from 'node:sqlite';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export function createDatabase(dbFilePath = path.join(__dirname, '..', 'photos.db')) {
  const db = new DatabaseSync(dbFilePath);

  // Enable foreign key constraints and WAL mode for reliability
  db.exec('PRAGMA foreign_keys = ON;');

  // Schema creation
  db.exec(`
    CREATE TABLE IF NOT EXISTS albums (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date_key TEXT UNIQUE NOT NULL,
      title TEXT NOT NULL,
      created_at TEXT DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS photos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      album_id INTEGER NOT NULL,
      filename TEXT NOT NULL,
      original_name TEXT NOT NULL,
      mime_type TEXT NOT NULL,
      size_bytes INTEGER NOT NULL,
      width INTEGER DEFAULT 0,
      height INTEGER DEFAULT 0,
      date_taken TEXT NOT NULL,
      camera_model TEXT DEFAULT '',
      caption TEXT DEFAULT '',
      created_at TEXT DEFAULT (datetime('now')),
      FOREIGN KEY (album_id) REFERENCES albums(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_photos_album_id ON photos(album_id);
    CREATE INDEX IF NOT EXISTS idx_photos_date_taken ON photos(date_taken DESC);
    CREATE INDEX IF NOT EXISTS idx_albums_date_key ON albums(date_key DESC);
  `);

  /**
   * Format YYYY-MM-DD into a readable title like "November 14, 2026"
   */
  function formatDateTitle(dateKey) {
    try {
      const [year, month, day] = dateKey.split('-').map(Number);
      if (!year || !month || !day) return dateKey;
      const date = new Date(year, month - 1, day);
      return new Intl.DateTimeFormat('en-US', {
        month: 'long',
        day: 'numeric',
        year: 'numeric'
      }).format(date);
    } catch {
      return dateKey;
    }
  }

  /**
   * Get existing album for date or create a new one
   */
  function getOrCreateAlbumForDate(dateKey) {
    const findStmt = db.prepare('SELECT * FROM albums WHERE date_key = ?');
    const existing = findStmt.get(dateKey);
    if (existing) return existing;

    const title = formatDateTitle(dateKey);
    const insertStmt = db.prepare('INSERT INTO albums (date_key, title) VALUES (?, ?)');
    const result = insertStmt.run(dateKey, title);
    return {
      id: Number(result.lastInsertRowid),
      date_key: dateKey,
      title: title,
      created_at: new Date().toISOString()
    };
  }

  /**
   * Insert a new photo record
   */
  function insertPhoto({
    album_id,
    filename,
    original_name,
    mime_type,
    size_bytes,
    width = 0,
    height = 0,
    date_taken,
    camera_model = '',
    caption = ''
  }) {
    const stmt = db.prepare(`
      INSERT INTO photos (
        album_id, filename, original_name, mime_type, size_bytes,
        width, height, date_taken, camera_model, caption
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);
    const result = stmt.run(
      album_id,
      filename,
      original_name,
      mime_type,
      size_bytes,
      width,
      height,
      date_taken,
      camera_model,
      caption
    );

    return {
      id: Number(result.lastInsertRowid),
      album_id,
      filename,
      original_name,
      mime_type,
      size_bytes,
      width,
      height,
      date_taken,
      camera_model,
      caption
    };
  }

  /**
   * Get all albums with photo count and up to 4 preview thumbnails
   */
  function getAlbumsWithPreviews() {
    const albums = db.prepare(`
      SELECT 
        a.id, 
        a.date_key, 
        a.title, 
        a.created_at,
        COUNT(p.id) as photo_count
      FROM albums a
      LEFT JOIN photos p ON p.album_id = a.id
      GROUP BY a.id
      ORDER BY a.date_key DESC
    `).all();

    const previewStmt = db.prepare(`
      SELECT id, filename, width, height, caption, date_taken
      FROM photos
      WHERE album_id = ?
      ORDER BY date_taken DESC, id DESC
      LIMIT 4
    `);

    return albums.map(album => {
      const previews = previewStmt.all(album.id);
      return {
        ...album,
        photo_count: Number(album.photo_count),
        preview_photos: previews
      };
    });
  }

  /**
   * Get single album with all of its photos
   */
  function getAlbumWithPhotos(albumId) {
    const album = db.prepare('SELECT * FROM albums WHERE id = ?').get(albumId);
    if (!album) return null;

    const photos = db.prepare(`
      SELECT * FROM photos
      WHERE album_id = ?
      ORDER BY date_taken DESC, id DESC
    `).all(albumId);

    return {
      album,
      photos
    };
  }

  /**
   * Get photo by ID
   */
  function getPhotoById(photoId) {
    return db.prepare(`
      SELECT p.*, a.date_key, a.title as album_title
      FROM photos p
      JOIN albums a ON a.id = p.album_id
      WHERE p.id = ?
    `).get(photoId);
  }

  /**
   * Delete photo by ID and remove empty album if needed
   */
  function deletePhoto(photoId) {
    const photo = getPhotoById(photoId);
    if (!photo) return null;

    db.prepare('DELETE FROM photos WHERE id = ?').run(photoId);

    // Check if album is now empty; if so, delete the album
    const countResult = db.prepare('SELECT COUNT(*) as count FROM photos WHERE album_id = ?').get(photo.album_id);
    if (Number(countResult.count) === 0) {
      db.prepare('DELETE FROM albums WHERE id = ?').run(photo.album_id);
    }

    return photo;
  }

  /**
   * Search photos across captions, filenames, or album titles
   */
  function searchPhotos(term) {
    const pattern = `%${term}%`;
    return db.prepare(`
      SELECT p.*, a.date_key, a.title as album_title
      FROM photos p
      JOIN albums a ON a.id = p.album_id
      WHERE p.caption LIKE ? 
         OR p.original_name LIKE ? 
         OR a.title LIKE ?
         OR a.date_key LIKE ?
      ORDER BY p.date_taken DESC, p.id DESC
      LIMIT 100
    `).all(pattern, pattern, pattern, pattern);
  }

  /**
   * Close database
   */
  function close() {
    db.close();
  }

  return {
    rawDb: db,
    getOrCreateAlbumForDate,
    insertPhoto,
    getAlbumsWithPreviews,
    getAlbumWithPhotos,
    getPhotoById,
    deletePhoto,
    searchPhotos,
    close
  };
}
