ExUnit.start()

# Start the test repo
{:ok, _} = Threadline.Test.Repo.start_link()

# Run migrations on test database
Ecto.Migrator.run(Threadline.Test.Repo, :up, all: true)
