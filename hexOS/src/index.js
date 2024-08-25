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
  const token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3MjQ2MzM2NjgsImlhdCI6MTcyNDAyODg2OCwidWlkIjoiYWEwOGY2YmQtNzI2Yy00OWYxLWFmNTMtMjk4N2U1ODU1MzQ4In0.eaKKXVQXepMyJvOCaFg-u19_hkZMrjPf8YUSKSBimxo"

  console.log(app.ports)

  app.ports.eventStart.subscribe(function(token) {
    // TODO: `url` itself should come from the Elm side
    const url = `http://localhost:4001/v1/player/sync?token=${token}`
    const sse = new EventSource(url)

    sse.addEventListener("message", (e) => {
      console.log("Got event!")
      console.log(e)
      app.ports.eventSubscriber.send(e.data)
    })
  })

});

if (process.env.NODE_ENV === "development") {
  console.log("Abcdefg")
  const ElmDebugTransform = await import("elm-debug-transformer")
  ElmDebugTransform.register({simple_mode: true})
}
