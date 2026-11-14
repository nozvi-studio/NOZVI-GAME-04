import express from 'express';
import cors from 'cors';
import multer from 'multer';
import path from 'node:path';
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';
import imageSize from 'image-size';
import { createDatabase } from './db.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export function createServer(options = {}) {
  const uploadsDir = options.uploadsDir || path.join(__dirname, '..', 'uploads');
  const dbPath = options.dbPath || path.join(__dirname, '..', 'photos.db');

  if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
  }

  const db = createDatabase(dbPath);
  const app = express();

  app.use(cors());
  app.use(express.json());

  // Static uploads directory with caching
  app.use('/uploads', express.static(uploadsDir, {
    maxAge: '7d',
    setHeaders: (res) => {
      res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    }
  }));

  // Multer storage
  const storage = multer.diskStorage({
    destination: (_req, _file, cb) => {
      cb(null, uploadsDir);
    },
    filename: (_req, file, cb) => {
      const ext = path.extname(file.originalname).toLowerCase() || '.jpg';
      const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
      cb(null, `photo-${uniqueSuffix}${ext}`);
    }
  });

  const upload = multer({
    storage,
    limits: { fileSize: 50 * 1024 * 1024 }, // 50MB
    fileFilter: (_req, file, cb) => {
      const allowed = /jpeg|jpg|png|webp|gif|svg\+xml|svg/;
      const isMimeOk = allowed.test(file.mimetype);
      const isExtOk = allowed.test(path.extname(file.originalname).toLowerCase().replace('.', ''));
      if (isMimeOk || isExtOk) {
        cb(null, true);
      } else {
        cb(new Error('Only image files (JPEG, PNG, WebP, GIF, SVG) are allowed'));
      }
    }
  });

  // Health check
  app.get('/api/health', (_req, res) => {
    res.json({ status: 'ok', timestamp: new Date().toISOString() });
  });

  // GET /api/albums - List all albums with previews
  app.get('/api/albums', (_req, res) => {
    try {
      const albums = db.getAlbumsWithPreviews();
      res.json(albums);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  // GET /api/albums/:id - Single album with all photos
  app.get('/api/albums/:id', (req, res) => {
    try {
      const albumId = Number(req.params.id);
      const data = db.getAlbumWithPhotos(albumId);
      if (!data) {
        return res.status(404).json({ error: 'Album not found' });
      }
      res.json(data);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  // GET /api/photos - Search or list photos
  app.get('/api/photos', (req, res) => {
    try {
      const query = (req.query.q || '').trim();
      if (query) {
        const results = db.searchPhotos(query);
        return res.json(results);
      }
      // Return recent photos
      const results = db.searchPhotos('');
      res.json(results);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  // GET /api/photos/:id - Single photo details
  app.get('/api/photos/:id', (req, res) => {
    try {
      const photo = db.getPhotoById(Number(req.params.id));
      if (!photo) {
        return res.status(404).json({ error: 'Photo not found' });
      }
      res.json(photo);
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  // POST /api/photos/upload - Upload one or more photos
  app.post('/api/photos/upload', upload.array('photos', 50), async (req, res) => {
    try {
      const files = req.files || [];
      if (files.length === 0) {
        return res.status(400).json({ error: 'No image files uploaded' });
      }

      const insertedPhotos = [];

      for (const file of files) {
        let width = 0;
        let height = 0;
        try {
          const dims = imageSize(file.path);
          if (dims) {
            width = dims.width || 0;
            height = dims.height || 0;
          }
        } catch {
          // If imageSize fails, retain default 0
        }

        // Determine date taken: explicit client date or file stat mtime
        let dateTakenISO;
        if (req.body.date_taken) {
          const parsed = new Date(req.body.date_taken);
          dateTakenISO = isNaN(parsed.getTime()) ? new Date().toISOString() : parsed.toISOString();
        } else {
          try {
            const stat = fs.statSync(file.path);
            dateTakenISO = stat.mtime.toISOString();
          } catch {
            dateTakenISO = new Date().toISOString();
          }
        }

        const dateKey = dateTakenISO.slice(0, 10); // 'YYYY-MM-DD'
        const album = db.getOrCreateAlbumForDate(dateKey);

        const photo = db.insertPhoto({
          album_id: album.id,
          filename: file.filename,
          original_name: file.originalname,
          mime_type: file.mimetype,
          size_bytes: file.size,
          width,
          height,
          date_taken: dateTakenISO,
          camera_model: req.body.camera_model || '',
          caption: req.body.caption || ''
        });

        insertedPhotos.push({
          ...photo,
          date_key: album.date_key,
          album_title: album.title
        });
      }

      res.status(201).json({
        success: true,
        count: insertedPhotos.length,
        photos: insertedPhotos
      });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  // DELETE /api/photos/:id - Delete photo from DB and disk
  app.delete('/api/photos/:id', async (req, res) => {
    try {
      const photoId = Number(req.params.id);
      const photo = db.getPhotoById(photoId);
      if (!photo) {
        return res.status(404).json({ error: 'Photo not found' });
      }

      // Delete from database (also deletes empty album if needed)
      db.deletePhoto(photoId);

      // Delete file from disk
      const filePath = path.join(uploadsDir, photo.filename);
      if (fs.existsSync(filePath)) {
        try {
          fs.unlinkSync(filePath);
        } catch (unlinkErr) {
          console.warn('Could not remove file from disk:', unlinkErr.message);
        }
      }

      res.json({ success: true, deletedPhoto: photo });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
  });

  // Serve Vite production build if dist folder exists
  const distDir = path.join(__dirname, '..', 'dist');
  if (fs.existsSync(distDir)) {
    app.use(express.static(distDir));
    app.get('*', (_req, res) => {
      res.sendFile(path.join(distDir, 'index.html'));
    });
  }

  return { app, db, uploadsDir };
}

// Standalone execution
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  const PORT = process.env.PORT || 3001;
  const { app } = createServer();
  app.listen(PORT, () => {
    console.log(`[Photo Organizer API] Server running on http://localhost:${PORT}`);
  });
}

