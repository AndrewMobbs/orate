## Goal
The purpose of this exercise is a tutorial / self-learning on using OpenAPI to generate a Rust web service using the [Axum](https://docs.rs/axum/latest/axum/) web application framework.

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

### orate_api/orate/orate.yaml

Create the directory
`mkdir -p orate_api/api`

Create the YAML file `orate/orate_api/api/orate.yaml`:

```yaml
openapi: 3.0.0
info:
  title: OpenAPI Rust Axum Tutorial Example API
  version: 0.1.0
  description: An example template for Rust Axum with OpenAPI generated server.
servers:
  - url: http://localhost:3000 # Replace with your actual server URL if different
    description: Development server
paths:
  /v1/hello:
    get:
      summary: Returns a greeting
      description: Responds with a simple string greeting.
      operationId: getHello
      responses:
        '200':
          description: A successful response with a greeting message.
          content:
            application/json:
              schema:
                type: string
                example: "Hello, World!"
                
```

## Generate the API library
Test the generator. We will run it as a container using `podman` :

`podman run --rm -v ./orate_api:/local openapitools/openapi-generator-cli generate -g rust-axum --generate-alias-as-model --additional-properties=packageName=orate_api,packageVersion=0.1.0 -i /local/api/orate.yaml -o /local`

This should create a full, compilable library in orate/orate_api
`cargo build`

Later we'll put in a build system to automate this, including extracting the API version number from the OpenAPI YAML, which the generator then uses as the Cargo package version number.

## Build the server logic

For this we will be entirely working within `orate/orate_server`
### orate/orate_server/Cargo.toml
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

### Handlers
These are the handlers for the server endpoints. API calls will be routed to code modules here which are then responsible for the server logic:

1. Create handlers module:
`mkdir -p src/handlers`


2. Create `src/handlers/mod.rs`:
3. Create the handler for our endpoint:
### main.rs
To actually run the server we just need a bit of code to call the Axum Router from the generated code and start a server for it. For the example we've hard-coded this to localhost:3000.

## Build system

Normally we could use a [build.rs](https://doc.rust-lang.org/cargo/reference/build-scripts.html) script to run the generator, but this generator clobbers the `Cargo.toml`, so cargo can't find the build.rs script after the first run...

### orate_api/build.rs
We still need a stub `build.rs` to let cargo know that the generated code has changed. However, it doesn't 
### Makefile
The Makefile is responsible for calling the OpenAPI generator, and also extracts the version from the OpenAPI YAML to pass to the generator. After that, everything is left to Cargo to actually build the project.

