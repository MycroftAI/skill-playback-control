/*
* Copyright 2021 by Aditya Mehra <aix.m@outlook.com>
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*    http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*
*/

import QtQuick 2.12
import QtMultimedia 5.12
import QtQuick.Controls 2.12 as Controls
import QtQuick.Templates 2.12 as T
import QtQuick.Layouts 1.3
import org.kde.kirigami 2.8 as Kirigami
import QtGraphicalEffects 1.0
import Mycroft 1.0 as Mycroft

Mycroft.CardDelegate {
    id: root
    fillWidth: true
    skillBackgroundColorOverlay: "black"
    cardBackgroundOverlayColor: "#490E33"
    cardRadius: 0

    property alias thumbnail: albumimg.source
    property int imageWidth: Kirigami.Units.gridUnit * 10

    // Track_Lengths, Durations, Positions are always in milliseconds
    // Position is always in milleseconds and relative to track_length if track_length = 530000, position values range from 0 to 530000

    property var media: sessionData.media
    property var playerDuration: media.length
    property real playerPosition: 0
    property var playerState: media.status
    property bool countdowntimerpaused: false

    function formatedDuration(millis){
        var minutes = Math.floor(millis / 60000);
        var seconds = ((millis % 60000) / 1000).toFixed(0);
        return minutes + ":" + (seconds < 10 ? '0' : '') + seconds;
    }

    function formatedPosition(millis){
        var minutes = Math.floor(millis / 60000);
        var seconds = ((millis % 60000) / 1000).toFixed(0);
        return minutes + ":" + (seconds < 10 ? '0' : '') + seconds;
    }

    Controls.ButtonGroup {
        id: autoPlayRepeatGroup
        buttons: autoPlayRepeatGroupLayout.children
    }

    onPlayerStateChanged: {
        console.log(playerState)
        if(playerState === "Playing"){
            root.playerPosition = media.position
            countdowntimer.running = true
        } else if(playerState === "Paused") {
            root.playerPosition = media.position
            countdowntimer.running = false
        }
    }

    Timer {
        id: countdowntimer
        interval: 1000
        running: false
        repeat: true
        onTriggered: {
            if(media.length > playerPosition){
                if(!countdowntimerpaused){
                    playerPosition = playerPosition + 1000
                }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: Mycroft.Units.gridUnit * 2
        color: "#490E33"

        ColumnLayout {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: bottomArea.top
            anchors.topMargin: Mycroft.Units.gridUnit * 2
            anchors.leftMargin: Mycroft.Units.gridUnit * 2
            anchors.rightMargin: Mycroft.Units.gridUnit * 2

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "transparent"

                GridLayout {
                    id: mainLayout
                    anchors.fill: parent
                    columnSpacing: 32
                    columns: 2

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.bottomMargin: 11
                        color: "white"

                        Image {
                            id: albumimg
                            visible: true
                            enabled: true
                            anchors.fill: parent
                            anchors.leftMargin: Mycroft.Units.gridUnit / 2
                            anchors.topMargin: Mycroft.Units.gridUnit / 2
                            anchors.rightMargin: Mycroft.Units.gridUnit / 2
                            anchors.bottomMargin: Mycroft.Units.gridUnit / 2
                            source: media.image
                            z: 100
                        }

                        RectangularGlow {
                            id: effect
                            anchors.fill: albumimg
                            glowRadius: 5
                            color: Qt.rgba(0, 0, 0, 0.7)
                            cornerRadius: 10
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "transparent"

                        ColumnLayout {
                            anchors.fill: parent

                            Controls.Label {
                                id: authortitle
                                text: "Bohemian Rhapsody"
                                maximumLineCount: 1
                                Layout.fillWidth: true
                                font.bold: true
                                font.pixelSize: Math.round(height * 0.765)
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                font.capitalization: Font.Capitalize
                                color: "white"
                                visible: true
                                enabled: true
                            }

                            Controls.Label {
                                id: songtitle
                                text: "Queen"
                                maximumLineCount: 1
                                Layout.fillWidth: true
                                font.pixelSize: Math.round(height * 0.805)
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                font.capitalization: Font.Capitalize
                                color: "white"
                                visible: true
                                enabled: true
                            }


                            RowLayout {
                                spacing: Kirigami.Units.largeSpacing * 3

                                Controls.Button {
                                    id: previousButton
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.alignment: Qt.AlignVCenter
                                    focus: false
                                    KeyNavigation.right: playButton
                                    KeyNavigation.down: seekableslider
                                    onClicked: {
                                        triggerGuiEvent("cps.gui.previous", {})
                                    }

                                    contentItem: Kirigami.Icon {
                                        source: Qt.resolvedUrl("images/media-skip-backward.svg")
                                        color: "white"
                                    }

                                    background: Rectangle {
                                        color: "transparent"
                                    }

                                    Keys.onReturnPressed: {
                                        clicked()
                                    }
                                }

                                Controls.Button {
                                    id: playButton
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.alignment: Qt.AlignVCenter
                                    onClicked: {
                                        if (playerState != "Playing"){
                                            triggerGuiEvent("cps.gui.play", {"media": {
                                                                    "image": media.image,
                                                                    "track": media.track,
                                                                    "album": media.album,
                                                                    "skill": media.skill,
                                                                    "length": media.length,
                                                                    "position": playerPosition,
                                                                    "status": "Playing"}})
                                        } else {
                                            triggerGuiEvent("cps.gui.pause", {"media": {
                                                                    "image": media.image,
                                                                    "title": media.title,
                                                                    "album": media.album,
                                                                    "skill_id":media.skill,
                                                                    "length": media.length,
                                                                    "position": playerPosition,
                                                                    "status": "Paused"}})
                                        }
                                    }

                                    background: Rectangle {
                                        color: "transparent"
                                    }

                                    contentItem: Kirigami.Icon {
                                        color: "white"
                                        source: playerState === "Playing" ? Qt.resolvedUrl("images/media-playback-pause.svg") : Qt.resolvedUrl("images/media-playback-start.svg")
                                    }
                                }

                                Controls.Button {
                                    id: nextButton
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.alignment: Qt.AlignVCenter
                                    onClicked: {
                                        triggerGuiEvent("cps.gui.next", {})
                                    }

                                    background: Rectangle {
                                        color: "transparent"
                                    }

                                    contentItem: Kirigami.Icon {
                                        source: Qt.resolvedUrl("images/media-skip-forward.svg")
                                        color: "white"
                                    }
                                }
                            }

                            RowLayout {
                                spacing: Kirigami.Units.largeSpacing * 3

                                Controls.Button {
                                    id: repeatButton
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.alignment: Qt.AlignVCenter
                                    focus: false
                                    KeyNavigation.right: playButton
                                    KeyNavigation.down: seekableslider
                                    onClicked: {
                                        triggerGuiEvent("cps.gui.repeat", {})
                                    }

                                    contentItem: Kirigami.Icon {
                                        source: Qt.resolvedUrl("images/media-playlist-repeat.svg")
                                        color: "white"
                                    }

                                    background: Rectangle {
                                        color: "transparent"
                                    }

                                    Keys.onReturnPressed: {
                                        clicked()
                                    }
                                }

                                Controls.Button {
                                    id: suffleButton
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.alignment: Qt.AlignVCenter
                                    onClicked: {
                                        triggerGuiEvent("cps.gui.suffle", {})
                                    }

                                    background: Rectangle {
                                        color: "transparent"
                                    }

                                    contentItem: Kirigami.Icon {
                                        source: Qt.resolvedUrl("images/media-playlist-shuffle.svg")
                                        color: "white"
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: bottomArea
            width: parent.width
            anchors.bottom: parent.bottom
            height: Mycroft.Units.gridUnit * 5
            color: "transparent"

            RowLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Mycroft.Units.gridUnit * 2
                anchors.rightMargin: Mycroft.Units.gridUnit * 2
                height: Mycroft.Units.gridUnit * 3

                Controls.Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                    font.pixelSize: height * 0.9
                    horizontalAlignment: Text.AlignLeft
                    verticalAlignment: Text.AlignVCenter
                    text: formatedPosition(playerPosition)
                    color: "white"
                }

                Controls.Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    font.pixelSize: height * 0.9
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    text: formatedDuration(playerDuration)
                    color: "white"
                }
            }

            T.Slider {
                id: seekableslider
                to: playerDuration
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: Mycroft.Units.gridUnit * 2
                property bool sync: false
                live: false
                visible: media.length !== -1 ? 1 : 0
                enabled: media.length !== -1 ? 1 : 0
                value: playerPosition

                onPressedChanged: {
                    if(seekableslider.pressed){
                        root.countdowntimerpaused = true
                    } else {
                        root.countdowntimerpaused = false
                    }
                }

                onValueChanged: {
                    if(root.countdowntimerpaused){
                        triggerGuiEvent("cps.gui.seek", {"seekValue": value})
                    }
                }

                handle: Item {
                    x: seekableslider.visualPosition * (parent.width - (Kirigami.Units.largeSpacing + Kirigami.Units.smallSpacing))
                    anchors.verticalCenter: parent.verticalCenter
                    height: Kirigami.Units.iconSizes.large

                    Rectangle {
                        id: hand
                        anchors.verticalCenter: parent.verticalCenter
                        implicitWidth: Kirigami.Units.iconSizes.small + Kirigami.Units.smallSpacing
                        implicitHeight: Kirigami.Units.iconSizes.small + Kirigami.Units.smallSpacing
                        radius: 100
                        color: seekableslider.pressed ? "#f0f0f0" : "#f6f6f6"
                        border.color: "#bdbebf"
                    }
                }

                background: Rectangle {
                    x: seekableslider.leftPadding
                    y: seekableslider.topPadding + seekableslider.availableHeight / 2 - height / 2
                    implicitHeight: 10
                    width: seekableslider.availableWidth
                    height: implicitHeight + Kirigami.Units.largeSpacing
                    radius: 10
                    color: "#bdbebf"

                    Rectangle {
                        width: seekableslider.visualPosition * parent.width
                        height: parent.height
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#21bea6" }
                            GradientStop { position: 1.0; color: "#2194be" }
                        }
                        radius: 9
                    }
                }
            }
        }
    }
}