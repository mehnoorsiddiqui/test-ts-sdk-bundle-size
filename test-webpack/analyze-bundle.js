import fs from 'fs';
// import { gzipSizeSync } from 'gzip-size';
// import { sync as brotliSizeSync } from 'brotli-size';

const bundlePath = new URL('../test-webpack/dist/bundle.js', import.meta.url);
const bundle = fs.readFileSync(bundlePath);

console.log('\n📦 Bundle Size Report:');
console.log(`   Raw:     ${(bundle.length / 1024).toFixed(2)} KB`);
// console.log(`   Gzip:    ${(gzipSizeSync(bundle) / 1024).toFixed(2)} KB`);
// console.log(`   Brotli:  ${(brotliSizeSync(bundle) / 1024).toFixed(2)} KB`);
