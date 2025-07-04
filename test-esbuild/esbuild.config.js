import { build } from 'esbuild';
import fs from 'fs';
// import gzipSize from 'gzip-size';
// import brotliSize from 'brotli-size';

const outputFile = 'dist/output.js';

build({
  entryPoints: ['src/index.js'],
  bundle: true,
  outfile: outputFile,
  minify: true,
  treeShaking: true,
  metafile: true,
  platform: 'node',
}).then(result => {
  console.log('✅ Build succeeded.');

  // Write metafile to disk
  fs.writeFileSync('meta.json', JSON.stringify(result.metafile, null, 2));
  console.log('📝 Meta file saved to meta.json');

  // Analyze bundle size
  const code = fs.readFileSync(outputFile);

  console.log('\n📦 Bundle Size Report:');
  console.log('Raw size    :', `${(code.length / 1024).toFixed(2)} KB`);
  // console.log('Gzip size   :', `${(gzipSize.sync(code) / 1024).toFixed(2)} KB`);
  // console.log('Brotli size :', `${(brotliSize.sync(code) / 1024).toFixed(2)} KB`);

}).catch(() => process.exit(1));
