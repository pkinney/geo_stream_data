defmodule GeoStreamDataTest do
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
end
