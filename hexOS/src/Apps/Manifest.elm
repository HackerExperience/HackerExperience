module Apps.Manifest exposing (..)


type Manifest
    = InvalidApp
    | LogViewerApp
    | RemoteAccessApp
    | DemoApp
      -- Popups
    | PopupConfirmationDialog
    | PopupDemoSingleton



-- -- NOTE: I may be able to merge both manifests into one (right?)
-- -- NOTE: Maybe move this to Popups.Manifest (i.e. its own root folder)
-- type PopupManifest
--     = ConfirmationDialog
