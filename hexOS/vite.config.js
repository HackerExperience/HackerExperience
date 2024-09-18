import path from "path";
import { defineConfig, loadEnv } from 'vite';
import elmPlugin from 'vite-plugin-elm';

export default defineConfig(({ command, mode }) => {
  const env = loadEnv(mode, process.cwd(), '')

  return {
    plugins: [
      elmPlugin({
        debug: false,
        optimize: false,
      })
    ],
    server: {
      strictPort: true,
      port: env.PORT || 8080
    },
    root: "src",
    build: {
      outDir: path.join(__dirname, "dist"),
      emptyOutDir: true
    },
    resolve: {
      alias: {
        $fonts: path.resolve('./assets/fonts'),
        $images: path.resolve('./assets/images')
      }
    },
    publicDir: 'assets'
  }
});
