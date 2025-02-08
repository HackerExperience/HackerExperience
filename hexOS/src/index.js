import "./styles/themes/midnight/_index.scss";
import "./styles/core.scss";
import { Elm } from "./Main.elm";

document.addEventListener("DOMContentLoaded", () => {
  const app = Elm.Main.init({
    node: document.getElementById('app'),
    flags: {
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
  app.ports.eventStart.subscribe(function({ token, baseUrl }) {
    const url = `${baseUrl}/v1/player/sync?token=${token}`
    const sse = new EventSource(url)

    sse.addEventListener("message", (e) => {
      console.log("Got event!")
      console.log(e)
      app.ports.eventSubscriber.send(JSON.parse(e.data))
    })
  })

});

if (process.env.NODE_ENV === "development") {
  console.log("Abcdefg")
  const ElmDebugTransform = await import("elm-debug-transformer")
  ElmDebugTransform.register({simple_mode: true})
}
