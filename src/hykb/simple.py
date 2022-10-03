#!/usr/bin/python3

# CC0, originally written by t184256.
# This is an example Python program for Linux that remaps a keyboard.
# The events (key presses releases and repeats), are captured with evdev,
# and then injected back with uinput.

# This approach should work in X, Wayland, anywhere!

# Also it is not limited to keyboards, may be adapted to any input devices.

# The program should be easily portable to other languages or extendable to
# run really any code in 'macros', e.g., fetching and typing current weather.

# The ones eager to do it in C can take a look at (overengineered) caps2esc:
# https://github.com/oblitum/caps2esc


# Import necessary libraries.
import atexit
# You need to install evdev with a package manager or pip3.
import evdev  # (sudo pip3 install evdev)


# Define an example dictionary describing the remaps.
REMAP_TABLE = {
    # Let's swap A and B...
    evdev.ecodes.KEY_A: evdev.ecodes.KEY_B,
    evdev.ecodes.KEY_B: evdev.ecodes.KEY_A,
}
# The names can be found with evtest or in evdev docs.


# The keyboard name we will intercept the events for. Obtainable with evtest.
MATCH = 'AT Translated Set 2 keyboard'
# Find all input devices.
devices = [evdev.InputDevice(fn) for fn in evdev.list_devices()]
# Limit the list to those containing MATCH and pick the first one.
kbd = [d for d in devices if MATCH in d.name][0]
atexit.register(kbd.ungrab)  # Don't forget to ungrab the keyboard on exit!
kbd.grab()  # Grab, i.e. prevent the keyboard from emitting original events.


# Create a new keyboard mimicking the original one.
with evdev.UInput.from_device(kbd, name='kbdremap') as ui:
    for ev in kbd.read_loop():  # Read events from original keyboard.
        if ev.type == evdev.ecodes.EV_KEY  and ev.code in REMAP_TABLE:
                # Lookup the key we want to press/release instead...
                remapped_code = REMAP_TABLE[ev.code]
                # And do it.
                ui.write(evdev.ecodes.EV_KEY, remapped_code, ev.value)
        else:
            # Passthrough other events unmodified (e.g. SYNs).
            ui.write(ev.type, ev.code, ev.value)
