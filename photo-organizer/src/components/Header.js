/**
 * Top App Header with brand, live debounced search, view navigation, theme toggle, and upload trigger
 */
export class Header {
  constructor({ onSearch, onOpenUpload, onSelectView }) {
    this.onSearch = onSearch;
    this.onOpenUpload = onOpenUpload;
    this.onSelectView = onSelectView;
    this.currentView = 'albums'; // 'albums' | 'all'
    this.debounceTimer = null;

    this.container = document.createElement('header');
    this.container.className = 'app-header';
    this.render();
    this.initTheme();
  }

  render() {
    this.container.innerHTML = `
      <div class="header-inner">
        <!-- Brand / Logo -->
        <div class="header-brand" id="brand-home" role="button" tabindex="0">
          <div class="brand-icon">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
              <rect x="3" y="3" width="18" height="18" rx="4" ry="4"></rect>
              <circle cx="8.5" cy="8.5" r="1.5"></circle>
              <polyline points="21 15 16 10 5 21"></polyline>
            </svg>
          </div>
          <div class="brand-text">
            <span class="brand-title">PhotoSphere</span>
            <span class="brand-subtitle">Local Date Albums</span>
          </div>
        </div>

        <!-- Search Bar -->
        <div class="header-search">
          <div class="search-input-wrap">
            <svg class="search-icon" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="11" cy="11" r="8"></circle>
              <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
            </svg>
            <input 
              type="search" 
              id="search-input" 
              placeholder="Search captions, dates (e.g. 2026-11), filenames..." 
              aria-label="Search photos" 
            />
            <button class="search-clear-btn" id="search-clear" style="display: none;" aria-label="Clear search">×</button>
          </div>
        </div>

        <!-- Actions -->
        <div class="header-actions">
          <div class="view-switch-group">
            <button class="view-btn active" id="view-albums-btn" data-view="albums" title="Grouped by date">
              Albums
            </button>
            <button class="view-btn" id="view-all-btn" data-view="all" title="All photos timeline">
              All Photos
            </button>
          </div>

          <button class="btn btn-primary upload-btn" id="header-upload-btn">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
              <line x1="12" y1="5" x2="12" y2="19"></line>
              <line x1="5" y1="12" x2="19" y2="12"></line>
            </svg>
            <span>Upload</span>
          </button>

          <button class="icon-btn theme-toggle-btn" id="theme-toggle" aria-label="Toggle dark/light theme" title="Toggle Theme">
            <svg class="theme-icon-sun" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="5"></circle>
              <line x1="12" y1="1" x2="12" y2="3"></line>
              <line x1="12" y1="21" x2="12" y2="23"></line>
              <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line>
              <line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line>
              <line x1="1" y1="12" x2="3" y2="12"></line>
              <line x1="21" y1="12" x2="23" y2="12"></line>
              <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line>
              <line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line>
            </svg>
          </button>
        </div>
      </div>
    `;

    this.setupListeners();
    return this.container;
  }

  setupListeners() {
    const brandHome = this.container.querySelector('#brand-home');
    brandHome.addEventListener('click', () => {
      this.clearSearch();
      this.setView('albums');
    });

    const searchInput = this.container.querySelector('#search-input');
    const searchClear = this.container.querySelector('#search-clear');

    searchInput.addEventListener('input', (e) => {
      const val = e.target.value.trim();
      searchClear.style.display = val ? 'block' : 'none';

      clearTimeout(this.debounceTimer);
      this.debounceTimer = setTimeout(() => {
        if (this.onSearch) this.onSearch(val);
      }, 250);
    });

    searchClear.addEventListener('click', () => {
      this.clearSearch();
    });

    // View switch buttons
    const albumsBtn = this.container.querySelector('#view-albums-btn');
    const allBtn = this.container.querySelector('#view-all-btn');

    albumsBtn.addEventListener('click', () => this.setView('albums'));
    allBtn.addEventListener('click', () => this.setView('all'));

    // Upload button
    const uploadBtn = this.container.querySelector('#header-upload-btn');
    uploadBtn.addEventListener('click', () => {
      if (this.onOpenUpload) this.onOpenUpload();
    });

    // Theme toggle
    const themeBtn = this.container.querySelector('#theme-toggle');
    themeBtn.addEventListener('click', () => this.toggleTheme());
  }

  clearSearch() {
    const searchInput = this.container.querySelector('#search-input');
    const searchClear = this.container.querySelector('#search-clear');
    if (searchInput) searchInput.value = '';
    if (searchClear) searchClear.style.display = 'none';
    if (this.onSearch) this.onSearch('');
  }

  setView(viewName) {
    this.currentView = viewName;
    const albumsBtn = this.container.querySelector('#view-albums-btn');
    const allBtn = this.container.querySelector('#view-all-btn');
    if (albumsBtn && allBtn) {
      albumsBtn.classList.toggle('active', viewName === 'albums');
      allBtn.classList.toggle('active', viewName === 'all');
    }
    if (this.onSelectView) {
      this.onSelectView(viewName);
    }
  }

  initTheme() {
    const saved = localStorage.getItem('photo_app_theme') || 'dark';
    document.documentElement.setAttribute('data-theme', saved);
  }

  toggleTheme() {
    const current = document.documentElement.getAttribute('data-theme') || 'dark';
    const next = current === 'dark' ? 'light' : 'dark';
    document.documentElement.setAttribute('data-theme', next);
    localStorage.setItem('photo_app_theme', next);
  }
}

