Seems to work. The --server flag is fundamental for the SP/MP api scenario:

npx elm-open-api ./lobby.yml --module-name LobbyAPI --server '{"dev": "http://localhost:3000", "prod": "http://localhost:4000"}'

Similar but SP and MP instead of Dev and Prod.

We may have a SP.Api and MP.Api which call Game.Api (generated) with the corresponding flag. Or something else.

In any case, now it's a matter of implementing a PoC API and seeing how it turns out.

The tooling to generate an OAS from Elixir will not be done now. For the time being, I'll just manually update the yml file.
Once I've confirmed that will work, I'll create a script in Elixir to generate the spec from the registered endpoints.


# Backend integration

Norm can be used to verify input/output types are valid, and then openapi schema can be generated based on the Norm spec (either automatically but, if too hard/brittle, manually)

Notice we still need to cast the input using the Validator pattern. The Validator must exist anyway and must always be called before inserting into the DB (without the :cast option)

For example, I may need to trim an input. Trimming happens only once: during the `get_params` phase. Norm would have to check on the trimmed input, but (ideally) the trimming operation would happen only once.

I might be okay with trimming twice at the Endpoint layer if it results in a simpler architecture/pattern.
