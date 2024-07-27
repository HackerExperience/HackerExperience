# Auth

Below is outdated. Needs confirmation. Don't trust it.

- We use server-side sessions (not JWTs)

### Flow

1. POST /login with username and password
2. Backend responds with `access_token`
3. Establish WS connection by passing the `access_token`
4. Backend will validate the `access_token` and accept/deny the connection
5. With the WS connection established, Client can request a `refresh_token` via WS
6. The refresh token can be used to establish a new WS connection if the current one dies

### Remarks about the proposed flow above

- `access_token` is deleted (from the Backend) upon the initial connection (it is a single-use token).
- In order to establish a new WS connection (say, because the original one died), both the `refresh_token`
AND the `access_token` originally used in the initial connection need to be passed.
- `access_token` is kept in an httpOnly cookie
- `refresh_token` is kept in the application memory
- By themselves, each token is useless. They only can be used together (to establish a new WS connection)

### Potential Flaws / Drawbacks

- Hard / impossible to support sessions that outlive the tab (unless we store this information in localstorage)
- Bad UX on crappy connections (refresh token is used but WS connection dies before a new refresh token is generated)
- I'm okay with these flaws for now...
