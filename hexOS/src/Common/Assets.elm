module Common.Assets exposing (logoUrl)


logoUrl : String
logoUrl =
    -- This is just an example on how to use static assets with Vite
    "[VITE_PLUGIN_ELM_ASSET:$images/logo.svg]"
