# hex2bin
A small tool for converting hex file into bin files, coding by zig.

## build

```
zig build-exe hex2bin.zig -O ReleaseSmall
```

## Usage

```
$ > ./hex2bin xxx.hex
```

## Example

```
$ > ./hex2bin rtthread.hex
=> rtthread_0x10000.bin
=> rtthread_0x100a150.bin
```

