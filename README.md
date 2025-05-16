# OpenAPI Rust Axum Tutorial Example (ORATE)

## Goal
The purpose of this exercise is a tutorial / self-learning on using OpenAPI to generate a Rust web service using the [Axum](https://docs.rs/axum/latest/axum/) web application framework. It is targetted at those fairly new to Rust.

## Create the project
`git init orate`  
`cd orate`  
## Define the workspaces
We will separate the generated code from the hand-written logic by using [Cargo Workspaces](https://doc.rust-lang.org/book/ch14-03-cargo-workspaces.html) . We don't use `cargo init` at the top-level, we just need a bare-bones `Cargo.toml`.

### Initialize the Cargo.toml
In the top level project create the following `Cargo.toml`:
```toml
[workspace]
resolver = "2"
```

Then create the crates:
```
cargo new orate_api --lib
cargo new orate_server --bin
```
Cargo should have already added the workspaces to the members field in Cargo.toml

## Define the API

#### orate_api/orate/orate.yaml

Create the directory:  
`mkdir -p orate_api/api`

Create the YAML file `orate/orate_api/api/orate.yaml`:
https://github.com/AndrewMobbs/orate/blob/34bcef15a6aa8afbf6402a508a1d1a6a152b93b8/orate_api/api/orate.yaml#L1C1-L22C41

## Generate the API library
Test the generator. We will run it as a container using `podman`. The directory with the specification file is mapped into the container as a volume, and also used as the output target.

`podman run --rm -v ./orate_api:/local openapitools/openapi-generator-cli generate -g rust-axum --generate-alias-as-model --additional-properties=packageName=orate_api,packageVersion=0.1.0 -i /local/api/orate.yaml -o /local`

This should create a full, compilable library in orate/orate_api  
`cargo build`

Later we'll put in a build system to automate this, including extracting the API version number from the OpenAPI YAML, which the generator then uses as the Cargo package version number.

## Build the server logic

For this we will be entirely working within `orate/orate_server`

#### orate/orate_server/Cargo.toml
Add the following to `orate/orate-server/Cargo.toml` after the `[package]` definition:

```toml
[dependencies] 
orate_api = { path = "../orate_api" }
```
Then from command line, add the following crates to get the latest versions:
`cargo add axum async-trait axum-extra http tracing tracing-subscriber thiserror`
`cargo add tokio -F rt-multi-thread`
`cargo add tower-http -F trace`

### Plumbing for the generated API

First we need to plumb the generated API into our server. This involves the context and error handlers, and a dispatch function to call the handlers for each endpoint.

#### orate/orate_server/src/api_error.rs
https://github.com/AndrewMobbs/orate/blob/34bcef15a6aa8afbf6402a508a1d1a6a152b93b8/orate_server/src/api_error.rs#L1-L17
#### orate/orate_server/src/api_context.rs
https://github.com/AndrewMobbs/orate/blob/34bcef15a6aa8afbf6402a508a1d1a6a152b93b8/orate_server/src/api_context.rs#L1-L72

### Handlers
These are the handlers for the server endpoints. API calls will be routed to code modules here which are then responsible for the server logic:

Create handlers module:
`mkdir -p src/handlers`
#### orate/orate_server/src/handlers/mod.rs
https://github.com/AndrewMobbs/orate/blob/34bcef15a6aa8afbf6402a508a1d1a6a152b93b8/orate_server/src/handlers/mod.rs#L1
#### orate/orate_server/src/handlers/hello_handler.rs
https://github.com/AndrewMobbs/orate/blob/34bcef15a6aa8afbf6402a508a1d1a6a152b93b8/orate_server/src/handlers/hello_handler.rs#L1-L20

### The server code
To actually run the server we just need a bit of code in `main.rs` to call the Axum Router from the generated code and start a server for it. For the example we've hard-coded this to localhost:3000.
#### orate/orate_server/src/main.rs
https://github.com/AndrewMobbs/orate/blob/34bcef15a6aa8afbf6402a508a1d1a6a152b93b8/orate_server/src/main.rs#L1-L25

## Build system

Normally we could use a [build.rs](https://doc.rust-lang.org/cargo/reference/build-scripts.html) script to run the generator, but this generator clobbers the `Cargo.toml`, so cargo can't find the build.rs script after the first run...

#### orate/orate_api/build.rs
We still need a stub `build.rs` to let cargo know that the generated code has changed.
https://github.com/AndrewMobbs/orate/blob/34bcef15a6aa8afbf6402a508a1d1a6a152b93b8/orate_api/build.rs#L1-L14

### Makefile
The Makefile is responsible for calling the OpenAPI generator, and also extracts the version from the OpenAPI YAML to pass to the generator. After that, everything is left to Cargo to actually build the project.
#### orate/Makefile
https://github.com/AndrewMobbs/orate/blob/34bcef15a6aa8afbf6402a508a1d1a6a152b93b8/Makefile#L1-L79
