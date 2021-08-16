defmodule GeoStreamData.Utils do
  @moduledoc false

  def simple?(%Geo.LineString{coordinates: points}) do
    !(points |> to_segments() |> any_intersections?())
  end

  def simple?(%Geo.Polygon{coordinates: [points | _]}) do
    segments = points |> to_segments()

    !(segments |> Enum.drop(1) |> any_intersections?()) &&
      !(segments |> Enum.drop(-1) |> any_intersections?())
  end

  def simple?(%Geo.MultiLineString{coordinates: coords}) do
    Enum.all?(coords, fn line -> %Geo.LineString{coordinates: line} |> simple?() end)
  end

  def simple?(%Geo.MultiPolygon{coordinates: coords}) do
    Enum.all?(coords, fn line -> %Geo.Polygon{coordinates: line} |> simple?() end)
  end

  def simple?(_), do: true

  def any_intersections?([{x1, y1}, s2 | rest]) do
    Enum.any?(rest, fn {x, y} ->
      SegSeg.intersection(x1, y1, x, y) |> elem(0)
    end) || any_intersections?([s2 | rest])
  end

  def any_intersections?(_), do: false

  def to_segments([p1, p2 | rest]) do
    [{p1, p2} | to_segments([p2 | rest])]
  end

  def to_segments(_), do: []
end
