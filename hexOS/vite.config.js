import path from "path";
import { defineConfig, loadEnv } from 'vite';
import elmPlugin from 'vite-plugin-elm';

export default defineConfig(({ command, mode }) => {
  const env = loadEnv(mode, process.cwd(), '')

  return {
    plugins: [
      elmPlugin({
        debug: true,
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
      minify: mode === 'production',
      rollupOptions: {
        input: {
          index: 'src/index.html',
          midnight: 'src/styles/themes/midnight/_index.scss',
          terminal: 'src/styles/themes/terminal/_index.scss'
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
