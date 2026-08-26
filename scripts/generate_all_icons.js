const sharp = require('sharp');
const pngToIco = require('png-to-ico').default || require('png-to-ico');
const fs = require('fs');
const path = require('path');

const repoRoot = path.resolve(__dirname, '..');
const svgPath = path.join(repoRoot, 'pala_icon.svg');

async function main() {
  console.log('Rendering all Pala platform icons with transparent corners from:', svgPath);
  const svgBuffer = fs.readFileSync(svgPath);

  const out1024 = path.join(repoRoot, 'pala_icon_1024.png');
  const out512 = path.join(repoRoot, 'pala_icon_512.png');
  const out256 = path.join(repoRoot, 'pala_icon_256.png');
  const out192 = path.join(repoRoot, 'pala_icon_192.png');
  const out128 = path.join(repoRoot, 'pala_icon_128.png');
  const out64 = path.join(repoRoot, 'pala_icon_64.png');
  const out48 = path.join(repoRoot, 'pala_icon_48.png');
  const out32 = path.join(repoRoot, 'pala_icon_32.png');
  const out16 = path.join(repoRoot, 'pala_icon_16.png');

  // Helper to render SVG directly to transparent PNG
  async function renderSvgToPng(width, height, dest) {
    await sharp(svgBuffer)
      .resize(width, height)
      .png({ compressionLevel: 9 })
      .toFile(dest);
  }

  // 1. Generate core PNG sizes with transparent alpha corners
  await renderSvgToPng(1024, 1024, out1024);
  await renderSvgToPng(512, 512, out512);
  await renderSvgToPng(256, 256, out256);
  await renderSvgToPng(192, 192, out192);
  await renderSvgToPng(128, 128, out128);
  await renderSvgToPng(64, 64, out64);
  await renderSvgToPng(48, 48, out48);
  await renderSvgToPng(32, 32, out32);
  await renderSvgToPng(16, 16, out16);

  console.log('[+] Core transparent PNGs created.');

  // 2. Generate Multi-Resolution ICO with transparent alpha corners
  const icoBuf = await pngToIco([out16, out32, out48, out64, out128, out256]);
  const rootIco = path.join(repoRoot, 'pala_icon.ico');
  fs.writeFileSync(rootIco, icoBuf);

  const winIco = path.join(repoRoot, 'app', 'windows', 'runner', 'resources', 'app_icon.ico');
  fs.writeFileSync(winIco, icoBuf);

  const webIco = path.join(repoRoot, 'website', 'src', 'app', 'favicon.ico');
  fs.writeFileSync(webIco, icoBuf);

  const docsIco = path.join(repoRoot, 'docs', 'favicon.ico');
  fs.writeFileSync(docsIco, icoBuf);

  console.log('[+] Transparent Windows app_icon.ico and favicons created.');

  // 3. Android Mipmaps (Transparent corners)
  const androidMap = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };
  for (const [folder, size] of Object.entries(androidMap)) {
    const dest = path.join(repoRoot, 'app', 'android', 'app', 'src', 'main', 'res', folder, 'ic_launcher.png');
    await renderSvgToPng(size, size, dest);
  }
  console.log('[+] Android mipmaps with transparent corners created.');

  // 4. iOS AppIcon set
  const iosMap = {
    'Icon-App-1024x1024@1x.png': 1024,
    'Icon-App-83.5x83.5@2x.png': 167,
    'Icon-App-76x76@2x.png': 152,
    'Icon-App-76x76@1x.png': 76,
    'Icon-App-60x60@3x.png': 180,
    'Icon-App-60x60@2x.png': 120,
    'Icon-App-40x40@3x.png': 120,
    'Icon-App-40x40@2x.png': 80,
    'Icon-App-40x40@1x.png': 40,
    'Icon-App-29x29@3x.png': 87,
    'Icon-App-29x29@2x.png': 58,
    'Icon-App-29x29@1x.png': 29,
    'Icon-App-20x20@3x.png': 60,
    'Icon-App-20x20@2x.png': 40,
    'Icon-App-20x20@1x.png': 20,
  };
  const iosDir = path.join(repoRoot, 'app', 'ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset');
  for (const [filename, size] of Object.entries(iosMap)) {
    const dest = path.join(iosDir, filename);
    await renderSvgToPng(size, size, dest);
  }
  console.log('[+] iOS AppIcons created.');

  // 5. macOS AppIcons
  const macDir = path.join(repoRoot, 'app', 'macos', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset');
  const macMap = {
    'app_icon_1024.png': 1024,
    'app_icon_512.png': 512,
    'app_icon_256.png': 256,
    'app_icon_128.png': 128,
    'app_icon_64.png': 64,
    'app_icon_32.png': 32,
    'app_icon_16.png': 16,
  };
  for (const [filename, size] of Object.entries(macMap)) {
    const dest = path.join(macDir, filename);
    await renderSvgToPng(size, size, dest);
  }
  console.log('[+] macOS AppIcons created.');

  // 6. Flutter Web & Website Logo assets
  await renderSvgToPng(32, 32, path.join(repoRoot, 'app', 'web', 'favicon.png'));
  await renderSvgToPng(192, 192, path.join(repoRoot, 'app', 'web', 'icons', 'Icon-192.png'));
  await renderSvgToPng(512, 512, path.join(repoRoot, 'app', 'web', 'icons', 'Icon-512.png'));
  await renderSvgToPng(192, 192, path.join(repoRoot, 'app', 'web', 'icons', 'Icon-maskable-192.png'));
  await renderSvgToPng(512, 512, path.join(repoRoot, 'app', 'web', 'icons', 'Icon-maskable-512.png'));

  await renderSvgToPng(512, 512, path.join(repoRoot, 'website', 'public', 'logo.png'));
  await renderSvgToPng(512, 512, path.join(repoRoot, 'docs', 'logo.png'));

  console.log('[+] All icons re-rendered with true transparent alpha corners!');
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});

