import QtQuick.Layouts 1.4
import QtQuick 2.4
import QtQuick.Controls 2.0
import org.kde.kirigami 2.4 as Kirigami

import Mycroft 1.0 as Mycroft


Mycroft.Delegate {
    id: root
    property var album_img: sessionData.image
    ColumnLayout {
        spacing: 2
        anchors.centerIn: parent
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter


        Image {
            Layout.alignment: Qt.AlignHCenter
            id: img
            source: Qt.resolvedUrl(root.album_img)
            Layout.preferredWidth: 300
            Layout.preferredHeight: 350
            fillMode: Image.PreserveAspectFit
        }
        Kirigami.Label {
            id: artist
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            font.family: "Noto Sans"
            font.bold: true
            font.weight: Font.Bold
            font.pixelSize: 30
            text: sessionData.artist
        }
        Mycroft.AutoFitLabel {
            id: track
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 150
            Layout.preferredWidth:parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            font.family: "Noto Sans"
            color: "#22a7f0"
            font.pixelSize: 30
            rightPadding: -font.pixelSize * 0.1
            text: sessionData.track
        }
        RowLayout {
            id: grid
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter | Qt.AlignBottom

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
