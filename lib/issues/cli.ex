defmodule Issues.CLI do

  @default_count 4

  def run(argv) do
    argv
      |> parse_args
      |> process
  end

  def parse_args(argv) do
    parse = OptionParser.parse(
              argv,
              switches: [help: :boolean],
              aliases:  [h: :help])
    case parse do

      { [help: true], _, _} ->  :help

      { _, [user, project, count], _} ->
        { user, project, String.to_integer(count) }

      { _, [user, project], _} ->
        { user, project, @default_count}

      _ -> :help
    end
  end

  def process(:help) do
    IO.puts """
    usage: issues <user> <project> [ count | #{@default_count} ]
    """
  end

  def process({user, project, count}) do
    Issues.GithubIssues.fetch(user, project)
    |> decode_responce
    |> convert_to_list_of_maps
    |> sort_into_ascending_order
    |> Enum.take(count)
    |> Issues.TableFormatter.print_table_for_columns(["number", "created_at", "title"])
  end

  def decode_responce({:ok, body}) do
    body
  end

  def decode_responce({:error, error}) do
    {_, message} = List.keyfind(error, "message", 0)
    IO.puts "Error fetching form Github: #{message}"
    System.halt(2)
  end

  def convert_to_list_of_maps(list) do
    list
    |> Enum.map(&Enum.into(&1, Map.new))
  end

  def sort_into_ascending_order(list_of_issues) do
    Enum.sort list_of_issues,
              fn i1, i2 -> i1["created_at"] <= i2["created_at"] end
  end

end
