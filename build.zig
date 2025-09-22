const std = @import("std");

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});

    _ = b.addModule("root", .{
        .root_source_file = b.path("src/zaudio.zig"),
    });

    const miniaudio = b.addModule("miniaudio", .{
        .target = target,
        .optimize = optimize,
    });

    const miniaudio_lib = b.addLibrary(.{
        .name = "miniaudio",
        .root_module = miniaudio,
        .linkage = .static,
    });

    b.installArtifact(miniaudio_lib);

    miniaudio.addIncludePath(b.path("libs/miniaudio"));
    miniaudio_lib.linkLibC();

    if (target.result.os.tag == .macos) {
        if (b.lazyDependency("system_sdk", .{})) |system_sdk| {
            miniaudio_lib.addFrameworkPath(system_sdk.path("macos12/System/Library/Frameworks"));
            miniaudio_lib.addSystemIncludePath(system_sdk.path("macos12/usr/include"));
            miniaudio_lib.addLibraryPath(system_sdk.path("macos12/usr/lib"));
        }
        miniaudio_lib.linkFramework("CoreAudio");
        miniaudio_lib.linkFramework("CoreFoundation");
        miniaudio_lib.linkFramework("AudioUnit");
        miniaudio_lib.linkFramework("AudioToolbox");
    } else if (target.result.os.tag == .linux) {
        miniaudio_lib.linkSystemLibrary("pthread");
        miniaudio_lib.linkSystemLibrary("m");
        miniaudio_lib.linkSystemLibrary("dl");
    }

    miniaudio.addCSourceFile(.{
        .file = b.path("src/zaudio.c"),
        .flags = &.{"-std=c99"},
    });
    miniaudio.addCSourceFile(.{
        .file = b.path("libs/miniaudio/miniaudio.c"),
        .flags = &.{
            "-DMA_NO_WEBAUDIO",
            "-DMA_NO_NULL",
            "-DMA_NO_JACK",
            "-DMA_NO_DSOUND",
            "-DMA_NO_WINMM",
            "-std=c99",
            "-fno-sanitize=undefined",
            if (target.result.os.tag == .macos) "-DMA_NO_RUNTIME_LINKING" else "",
        },
    });

    const test_step = b.step("test", "Run zaudio tests");

    const test_module = b.addModule("test", .{
        .root_source_file = b.path("src/zaudio.zig"),
        .target = target,
        .optimize = optimize,
    });

    const tests = b.addTest(.{
        .name = "zaudio-tests",
        .root_module = test_module,
    });
    b.installArtifact(tests);

    tests.linkLibrary(miniaudio_lib);

    test_step.dependOn(&b.addRunArtifact(tests).step);
}
