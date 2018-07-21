# QML PositionSource with map matching support

This is a QML type - `PositionSourceMapMatched` - that is designed to
be an extended PositionSource. In addition to regular PositionSource
functionality, it allows to determine current street name, direction
of travel along the street, current speed limit. For that, it
communicates with local [OSM Scout
Server](https://rinigus.github.io/osmscout-server) and uses map
maptching functionality of
[Valhalla](https://github.com/valhalla/valhalla).

Communication between PositionSourceMapMatched and OSM Scout Server is
implemented through DBus. Thus, to use this QML type, you would need 

* [OSM Scout Server](https://github.com/rinigus/osmscout-server)
* [Nemo QML Plugin D-Bus](https://git.merproject.org/mer-core/nemo-qml-plugin-dbus)

The maps required for map matching can be downloaded by OSM Scout
Server (GUI recommended).

While, at present, the type exposes only street name, direction, and
speed limit, it can be easily extended to provide other information
supported by Valhalla's map matching functionality. Note that it is
focused on just-in-time data, not longer stretches. 

## API

