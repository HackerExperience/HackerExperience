module OS.CtxMenu.Menus exposing (..)

import Game.Model.Log exposing (Log)


type OSMenu
    = OSRootMenu


type LogViewerMenu
    = LVRootMenu
    | LVEntryMenu Log


type Menu
    = OS OSMenu
    | LogViewer LogViewerMenu
