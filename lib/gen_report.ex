defmodule GenReport do
  alias GenReport.Parser

  @names [
    "Daniele",
    "Mayk",
    "Giuliano",
    "Cleiton",
    "Jakeliny",
    "Joseph",
    "Diego",
    "Danilo",
    "Rafael",
    "Vinicius"
  ]

  @mounths %{
    "1" => "janeiro",
    "2" => "fevereiro",
    "3" => "março",
    "4" => "abril",
    "5" => "maio",
    "6" => "junho",
    "7" => "julho",
    "8" => "agosto",
    "9" => "setembro",
    "10" => "outubro",
    "11" => "novembro",
    "12" => "dezembro"
  }

  @years [2018, 2019, 2016, 2017, 2020]

  def build("") do
    {:error, "Insira o nome de um arquivo"}
  end

  def build() do
    {:error, "Insira o nome de um arquivo"}
  end

  def build(nil) do
    {:error, "Insira o nome de um arquivo"}
  end

  def build(filename) do
    all_hours =
      Parser.parse_file(filename)
      |> all_hours()

    hours_per_month =
      Parser.parse_file(filename)
      |> hours_per_mounth()

    hours_per_year =
      Parser.parse_file(filename)
      |> hours_per_year()

    %{
      "all_hours" => all_hours,
      "hours_per_month" => hours_per_month,
      "hours_per_year" => hours_per_year
    }
  end

  def build_from_many(filenames) do
    filenames
    |> Task.async_stream(&build/1)
    |> Enum.reduce(report_acc(), fn {:ok, result}, report -> sum_reports(report, result) end)
  end

  defp sum_reports(report, result) do
    Map.merge(report, result, fn _k, value1, value2 ->
      if is_map(value1) do
        sum_reports(value1, value2)
      else
        value1 + value2
      end
    end)
  end

  defp report_acc() do
    %{
      "all_hours" => names_acc(),
      "hours_per_month" => name_month_acc(),
      "hours_per_year" => year_name_acc()
    }
  end

  defp all_hours(report_stream) do
    report_stream
    |> Enum.reduce(names_acc(), fn line, report -> sum_hours_by_name(line, report) end)
  end

  defp hours_per_mounth(report_stream) do
    report_stream
    |> Enum.reduce(name_month_acc(), fn line, report ->
      sum_hours_by_name_and_month(line, report)
    end)
  end

  defp hours_per_year(report_stream) do
    report_stream
    |> Enum.reduce(year_name_acc(), fn line, report ->
      sum_hours_by_year_and_name(line, report)
    end)
  end

  defp sum_hours_by_name([name, hours, _day, _mounth, _year], report) do
    map_index = String.downcase(name)
    Map.put(report, map_index, report[map_index] + hours)
  end

  defp sum_hours_by_name_and_month([name, hours, _day, month, _year], report) do
    months = report[name]
    months = Map.put(months, month, months[month] + hours)
    Map.put(report, name, months)
  end

  defp sum_hours_by_year_and_name([name, hours, _day, _month, year], report) do
    years = report[name]
    years = Map.put(years, year, years[year] + hours)
    Map.put(report, name, years)
  end

  def names_acc() do
    @names
    |> Enum.map(&String.downcase/1)
    |> Enum.into(%{}, &{&1, 0})
  end

  def name_month_acc() do
    @names
    |> Enum.into(%{}, &{String.downcase(&1), months_acc()})
  end

  defp months_acc() do
    @mounths
    |> Map.values()
    |> Enum.into(%{}, &{&1, 0})
  end

  def year_name_acc() do
    @names
    |> Enum.into(%{}, &{String.downcase(&1), year_acc()})
  end

  def year_acc() do
    @years
    |> Enum.into(%{}, &{&1, 0})
  end
end
