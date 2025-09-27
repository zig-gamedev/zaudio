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
- [x] `Decoder` (missing methods)
- [x] `Encoder` (missing methods)
- [x] `DataConverter` 

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

Now in your code you may import and use the high level API of `zaudio`:

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

Or use the low level API which is similar to the original miniaudio library, but because the callback function is bridged from the original C library, you must explicitly handle the errors at the callback level:

```zig
const zaudio = @import("zaudio");

pub fn main() !void {
  ...
  zaudio.init(std.heap.smp_allocator);
  defer zaudio.deinit();

  const decoder_config = zaudio.Decoder.Config.initDefault();
  var mp3_decoder = try zaudio.Decoder.createFromFile("testing_media/Accipiter Supersaw Demo.mp3", decoder_config);
  defer mp3_decoder.destroy();

  // device
  var device_config = zaudio.Device.Config.init(.playback);
  device_config.playback.format = zaudio.Format.float32;
  device_config.playback.channels = 2;
  device_config.sample_rate = SAMPLE_RATE;
  device_config.data_callback = data_callback; // we will fill that with actual signal source
  device_config.user_data = mp3_decoder;

  const device = zaudio.Device.create(null, device_config) catch {
      @panic("Failed to open playback device");
  };
  defer device.destroy();

  zaudio.Device.start(device) catch {
      zaudio.Device.destroy(device);
      @panic("Failed to start playback device");
  };
  ...
}

fn data_callback(device: *zaudio.Device, pOutput: ?*anyopaque, _: ?*const anyopaque, frame_count: u32) callconv(.c) void {
    const decoder_opt: ?*zaudio.Decoder = @ptrCast(device.getUserData());

    if (decoder_opt) |decoder| {
        var frames_read: u64 = 0;

        _ = try decoder.readPCMFrames(pOutput.?, frame_count) catch |err| {
            std.debug.print("ERROR: {any}", .{err});
            return;
        };

        if (frames_read < frame_count) {
            decoder.seekToPCMFrames(0) catch {
                @panic("cannot seek");
            };
        }
    } else {
        return;
    }
}

```