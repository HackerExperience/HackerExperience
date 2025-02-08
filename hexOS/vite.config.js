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
      emptyOutDir: true,
      rollupOptions: {
        output: {
          manualChunks: {
            core: ["src/styles/core.scss"],
            theme: ["src/styles/themes/_index.scss"]
          }
        }
      }
    },
    resolve: {
      alias: {
        $fonts: path.resolve('./assets/fonts'),
        $images: path.resolve('./assets/images')
      }
    },
    publicDir: 'assets',
    css: {
      preprocessorOptions: {
        scss: {
          api: 'modern-compiler',
          devSourcemap: true
        }
      }
    }
  }
});
