defmodule GeoStreamDataTest do
  @moduledoc false
  use ExUnit.Case
  use ExUnitProperties

  property "generates a geometry" do
    check all geo <- GeoStreamData.geometry() do
      assert geo.__struct__ in [
               Geo.Point,
               Geo.LineString,
               Geo.Polygon,
               Geo.MultiPoint,
               Geo.MultiLineString,
               Geo.MultiPolygon
             ]
    end
  end

  property "generates a geometry in a given envelope" do
    check all env <- envelope(),
              geo <- GeoStreamData.geometry(env) do
      assert Envelope.contains?(env, Envelope.from_geo(geo))
    end
  end

  property "generates a point in a given envelope" do
    check all point <- GeoStreamData.point(%{min_x: 0, max_x: 10, min_y: -5, max_y: 15}) do
      %Geo.Point{coordinates: {x, y}} = point
      assert x >= 0 and x <= 10
      assert y >= -5 and y <= 15
    end
  end

  property "generates a simple geometry" do
    check all geo <- GeoStreamData.geometry() do
      assert GeoStreamData.Utils.simple?(geo)
    end
  end

  property "generated geometry can be converted to valid WKT" do
    check all geo <- GeoStreamData.geometry() do
      assert {:ok, wkb} = Geo.WKT.encode(geo)
      assert {:ok, geo2} = Geo.WKT.decode(wkb)
      assert geo == geo2
    end
  end

  property "generates Point geometries" do
    check all geo <- GeoStreamData.point() do
      assert geo.__struct__ == Geo.Point
    end
  end

  property "generates a valid LineString" do
    check all geo <- GeoStreamData.line_string() do
      assert geo.__struct__ == Geo.LineString
      assert length(geo.coordinates) >= 2
      assert GeoStreamData.Utils.simple?(geo)
    end
  end

  property "generates a valid Polygon" do
    check all geo <- GeoStreamData.polygon() do
      assert geo.__struct__ == Geo.Polygon
      assert length(geo.coordinates |> List.first()) >= 4
      assert GeoStreamData.Utils.simple?(geo)
    end
  end

  def envelope() do
    # {uniq_list_of(integer(-10_000..10_000), length: 2),
    #  uniq_list_of(integer(-10_000..10_000), length: 2)}
    uniq_list_of(float(min: -10_000, max: 10_000), length: 2)
    |> list_of(length: 2)
    |> bind(fn [x, y] ->
      {min_x, max_x} = Enum.min_max(x)
      {min_y, max_y} = Enum.min_max(y)

      constant(%Envelope{
        min_x: min_x,
        max_x: max_x,
        min_y: min_y,
        max_y: max_y
      })
    end)
  end
end
