import QtQuick 2.0
import QtPositioning 5.2
import Nemo.DBus 2.0

Item {
    id: master

    // Properties
    property alias active: gps.active
    property real  direction: 0
    property bool  directionValid: false
    property alias mapMatchingAvailable: scoutbus.available
    property alias mapMatchingMode: scoutbus.mode
    property alias name: gps.name
    property var   position: gps.position
    property alias preferredPositioningMethods: gps.preferredPositioningMethods
    property alias sourceError: gps.sourceError
    property string streetName: ""
    property real  streetSpeedAssumed: -1  // in m/s
    property real  streetSpeedLimit: -1    // in m/s
    property alias supportedPositioningMethods: gps.supportedPositioningMethods
    property alias updateInterval: gps.updateInterval
    property alias valid: gps.valid

    // Properties used for testing
    property var   testingCoordinate: undefined

    // Signals

    // signal is not provided by Sailfish version of PositionSource
    // signal updateTimeout()

    // Methods
    function start() {
        gps.start()
    }

    function stop() {
        gps.stop()
    }

    function update() {
        gps.update()
    }

    //////////////////////////////////////////////////////////////
    /// Implementation
    //////////////////////////////////////////////////////////////

    // provider for actual position
    PositionSource {
        id: gps
        active: true

        function positionUpdate(position) {
            if (scoutbus.available &&
                    scoutbus.mode &&
                    position.latitudeValid && position.longitudeValid &&
                    position.horizontalAccuracyValid) {
                scoutbus.mapMatch(position);
            } else {
                master.position = position;
                if (scoutbus.mode && scoutbus.running)
                    scoutbus.stop();
            }
        }

        onPositionChanged: positionUpdate(position)

        //onUpdateTimeout: master.updateTimeout()
    }

    // interaction with OSM Scout Server via D-Bus
    DBusInterface {
        id: scoutbus
        service: "org.osm.scout.server1"
        path: "/org/osm/scout/server1/mapmatching1"
        iface: "org.osm.scout.server1.mapmatching1"

        property bool available: false
        property int  mode: 0
        property bool running: false;

        Component.onCompleted: {
            checkAvailable();
        }

        function checkAvailable() {
            if (getProperty("Active")) {
                if (!available) {
                    available = true;
                    if (mode) call('Reset', mode);
                }
            } else {
                available = false
                if (mode) resetValues();
            }
        }

        function mapMatch(position) {
            if (!mode || !available) return;

            typedCall("Update",
                      [ {'type': 'i', 'value': mode},
                       {'type': 'd', 'value': position.coordinate.latitude},
                       {'type': 'd', 'value': position.coordinate.longitude},
                       {'type': 'd', 'value': position.horizontalAccuracy} ],
                      function(result) {
                          // successful call
                          var r = JSON.parse(result);
                          var position = {}
                          for (var i in gps.position) {
                              if (!(gps.position[i] instanceof Function) && i!=="coordinate")
                                  position[i] = gps.position[i]
                          }

                          var latitude = master.position.coordinate.latitude
                          var longitude = master.position.coordinate.longitude

                          if (r.latitude !== undefined) latitude = r.latitude;
                          if (r.longitude !== undefined) longitude = r.longitude;
                          position.coordinate = QtPositioning.coordinate(latitude, longitude);

                          if (r.direction!==undefined) master.direction = r.direction;
                          if (r.direction_valid!==undefined) master.directionValid = r.direction_valid;
                          if (r.street_name!==undefined) master.streetName = r.street_name;
                          if (r.street_speed_assumed!==undefined) master.streetSpeedAssumed = r.street_speed_assumed;
                          if (r.street_speed_limit!==undefined) master.streetSpeedLimit = r.street_speed_limit;

                          // always update position
                          master.position = position;
                      },
                      function(result) {
                          // error
                          scoutbus.resetValues();
                          master.position = gps.position;
                      }
                      );

            running = true;
        }

        function resetValues() {
            master.directionValid = false;
            master.streetName = ""
            master.streetSpeedAssumed = -1;
            master.streetSpeedLimit = -1;
        }

        function stop() {
            if (mode) {
                call('Stop', mode);
                if (gps.active) resetValues();
            }
            running = false;
        }

        onModeChanged: {
            if (!available) return;
            if (mode) call('Reset', mode);
        }
    }

    // monitor availibility of OSM Scout Server on D-Bus
    DBusInterface {
        // monitors availibility of the dbus service
        service: "org.freedesktop.DBus"
        path: "/org/freedesktop/DBus"
        iface: "org.freedesktop.DBus"
        signalsEnabled: true

        function nameOwnerChanged(name, old_owner, new_owner) {
            if (name === scoutbus.service)
                scoutbus.checkAvailable()
        }
    }

    // start OSM Scout Server via systemd socket activation
    // if the server is not available, but needed
    Timer {
        id: activationTimer
        interval: 5000
        repeat: true
        running: scoutbus.mode > 0 && !scoutbus.available
        onTriggered: {
            console.log('Activating OSM Scout Server');

            var xmlhttp = new XMLHttpRequest();
            xmlhttp.open("GET",
                         "http://localhost:8553/v1/activate",
                         true);
            xmlhttp.send();
        }
    }

    // support for testing
    Timer {
        id: testingTimer
        interval: gps.updateInterval
        running: false
        repeat: true
        onTriggered: {
            var p= {};
            p.coordinate = master.testingCoordinate;
            p.horizontalAccuracy = 15;
            p.latitudeValid = true;
            p.longitudeValid = true;
            p.horizontalAccuracyValid = true;
            gps.positionUpdate(p);
        }
    }

    onTestingCoordinateChanged: {
        if (!testingTimer.running) testingTimer.running = true;
    }
}
