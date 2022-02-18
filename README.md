# GeoStreamData


![Build Status](https://github.com/pkinney/geo_stream_data/actions/workflows/ci.yaml/badge.svg)
[![Hex.pm](https://img.shields.io/hexpm/v/geo_stream_data.svg)](https://hex.pm/packages/geo_stream_data)

`GeoStreamData` is a library for generating geospatial data for property testing.  

You can learn more about how to use `StreamData` and `ExUnitProperties` [here](https://github.com/whatyouhide/stream_data).

## Installation

```elixir
def deps do
  [
    {:geo_stream_data, "~> 0.2"}
  ]
end
```

## Usage

Most generally, there is a `geometry()` function that returns a stream of geometries
of multiple types. LineStrings and Polygons that are generated are (mostly) guaranteed
to be simple (having no non-consecutive line segments that intersect).

```elixir
defmodule Envelope.PropertyTest do
  use ExUnit.Case
  use ExUnitProperties

  property "Two geometries are disjoint if their envelopes are disjoint" do
    check all geo1 <- GeoStreamData.geometry(),
              geo2 <- GeoStreamData.geometry(),
              env1 = Envelope.from_geo(geo1),
              env2 = Envelope.from_geo(geo2) do
      if !Envelope.intersects?(env1, env2) do
        assert Topo.disjoint?(geo1, geo2)
      end
    end
  end
end
```

There are also individual functions for generating streams of each type of geometry exclusively:

* `point()` - `Geo.Point`
* `line_string()` - `Geo.LineString`
* `polygon()` - `Geo.Polygon`
* `multi_point()` - `Geo.MultiPoint`
* `multi_line_string()` - `Geo.MultiLineString`
* `multi_polygon()` - `Geo.MultiPolygon`

```elixir
property "A LineString contains a subset of its points" do
  check all line1 <- GeoStreamData.line_string(),
            a <- integer(0..(length(line1.coordinates) - 3)),
            b <- integer(2..(length(line1.coordinates) - a)) do
    line2 = %Geo.LineString{coordinates: Enum.slice(line1.coordinates, a..(a + b))}
    assert Topo.contains?(line1, line2)
  end
end
```

And each can be passed a map representing an envelope within which the generated geometries should be contained:

```elixir
property "generates a point in a given envelope" do
  check all point <- GeoStreamData.point(%{min_x: 0, max_x: 10, min_y: -5, max_y: 15}) do
    %Geo.Point{coordinates: {x, y}} = point
    assert x >= 0 and x <= 10
    assert y >= -5 and y <= 15
  end
end
```
