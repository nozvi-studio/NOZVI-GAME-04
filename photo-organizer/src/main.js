import './style.css';
import { getAlbums, getAlbum, getPhotos, deletePhoto } from './api.js';
import { Header } from './components/Header.js';
import { AlbumGrid } from './components/AlbumGrid.js';
import { PhotoGrid } from './components/PhotoGrid.js';
import { PhotoModal } from './components/PhotoModal.js';
import { Uploader } from './components/Uploader.js';

class AppCoordinator {
  constructor() {
    this.appRoot = document.getElementById('app');
    this.headerRoot = document.getElementById('header-root');

    this.albums = [];
    this.currentView = 'albums'; // 'albums' | 'album-detail' | 'all-photos' | 'search'
    this.activeAlbum = null;
    this.activePhotos = [];

    this.init();
  }

  async init() {
    // 1. Initialize Photo Modal (lightbox)
    this.photoModal = new PhotoModal({
      onDeletePhoto: (photoId) => this.handleDeletePhoto(photoId)
    });

    // 2. Initialize Uploader dialog
    this.uploader = new Uploader({
      onUploadComplete: () => this.handleUploadSuccess()
    });

    // 3. Initialize Header
    this.header = new Header({
      onSearch: (query) => this.handleSearch(query),
      onOpenUpload: () => this.uploader.open(),
      onSelectView: (viewName) => this.handleSelectView(viewName)
    });
    this.headerRoot.appendChild(this.header.container);

    // 4. Initialize Main Views
    this.albumGrid = new AlbumGrid({
      onSelectAlbum: (albumId) => this.openAlbumDetail(albumId)
    });

    this.photoGrid = new PhotoGrid({
      onBack: () => this.backToAlbums(),
      onOpenPhoto: (photo, index, list) => this.photoModal.open(photo, index, list),
      onDeletePhoto: (photoId) => this.handleDeletePhoto(photoId)
    });

    // 5. Load and display albums
    await this.loadAlbums();
  }

  async loadAlbums() {
    try {
      this.appRoot.innerHTML = '<div class="loading-state"><p>Loading albums...</p></div>';
      this.albums = await getAlbums();
      this.renderCurrentView();
    } catch (err) {
      this.appRoot.innerHTML = `
        <div class="empty-state">
          <div class="empty-icon">⚠️</div>
          <h3>Failed to load albums</h3>
          <p>${err.message}</p>
          <button class="btn btn-primary" onclick="location.reload()" style="margin-top:16px;">Retry</button>
        </div>
      `;
    }
  }

  renderCurrentView() {
    this.appRoot.innerHTML = '';

    if (this.currentView === 'albums') {
      const el = this.albumGrid.render(this.albums);
      this.appRoot.appendChild(el);
    } else if (this.currentView === 'album-detail' && this.activeAlbum) {
      const el = this.photoGrid.render(this.activeAlbum, this.activePhotos);
      this.appRoot.appendChild(el);
    } else if (this.currentView === 'all-photos' || this.currentView === 'search') {
      const virtualAlbum = {
        title: this.currentView === 'search' ? 'Search Results' : 'All Photos',
        date_key: `${this.activePhotos.length} items found`
      };
      const el = this.photoGrid.render(virtualAlbum, this.activePhotos);
      this.appRoot.appendChild(el);
    }
  }

  async openAlbumDetail(albumId) {
    try {
      this.appRoot.innerHTML = '<div class="loading-state"><p>Opening album...</p></div>';
      const data = await getAlbum(albumId);
      this.activeAlbum = data.album;
      this.activePhotos = data.photos;
      this.currentView = 'album-detail';
      this.renderCurrentView();
      window.scrollTo({ top: 0, behavior: 'smooth' });
    } catch (err) {
      alert(`Could not load album: ${err.message}`);
      this.backToAlbums();
    }
  }

  backToAlbums() {
    this.currentView = 'albums';
    this.activeAlbum = null;
    this.activePhotos = [];
    this.header.clearSearch();
    this.header.setView('albums');
    this.renderCurrentView();
  }

  async handleSearch(query) {
    if (!query) {
      if (this.currentView === 'search') {
        this.currentView = 'albums';
        this.renderCurrentView();
      }
      return;
    }

    try {
      this.currentView = 'search';
      this.activeAlbum = null;
      this.activePhotos = await getPhotos(query);
      this.renderCurrentView();
    } catch (err) {
      console.error('Search error:', err);
    }
  }

  async handleSelectView(viewName) {
    if (viewName === 'albums') {
      this.currentView = 'albums';
      this.activeAlbum = null;
      this.activePhotos = [];
      this.renderCurrentView();
    } else if (viewName === 'all') {
      try {
        this.currentView = 'all-photos';
        this.activeAlbum = null;
        this.activePhotos = await getPhotos('');
        this.renderCurrentView();
      } catch (err) {
        alert(`Error loading all photos: ${err.message}`);
      }
    }
  }

  async handleDeletePhoto(photoId) {
    try {
      await deletePhoto(photoId);

      // Remove photo from active list
      this.activePhotos = this.activePhotos.filter(p => p.id !== photoId);

      // Refresh albums in background
      this.albums = await getAlbums();

      // If active album is now empty, return to albums
      if (this.currentView === 'album-detail') {
        if (this.activePhotos.length === 0) {
          this.backToAlbums();
          return;
        }
      }

      this.renderCurrentView();
    } catch (err) {
      alert(`Could not delete photo: ${err.message}`);
    }
  }

  async handleUploadSuccess() {
    await this.loadAlbums();
    if (this.currentView === 'album-detail' && this.activeAlbum) {
      // Re-fetch current album
      await this.openAlbumDetail(this.activeAlbum.id);
    }
  }
}

// Bootstrap application on DOM ready
document.addEventListener('DOMContentLoaded', () => {
  new AppCoordinator();
});

