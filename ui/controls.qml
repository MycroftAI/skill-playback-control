import QtQuick.Layouts 1.4
import QtQuick 2.4
import QtQuick.Controls 2.0
import org.kde.kirigami 2.4 as Kirigami

import Mycroft 1.0 as Mycroft
import org.kde.lottie 1.0

Mycroft.Delegate {

    ColumnLayout {
        Layout.fillWidth: true
        anchors.centerIn: parent
        LottieAnimation {
            id: record
            Layout.preferredWidth: Kirigami.Units.gridUnit * 14
            Layout.preferredHeight: Kirigami.Units.gridUnit * 14
            source: Qt.resolvedUrl("music_fly.json")
            loops: Animation.Infinite
            fillMode: Image.PreserveAspectFit
            running: true
        }
        Item {
            height: Kirigami.Units.largeSpacing * 10
        }
        RowLayout {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true

            Image {
                height: 200
                source: Qt.resolvedUrl("prev.svg")
                opacity: aprev.pressed ? 0.5 : 1.0
                MouseArea {
                    id: aprev
                    anchors.fill: parent
                    onClicked: triggerGuiEvent("prev", {})
                }
            }
            Item {
                width: Kirigami.Units.largeSpacing * 5
            }
            Image {
                height: 200
                source: Qt.resolvedUrl("pause.svg")
                opacity: apause.pressed ? 0.5 : 1.0
                MouseArea {
                    id: apause
                    anchors.fill: parent
                    onClicked: triggerGuiEvent("set", {"click": "CLICK"})
                }
            }
            Item {
                width: Kirigami.Units.largeSpacing * 5
            }
            Image {
                height: 200
                source: Qt.resolvedUrl("next.svg")
                opacity: anext.pressed ? 0.5 : 1.0
                MouseArea {
                    id: anext
                    anchors.fill: parent
                    onClicked: triggerGuiEvent("next", {})
                }
            }
        }
    }
}
