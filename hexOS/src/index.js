// import "./style.css";
import { Elm } from "./Main.elm";

document.addEventListener("DOMContentLoaded", () => {
  Elm.Main.init({
    node: document.getElementById('app'),
    flags: {
      "theme": {
        "c": {
          "primary": "#2ba964",
          "background": "#ffffff",
        },
        "logo": "foo_logo.png",
        "default": true
      },
      "creds": "42",
      "viewportX": window.innerWidth,
      "viewportY": window.innerHeight,
      "randomSeed1": 1,
      "randomSeed2": 2,
      "randomSeed3": 3,
      "randomSeed4": 4
    }
  });
});

if (process.env.NODE_ENV === "development") {
  console.log("Abcdefg")
  const ElmDebugTransform = await import("elm-debug-transformer")
  ElmDebugTransform.register({simple_mode: true})
}
