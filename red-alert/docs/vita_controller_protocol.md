# Vita Controller Protocol

Godot hosts a UDP endpoint on port `27300`. The Vita app and game must be on the
same reachable network. Send UTF-8 JSON datagrams to the game host; telemetry
is sent back to the source IP and port of the most recent datagram. The game
expires the connection and releases held controls after 1.5 seconds without a
packet.

Send a keepalive to connect:

```json
{"type":"hello","protocol":1}
```

Send input continuously (about 20-30 times per second). Stick values are
normalized floats from `-1.0` to `1.0`; buttons are the currently held Vita
button names. Omit released buttons.

```json
{"type":"input","axes":{"left_x":0.0,"left_y":0.0,"right_x":0.0,"right_y":0.0},"buttons":["cross"]}
```

Button mapping: `cross` jumps, `square` or `r` interacts, `l` holds breathe,
and `start` pauses. Stick mappings follow screen coordinates: negative left Y
moves forward and negative right Y looks up.

The game replies with a `telemetry` packet up to four times per second:

```json
{"type":"telemetry","protocol":1,"connected":true,"ship":{"status":"NOMINAL","shift_seconds_left":300,"fixes":0,"alert_id":"","alert":"","alert_seconds_left":0},"readings":{"oxygen_percent":100,"co2_scrubber_percent":100,"power_percent":100,"core_temperature_percent":0,"coolant_temperature_c":18}}
```

The percentages come from the live game simulation. `coolant_temperature_c`
is a placeholder display value derived from the simulated reactor heat, not a
physical temperature model. Unknown packet types are ignored. The bridge binds
to all local interfaces; allow inbound UDP port `27300` through the host firewall
when connecting from the Vita.