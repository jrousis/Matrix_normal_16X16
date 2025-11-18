# Matrix_normal_16X16

ESP32-based controller for daisy-chained 16?16 LED matrix modules driven by TI TLC5916/TLC5917. Provides centered and scrolling text (with Greek font support), flashing lines, and automatic brightness via a photo sensor. Communication over RS485 for remote message updates.

## Features
- Multiple 16?16 modules arranged horizontally (`MODULE_X`) and vertically (`MODULE_Y`)
- Static-scan rendering via `Rousis_Matrix16_Static` driver library
- Text rendering with fonts:
  - `SystemFont5x7_greek`, `greek_big_7x7`, `Big_font`, `Big_font_2`
- Centered text, 2-line mode, flashing lines, and smooth scrolling
- Auto-brightness using a photo sensor on ADC
- RS485 protocol to receive pages/messages and control options
- Test patterns on boot when the test pin is held low

## Hardware
- MCU: ESP32
- LED sink drivers: TI TLC5916 / TLC5917 (daisy-chain)
- Default library driver pins (`Rousis_Matrix16_Static`):
  - CLK `GPIO26`
  - LE/LATCH `GPIO14`
  - OE (active low) `GPIO27`
  - DATA `GPIO33`
- Project pins:
  - RS485: RXD2 `GPIO16`, TXD2 `GPIO17`, Direction `GPIO4` (HIGH=write, LOW=read)
  - Test button: `GPIO22` (input pull-up). Hold LOW during boot to cycle test patterns.
  - Photo sensor: `GPIO36` (ADC1) for auto brightness

Note: Adjust wiring to match your board. Pin constants are defined in `libraries/Rousis_Matrix16_Static/RousisMatrix16_Static.h` and in `Matrix_normal_16X16.ino`.

## Build and Upload
You can build with Arduino IDE, Visual Studio (Visual Micro), or PlatformIO.

- Arduino IDE
  - Install ESP32 board support
  - Board: ESP32 Dev Module
  - Ensure Bluetooth is enabled in your ESP32 core build (code checks `CONFIG_BT_ENABLED` / `CONFIG_BLUEDROID_ENABLED`)
  - Place `Rousis_Matrix16_Static` under `libraries/`
  - Open `Matrix_normal_16X16.ino` and Upload

- Visual Studio (Visual Micro)
  - Open the solution
  - Set board via __vMicro > Board__ (choose ESP32 Dev Module)
  - Build via __Build__ and upload via __vMicro > Upload__

- PlatformIO (example `platformio.ini`)
  - `board = esp32dev`
  - `framework = arduino`
  - Add the library folder under `lib/` or reference it via `lib_deps`

## Configuration
Edit the top of `Matrix_normal_16X16.ino`:
- Number of modules:
  - `#define MODULE_X 4`
  - `#define MODULE_Y 1`
- Scan mode (from library): `#define SCAN_TYPE STATIC_SCAN`
- Auto-brightness sampling:
  - `#define PHOTO_SAMPLES 60`
  - `#define PHOTO_SAMPLE_DELAY 1000`

## Quick Start (drawing text)
## Runtime Behavior
- Boot sequence:
  - Optionally cycles test patterns if `GPIO22` is held LOW
  - Shows company/device/version, then “Ready”
- Auto-brightness:
  - Samples `GPIO36`, averages `PHOTO_SAMPLES`, and calls `myLED.displayBrightness(brightness)`
- Flashing:
  - A FreeRTOS task toggles lines at ~500 ms intervals
- Scrolling:
  - Long lines scroll automatically; spacing is 1 px (single line) or 2 px (double line)
- Breakable delays:
  - Setting `myLED.stop_flag = true` cancels current page delay

## RS485 Message Protocol (summary)
- Serial: `Serial1` at 9600 8N1, RX=`GPIO16`, TX=`GPIO17`, DIR=`GPIO4`
- Session framing (high level):
  - Preamble `0xCA`, then 4 bytes header where [2..3] form payload size
  - Start-of-payload marker `0x01`, followed by page packet
- Page packet (starts with):
  - `0x55 0xAA <address|0x00> 0xA1 0x02 ...`
- Supported commands inside a page:
  - `0xE0 <bright>`: set brightness (1..16)
  - `0x01`: start page definition
    - `<delay&0x0F> <functionByte>`
    - Optional `0xD6 '0'|'1'`: select font
    - Optional `0x05 <functionByte>`: start line-2 definition
    - Text bytes until `0x00` terminator
- After a valid packet, device replies `AA 55 4F 4B 21` (`"OK!"`)

See `Matrix_normal_16X16.ino` for the exact parsing logic.

## Library
The driver resides in `libraries/Rousis_Matrix16_Static/` (`RousisMatrix16_Static.h/.cpp`) and targets TI TLC5916/5917. Key API:
- `displayEnable()/displayDisable()`
- `selectFont(fontPtr)`
- `drawString(x, y, chars, length, space)`
- `scrollingString(x, y, chars, length, space, speed)`
- `drawFilledBox(x1,y1,x2,y2, mode)`
- `writePixel(x,y,on)`
- `scanDisplay()`
- `displayBrightness(value 0..255)`
- `stop_flag` (bool) to interrupt waits

## Test Patterns
Hold the test pin (GPIO22) LOW at boot, or send instruction `0xAF` over RS485, to cycle:
- All pixels on
- Vertical stripes (even/odd)
- Horizontal stripes (even/odd)

## Project Structure
- `Matrix_normal_16X16.ino` — main sketch
- `libraries/Rousis_Matrix16_Static/` — LED matrix driver and fonts
- `fonts/` — font headers used by the sketch

## License
Add a license (e.g., MIT) in `LICENSE` before publishing.