# [zaudio](https://github.com/zig-gamedev/zaudio)

Zig build package and wrapper for [miniaudio](https://github.com/mackron/miniaudio) v0.11.22

As an example program please see [audio experiments (wgpu)](https://github.com/michal-z/zig-gamedev/tree/main/samples/audio_experiments_wgpu).

## Features

Provided structs:

- [x] `Device`
- [x] `Engine`
- [x] `Sound`
- [x] `SoundGroup`
- [x] `NodeGraph`
- [x] `Fence`
- [ ] `Context` (missing methods)
- [ ] `ResourceManager` (missing methods)
- [ ] `Log` (missing methods)
- [x] `DataSource` (missing methods)
  - [x] `Waveform`
  - [x] `Noise`
  - [x] custom data sources
- [x] `Node`
  - [x] `DataSourceNode`
  - [x] `SplitterNode`
  - [x] `BiquadNode`
  - [x] `LpfNode // Low-Pass Filter`
  - [x] `HpfNode // High-Pass Filter`
  - [x] `NotchNode`
  - [x] `PeakNode`
  - [x] `LoshelfNode // Low Shelf Filter`
  - [x] `HishelfNode // High Shelf Filter`
  - [x] `DelayNode`
  - [x] custom nodes

## Getting started

In your `build.zig` add:

```zig
pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{ ... });

    const zaudio = b.dependency("zaudio", .{});
    exe.root_module.addImport("zaudio", zaudio.module("root"));
    exe.linkLibrary(zaudio.artifact("miniaudio"));
}
```

Now in your code you may import and use `zaudio`:

```zig
const zaudio = @import("zaudio");

pub fn main() !void {
    ...
    zaudio.init(allocator);
    defer zaudio.deinit();

    const engine = try zaudio.Engine.create(null);
    defer engine.destroy();

    const music = try engine.createSoundFromFile(
        content_dir ++ "Broke For Free - Night Owl.mp3",
        .{ .flags = .{ .stream = true } },
    );
    defer music.destroy();
    try music.start();
    ...
}
```
