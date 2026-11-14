import { formatBytes, formatDate } from '../utils.js';

/**
 * Modern modal dialog for viewing full-resolution photos and inspecting metadata
 * Implements modern-web-guidance for <dialog closedby="any">, scroll containment,
 * and keyboard navigation.
 */
export class PhotoModal {
  constructor({ onDeletePhoto }) {
    this.onDeletePhoto = onDeletePhoto;
    this.currentIndex = 0;
    this.photosList = [];

    this.dialog = document.createElement('dialog');
    this.dialog.id = 'photo-lightbox-dialog';
    this.dialog.setAttribute('closedby', 'any');
    this.dialog.setAttribute('aria-label', 'Photo Viewer');

    this.setupDialogDom();
    this.setupListeners();
    document.body.appendChild(this.dialog);
  }

  setupDialogDom() {
    this.dialog.innerHTML = `
      <div class="lightbox-container">
        <!-- Main Viewer Area -->
        <div class="lightbox-main">
          <!-- Top Bar -->
          <div class="lightbox-topbar">
            <span class="lightbox-counter" id="lb-counter">1 / 1</span>
            <div class="lightbox-actions">
              <button class="icon-btn" id="lb-info-toggle" aria-label="Toggle details drawer" title="Toggle Info">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <circle cx="12" cy="12" r="10"></circle>
                  <line x1="12" y1="16" x2="12" y2="12"></line>
                  <line x1="12" y1="8" x2="12.01" y2="8"></line>
                </svg>
              </button>
              <button class="icon-btn close-btn" id="lb-close" aria-label="Close dialog" title="Close (Esc)">
                <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
                  <line x1="18" y1="6" x2="6" y2="18"></line>
                  <line x1="6" y1="6" x2="18" y2="18"></line>
                </svg>
              </button>
            </div>
          </div>

          <!-- Image Display & Nav Buttons -->
          <div class="lightbox-stage">
            <button class="nav-arrow nav-prev" id="lb-prev" aria-label="Previous photo">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <polyline points="15 18 9 12 15 6"></polyline>
              </svg>
            </button>

            <div class="lightbox-image-wrap">
              <img id="lb-image" src="" alt="Full view" />
            </div>

            <button class="nav-arrow nav-next" id="lb-next" aria-label="Next photo">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <polyline points="9 18 15 12 9 6"></polyline>
              </svg>
            </button>
          </div>
        </div>

        <!-- Sidebar / Details Drawer -->
        <aside class="lightbox-sidebar" id="lb-sidebar">
          <div class="sidebar-header">
            <h3>Photo Details</h3>
          </div>
          <div class="sidebar-body">
            <div class="meta-item">
              <span class="meta-label">File Name</span>
              <span class="meta-value" id="lb-filename">-</span>
            </div>
            <div class="meta-item">
              <span class="meta-label">Date Taken</span>
              <span class="meta-value" id="lb-date">-</span>
            </div>
            <div class="meta-item">
              <span class="meta-label">Dimensions</span>
              <span class="meta-value" id="lb-dimensions">-</span>
            </div>
            <div class="meta-item">
              <span class="meta-label">File Size</span>
              <span class="meta-value" id="lb-size">-</span>
            </div>
            <div class="meta-item">
              <span class="meta-label">Format</span>
              <span class="meta-value" id="lb-format">-</span>
            </div>
            <div class="meta-item" id="lb-camera-row">
              <span class="meta-label">Camera</span>
              <span class="meta-value" id="lb-camera">-</span>
            </div>
            <div class="meta-item" id="lb-caption-row">
              <span class="meta-label">Caption</span>
              <span class="meta-value" id="lb-caption">-</span>
            </div>
          </div>
          <div class="sidebar-actions">
            <a class="btn btn-secondary btn-download" id="lb-download" download href="#" target="_blank">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                <polyline points="7 10 12 15 17 10"></polyline>
                <line x1="12" y1="15" x2="12" y2="3"></line>
              </svg>
              <span>Download</span>
            </a>
            <button class="btn btn-danger" id="lb-delete">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <polyline points="3 6 5 6 21 6"></polyline>
                <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
              </svg>
              <span>Delete Photo</span>
            </button>
          </div>
        </aside>
      </div>
    `;

    this.elements = {
      image: this.dialog.querySelector('#lb-image'),
      counter: this.dialog.querySelector('#lb-counter'),
      prevBtn: this.dialog.querySelector('#lb-prev'),
      nextBtn: this.dialog.querySelector('#lb-next'),
      closeBtn: this.dialog.querySelector('#lb-close'),
      infoToggle: this.dialog.querySelector('#lb-info-toggle'),
      sidebar: this.dialog.querySelector('#lb-sidebar'),
      filename: this.dialog.querySelector('#lb-filename'),
      date: this.dialog.querySelector('#lb-date'),
      dimensions: this.dialog.querySelector('#lb-dimensions'),
      size: this.dialog.querySelector('#lb-size'),
      format: this.dialog.querySelector('#lb-format'),
      camera: this.dialog.querySelector('#lb-camera'),
      cameraRow: this.dialog.querySelector('#lb-camera-row'),
      caption: this.dialog.querySelector('#lb-caption'),
      captionRow: this.dialog.querySelector('#lb-caption-row'),
      downloadBtn: this.dialog.querySelector('#lb-download'),
      deleteBtn: this.dialog.querySelector('#lb-delete')
    };
  }

  setupListeners() {
    this.elements.closeBtn.addEventListener('click', () => this.close());
    this.elements.prevBtn.addEventListener('click', () => this.prev());
    this.elements.nextBtn.addEventListener('click', () => this.next());

    this.elements.infoToggle.addEventListener('click', () => {
      this.elements.sidebar.classList.toggle('hidden');
    });

    this.elements.deleteBtn.addEventListener('click', () => {
      const currentPhoto = this.photosList[this.currentIndex];
      if (currentPhoto && confirm(`Delete "${currentPhoto.original_name}"?`)) {
        this.close();
        this.onDeletePhoto(currentPhoto.id);
      }
    });

    // Keyboard navigation
    this.dialog.addEventListener('keydown', (e) => {
      if (e.key === 'ArrowLeft') {
        e.preventDefault();
        this.prev();
      } else if (e.key === 'ArrowRight') {
        e.preventDefault();
        this.next();
      }
    });

    // Light-dismiss fallback for browsers without native `closedby` support
    if (!('closedBy' in HTMLDialogElement.prototype)) {
      this.dialog.addEventListener('click', (event) => {
        if (event.target !== this.dialog) return;
        const rect = this.dialog.getBoundingClientRect();
        const isDialogContent = (
          rect.top <= event.clientY &&
          event.clientY <= rect.top + rect.height &&
          rect.left <= event.clientX &&
          event.clientX <= rect.left + rect.width
        );
        if (!isDialogContent) {
          this.close();
        }
      });
    }
  }

  open(photo, index, photosList) {
    this.photosList = photosList || [photo];
    this.currentIndex = index >= 0 ? index : 0;
    this.updateView();
    this.dialog.showModal();
  }

  close() {
    if (this.dialog.open) {
      this.dialog.close();
    }
  }

  prev() {
    if (this.photosList.length <= 1) return;
    this.currentIndex = (this.currentIndex - 1 + this.photosList.length) % this.photosList.length;
    this.updateView();
  }

  next() {
    if (this.photosList.length <= 1) return;
    this.currentIndex = (this.currentIndex + 1) % this.photosList.length;
    this.updateView();
  }

  updateView() {
    const photo = this.photosList[this.currentIndex];
    if (!photo) return;

    this.elements.image.src = `/uploads/${photo.filename}`;
    this.elements.image.alt = photo.caption || photo.original_name;
    this.elements.counter.textContent = `${this.currentIndex + 1} / ${this.photosList.length}`;

    // Nav arrows visibility
    const hasMultiple = this.photosList.length > 1;
    this.elements.prevBtn.style.display = hasMultiple ? 'flex' : 'none';
    this.elements.nextBtn.style.display = hasMultiple ? 'flex' : 'none';

    // Metadata
    this.elements.filename.textContent = photo.original_name || photo.filename;
    this.elements.date.textContent = formatDate(photo.date_taken);
    this.elements.dimensions.textContent = (photo.width && photo.height) 
      ? `${photo.width} × ${photo.height} px` 
      : 'Original resolution';
    this.elements.size.textContent = formatBytes(photo.size_bytes);
    this.elements.format.textContent = photo.mime_type || 'image';

    if (photo.camera_model) {
      this.elements.camera.textContent = photo.camera_model;
      this.elements.cameraRow.style.display = 'flex';
    } else {
      this.elements.cameraRow.style.display = 'none';
    }

    if (photo.caption) {
      this.elements.caption.textContent = photo.caption;
      this.elements.captionRow.style.display = 'flex';
    } else {
      this.elements.captionRow.style.display = 'none';
    }

    this.elements.downloadBtn.href = `/uploads/${photo.filename}`;
    this.elements.downloadBtn.download = photo.original_name || photo.filename;
  }
}

