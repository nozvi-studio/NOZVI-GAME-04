import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { createDatabase } from './db.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const uploadsDir = path.join(__dirname, '..', 'uploads');
const dbPath = path.join(__dirname, '..', 'photos.db');

if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

function generateSvgPhoto(title, color1, color2, iconType) {
  let iconSvg = '';
  if (iconType === 'mountain') {
    iconSvg = `
      <polygon points="120,420 300,180 480,420" fill="rgba(255,255,255,0.25)" />
      <polygon points="320,420 460,240 600,420" fill="rgba(255,255,255,0.18)" />
      <circle cx="560" cy="140" r="45" fill="#FFE082" />
    `;
  } else if (iconType === 'sun') {
    iconSvg = `
      <circle cx="400" cy="280" r="90" fill="#FFD54F" />
      <path d="M 100 480 Q 250 420 400 480 T 700 480 L 700 600 L 100 600 Z" fill="rgba(255,255,255,0.22)" />
    `;
  } else if (iconType === 'forest') {
    iconSvg = `
      <polygon points="200,450 300,280 400,450" fill="rgba(255,255,255,0.28)" />
      <polygon points="350,450 450,220 550,450" fill="rgba(255,255,255,0.32)" />
      <polygon points="500,450 600,310 700,450" fill="rgba(255,255,255,0.2)" />
    `;
  } else if (iconType === 'city') {
    iconSvg = `
      <rect x="180" y="240" width="100" height="260" fill="rgba(255,255,255,0.25)" rx="6"/>
      <rect x="310" y="160" width="140" height="340" fill="rgba(255,255,255,0.32)" rx="8"/>
      <rect x="480" y="220" width="120" height="280" fill="rgba(255,255,255,0.22)" rx="6"/>
    `;
  } else {
    iconSvg = `
      <circle cx="400" cy="300" r="110" fill="none" stroke="rgba(255,255,255,0.4)" stroke-width="8" />
      <circle cx="400" cy="300" r="40" fill="rgba(255,255,255,0.35)" />
    `;
  }

  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 600" width="800" height="600">
    <defs>
      <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
        <stop offset="0%" stop-color="${color1}" />
        <stop offset="100%" stop-color="${color2}" />
      </linearGradient>
    </defs>
    <rect width="800" height="600" fill="url(#grad)" />
    ${iconSvg}
    <text x="40" y="550" font-family="-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" font-size="28" font-weight="700" fill="#FFFFFF" letter-spacing="0.5">${title}</text>
  </svg>`;
}

export function seedDatabase(customDbPath = dbPath, customUploadsDir = uploadsDir) {
  const db = createDatabase(customDbPath);

  const sampleData = [
    // Today's Album (4 photos -> will test 4-tile preview)
    {
      date: '2026-11-14',
      photos: [
        { title: 'Golden Sunrise', colors: ['#FF7E5F', '#FEB47B'], icon: 'sun', camera: 'Sony A7 IV', caption: 'Sunrise over coastal cliffs' },
        { title: 'Pine Ridge Trail', colors: ['#2B580C', '#639A67'], icon: 'forest', camera: 'iPhone 16 Pro', caption: 'Morning hike through the redwoods' },
        { title: 'Urban Skyline', colors: ['#141E30', '#243B55'], icon: 'city', camera: 'Fujifilm X-T5', caption: 'City waking up with glass reflections' },
        { title: 'Alpine Peak', colors: ['#2980B9', '#6DD5FA'], icon: 'mountain', camera: 'Sony A7 IV', caption: 'First snow on the summit' },
        { title: 'Studio Reflection', colors: ['#8E2DE2', '#4A00E0'], icon: 'lens', camera: 'Canon R5', caption: 'Macro prism photography' }
      ]
    },
    // Yesterday's Album (3 photos -> will test 3-tile preview)
    {
      date: '2026-11-13',
      photos: [
        { title: 'Autumn Canopy', colors: ['#F7971E', '#FFD200'], icon: 'forest', camera: 'iPhone 16 Pro', caption: 'Vibrant amber leaves in park' },
        { title: 'Pacific Horizon', colors: ['#00c6ff', '#0072ff'], icon: 'sun', camera: 'Leica Q3', caption: 'Clear blue ocean horizon' },
        { title: 'Neon Avenue', colors: ['#f12711', '#f5af19'], icon: 'city', camera: 'Sony A7 IV', caption: 'Street lights after light drizzle' }
      ]
    },
    // Earlier this week (2 photos -> will test 2-tile preview)
    {
      date: '2026-11-10',
      photos: [
        { title: 'Highland Meadow', colors: ['#11998e', '#38ef7d'], icon: 'mountain', camera: 'Fujifilm X-T5', caption: 'Wildflowers across green valley' },
        { title: 'Sunset Silhouette', colors: ['#ff416c', '#ff4b2b'], icon: 'sun', camera: 'Canon R5', caption: 'Dusk silhouette of mountain ridge' }
      ]
    },
    // Last week (1 photo -> will test 1-tile single hero preview)
    {
      date: '2026-11-04',
      photos: [
        { title: 'Architectural Geometry', colors: ['#232526', '#414345'], icon: 'city', camera: 'Leica Q3', caption: 'Modern minimalist facade lines' }
      ]
    }
  ];

  let totalPhotos = 0;

  for (const group of sampleData) {
    const album = db.getOrCreateAlbumForDate(group.date);

    group.photos.forEach((item, index) => {
      const filename = `seed-${group.date}-${index + 1}.svg`;
      const filePath = path.join(customUploadsDir, filename);

      const svgContent = generateSvgPhoto(item.title, item.colors[0], item.colors[1], item.icon);
      fs.writeFileSync(filePath, svgContent, 'utf-8');

      const dateTaken = `${group.date}T1${index}:30:00.000Z`;
      db.insertPhoto({
        album_id: album.id,
        filename,
        original_name: `${item.title.toLowerCase().replace(/\s+/g, '-')}.svg`,
        mime_type: 'image/svg+xml',
        size_bytes: Buffer.byteLength(svgContent, 'utf-8'),
        width: 800,
        height: 600,
        date_taken: dateTaken,
        camera_model: item.camera,
        caption: item.caption
      });
      totalPhotos++;
    });
  }

  console.log(`[Seed] Successfully seeded ${sampleData.length} albums with ${totalPhotos} photos.`);
  db.close();
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  seedDatabase();
}

