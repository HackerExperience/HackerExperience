use argon2::{
    password_hash::{rand_core::OsRng, PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2, Params,
};

#[rustler::nif]
pub fn hash(pepper: String, pwd: String) -> Result<String, String> {
    let salt = SaltString::generate(&mut OsRng);

    let params = match get_params() {
        Ok(params) => params,
        Err(err) => return Err(err)
    };

    let hash_result = match Argon2::new_with_secret(
        pepper.as_bytes(),
        argon2::Algorithm::Argon2id,
        argon2::Version::V0x13,
        params,
    ) {
        Ok(argon2) => argon2.hash_password(pwd.as_bytes(), &salt),
        Err(err) => return Err(err.to_string()),
    };

    return match hash_result {
        Ok(hash) => Ok(hash.to_string()),
        Err(err) => Err(err.to_string()),
    };
}

#[rustler::nif]
pub fn verify(pepper: String, pwd: String, hashed_pwd: String) -> Result<(), String> {
    let parsed_hash = match PasswordHash::new(&hashed_pwd){
        Ok(h) => h,
        Err(err) => return Err(err.to_string())
    };

    let params = match get_params() {
        Ok(params) => params,
        Err(err) => return Err(err),
    };

    let verify_result = match Argon2::new_with_secret(
        pepper.as_bytes(),
        argon2::Algorithm::Argon2id,
        argon2::Version::V0x13,
        params,
    ) {
        Ok(argon2) => argon2.verify_password(pwd.as_bytes(), &parsed_hash),
        Err(err) => return Err(err.to_string()),
    };

    return match verify_result {
        Ok(()) => Ok(()),
        Err(err) => Err(err.to_string()),
    }
}

fn get_params() -> Result<Params, String> {
    // TODO: Move these hard-coded values to a config file (and use less resources on dev/test envs)
    // TODO: The values here are not production-ready and should be revised before a public release
    return match Params::new(1 * 1024, 1, 1, Some(Params::DEFAULT_OUTPUT_LEN)) {
        Ok(params) => Ok(params),
        Err(err) => return Err(err.to_string()),
    };
}

rustler::init!("Elixir.Core.Crypto.Password.Argon2", [hash, verify]);

