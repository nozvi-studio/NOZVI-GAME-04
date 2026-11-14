/**
 * REST API client for the local Photo Organizer backend
 */

export async function getAlbums() {
  const res = await fetch('/api/albums');
  if (!res.ok) throw new Error(`Failed to fetch albums: ${res.statusText}`);
  return res.json();
}

export async function getAlbum(id) {
  const res = await fetch(`/api/albums/${id}`);
  if (!res.ok) throw new Error(`Failed to fetch album #${id}: ${res.statusText}`);
  return res.json();
}

export async function getPhotos(searchQuery = '') {
  const url = searchQuery 
    ? `/api/photos?q=${encodeURIComponent(searchQuery)}`
    : '/api/photos';
  const res = await fetch(url);
  if (!res.ok) throw new Error(`Failed to fetch photos: ${res.statusText}`);
  return res.json();
}

export async function getPhoto(id) {
  const res = await fetch(`/api/photos/${id}`);
  if (!res.ok) throw new Error(`Failed to fetch photo #${id}: ${res.statusText}`);
  return res.json();
}

export async function uploadPhotos(files, metadata = {}, onProgress = null) {
  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    const formData = new FormData();

    for (const file of files) {
      formData.append('photos', file);
    }
    if (metadata.date_taken) {
      formData.append('date_taken', metadata.date_taken);
    }
    if (metadata.caption) {
      formData.append('caption', metadata.caption);
    }
    if (metadata.camera_model) {
      formData.append('camera_model', metadata.camera_model);
    }

    xhr.open('POST', '/api/photos/upload');

    if (onProgress && xhr.upload) {
      xhr.upload.onprogress = (e) => {
        if (e.lengthComputable) {
          const percent = Math.round((e.loaded / e.total) * 100);
          onProgress(percent);
        }
      };
    }

    xhr.onload = () => {
      if (xhr.status >= 200 && xhr.status < 300) {
        try {
          const data = JSON.parse(xhr.responseText);
          resolve(data);
        } catch (e) {
          reject(new Error('Invalid response from server'));
        }
      } else {
        try {
          const errData = JSON.parse(xhr.responseText);
          reject(new Error(errData.error || `Upload failed with status ${xhr.status}`));
        } catch {
          reject(new Error(`Upload failed with status ${xhr.status}`));
        }
      }
    };

    xhr.onerror = () => reject(new Error('Network error during photo upload'));
    xhr.send(formData);
  });
}

export async function deletePhoto(id) {
  const res = await fetch(`/api/photos/${id}`, {
    method: 'DELETE'
  });
  if (!res.ok) throw new Error(`Failed to delete photo #${id}`);
  return res.json();
}

