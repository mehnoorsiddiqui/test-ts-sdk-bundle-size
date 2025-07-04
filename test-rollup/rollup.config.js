import resolve from '@rollup/plugin-node-resolve';
import commonjs from '@rollup/plugin-commonjs';
import json from '@rollup/plugin-json';
import { builtinModules } from 'module';
import filesize from 'rollup-plugin-filesize';

export default {
  input: 'src/index.js',
  output: {
    file: 'dist/bundle.js', // ESM file extension
    format: 'esm',           // Native ES module format
    sourcemap: true
  },
  external: [
    ...builtinModules,       // exclude Node.js built-ins like fs, path
  ],
  plugins: [
    resolve({
      preferBuiltins: true,
      exportConditions: ['node', 'import'] // important for proper ESM resolution
    }),
    commonjs(),
    json(),
    filesize() 
  ],
  treeshake: {
    moduleSideEffects: false // only include used code
  }
};