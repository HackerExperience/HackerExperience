// import "./style.css";
import { Elm } from "./Main.elm";

document.addEventListener("DOMContentLoaded", () => {
  const app = Elm.Main.init({
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

  // TODO: Describe token auth and why we have a token only for SSE
  // TODO: Temporary placeholder until we fully integrate with the Elm side
  const token = "xyz"

  // app.ports.sseStart.subscribe(function(url, token) {
    // const sse = new EventSource(`${url}?token=${token}`, sseOptions)
    const sse = new EventSource(`http://localhost:4001/v1/player/sync?token=${token}`)

    sse.addEventListener("message", (e) => {
      console.log("Got event!")
      console.log(e)
      app.ports.eventReader.send(e.data)
    })
  // })

});

if (process.env.NODE_ENV === "development") {
  console.log("Abcdefg")
  const ElmDebugTransform = await import("elm-debug-transformer")
  ElmDebugTransform.register({simple_mode: true})
}
