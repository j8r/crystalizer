# Crystalizer

[![Build Status](https://cloud.drone.io/api/badges/j8r/crystalizer/status.svg)](https://cloud.drone.io/j8r/crystalizer)
[![ISC](https://img.shields.io/badge/License-ISC-blue.svg?style=flat-square)](https://en.wikipedia.org/wiki/ISC_license)

[De]serialize any Crystal object - out of the box. Supports JSON, YAML.

## Features

- [De]serialize anything, "out-of-the-box"
- Advanced serialization with annotations, but **not required**
- Shared annotations for all formats (JSON, YAML...)

Implementation bonus: no monkey patching involved :) (no method pollution on objects)

## Installation

Add the dependency to your `shard.yml`:

```yaml
dependencies:
  clicr:
    github: j8r/crystalizer
```

## Usage

```crystal
require "crystalizer/json"
require "crystalizer/yaml"


struct Point
  getter x : Int32
  @[Crystalizer::Field(key: "Y")]
  getter y : String

  def initialize(@x, @y)
  end
end

point = Point.new 1, "a"

{Crystalizer::YAML, Crystalizer::JSON}.each do |format|
  string = format.serialize point
  puts string
  puts format.deserialize string, to: Point
end
```

Note: annotations are similar to the stdlib's `Serializable`, but all features are yet fully implemented.

## License

Copyright (c) 2020 Julien Reichardt - ISC License
