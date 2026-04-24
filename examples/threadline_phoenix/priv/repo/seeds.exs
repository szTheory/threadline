# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     ThreadlinePhoenix.Repo.insert!(%ThreadlinePhoenix.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias ThreadlinePhoenix.{Post, Repo}

%Post{}
|> Post.changeset(%{title: "Synthetic note A", slug: "synthetic-note-a"})
|> Repo.insert!()

%Post{}
|> Post.changeset(%{title: "Synthetic note B", slug: "synthetic-note-b"})
|> Repo.insert!()
