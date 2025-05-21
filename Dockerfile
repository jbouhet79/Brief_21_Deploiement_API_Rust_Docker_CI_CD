FROM rust:1.87

WORKDIR /myapp
COPY . /myapp

RUN rustup default nightly && rustup update
RUN cargo install --path .

CMD ["cargo", "run"]

