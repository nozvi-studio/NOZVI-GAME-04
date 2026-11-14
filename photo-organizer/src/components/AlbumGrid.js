import { formatRelativeDate } from '../utils.js';

/**
 * Component to render albums grouped by date with a tile preview mosaic
 */
export class AlbumGrid {
  constructor({ onSelectAlbum }) {
    this.onSelectAlbum = onSelectAlbum;
    this.container = document.createElement('section');
    this.container.className = 'album-catalog-section';
  }

  render(albums = []) {
    this.container.innerHTML = '';

    if (albums.length === 0) {
      this.container.innerHTML = `
        <div class="empty-state">
          <div class="empty-icon">📁</div>
          <h3>No Albums Found</h3>
          <p>Drag & drop photos or click "Upload Photos" above to organize by date.</p>
        </div>
      `;
      return this.container;
    }

    const header = document.createElement('div');
    header.className = 'section-header';
    header.innerHTML = `
      <div>
        <h2 class="section-title">Date Albums</h2>
        <p class="section-subtitle">${albums.length} ${albums.length === 1 ? 'album' : 'albums'} organized chronologically</p>
      </div>
    `;
    this.container.appendChild(header);

    const grid = document.createElement('div');
    grid.className = 'album-cards-grid';

    for (const album of albums) {
      const card = this.createAlbumCard(album);
      grid.appendChild(card);
    }

    this.container.appendChild(grid);
    return this.container;
  }

  createAlbumCard(album) {
    const card = document.createElement('article');
    card.className = 'album-card';
    card.tabIndex = 0;
    card.setAttribute('role', 'button');
    card.setAttribute('aria-label', `Open album for ${album.title}, contains ${album.photo_count} photos`);

    // Click & Keyboard Enter/Space to select album
    card.addEventListener('click', () => this.onSelectAlbum(album.id));
    card.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        this.onSelectAlbum(album.id);
      }
    });

    // Tile preview
    const previewContainer = this.renderTilePreview(album);
    card.appendChild(previewContainer);

    // Meta info
    const meta = document.createElement('div');
    meta.className = 'album-card-info';

    const relativeLabel = formatRelativeDate(album.date_key);
    const isSpecialRelative = relativeLabel === 'Today' || relativeLabel === 'Yesterday';

    meta.innerHTML = `
      <div class="album-title-row">
        <h3 class="album-date-title">${album.title}</h3>
        ${isSpecialRelative ? `<span class="badge badge-relative">${relativeLabel}</span>` : ''}
      </div>
      <div class="album-stats-row">
        <span class="album-photo-count">${album.photo_count} ${album.photo_count === 1 ? 'photo' : 'photos'}</span>
        <span class="album-date-badge">${album.date_key}</span>
      </div>
    `;
    card.appendChild(meta);

    return card;
  }

  renderTilePreview(album) {
    const previewWrapper = document.createElement('div');
    const previews = album.preview_photos || [];
    const count = previews.length;

    if (count === 0) {
      previewWrapper.className = 'tile-preview tiles-empty';
      previewWrapper.innerHTML = `
        <div class="tile-empty-placeholder">
          <span>📷</span>
        </div>
      `;
      return previewWrapper;
    }

    if (count === 1) {
      previewWrapper.className = 'tile-preview tiles-1';
      const img = document.createElement('img');
      img.src = `/uploads/${previews[0].filename}`;
      img.alt = previews[0].caption || album.title;
      img.loading = 'lazy';
      previewWrapper.appendChild(img);
      return previewWrapper;
    }

    if (count === 2) {
      previewWrapper.className = 'tile-preview tiles-2';
      for (const p of previews) {
        const item = document.createElement('div');
        item.className = 'tile-slot';
        const img = document.createElement('img');
        img.src = `/uploads/${p.filename}`;
        img.alt = p.caption || album.title;
        img.loading = 'lazy';
        item.appendChild(img);
        previewWrapper.appendChild(item);
      }
      return previewWrapper;
    }

    if (count === 3) {
      previewWrapper.className = 'tile-preview tiles-3';
      // First is hero (left span 2 rows), second and third are right stacked
      previews.forEach((p, idx) => {
        const item = document.createElement('div');
        item.className = `tile-slot tile-slot-${idx + 1}`;
        const img = document.createElement('img');
        img.src = `/uploads/${p.filename}`;
        img.alt = p.caption || album.title;
        img.loading = 'lazy';
        item.appendChild(img);
        previewWrapper.appendChild(item);
      });
      return previewWrapper;
    }

    // 4 or more previews (2x2 grid)
    previewWrapper.className = 'tile-preview tiles-4';
    previews.slice(0, 4).forEach((p, idx) => {
      const item = document.createElement('div');
      item.className = `tile-slot tile-slot-${idx + 1}`;
      const img = document.createElement('img');
      img.src = `/uploads/${p.filename}`;
      img.alt = p.caption || album.title;
      img.loading = 'lazy';
      item.appendChild(img);

      // If more than 4 total photos in album, show overlay on 4th tile
      if (idx === 3 && album.photo_count > 4) {
        const overlay = document.createElement('div');
        overlay.className = 'tile-more-overlay';
        overlay.textContent = `+${album.photo_count - 4}`;
        item.appendChild(overlay);
      }

      previewWrapper.appendChild(item);
    });

    return previewWrapper;
  }
}

