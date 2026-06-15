# Alphanumeric Typing Balloons Game (16-Bit x86 Assembly)

A real-time, low-level arcade typing game engineered from the ground up in 16-bit x86 Intel Assembly language targeting the MS-DOS platform. Operating strictly within Real Mode, this software bypasses standard high-level OS abstractions to execute custom asynchronous Interrupt Service Routines (ISRs), drive bare-metal hardware ports, handle direct Video RAM (VRAM) cell transformations, and program hardware timers to generate audio themes.

---

##  Core System Features

* **Asynchronous Multi-Interrupt Engine:** Bypasses blocking BIOS/DOS polling loops by intercepting the Hardware Timer (`INT 08h`) and Keyboard (`INT 09h`) vectors to decouple background processing from frame loops.
* **Direct Color Text-Mode VRAM Matrix (`0xB800`):** Updates characters and cellular color attribute masks simultaneously by mapping byte writes directly into video segment memory `0xB800:0000`.
* **Dynamic Multi-Entity Scheduler:** Manages up to 5 concurrent alphanumeric balloons floating up independently with randomized horizontal offsets ($5 \le X \le 70$), customized speed factors, and unique character data symbols.
* **Bare-Metal PC Speaker Synthesizer:** Features an integrated multi-note background score step-sequencer and discrete interactive collision/pop frequency shifts. It achieves this by configuring the 8253/8254 Programmable Interval Timer (PIT) and gating the 8255 PPI chip.
* **Real-Time Match Validation Engine:** Implements case-insensitive input screening, instantly resolving hardware make-codes against active on-screen targets without losing processing cycles.
* **Dynamic Palette Inversion System:** Employs an on-the-fly thematic display inversion utility triggered by the `INSERT` hardware scan-code, recalculating structural cell color boundaries across active components seamlessly.
* **State-Driven Menu Architecture:** Features separate states for a Start Splash screen, Configuration/Difficulty Selection Menu, Real-time Dashboard HUD, Inline Game-Pause Overlays, and a terminal Game Over Performance Report.

---

##  Control Mapping Matrix

| Key | Binding Type | Functional System Behavior |
| :--- | :--- | :--- |
| **Alphanumeric (`A-Z`, `a-z`, `0-9`)** | Standard ASCII Input | Validated against target registers of active entities to clear matching items. |
| **SPACEBAR** | Mode/State Trigger | Acts as a menu action key or halts frame progression during a live simulation loop. |
| **ESCAPE (`ESC`)** | Abort Vector | Immediately breaks out of active game loops, unhooks handlers, and safely drops back to the DOS prompt. |
| **BACKSPACE** | Audio Gating Toggle | Manually toggles the background audio step-sequencer `ON` or `OFF` during active gameplay. |
| **INSERT (`INS`)** | Canvas Theme Toggle | Automatically shifts display matrices between High-Contrast Light and Dark Mode templates. |
| **`1` & `2`** | Velocity Scaling Matrix | Tailors bit-masks inside frame-counters to select Easy or Hard speed profiles. |
| **`R` / `r`** | State Reinitialization | Wipes tracking variables and metrics, restarting execution from the Game Over frame. |

---

##  Low-Level Code Architecture Breakdown

### 1. Engine Initialization & Vector Interception
The application uses a unified segment `.COM` architecture starting at `[org 0x0100]`. During initialization, the engine calls DOS Interrupt `INT 21h` (with function `AH = 0x35`) to lookup and store the original segment and offset pointers for the system clock (`INT 08h`) and keyboard peripheral (`INT 09h`) into dedicated double-word variables (`old_timer_int`, `old_keyboard_int`). It then safely overrides the Interrupt Vector Table (IVT) with its custom ISR routines via function `AH = 0x25`.

### 2. Low-Level Keyboard Handler Subsystem (`INT 09h`)
The custom `keyboard_interrupt` routine acts as an independent event listener. When a key is pressed, it interacts with hardware ports directly:
* Reads raw scan codes directly from the keyboard controller via **I/O Port `0x60`**.
* Examines the most significant bit (MSB) to screen out key-release break codes.
* References an embedded translation matrix (`scan_codes`) to map raw scan values to ASCII characters.
* Asynchronously sets system flag indicators (`esc_pressed`, `backspace_pressed`, `ins_pressed`) without locking execution.
* Signals the Master Programmable Interrupt Controller (PIC) by outputting an End-Of-Interrupt (EOI) command control byte (`0x20`) over **I/O Port `0x20`** before executing `iret`.

### 3. Asynchronous Clock Scheduler (`INT 08h`)
System clock ticks route directly into the custom `timer_interrupt` handler. 
* It checks sub-ticks against a tracking variable (`tick_counter`). Once 18 cycles accumulate (~1 second), it decrements the total game match counter (`game_time`).
* It maintains an audio division counter (`music_tempo_counter`) that moves forward through background melody array indices at precise sub-tick intervals. This keeps audio playback in sync without using standard CPU delay loops.

### 4. Text-Mode Render System (`0xB800`)
Visuals completely bypass slow console print functions. Instead, the engine sets up structural matrix calculations targeted directly at the standard color text segment address **`0xB800:0000`**:
* **Balloons:** Rendered as 5x5 layout configurations utilizing custom ASCII high-bit block elements like `0xDB` (█), `0xDF` (▀), and `0xDC` (▄).
* **Strings:** Suspended below the balloon base using vertical pipes (`0xB3`, │) spanning two rows.
* **Dynamic Palette Shifts:** Modifying background colors triggers memory array updates across the system. The `update_colors` and `toggle_dark_mode` subroutines automatically rewrite VRAM cell attributes to invert themes seamlessly.

### 5. Multi-Channel Hardware Sound Synth
The audio engine drives square-wave tones by sending values straight to the Programmable Interval Timer (PIT) hardware registers:
1. Sets up the configuration sequence by outputting control word mode byte `0xB6` to the command register via **Port `0x43`**.
2. Splits and pipes note frequency divisor steps across **Port `0x42`** (Channel 2 PIT register).
3. Enables and gates the PC Speaker amplifier circuit by toggling bits on and off through the Peripheral Interface Adapter (PPI) via **Port `0x61`**.
4. Balloon pops run through the `play_pop_sound` routine, which temporarily shifts sound synthesis frequencies between high and low bands to create a clean explosion sound effect.

### 6. Algorithmic Asset Generation (PRNG)
Entity tracking relies on a Linear Congruential Generator (LCG) routine (`get_random`). This routine uses custom mathematical scaling factors (`mul dx` with multiplier `0x8405`) to update a `random_seed` variable. The resulting randomized values are used to compute random column spawn points ($5 \le X \le 70$) and choose letters from a 62-character target array ($A-Z, a-z, 0-9$).

---




##  Compilation & Emulation Guide

To compile and run this project, you need the Netwide Assembler (NASM) along with an environment that emulates 16-bit real-mode, such as DOSBox.

### 1. Build Compilation
Assemble the flat source code into a standard 16-bit `.COM` executable binary using NASM:
```bash
nasm -f bin Phase2.asm -o bubbles.com











