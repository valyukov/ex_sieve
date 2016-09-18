defmodule ExSieve.Factory do
  use ExMachina.Ecto, repo: ExSieve.Repo

  def post_factory do
    %ExSieve.Post{
      title: sequence("Title #"),
      body: sequence("Post body #"),
      comments: build_pair(:comment),
      user: build(:user),
      published: true
    }
  end

  def comment_factory do
    %ExSieve.Comment{
      body: sequence("Comment body #"),
      user: build(:user)
    }
  end

  def user_factory do
    %ExSieve.User{
      name: sequence("User #")
    }
  end
end
