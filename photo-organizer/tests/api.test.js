import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import os from 'node:os';
import { fileURLToPath } from 'node:url';
import { createServer } from '../server/server.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

test('API Server: Endpoints and file uploads', async (t) => {
  // Use temporary directory for isolated test execution
  const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'photo-organizer-test-'));
  const testUploadsDir = path.join(tmpDir, 'uploads');
  const testDbPath = path.join(tmpDir, 'test.db');

  const { app, db } = createServer({
    uploadsDir: testUploadsDir,
    dbPath: testDbPath
  });

  // Start server on ephemeral port
  const server = await new Promise((resolve) => {
    const s = app.listen(0, () => resolve(s));
  });
  const port = server.address().port;
  const baseUrl = `http://localhost:${port}`;

  t.after(() => {
    server.close();
    db.close();
    try {
      fs.rmSync(tmpDir, { recursive: true, force: true });
    } catch {}
  });

  // 1. Health check
  const healthRes = await fetch(`${baseUrl}/api/health`);
  assert.equal(healthRes.status, 200);
  const healthData = await healthRes.json();
  assert.equal(healthData.status, 'ok');

  // 2. Initial albums should be empty
  const initialAlbumsRes = await fetch(`${baseUrl}/api/albums`);
  assert.equal(initialAlbumsRes.status, 200);
  const initialAlbums = await initialAlbumsRes.json();
  assert.deepEqual(initialAlbums, []);

  // 3. Upload a photo via multipart/form-data
  const sampleSvg = `<svg xmlns="http://www.w3.org/2000/svg" width="400" height="300"><rect width="400" height="300" fill="red"/></svg>`;
  const blob = new Blob([sampleSvg], { type: 'image/svg+xml' });
  const formData = new FormData();
  formData.append('photos', blob, 'test-sunset.svg');
  formData.append('caption', 'My Test Sunset');
  formData.append('date_taken', '2026-11-14T12:00:00.000Z');

  const uploadRes = await fetch(`${baseUrl}/api/photos/upload`, {
    method: 'POST',
    body: formData
  });
  assert.equal(uploadRes.status, 201);
  const uploadData = await uploadRes.json();
  assert.equal(uploadData.success, true);
  assert.equal(uploadData.count, 1);
  const uploadedPhoto = uploadData.photos[0];
  assert.equal(uploadedPhoto.original_name, 'test-sunset.svg');
  assert.equal(uploadedPhoto.caption, 'My Test Sunset');
  assert.equal(uploadedPhoto.date_key, '2026-11-14');

  // 4. Verify file was saved to uploads directory and can be fetched
  const fileOnDisk = path.join(testUploadsDir, uploadedPhoto.filename);
  assert.ok(fs.existsSync(fileOnDisk), 'File must exist on disk');

  const staticRes = await fetch(`${baseUrl}/uploads/${uploadedPhoto.filename}`);
  assert.equal(staticRes.status, 200);

  // 5. Query albums: should contain 1 album with 1 preview photo
  const albumsRes = await fetch(`${baseUrl}/api/albums`);
  assert.equal(albumsRes.status, 200);
  const albums = await albumsRes.json();
  assert.equal(albums.length, 1);
  assert.equal(albums[0].date_key, '2026-11-14');
  assert.equal(albums[0].photo_count, 1);
  assert.equal(albums[0].preview_photos.length, 1);

  // 6. Query album detail
  const albumDetailRes = await fetch(`${baseUrl}/api/albums/${albums[0].id}`);
  assert.equal(albumDetailRes.status, 200);
  const albumDetail = await albumDetailRes.json();
  assert.equal(albumDetail.album.id, albums[0].id);
  assert.equal(albumDetail.photos.length, 1);

  // 7. Search photos
  const searchRes = await fetch(`${baseUrl}/api/photos?q=Sunset`);
  assert.equal(searchRes.status, 200);
  const searchResults = await searchRes.json();
  assert.equal(searchResults.length, 1);
  assert.equal(searchResults[0].caption, 'My Test Sunset');

  // 8. Delete photo: should remove from DB, delete from disk, and delete empty album
  const deleteRes = await fetch(`${baseUrl}/api/photos/${uploadedPhoto.id}`, {
    method: 'DELETE'
  });
  assert.equal(deleteRes.status, 200);
  const deleteData = await deleteRes.json();
  assert.equal(deleteData.success, true);

  assert.ok(!fs.existsSync(fileOnDisk), 'File on disk should be deleted');

  // Albums should now be empty
  const emptyAlbumsRes = await fetch(`${baseUrl}/api/albums`);
  const emptyAlbums = await emptyAlbumsRes.json();
  assert.deepEqual(emptyAlbums, []);
});

