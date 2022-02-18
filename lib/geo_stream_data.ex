defmodule GeoStreamData do
  @moduledoc """
  A generator for property-based testing of geospatial data.


  """

  # use ExUnitProperties

  @type envelope() :: %{min_x: number(), max_x: number(), min_y: number(), max_y: number()}

  @type geometry_type() ::
          Geo.Point.t()
          | Geo.LineString.t()
          | Geo.Polygon.t()
          | Geo.MultiPoint.t()
          | Geo.MultiLineString.t()
          | Geo.MultiPolygon.t()

  @geometry_types ~w(point line_string polygon multi_point multi_line_string multi_polygon)a
  @default_env %{min_x: -180, max_x: 180, min_y: -90, max_y: 90}

  @spec geometry(envelope()) :: StreamData.t(geometry_type())
  def geometry(env \\ @default_env) do
    StreamData.bind(StreamData.member_of(@geometry_types), fn
      :point -> point(env)
      :line_string -> line_string(env)
      :polygon -> polygon(env)
      :multi_point -> multi_point(env)
      :multi_line_string -> multi_line_string(env)
      :multi_polygon -> multi_polygon(env)
    end)
  end

  @spec point_tuple(envelope()) :: StreamData.t({number(), number()})
  def point_tuple(env \\ @default_env) do
    StreamData.bind(StreamData.float(min: env.min_x, max: env.max_x), fn x ->
      StreamData.bind(StreamData.float(min: env.min_y, max: env.max_y), fn y ->
        StreamData.constant({x, y} |> enforce_env(env))
      end)
    end)
  end

  @spec point(envelope()) :: StreamData.t(Geo.Point.t())
  def point(env \\ @default_env) do
    StreamData.bind(point_tuple(env), fn point ->
      %Geo.Point{coordinates: point} |> StreamData.constant()
    end)
  end

  @spec line_string(envelope()) :: StreamData.t(Geo.LineString.t())
  def line_string(env \\ @default_env) do
    StreamData.uniq_list_of(point_tuple(env), min_length: 3)
    |> StreamData.bind_filter(fn points ->
      sorted = points |> sort_radially() |> shift_random() |> reverse_sometimes()

      line_string = %Geo.LineString{coordinates: sorted}

      if __MODULE__.Utils.simple?(line_string) do
        {:cont, StreamData.constant(line_string)}
      else
        :skip
      end
    end)
  end

  @spec polygon(envelope()) :: StreamData.t(Geo.Polygon.t())
  def polygon(env \\ @default_env) do
    StreamData.uniq_list_of(point_tuple(env), min_length: 3)
    |> StreamData.bind_filter(fn points ->
      sorted = points |> sort_radially() |> shift_random()

      polygon = %Geo.Polygon{coordinates: [sorted ++ Enum.take(sorted, 1)]}

      if __MODULE__.Utils.simple?(polygon) do
        {:cont, StreamData.constant(polygon)}
      else
        :skip
      end
    end)
  end

  @spec multi_point(envelope()) :: StreamData.t(Geo.MultiPoint.t())
  def multi_point(env \\ @default_env) do
    StreamData.list_of(point_tuple(env), min_length: 1)
    |> StreamData.bind(fn points ->
      %Geo.MultiPoint{coordinates: points}
      |> StreamData.constant()
    end)
  end

  @spec multi_line_string(envelope()) :: StreamData.t(Geo.MultiLineString.t())
  def multi_line_string(env \\ @default_env) do
    StreamData.list_of(line_string(env), min_length: 1)
    |> StreamData.bind(fn line_strings ->
      %Geo.MultiLineString{coordinates: Enum.map(line_strings, & &1.coordinates)}
      |> StreamData.constant()
    end)
  end

  @spec multi_polygon(envelope()) :: StreamData.t(Geo.MultiPolygon.t())
  def multi_polygon(env \\ @default_env) do
    StreamData.list_of(polygon(env), min_length: 1)
    |> StreamData.bind(fn polygons ->
      %Geo.MultiPolygon{coordinates: Enum.map(polygons, & &1.coordinates)}
      |> StreamData.constant()
    end)
  end

  defp sort_radially(points) do
    {min_x, max_x} = Enum.map(points, &elem(&1, 0)) |> Enum.min_max()
    {min_y, max_y} = Enum.map(points, &elem(&1, 1)) |> Enum.min_max()

    center = {(min_x + max_x) / 2, (min_y + max_y) / 2}
    points |> Enum.sort_by(&angle(&1, center))
  end

  defp angle({x, y}, {cx, cy}), do: {do_angle(cx - x, cy - y), cy - y}

  defp do_angle(dx, dy) when dx == 0 and dy < 0, do: 3 * :math.pi() / 2.0
  defp do_angle(dx, _) when dx == 0, do: :math.pi() / 2.0
  defp do_angle(dx, dy) when dy == 0 and dx < 0, do: :math.pi()
  defp do_angle(_, dy) when dy == 0, do: 0.0

  defp do_angle(dx, dy) when dx < 0, do: :math.pi() + :math.atan(dy / dx)
  defp do_angle(dx, dy), do: :math.atan(dy / dx)

  defp reverse_sometimes(points) do
    if :rand.uniform() > 0.5 do
      points
    else
      points |> Enum.reverse()
    end
  end

  defp shift_random(points) do
    points
    |> Enum.split(:rand.uniform(length(points)))
    |> Tuple.to_list()
    |> Enum.reverse()
    |> List.flatten()
  end

  # Occasionally, StreamData's float generator generates a float that is outside of the min/max
  # provide due to rounding differences.  This just ensures that the points generated stay inside
  # the given envelope.
  defp enforce_env({x, y}, env) do
    {x |> min(env.max_x) |> max(env.min_x), y |> min(env.max_y) |> max(env.min_y)}
  end
end
