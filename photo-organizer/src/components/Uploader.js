import { uploadPhotos } from '../api.js';

/**
 * Modern Drag-and-Drop Photo Uploader with Progress Bar & Instant Thumbnail Previews
 */
export class Uploader {
  constructor({ onUploadComplete }) {
    this.onUploadComplete = onUploadComplete;
    this.selectedFiles = [];

    this.dialog = document.createElement('dialog');
    this.dialog.id = 'upload-dialog';
    this.dialog.setAttribute('closedby', 'any');
    this.dialog.setAttribute('aria-label', 'Upload Photos');

    this.setupDialogDom();
    this.setupListeners();
    document.body.appendChild(this.dialog);
  }

  setupDialogDom() {
    this.dialog.innerHTML = `
      <div class="upload-modal-container">
        <div class="upload-modal-header">
          <h3>Upload Local Photos</h3>
          <button class="icon-btn close-btn" id="upload-close" aria-label="Close dialog">
            <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
              <line x1="18" y1="6" x2="6" y2="18"></line>
              <line x1="6" y1="6" x2="18" y2="18"></line>
            </svg>
          </button>
        </div>

        <div class="upload-dropzone" id="upload-dropzone">
          <input type="file" id="file-input" multiple accept="image/*" style="display: none;" />
          <div class="dropzone-content">
            <div class="dropzone-icon">
              <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                <polyline points="17 8 12 3 7 8"></polyline>
                <line x1="12" y1="3" x2="12" y2="15"></line>
              </svg>
            </div>
            <h4>Drag & Drop photos here</h4>
            <p>or click to browse your computer (JPEG, PNG, WebP, GIF, SVG)</p>
            <button type="button" class="btn btn-secondary browse-btn" id="browse-btn">
              Browse Files
            </button>
          </div>
        </div>

        <!-- Extra metadata options -->
        <div class="upload-meta-inputs">
          <div class="input-group">
            <label for="upload-date">Date Override (Optional)</label>
            <input type="date" id="upload-date" class="form-input" />
            <small>Leave empty to auto-extract date from file timestamp</small>
          </div>
          <div class="input-group">
            <label for="upload-caption">Caption / Album Note (Optional)</label>
            <input type="text" id="upload-caption" class="form-input" placeholder="e.g. Vacation in Kyoto, Family Gathering" />
          </div>
        </div>

        <!-- Selected files preview list -->
        <div class="upload-previews-container" id="upload-previews" style="display: none;">
          <h4 id="preview-count-label">Selected Photos (0)</h4>
          <div class="upload-previews-grid" id="previews-grid"></div>
        </div>

        <!-- Progress bar -->
        <div class="upload-progress-wrap" id="upload-progress-wrap" style="display: none;">
          <div class="progress-bar-track">
            <div class="progress-bar-fill" id="progress-bar-fill" style="width: 0%;"></div>
          </div>
          <span class="progress-text" id="progress-text">Uploading... 0%</span>
        </div>

        <!-- Modal Actions -->
        <div class="upload-modal-actions">
          <button type="button" class="btn btn-secondary" id="upload-cancel">Cancel</button>
          <button type="button" class="btn btn-primary" id="upload-submit" disabled>
            Upload Photos
          </button>
        </div>
      </div>
    `;

    this.elements = {
      closeBtn: this.dialog.querySelector('#upload-close'),
      cancelBtn: this.dialog.querySelector('#upload-cancel'),
      submitBtn: this.dialog.querySelector('#upload-submit'),
      dropzone: this.dialog.querySelector('#upload-dropzone'),
      fileInput: this.dialog.querySelector('#file-input'),
      browseBtn: this.dialog.querySelector('#browse-btn'),
      dateInput: this.dialog.querySelector('#upload-date'),
      captionInput: this.dialog.querySelector('#upload-caption'),
      previewsContainer: this.dialog.querySelector('#upload-previews'),
      previewsGrid: this.dialog.querySelector('#previews-grid'),
      previewCountLabel: this.dialog.querySelector('#preview-count-label'),
      progressWrap: this.dialog.querySelector('#upload-progress-wrap'),
      progressFill: this.dialog.querySelector('#progress-bar-fill'),
      progressText: this.dialog.querySelector('#progress-text')
    };
  }

  setupListeners() {
    this.elements.closeBtn.addEventListener('click', () => this.close());
    this.elements.cancelBtn.addEventListener('click', () => this.close());

    // File input browse
    this.elements.browseBtn.addEventListener('click', () => this.elements.fileInput.click());
    this.elements.dropzone.addEventListener('click', (e) => {
      if (e.target !== this.elements.browseBtn) {
        this.elements.fileInput.click();
      }
    });

    this.elements.fileInput.addEventListener('change', (e) => {
      this.handleFiles(Array.from(e.target.files));
    });

    // Drag and drop events
    ['dragenter', 'dragover'].forEach(name => {
      this.elements.dropzone.addEventListener(name, (e) => {
        e.preventDefault();
        e.stopPropagation();
        this.elements.dropzone.classList.add('drag-active');
      });
    });

    ['dragleave', 'drop'].forEach(name => {
      this.elements.dropzone.addEventListener(name, (e) => {
        e.preventDefault();
        e.stopPropagation();
        this.elements.dropzone.classList.remove('drag-active');
      });
    });

    this.elements.dropzone.addEventListener('drop', (e) => {
      const dt = e.dataTransfer;
      if (dt && dt.files && dt.files.length > 0) {
        this.handleFiles(Array.from(dt.files));
      }
    });

    // Submit upload
    this.elements.submitBtn.addEventListener('click', () => this.startUpload());

    // Fallback light-dismiss for browsers without closedby
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
        if (!isDialogContent) this.close();
      });
    }
  }

  open() {
    this.reset();
    this.dialog.showModal();
  }

  close() {
    if (this.dialog.open) {
      this.dialog.close();
    }
  }

  reset() {
    this.selectedFiles = [];
    this.elements.fileInput.value = '';
    this.elements.captionInput.value = '';
    this.elements.dateInput.value = '';
    this.elements.previewsGrid.innerHTML = '';
    this.elements.previewsContainer.style.display = 'none';
    this.elements.progressWrap.style.display = 'none';
    this.elements.progressFill.style.width = '0%';
    this.elements.submitBtn.disabled = true;
    this.elements.submitBtn.textContent = 'Upload Photos';
  }

  handleFiles(files) {
    const validFiles = files.filter(f => f.type.startsWith('image/'));
    if (validFiles.length === 0) return;

    this.selectedFiles = this.selectedFiles.concat(validFiles);
    this.elements.submitBtn.disabled = false;
    this.elements.submitBtn.textContent = `Upload ${this.selectedFiles.length} ${this.selectedFiles.length === 1 ? 'Photo' : 'Photos'}`;

    this.renderPreviews();
  }

  renderPreviews() {
    this.elements.previewsContainer.style.display = 'block';
    this.elements.previewCountLabel.textContent = `Selected Photos (${this.selectedFiles.length})`;
    this.elements.previewsGrid.innerHTML = '';

    this.selectedFiles.forEach((file, idx) => {
      const thumb = document.createElement('div');
      thumb.className = 'upload-preview-thumb';

      const img = document.createElement('img');
      img.src = URL.createObjectURL(file);
      thumb.appendChild(img);

      const removeBtn = document.createElement('button');
      removeBtn.className = 'thumb-remove-btn';
      removeBtn.innerHTML = '×';
      removeBtn.setAttribute('aria-label', `Remove ${file.name}`);
      removeBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        this.selectedFiles.splice(idx, 1);
        if (this.selectedFiles.length === 0) {
          this.reset();
        } else {
          this.renderPreviews();
          this.elements.submitBtn.textContent = `Upload ${this.selectedFiles.length} Photos`;
        }
      });
      thumb.appendChild(removeBtn);

      this.elements.previewsGrid.appendChild(thumb);
    });
  }

  async startUpload() {
    if (this.selectedFiles.length === 0) return;

    this.elements.submitBtn.disabled = true;
    this.elements.cancelBtn.disabled = true;
    this.elements.progressWrap.style.display = 'block';

    const meta = {
      caption: this.elements.captionInput.value.trim(),
      date_taken: this.elements.dateInput.value ? `${this.elements.dateInput.value}T12:00:00.000Z` : undefined
    };

    try {
      await uploadPhotos(this.selectedFiles, meta, (percent) => {
        this.elements.progressFill.style.width = `${percent}%`;
        this.elements.progressText.textContent = `Uploading... ${percent}%`;
      });

      this.elements.progressText.textContent = 'Upload complete!';
      setTimeout(() => {
        this.close();
        if (this.onUploadComplete) {
          this.onUploadComplete();
        }
      }, 500);
    } catch (err) {
      alert(`Error uploading photos: ${err.message}`);
      this.elements.submitBtn.disabled = false;
      this.elements.cancelBtn.disabled = false;
      this.elements.progressText.textContent = 'Upload failed. Please try again.';
    }
  }
}

