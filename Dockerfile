# Use the official Elixir image
FROM elixir:latest

# Install Hex package manager and Rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set the working directory
WORKDIR /app

# Copy the mix files
COPY mix.exs mix.lock ./

# Copy the rest of the application code
COPY . .

# Install git for heroicons
RUN apt-get update && apt-get install -y git

# Set the build environment
ENV MIX_ENV=dev

# Install and compile ALL dependencies including dev dependencies
RUN mix deps.get
RUN mix deps.compile

# Compile the project
RUN mix compile

# Set the environment to production for deployment
ENV MIX_ENV=prod
ENV PHX_SERVER=true

# Create database directory
RUN mkdir -p /app/priv/repo/data

# Set the database path
ENV DATABASE_PATH=/app/priv/repo/data/jumpapp_balance_prod.db

# Expose the port the Phoenix app runs on
EXPOSE 4000

# Compile assets for production
RUN mix assets.deploy

# Set the default command to run the Phoenix server
CMD ["sh", "-c", "mix ecto.setup && mix phx.server"]