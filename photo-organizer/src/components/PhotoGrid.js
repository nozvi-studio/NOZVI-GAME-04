import { formatDate, formatBytes } from '../utils.js';

/**
 * Component to render all photos within a selected date album
 */
export class PhotoGrid {
  constructor({ onBack, onOpenPhoto, onDeletePhoto }) {
    this.onBack = onBack;
    this.onOpenPhoto = onOpenPhoto;
    this.onDeletePhoto = onDeletePhoto;
    this.container = document.createElement('section');
    this.container.className = 'album-detail-section';
  }

  render(album, photos = []) {
    this.container.innerHTML = '';

    // Navigation and Album Info Header
    const topBar = document.createElement('div');
    topBar.className = 'detail-top-bar';

    const backBtn = document.createElement('button');
    backBtn.className = 'btn btn-secondary btn-back';
    backBtn.innerHTML = `
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
        <line x1="19" y1="12" x2="5" y2="12"></line>
        <polyline points="12 19 5 12 12 5"></polyline>
      </svg>
      <span>Back to Albums</span>
    `;
    backBtn.addEventListener('click', () => this.onBack());
    topBar.appendChild(backBtn);

    const info = document.createElement('div');
    info.className = 'detail-header-info';
    info.innerHTML = `
      <h2 class="detail-album-title">${album.title}</h2>
      <div class="detail-album-meta">
        <span class="badge badge-date">${album.date_key}</span>
        <span class="detail-count">${photos.length} ${photos.length === 1 ? 'photo' : 'photos'}</span>
      </div>
    `;
    topBar.appendChild(info);

    this.container.appendChild(topBar);

    if (photos.length === 0) {
      const empty = document.createElement('div');
      empty.className = 'empty-state';
      empty.innerHTML = `
        <div class="empty-icon">📷</div>
        <h3>No photos left in this album</h3>
        <p>Upload new photos or return to the main catalog.</p>
      `;
      this.container.appendChild(empty);
      return this.container;
    }

    const grid = document.createElement('div');
    grid.className = 'photos-gallery-grid';

    photos.forEach((photo, index) => {
      const card = this.createPhotoCard(photo, index, photos);
      grid.appendChild(card);
    });

    this.container.appendChild(grid);
    return this.container;
  }

  createPhotoCard(photo, index, photosList) {
    const card = document.createElement('div');
    card.className = 'photo-card';
    card.tabIndex = 0;
    card.setAttribute('role', 'button');
    card.setAttribute('aria-label', `View photo ${photo.caption || photo.original_name}`);

    // Thumbnail container
    const thumbWrap = document.createElement('div');
    thumbWrap.className = 'photo-thumb-wrap';

    const img = document.createElement('img');
    img.src = `/uploads/${photo.filename}`;
    img.alt = photo.caption || photo.original_name;
    img.loading = 'lazy';
    thumbWrap.appendChild(img);

    // Hover / focus action overlay
    const overlay = document.createElement('div');
    overlay.className = 'photo-overlay';

    const viewBtn = document.createElement('button');
    viewBtn.className = 'overlay-btn view-btn';
    viewBtn.setAttribute('aria-label', 'Open full photo');
    viewBtn.innerHTML = `
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
        <circle cx="12" cy="12" r="3"></circle>
      </svg>
    `;
    viewBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      this.onOpenPhoto(photo, index, photosList);
    });

    const deleteBtn = document.createElement('button');
    deleteBtn.className = 'overlay-btn delete-btn';
    deleteBtn.setAttribute('aria-label', 'Delete photo');
    deleteBtn.innerHTML = `
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <polyline points="3 6 5 6 21 6"></polyline>
        <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
      </svg>
    `;
    deleteBtn.addEventListener('click', (e) => {
      e.stopPropagation();
      if (confirm(`Are you sure you want to delete "${photo.original_name}"?`)) {
        this.onDeletePhoto(photo.id);
      }
    });

    overlay.appendChild(viewBtn);
    overlay.appendChild(deleteBtn);
    thumbWrap.appendChild(overlay);

    card.appendChild(thumbWrap);

    // Footer info
    const footer = document.createElement('div');
    footer.className = 'photo-card-footer';
    footer.innerHTML = `
      <span class="photo-card-name" title="${photo.caption || photo.original_name}">
        ${photo.caption || photo.original_name}
      </span>
      <span class="photo-card-size">${formatBytes(photo.size_bytes)}</span>
    `;
    card.appendChild(footer);

    // Card click opens viewer
    card.addEventListener('click', () => {
      this.onOpenPhoto(photo, index, photosList);
    });
    card.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        this.onOpenPhoto(photo, index, photosList);
      }
    });

    return card;
  }
}

