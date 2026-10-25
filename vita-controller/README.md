# Vita LAN Controller POC

A small native PS Vita controller client for the Red Alert Godot game. It sends
stick and button state over UDP and displays connection status on the Vita.
This is an input/connection proof of concept; it does not render the ship
 dashboard or stream video.

## Controls

- Left stick: move
- Right stick: look
- Cross: jump
- Square or R: interact
- L: breathe
- Start: pause

The client sends input at about 30 Hz. If packets stop, the Godot bridge releases
held input after 1.5 seconds.

## Build

The build host needs VitaSDK, CMake, and the VitaSDK `libvita2d` package for its
system-font status screen. VitaSDK was not present in the workspace environment
when this project was started. Install VitaSDK and `libvita2d` using their
official setup instructions, then configure the laptop's hotspot and find its
IPv4 address on that hotspot. NetworkManager's default Linux hotspot address is
often `10.42.0.1`.

```sh
export VITASDK=/usr/local/vitasdk
export PATH="$VITASDK/bin:$PATH"
cmake -S . -B build \
  -DCMAKE_TOOLCHAIN_FILE="$VITASDK/share/vita.toolchain.cmake" \
  -DVITA_HOST_IP=10.42.0.1
cmake --build build --parallel
```

On first launch, use left/right to select an address part, up/down to adjust it,
and L/R to adjust by ten. Cross saves the laptop address on the Vita and starts
the controller. The saved address is reused on later launches, so changing
networks does not require rebuilding the VPK. Square restores the build default.
The build-time `-DVITA_HOST_IP=<address>` remains the default and is used if no
saved address exists. The game must be running on the laptop and inbound UDP
port `27300` must be allowed through its firewall. The Vita and laptop must be
connected to the same local network; internet access and school SSO are not
used by this controller protocol.

The VPK is written to `build/vita_lan_controller.vpk`. Use VitaShell's built-in
FTP to transfer it to `ux0:download/`, then select it in VitaShell to install.

## Host protocol test

The portable packet encoder and analog deadzone can be tested without VitaSDK:

```sh
cc -std=c11 -Wall -Wextra -Werror -pedantic \
  src/protocol.c tests/test_protocol.c -lm -o /tmp/vita-controller-test
/tmp/vita-controller-test
```
