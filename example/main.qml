import QtQuick 2.9
import QtQuick.Window 2.2

import QtPositioning 5.9
import QtLocation 5.9
import "."

Window {
    visible: true
    width: 980
    height: 240
    title: qsTr("Simple Map")

    Map {
        anchors.fill: parent
        plugin: Plugin {
            name: "mapboxgl"
            PluginParameter {
                name: "mapboxgl.mapping.additional_style_urls"
                value: "http://localhost:8553/v1/mbgl/style?style=osmbright"
            }
        }

        center: QtPositioning.coordinate(59.437, 24.754) // Tallinn
        zoomLevel: 14

        //        bearing: {
        //            if (pos.directionValid) return pos.direction;
        //            return 0;
        //        }

        MapCircle {
            id: positionCircle
            center {
                latitude: 59.437
                longitude: 24.754
            }

            radius: 15.0
            color: 'red'
            border.width: 3
        }

        MapCircle {
            id: positionCenter
            center:parent.center

            radius: 10.0
            color: 'green'
            border.width: 3
        }

        onCenterChanged: {
            pos.testingCoordinate = center
        }
    }

    PositionSourceMapMatched {
        id: pos
        mapMatchingMode: 1
        timingStatsEnable: true
        onPositionChanged: positionCircle.center = pos.position.coordinate
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 10
        color: "white"
        height: txt.height + 10
        width: txt.width + 10
        Text {
            id: txt
            anchors.centerIn: parent
            text: {
                var s = 'Street: ' + pos.streetName
                s += "\nSpeed limit: " + Math.round(pos.streetSpeedLimit*3.6) + ' km/h'
                s += "\nSpeed assumed: " + Math.round(pos.streetSpeedAssumed*3.6) + ' km/h'
                s += "\nDirection: " + (pos.direction).toFixed(1)
                s += "\nDirection valid: " + pos.directionValid
                s += "\n"
                s += "Timing:\n"
                s += "Average: " + (pos.timingOverallAvr*1e3).toFixed(1) + " ms\n"
                s += "Min: " + (pos.timingOverallMin*1e3).toFixed(1) + " ms\n"
                s += "Max: " + (pos.timingOverallMax*1e3).toFixed(1) + " ms\n"
                return s;
            }
        }
    }
}
