FROM elixir:1.16

# Install system dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    inotify-tools \
    && rm -rf /var/lib/apt/lists/*

# Set up the working directory inside the container
WORKDIR /app/examples/threadline_phoenix

# Install Hex and Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# We are building the demo app from the repo root to allow path dependencies to resolve.
# The build context in docker-compose must be the repository root.

# Copy the entire repository into the container
COPY . /app

# Switch to the demo app directory
WORKDIR /app/examples/threadline_phoenix

# Set the environment
ENV MIX_ENV=dev
ENV DB_HOST=postgres

# Fetch and compile dependencies
RUN mix deps.get
RUN mix compile

# Expose the Phoenix port
EXPOSE 4000

# Copy and set the entrypoint script
COPY examples/threadline_phoenix/entrypoint.sh /app/examples/threadline_phoenix/entrypoint.sh
RUN chmod +x /app/examples/threadline_phoenix/entrypoint.sh

ENTRYPOINT ["/app/examples/threadline_phoenix/entrypoint.sh"]

# Default command to run the server
CMD ["mix", "phx.server"]
