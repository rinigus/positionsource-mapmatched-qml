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


## Usage

The code is contained in a single QML file. So, copy
PositionSourceMapMatched.qml into your source tree and use it via
local import. Since its licensed under MIT license, it should be
compatible with the variuos open source and proprietary licenses.

When used in the program, if the map matching mode is enabled,
`PositionSourceMapMatched` will automatically request map matched
position and available data regarding it. If needed, it will try to
start OSM Scout Server through systemd socket activation and will
follow apperance / disappearance of the server on D-Bus. The
corresponding status is communicated via properties.

In addition to regular usage, there are facilities for the use of the
type in testing environment (feeding coordinates from outside) and
timing statistics.

See included example for usage of `PositionSourceMapMatched` and
showing available data.


## API

The exported API follows QML
[PositionSource](https://doc.qt.io/qt-5/qml-qtpositioning-positionsource.html).

The main limitations, when compared to the PositionSource, are:

* `position` property is replaced by JS Object with the same
  properties as the original. Thus, there are no methods or signals
  associated with the changes with the properties of `position` (for
  example, you cannot follow `onAltitudeValidChanged` signal of
  `position`). However, changes in `position` property are signaled,
  as usual, via on `onPositionChanged` of `PositionSourceMapMatched`.

* `signal `**`updateTimeout()`** is not propagated due to the absence
  of this signal in Sailfish QtPositioning module. Feel free to
  uncomment the corresponding code in _master_ and _gps_ sections of
  the code.

The public API is extending PositionSource via additional
properties. Below, the properties are described by their use:
production, testing, and timining.

### Properties

* `real `**`direction`** Direction of travel along the matched street
  or path. Given in degrees from true north.

* `bool `**`directionValid`** True if `direction` contains valid data

* `bool `**`mapMatchingAvailable`** True if OSM Scout Server is running
  and exposing map matching via D-Bus

* `int `**`mapMatchingMode`** Requested map matching mode. This
  follows `enum Mode` values in valhallamapmatcher.h of OSM Scout
  Server code. At present, the following modes are available (value and its
  meaning listed below):
  - 0 no map matching
  - 1 car, "auto" in Valhalla API
  - 2 car along shorter distance, "auto_shorter" in Valhalla API
  - 3 bicycle
  - 4 bus
  - 5 pedestrian
  Care will be taken to keep map matching modes backwards
  compatible and only extension of the values is planned, if
  needed.

* `string `**`streetName`** Street name of the matched Valhalla's
  edge. Can be empty due to the failed map matching or in the absence
  of the street name in OSM data.

* `real `**`streetSpeedAssumed`** Speed assumed for traveling along
    the matched Valhalla's edge. Speed is given in meters/second,
    negative in the absence of data.

* `real `**`streetSpeedLimit`** Speed limit for traveling along the
   matched Valhalla's edge. Speed is given in meters/second, negative
   in the absence of data.


### Timing statistics properties

Timing statistics allows to determine performance of map
matching. Statistics is given by average, minimum and maximum call
times. Call time is defined as a time elapsed from obtaining GPS
position change till receiving and processing the response of map
matching algorithm.

* `bool `**`timingStatsEnable`** Set to `true` to enable timing
  statistics. Statistics will be collected from the moment this
  property is set to `true`.

* `real `**`timingOverallAvr`** Average call time for map matching in
  seconds. 

* `real `**`timingOverallMax`** Maximal call time for map matching in
  seconds.

* `real `**`timingOverallMin`** Minimal call time for map matching in
  seconds.
  

### Debug properties

To simplify debugging in the absence of GPS signal, one can provide
coordinates by using **`testingCoordinate`** property. For example, as
has been done earlier for Poor Maps by @otsaloma, one can hook changes
in map center QML item to this property. As soon as
`testingCoordinate` is set, a timer will be started that will update
internal PositionSourceMapMatched with the same period as requested by
`updateInterval`. To stop such testing, set `testingCoordinate` to
`undefined`.

See included example for how to use this feature.
