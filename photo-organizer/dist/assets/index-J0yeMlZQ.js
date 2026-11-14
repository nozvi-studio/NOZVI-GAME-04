(function(){const e=document.createElement("link").relList;if(e&&e.supports&&e.supports("modulepreload"))return;for(const n of document.querySelectorAll('link[rel="modulepreload"]'))s(n);new MutationObserver(n=>{for(const i of n)if(i.type==="childList")for(const l of i.addedNodes)l.tagName==="LINK"&&l.rel==="modulepreload"&&s(l)}).observe(document,{childList:!0,subtree:!0});function t(n){const i={};return n.integrity&&(i.integrity=n.integrity),n.referrerPolicy&&(i.referrerPolicy=n.referrerPolicy),n.crossOrigin==="use-credentials"?i.credentials="include":n.crossOrigin==="anonymous"?i.credentials="omit":i.credentials="same-origin",i}function s(n){if(n.ep)return;n.ep=!0;const i=t(n);fetch(n.href,i)}})();async function p(){const o=await fetch("/api/albums");if(!o.ok)throw new Error(`Failed to fetch albums: ${o.statusText}`);return o.json()}async function g(o){const e=await fetch(`/api/albums/${o}`);if(!e.ok)throw new Error(`Failed to fetch album #${o}: ${e.statusText}`);return e.json()}async function u(o=""){const e=o?`/api/photos?q=${encodeURIComponent(o)}`:"/api/photos",t=await fetch(e);if(!t.ok)throw new Error(`Failed to fetch photos: ${t.statusText}`);return t.json()}async function b(o,e={},t=null){return new Promise((s,n)=>{const i=new XMLHttpRequest,l=new FormData;for(const a of o)l.append("photos",a);e.date_taken&&l.append("date_taken",e.date_taken),e.caption&&l.append("caption",e.caption),e.camera_model&&l.append("camera_model",e.camera_model),i.open("POST","/api/photos/upload"),t&&i.upload&&(i.upload.onprogress=a=>{if(a.lengthComputable){const r=Math.round(a.loaded/a.total*100);t(r)}}),i.onload=()=>{if(i.status>=200&&i.status<300)try{const a=JSON.parse(i.responseText);s(a)}catch{n(new Error("Invalid response from server"))}else try{const a=JSON.parse(i.responseText);n(new Error(a.error||`Upload failed with status ${i.status}`))}catch{n(new Error(`Upload failed with status ${i.status}`))}},i.onerror=()=>n(new Error("Network error during photo upload")),i.send(l)})}async function v(o){const e=await fetch(`/api/photos/${o}`,{method:"DELETE"});if(!e.ok)throw new Error(`Failed to delete photo #${o}`);return e.json()}class y{constructor({onSearch:e,onOpenUpload:t,onSelectView:s}){this.onSearch=e,this.onOpenUpload=t,this.onSelectView=s,this.currentView="albums",this.debounceTimer=null,this.container=document.createElement("header"),this.container.className="app-header",this.render(),this.initTheme()}render(){return this.container.innerHTML=`
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
    `,this.setupListeners(),this.container}setupListeners(){this.container.querySelector("#brand-home").addEventListener("click",()=>{this.clearSearch(),this.setView("albums")});const t=this.container.querySelector("#search-input"),s=this.container.querySelector("#search-clear");t.addEventListener("input",r=>{const c=r.target.value.trim();s.style.display=c?"block":"none",clearTimeout(this.debounceTimer),this.debounceTimer=setTimeout(()=>{this.onSearch&&this.onSearch(c)},250)}),s.addEventListener("click",()=>{this.clearSearch()});const n=this.container.querySelector("#view-albums-btn"),i=this.container.querySelector("#view-all-btn");n.addEventListener("click",()=>this.setView("albums")),i.addEventListener("click",()=>this.setView("all")),this.container.querySelector("#header-upload-btn").addEventListener("click",()=>{this.onOpenUpload&&this.onOpenUpload()}),this.container.querySelector("#theme-toggle").addEventListener("click",()=>this.toggleTheme())}clearSearch(){const e=this.container.querySelector("#search-input"),t=this.container.querySelector("#search-clear");e&&(e.value=""),t&&(t.style.display="none"),this.onSearch&&this.onSearch("")}setView(e){this.currentView=e;const t=this.container.querySelector("#view-albums-btn"),s=this.container.querySelector("#view-all-btn");t&&s&&(t.classList.toggle("active",e==="albums"),s.classList.toggle("active",e==="all")),this.onSelectView&&this.onSelectView(e)}initTheme(){const e=localStorage.getItem("photo_app_theme")||"dark";document.documentElement.setAttribute("data-theme",e)}toggleTheme(){const t=(document.documentElement.getAttribute("data-theme")||"dark")==="dark"?"light":"dark";document.documentElement.setAttribute("data-theme",t),localStorage.setItem("photo_app_theme",t)}}function m(o){if(!o||o===0)return"0 B";const e=1024,t=["B","KB","MB","GB"],s=Math.floor(Math.log(o)/Math.log(e));return`${parseFloat((o/Math.pow(e,s)).toFixed(1))} ${t[s]}`}function w(o){if(!o)return"";try{const e=new Date(o);return new Intl.DateTimeFormat("en-US",{dateStyle:"medium",timeStyle:"short"}).format(e)}catch{return o}}function f(o){if(!o)return"";const e=new Date,t=e.toISOString().slice(0,10),s=new Date(e);s.setDate(e.getDate()-1);const n=s.toISOString().slice(0,10);if(o===t)return"Today";if(o===n)return"Yesterday";try{const[i,l,a]=o.split("-").map(Number),r=new Date(i,l-1,a);return new Intl.DateTimeFormat("en-US",{weekday:"short",month:"short",day:"numeric",year:r.getFullYear()!==e.getFullYear()?"numeric":void 0}).format(r)}catch{return o}}class x{constructor({onSelectAlbum:e}){this.onSelectAlbum=e,this.container=document.createElement("section"),this.container.className="album-catalog-section"}render(e=[]){if(this.container.innerHTML="",e.length===0)return this.container.innerHTML=`
        <div class="empty-state">
          <div class="empty-icon">📁</div>
          <h3>No Albums Found</h3>
          <p>Drag & drop photos or click "Upload Photos" above to organize by date.</p>
        </div>
      `,this.container;const t=document.createElement("div");t.className="section-header",t.innerHTML=`
      <div>
        <h2 class="section-title">Date Albums</h2>
        <p class="section-subtitle">${e.length} ${e.length===1?"album":"albums"} organized chronologically</p>
      </div>
    `,this.container.appendChild(t);const s=document.createElement("div");s.className="album-cards-grid";for(const n of e){const i=this.createAlbumCard(n);s.appendChild(i)}return this.container.appendChild(s),this.container}createAlbumCard(e){const t=document.createElement("article");t.className="album-card",t.tabIndex=0,t.setAttribute("role","button"),t.setAttribute("aria-label",`Open album for ${e.title}, contains ${e.photo_count} photos`),t.addEventListener("click",()=>this.onSelectAlbum(e.id)),t.addEventListener("keydown",a=>{(a.key==="Enter"||a.key===" ")&&(a.preventDefault(),this.onSelectAlbum(e.id))});const s=this.renderTilePreview(e);t.appendChild(s);const n=document.createElement("div");n.className="album-card-info";const i=f(e.date_key),l=i==="Today"||i==="Yesterday";return n.innerHTML=`
      <div class="album-title-row">
        <h3 class="album-date-title">${e.title}</h3>
        ${l?`<span class="badge badge-relative">${i}</span>`:""}
      </div>
      <div class="album-stats-row">
        <span class="album-photo-count">${e.photo_count} ${e.photo_count===1?"photo":"photos"}</span>
        <span class="album-date-badge">${e.date_key}</span>
      </div>
    `,t.appendChild(n),t}renderTilePreview(e){const t=document.createElement("div"),s=e.preview_photos||[],n=s.length;if(n===0)return t.className="tile-preview tiles-empty",t.innerHTML=`
        <div class="tile-empty-placeholder">
          <span>📷</span>
        </div>
      `,t;if(n===1){t.className="tile-preview tiles-1";const i=document.createElement("img");return i.src=`/uploads/${s[0].filename}`,i.alt=s[0].caption||e.title,i.loading="lazy",t.appendChild(i),t}if(n===2){t.className="tile-preview tiles-2";for(const i of s){const l=document.createElement("div");l.className="tile-slot";const a=document.createElement("img");a.src=`/uploads/${i.filename}`,a.alt=i.caption||e.title,a.loading="lazy",l.appendChild(a),t.appendChild(l)}return t}return n===3?(t.className="tile-preview tiles-3",s.forEach((i,l)=>{const a=document.createElement("div");a.className=`tile-slot tile-slot-${l+1}`;const r=document.createElement("img");r.src=`/uploads/${i.filename}`,r.alt=i.caption||e.title,r.loading="lazy",a.appendChild(r),t.appendChild(a)}),t):(t.className="tile-preview tiles-4",s.slice(0,4).forEach((i,l)=>{const a=document.createElement("div");a.className=`tile-slot tile-slot-${l+1}`;const r=document.createElement("img");if(r.src=`/uploads/${i.filename}`,r.alt=i.caption||e.title,r.loading="lazy",a.appendChild(r),l===3&&e.photo_count>4){const c=document.createElement("div");c.className="tile-more-overlay",c.textContent=`+${e.photo_count-4}`,a.appendChild(c)}t.appendChild(a)}),t)}}class C{constructor({onBack:e,onOpenPhoto:t,onDeletePhoto:s}){this.onBack=e,this.onOpenPhoto=t,this.onDeletePhoto=s,this.container=document.createElement("section"),this.container.className="album-detail-section"}render(e,t=[]){this.container.innerHTML="";const s=document.createElement("div");s.className="detail-top-bar";const n=document.createElement("button");n.className="btn btn-secondary btn-back",n.innerHTML=`
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round">
        <line x1="19" y1="12" x2="5" y2="12"></line>
        <polyline points="12 19 5 12 12 5"></polyline>
      </svg>
      <span>Back to Albums</span>
    `,n.addEventListener("click",()=>this.onBack()),s.appendChild(n);const i=document.createElement("div");if(i.className="detail-header-info",i.innerHTML=`
      <h2 class="detail-album-title">${e.title}</h2>
      <div class="detail-album-meta">
        <span class="badge badge-date">${e.date_key}</span>
        <span class="detail-count">${t.length} ${t.length===1?"photo":"photos"}</span>
      </div>
    `,s.appendChild(i),this.container.appendChild(s),t.length===0){const a=document.createElement("div");return a.className="empty-state",a.innerHTML=`
        <div class="empty-icon">📷</div>
        <h3>No photos left in this album</h3>
        <p>Upload new photos or return to the main catalog.</p>
      `,this.container.appendChild(a),this.container}const l=document.createElement("div");return l.className="photos-gallery-grid",t.forEach((a,r)=>{const c=this.createPhotoCard(a,r,t);l.appendChild(c)}),this.container.appendChild(l),this.container}createPhotoCard(e,t,s){const n=document.createElement("div");n.className="photo-card",n.tabIndex=0,n.setAttribute("role","button"),n.setAttribute("aria-label",`View photo ${e.caption||e.original_name}`);const i=document.createElement("div");i.className="photo-thumb-wrap";const l=document.createElement("img");l.src=`/uploads/${e.filename}`,l.alt=e.caption||e.original_name,l.loading="lazy",i.appendChild(l);const a=document.createElement("div");a.className="photo-overlay";const r=document.createElement("button");r.className="overlay-btn view-btn",r.setAttribute("aria-label","Open full photo"),r.innerHTML=`
      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
        <circle cx="12" cy="12" r="3"></circle>
      </svg>
    `,r.addEventListener("click",d=>{d.stopPropagation(),this.onOpenPhoto(e,t,s)});const c=document.createElement("button");c.className="overlay-btn delete-btn",c.setAttribute("aria-label","Delete photo"),c.innerHTML=`
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <polyline points="3 6 5 6 21 6"></polyline>
        <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
      </svg>
    `,c.addEventListener("click",d=>{d.stopPropagation(),confirm(`Are you sure you want to delete "${e.original_name}"?`)&&this.onDeletePhoto(e.id)}),a.appendChild(r),a.appendChild(c),i.appendChild(a),n.appendChild(i);const h=document.createElement("div");return h.className="photo-card-footer",h.innerHTML=`
      <span class="photo-card-name" title="${e.caption||e.original_name}">
        ${e.caption||e.original_name}
      </span>
      <span class="photo-card-size">${m(e.size_bytes)}</span>
    `,n.appendChild(h),n.addEventListener("click",()=>{this.onOpenPhoto(e,t,s)}),n.addEventListener("keydown",d=>{(d.key==="Enter"||d.key===" ")&&(d.preventDefault(),this.onOpenPhoto(e,t,s))}),n}}class k{constructor({onDeletePhoto:e}){this.onDeletePhoto=e,this.currentIndex=0,this.photosList=[],this.dialog=document.createElement("dialog"),this.dialog.id="photo-lightbox-dialog",this.dialog.setAttribute("closedby","any"),this.dialog.setAttribute("aria-label","Photo Viewer"),this.setupDialogDom(),this.setupListeners(),document.body.appendChild(this.dialog)}setupDialogDom(){this.dialog.innerHTML=`
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
    `,this.elements={image:this.dialog.querySelector("#lb-image"),counter:this.dialog.querySelector("#lb-counter"),prevBtn:this.dialog.querySelector("#lb-prev"),nextBtn:this.dialog.querySelector("#lb-next"),closeBtn:this.dialog.querySelector("#lb-close"),infoToggle:this.dialog.querySelector("#lb-info-toggle"),sidebar:this.dialog.querySelector("#lb-sidebar"),filename:this.dialog.querySelector("#lb-filename"),date:this.dialog.querySelector("#lb-date"),dimensions:this.dialog.querySelector("#lb-dimensions"),size:this.dialog.querySelector("#lb-size"),format:this.dialog.querySelector("#lb-format"),camera:this.dialog.querySelector("#lb-camera"),cameraRow:this.dialog.querySelector("#lb-camera-row"),caption:this.dialog.querySelector("#lb-caption"),captionRow:this.dialog.querySelector("#lb-caption-row"),downloadBtn:this.dialog.querySelector("#lb-download"),deleteBtn:this.dialog.querySelector("#lb-delete")}}setupListeners(){this.elements.closeBtn.addEventListener("click",()=>this.close()),this.elements.prevBtn.addEventListener("click",()=>this.prev()),this.elements.nextBtn.addEventListener("click",()=>this.next()),this.elements.infoToggle.addEventListener("click",()=>{this.elements.sidebar.classList.toggle("hidden")}),this.elements.deleteBtn.addEventListener("click",()=>{const e=this.photosList[this.currentIndex];e&&confirm(`Delete "${e.original_name}"?`)&&(this.close(),this.onDeletePhoto(e.id))}),this.dialog.addEventListener("keydown",e=>{e.key==="ArrowLeft"?(e.preventDefault(),this.prev()):e.key==="ArrowRight"&&(e.preventDefault(),this.next())}),"closedBy"in HTMLDialogElement.prototype||this.dialog.addEventListener("click",e=>{if(e.target!==this.dialog)return;const t=this.dialog.getBoundingClientRect();t.top<=e.clientY&&e.clientY<=t.top+t.height&&t.left<=e.clientX&&e.clientX<=t.left+t.width||this.close()})}open(e,t,s){this.photosList=s||[e],this.currentIndex=t>=0?t:0,this.updateView(),this.dialog.showModal()}close(){this.dialog.open&&this.dialog.close()}prev(){this.photosList.length<=1||(this.currentIndex=(this.currentIndex-1+this.photosList.length)%this.photosList.length,this.updateView())}next(){this.photosList.length<=1||(this.currentIndex=(this.currentIndex+1)%this.photosList.length,this.updateView())}updateView(){const e=this.photosList[this.currentIndex];if(!e)return;this.elements.image.src=`/uploads/${e.filename}`,this.elements.image.alt=e.caption||e.original_name,this.elements.counter.textContent=`${this.currentIndex+1} / ${this.photosList.length}`;const t=this.photosList.length>1;this.elements.prevBtn.style.display=t?"flex":"none",this.elements.nextBtn.style.display=t?"flex":"none",this.elements.filename.textContent=e.original_name||e.filename,this.elements.date.textContent=w(e.date_taken),this.elements.dimensions.textContent=e.width&&e.height?`${e.width} × ${e.height} px`:"Original resolution",this.elements.size.textContent=m(e.size_bytes),this.elements.format.textContent=e.mime_type||"image",e.camera_model?(this.elements.camera.textContent=e.camera_model,this.elements.cameraRow.style.display="flex"):this.elements.cameraRow.style.display="none",e.caption?(this.elements.caption.textContent=e.caption,this.elements.captionRow.style.display="flex"):this.elements.captionRow.style.display="none",this.elements.downloadBtn.href=`/uploads/${e.filename}`,this.elements.downloadBtn.download=e.original_name||e.filename}}class E{constructor({onUploadComplete:e}){this.onUploadComplete=e,this.selectedFiles=[],this.dialog=document.createElement("dialog"),this.dialog.id="upload-dialog",this.dialog.setAttribute("closedby","any"),this.dialog.setAttribute("aria-label","Upload Photos"),this.setupDialogDom(),this.setupListeners(),document.body.appendChild(this.dialog)}setupDialogDom(){this.dialog.innerHTML=`
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
    `,this.elements={closeBtn:this.dialog.querySelector("#upload-close"),cancelBtn:this.dialog.querySelector("#upload-cancel"),submitBtn:this.dialog.querySelector("#upload-submit"),dropzone:this.dialog.querySelector("#upload-dropzone"),fileInput:this.dialog.querySelector("#file-input"),browseBtn:this.dialog.querySelector("#browse-btn"),dateInput:this.dialog.querySelector("#upload-date"),captionInput:this.dialog.querySelector("#upload-caption"),previewsContainer:this.dialog.querySelector("#upload-previews"),previewsGrid:this.dialog.querySelector("#previews-grid"),previewCountLabel:this.dialog.querySelector("#preview-count-label"),progressWrap:this.dialog.querySelector("#upload-progress-wrap"),progressFill:this.dialog.querySelector("#progress-bar-fill"),progressText:this.dialog.querySelector("#progress-text")}}setupListeners(){this.elements.closeBtn.addEventListener("click",()=>this.close()),this.elements.cancelBtn.addEventListener("click",()=>this.close()),this.elements.browseBtn.addEventListener("click",()=>this.elements.fileInput.click()),this.elements.dropzone.addEventListener("click",e=>{e.target!==this.elements.browseBtn&&this.elements.fileInput.click()}),this.elements.fileInput.addEventListener("change",e=>{this.handleFiles(Array.from(e.target.files))}),["dragenter","dragover"].forEach(e=>{this.elements.dropzone.addEventListener(e,t=>{t.preventDefault(),t.stopPropagation(),this.elements.dropzone.classList.add("drag-active")})}),["dragleave","drop"].forEach(e=>{this.elements.dropzone.addEventListener(e,t=>{t.preventDefault(),t.stopPropagation(),this.elements.dropzone.classList.remove("drag-active")})}),this.elements.dropzone.addEventListener("drop",e=>{const t=e.dataTransfer;t&&t.files&&t.files.length>0&&this.handleFiles(Array.from(t.files))}),this.elements.submitBtn.addEventListener("click",()=>this.startUpload()),"closedBy"in HTMLDialogElement.prototype||this.dialog.addEventListener("click",e=>{if(e.target!==this.dialog)return;const t=this.dialog.getBoundingClientRect();t.top<=e.clientY&&e.clientY<=t.top+t.height&&t.left<=e.clientX&&e.clientX<=t.left+t.width||this.close()})}open(){this.reset(),this.dialog.showModal()}close(){this.dialog.open&&this.dialog.close()}reset(){this.selectedFiles=[],this.elements.fileInput.value="",this.elements.captionInput.value="",this.elements.dateInput.value="",this.elements.previewsGrid.innerHTML="",this.elements.previewsContainer.style.display="none",this.elements.progressWrap.style.display="none",this.elements.progressFill.style.width="0%",this.elements.submitBtn.disabled=!0,this.elements.submitBtn.textContent="Upload Photos"}handleFiles(e){const t=e.filter(s=>s.type.startsWith("image/"));t.length!==0&&(this.selectedFiles=this.selectedFiles.concat(t),this.elements.submitBtn.disabled=!1,this.elements.submitBtn.textContent=`Upload ${this.selectedFiles.length} ${this.selectedFiles.length===1?"Photo":"Photos"}`,this.renderPreviews())}renderPreviews(){this.elements.previewsContainer.style.display="block",this.elements.previewCountLabel.textContent=`Selected Photos (${this.selectedFiles.length})`,this.elements.previewsGrid.innerHTML="",this.selectedFiles.forEach((e,t)=>{const s=document.createElement("div");s.className="upload-preview-thumb";const n=document.createElement("img");n.src=URL.createObjectURL(e),s.appendChild(n);const i=document.createElement("button");i.className="thumb-remove-btn",i.innerHTML="×",i.setAttribute("aria-label",`Remove ${e.name}`),i.addEventListener("click",l=>{l.stopPropagation(),this.selectedFiles.splice(t,1),this.selectedFiles.length===0?this.reset():(this.renderPreviews(),this.elements.submitBtn.textContent=`Upload ${this.selectedFiles.length} Photos`)}),s.appendChild(i),this.elements.previewsGrid.appendChild(s)})}async startUpload(){if(this.selectedFiles.length===0)return;this.elements.submitBtn.disabled=!0,this.elements.cancelBtn.disabled=!0,this.elements.progressWrap.style.display="block";const e={caption:this.elements.captionInput.value.trim(),date_taken:this.elements.dateInput.value?`${this.elements.dateInput.value}T12:00:00.000Z`:void 0};try{await b(this.selectedFiles,e,t=>{this.elements.progressFill.style.width=`${t}%`,this.elements.progressText.textContent=`Uploading... ${t}%`}),this.elements.progressText.textContent="Upload complete!",setTimeout(()=>{this.close(),this.onUploadComplete&&this.onUploadComplete()},500)}catch(t){alert(`Error uploading photos: ${t.message}`),this.elements.submitBtn.disabled=!1,this.elements.cancelBtn.disabled=!1,this.elements.progressText.textContent="Upload failed. Please try again."}}}class L{constructor(){this.appRoot=document.getElementById("app"),this.headerRoot=document.getElementById("header-root"),this.albums=[],this.currentView="albums",this.activeAlbum=null,this.activePhotos=[],this.init()}async init(){this.photoModal=new k({onDeletePhoto:e=>this.handleDeletePhoto(e)}),this.uploader=new E({onUploadComplete:()=>this.handleUploadSuccess()}),this.header=new y({onSearch:e=>this.handleSearch(e),onOpenUpload:()=>this.uploader.open(),onSelectView:e=>this.handleSelectView(e)}),this.headerRoot.appendChild(this.header.container),this.albumGrid=new x({onSelectAlbum:e=>this.openAlbumDetail(e)}),this.photoGrid=new C({onBack:()=>this.backToAlbums(),onOpenPhoto:(e,t,s)=>this.photoModal.open(e,t,s),onDeletePhoto:e=>this.handleDeletePhoto(e)}),await this.loadAlbums()}async loadAlbums(){try{this.appRoot.innerHTML='<div class="loading-state"><p>Loading albums...</p></div>',this.albums=await p(),this.renderCurrentView()}catch(e){this.appRoot.innerHTML=`
        <div class="empty-state">
          <div class="empty-icon">⚠️</div>
          <h3>Failed to load albums</h3>
          <p>${e.message}</p>
          <button class="btn btn-primary" onclick="location.reload()" style="margin-top:16px;">Retry</button>
        </div>
      `}}renderCurrentView(){if(this.appRoot.innerHTML="",this.currentView==="albums"){const e=this.albumGrid.render(this.albums);this.appRoot.appendChild(e)}else if(this.currentView==="album-detail"&&this.activeAlbum){const e=this.photoGrid.render(this.activeAlbum,this.activePhotos);this.appRoot.appendChild(e)}else if(this.currentView==="all-photos"||this.currentView==="search"){const e={title:this.currentView==="search"?"Search Results":"All Photos",date_key:`${this.activePhotos.length} items found`},t=this.photoGrid.render(e,this.activePhotos);this.appRoot.appendChild(t)}}async openAlbumDetail(e){try{this.appRoot.innerHTML='<div class="loading-state"><p>Opening album...</p></div>';const t=await g(e);this.activeAlbum=t.album,this.activePhotos=t.photos,this.currentView="album-detail",this.renderCurrentView(),window.scrollTo({top:0,behavior:"smooth"})}catch(t){alert(`Could not load album: ${t.message}`),this.backToAlbums()}}backToAlbums(){this.currentView="albums",this.activeAlbum=null,this.activePhotos=[],this.header.clearSearch(),this.header.setView("albums"),this.renderCurrentView()}async handleSearch(e){if(!e){this.currentView==="search"&&(this.currentView="albums",this.renderCurrentView());return}try{this.currentView="search",this.activeAlbum=null,this.activePhotos=await u(e),this.renderCurrentView()}catch(t){console.error("Search error:",t)}}async handleSelectView(e){if(e==="albums")this.currentView="albums",this.activeAlbum=null,this.activePhotos=[],this.renderCurrentView();else if(e==="all")try{this.currentView="all-photos",this.activeAlbum=null,this.activePhotos=await u(""),this.renderCurrentView()}catch(t){alert(`Error loading all photos: ${t.message}`)}}async handleDeletePhoto(e){try{if(await v(e),this.activePhotos=this.activePhotos.filter(t=>t.id!==e),this.albums=await p(),this.currentView==="album-detail"&&this.activePhotos.length===0){this.backToAlbums();return}this.renderCurrentView()}catch(t){alert(`Could not delete photo: ${t.message}`)}}async handleUploadSuccess(){await this.loadAlbums(),this.currentView==="album-detail"&&this.activeAlbum&&await this.openAlbumDetail(this.activeAlbum.id)}}document.addEventListener("DOMContentLoaded",()=>{new L});
//# sourceMappingURL=index-J0yeMlZQ.js.map
