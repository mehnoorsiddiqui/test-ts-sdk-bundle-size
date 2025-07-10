// const path = require('path');

// module.exports = {
//   entry: './src/index.js', // entry point
//   output: {
//     filename: 'bundle.js',
//     path: path.resolve(__dirname, 'dist'),
//   },
//   resolve: {
//     fallback: {
//       stream: require.resolve('stream-browserify'),
//       path: require.resolve('path-browserify'),
//     },
//   },
//   mode: 'development', // or 'production'
// };
import path from 'path';
import { fileURLToPath } from 'url';
import webpack from 'webpack';
import TerserPlugin from 'terser-webpack-plugin';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export default {
  mode: 'production', // Enables tree-shaking and minification
  entry: './src/index.ts',
  output: {
    filename: 'bundle.js',
    path: path.resolve(__dirname, 'dist'),
    clean: true,
  },
    module: {
    rules: [
      {
        test: /\.tsx?$/,
        use: 'ts-loader',
        exclude: /node_modules/,
      },
    ],
  },
  resolve: {
    fallback: {
        buffer: 'buffer/',
        stream: 'stream-browserify',
        process: 'process/browser',
    },
     extensions: [".ts", ".js"]
  },
  plugins: [
    new webpack.ProvidePlugin({
      Buffer: ['buffer', 'Buffer'],
      process: ['process'],
    }),
  ],
  optimization: {
    usedExports: true, // Enables tree-shaking
    minimize: true,
    minimizer: [new TerserPlugin()],
  },
};
