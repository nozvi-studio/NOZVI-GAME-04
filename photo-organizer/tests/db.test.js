import test from 'node:test';
import assert from 'node:assert/strict';
import { createDatabase } from '../server/db.js';

test('Database: album creation and date grouping', () => {
  const db = createDatabase(':memory:');

  try {
    // 1. Get or create album for 2026-11-14
    const album1 = db.getOrCreateAlbumForDate('2026-11-14');
    assert.equal(album1.date_key, '2026-11-14');
    assert.equal(album1.title, 'November 14, 2026');

    // Getting same date returns existing album
    const album1Again = db.getOrCreateAlbumForDate('2026-11-14');
    assert.equal(album1.id, album1Again.id);

    // 2. Insert photos into album1
    const p1 = db.insertPhoto({
      album_id: album1.id,
      filename: 'sample1.jpg',
      original_name: 'sunset.jpg',
      mime_type: 'image/jpeg',
      size_bytes: 102400,
      width: 1920,
      height: 1080,
      date_taken: '2026-11-14T18:30:00.000Z',
      caption: 'Beautiful sunset'
    });
    assert.ok(p1.id > 0);

    const p2 = db.insertPhoto({
      album_id: album1.id,
      filename: 'sample2.jpg',
      original_name: 'beach.jpg',
      mime_type: 'image/jpeg',
      size_bytes: 204800,
      width: 1920,
      height: 1080,
      date_taken: '2026-11-14T19:00:00.000Z',
      caption: 'Beach evening'
    });
    assert.ok(p2.id > p1.id);

    // 3. Create album for an earlier date: 2026-11-10
    const album2 = db.getOrCreateAlbumForDate('2026-11-10');
    const p3 = db.insertPhoto({
      album_id: album2.id,
      filename: 'sample3.jpg',
      original_name: 'mountain.jpg',
      mime_type: 'image/jpeg',
      size_bytes: 153600,
      width: 1200,
      height: 800,
      date_taken: '2026-11-10T10:00:00.000Z',
      caption: 'Hiking the ridge'
    });
    assert.ok(p3.id > 0);

    // 4. Test getAlbumsWithPreviews
    const albums = db.getAlbumsWithPreviews();
    assert.equal(albums.length, 2);
    // Ordered newest first
    assert.equal(albums[0].date_key, '2026-11-14');
    assert.equal(albums[0].photo_count, 2);
    assert.equal(albums[0].preview_photos.length, 2);
    assert.equal(albums[1].date_key, '2026-11-10');
    assert.equal(albums[1].photo_count, 1);
    assert.equal(albums[1].preview_photos.length, 1);

    // 5. Test getAlbumWithPhotos
    const detailed = db.getAlbumWithPhotos(album1.id);
    assert.equal(detailed.album.date_key, '2026-11-14');
    assert.equal(detailed.photos.length, 2);

    // 6. Test searchPhotos
    const searchSunset = db.searchPhotos('sunset');
    assert.equal(searchSunset.length, 1);
    assert.equal(searchSunset[0].caption, 'Beautiful sunset');

    const searchDate = db.searchPhotos('November 14');
    assert.equal(searchDate.length, 2);

    // 7. Test deletePhoto and automatic album deletion when empty
    const deleted = db.deletePhoto(p3.id);
    assert.equal(deleted.id, p3.id);

    // Album2 should now be deleted since it has 0 photos
    const albumsAfter = db.getAlbumsWithPreviews();
    assert.equal(albumsAfter.length, 1);
    assert.equal(albumsAfter[0].id, album1.id);

  } finally {
    db.close();
  }
});
