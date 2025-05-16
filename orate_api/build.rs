use std::path::Path;

fn main() {
    // Tell Cargo that if the OpenAPI spec file changes, it should re-run this build script.
    // This registers the dependency with Cargo's build cache.
    // The actual generation is handled by the Makefile, but Cargo knowing
    // about this dependency ensures it considers the crate potentially stale
    // when the spec changes.
    let spec_path = Path::new("api/orate.yaml");
    println!("cargo:rerun-if-changed={}", spec_path.display());

    // The build.rs doesn't run the generator in this setup.
    println!("orate_api build.rs finished. (Generation handled by Makefile)");
}
