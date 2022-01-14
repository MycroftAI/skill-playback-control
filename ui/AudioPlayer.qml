/*
 * Copyright 2019 by Aditya Mehra <aix.m@outlook.com>
 * Copyright 2019 by Marco Martin <mart@kde.org>
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
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12
import QtMultimedia 5.12
import QtGraphicalEffects 1.0
import QtQuick.Templates 2.12 as T
import QtQuick.Controls 2.12 as Controls
import org.kde.kirigami 2.11 as Kirigami
import Mycroft 1.0 as Mycroft

Mycroft.CardDelegate {
    id: root

    fillWidth: true
    skillBackgroundColorOverlay: "black"
    cardBackgroundOverlayColor: "black"
    cardRadius: 10

    readonly property var audioService: Mycroft.MediaService

    property var source
    property string status: "stop"
    property var thumbnail
    property var title
    property var author
    property var playerMeta
    property var cpsMeta

    //Player Support Vertical / Horizontal Layouts
    property int switchWidth: Kirigami.Units.gridUnit * 22
    readonly property bool horizontal: width > switchWidth

    //Individual Components Visibility Properties
    property bool progressBar: true
    property bool thumbnailVisible: true
    property bool titleVisible: true

    //Player Button Control Actions
    property var nextAction: "mediaservice.gui.requested.next"
    property var previousAction: "mediaservice.gui.requested.previous"
    property var currentState: audioService.playbackState

    //Mediaplayer Related Properties To Be Set By Probe MediaPlayer
    property var playerDuration
    property var playerPosition

    //Spectrum Related Properties
    property var spectrum: [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    property var soundModelLength: audioService.spectrum.length
    property color spectrumColorNormal: Qt.rgba(1, 1, 1, 0.5)
    property color spectrumColorMid: spectrumColorNormal
    property color spectrumColorPeak: Qt.rgba(1, 0, 0, 0.5)
    property real spectrumScale: 1
    property bool spectrumVisible: true
    readonly property real spectrumHeight: (rep.parent.height / normalize(spectrumScale))

    onSourceChanged: {
        console.log(source)
        play()
    }

     Timer {
        id: sampler
        running: true
        interval: 100
        repeat: true
        onTriggered: {
            spectrum = audioService.spectrum
        }
    }

    onActiveFocusChanged: {
        if(activeFocus){
            playButton.forceActiveFocus();
        }
    }

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

    function normalize(e){
        switch(e){case.1:return 10;case.2:return 9;case.3:return 8;
        case.4:return 7;case.5:return 6;case.6:return 5;case.7:return 4;case.8:return 3;
        case.9:return 2;case 1:return 1; default: return 1}
    }

    function play(){
        audioService.playURL(source)
    }

    function pause(){
        audioService.playerPause()
    }

    function stop(){
        audioService.playerStop()
    }

    function resume(){
        audioService.playerContinue()
    }

    function seek(val){
        audioService.playerSeek(val)
    }

    function fetchMetaTitleFromFile() {
        var playerMeta = audioService.getPlayerMeta()
        var title = playerMeta.Title
        if(title !== "" || title !== " ") {
            root.title = root.playerMeta.Title
        }
    }

    function fetchMetaAuthorFromFile() {
        var playerMeta = audioService.getPlayerMeta()
        if(playerMeta.hasOwnProperty("Artist")) {
            var artist = root.playerMeta.Artist
            if(artist !== "" || artist !== " ") {
                root.author = root.playerMeta.Artist
            }
        } else if(playerMeta.hasOwnProperty("ContributingArtist")) {
            var contrib_artist = root.playerMeta.ContributingArtist
            if(contrib_artist !== "" || contrib_artist !== " ") {
                root.author = contrib_artist
            }
        } else {
            root.author = ""
        }
    }

    function get_marquee_distance(text, width){
        var multiplier = 2
        var split_title_by_num = text.split(" ").length
        if(split_title_by_num > 2) {
            var multiplier = 2 + 1 + (split_title_by_num / 10) //padding
        }
        var def_distance = width * multiplier
        console.log("Default Distance")
        console.log(def_distance)

        return def_distance
    }

    Connections {
        target: Mycroft.MediaService

        onDurationChanged: {
            playerDuration = dur
        }
        onPositionChanged: {
            playerPosition = pos
        }
        onPlayRequested: {
            source = audioService.getTrack()
        }

        onStopRequested: {
            source = ""
        }

        onMediaStatusChanged: {
            console.log(status)
        }

        onMetaUpdated: {
            root.playerMeta = audioService.getPlayerMeta()
        }

        onMetaReceived: {
            root.cpsMeta = audioService.getCPSMeta()
            root.thumbnail = root.cpsMeta.thumbnail
            root.title = root.cpsMeta.title
            root.author = root.cpsMeta.artist

            // If CPS Title or Author is missing try fetch it from qmultimedia metainfo
            if (!root.title && root.playerMeta) {
                console.log("Should not be here")
                fetchMetaTitleFromFile()
            }

            if (!root.author && root.playerMeta) {
                console.log("Should not be here 2")
                fetchMetaAuthorFromFile()
            }
        }
    }
    
    ColumnLayout {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bottomArea.top
        anchors.topMargin: Mycroft.Units.gridUnit * 2
        anchors.leftMargin: Mycroft.Units.gridUnit * 2
        anchors.rightMargin: Mycroft.Units.gridUnit * 2
        z: 2

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
                    color: "transparent"

                    Image {
                        id: albumimg
                        visible: root.thumbnail != "" ? 1 : 0
                        enabled: root.thumbnail != "" ? 1 : 0
                        anchors.fill: parent
                        anchors.leftMargin: Mycroft.Units.gridUnit / 2
                        anchors.topMargin: Mycroft.Units.gridUnit / 2
                        anchors.rightMargin: Mycroft.Units.gridUnit / 2
                        anchors.bottomMargin: Mycroft.Units.gridUnit / 2
                        source: root.thumbnail
                        z: 100
                    }

                    RectangularGlow {
                        id: effect
                        anchors.fill: albumimg
                        visible: root.thumbnail != "" ? 1 : 0
                        enabled: root.thumbnail != "" ? 1 : 0
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

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Mycroft.Units.gridUnit * 3
                            clip: true
                            color: "transparent"

                            Mycroft.MarqueeText {
                                id: songtitle
                                anchors.verticalCenter: parent.verticalCenter
                                width: root.width
                                text: root.title + " "
                                font.bold: true
                                font.pixelSize: parent.height * 0.7
                                font.capitalization: Font.Capitalize
                                color: "white"
                                visible: true
                                enabled: true
                                rightToLeft: true
                                distance: get_marquee_distance(root.title, parent.width)

                                onDistanceChanged: {
                                    reset()
                                }
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Mycroft.Units.gridUnit * 3
                            clip: true
                            color: "transparent"

                            Mycroft.MarqueeText {
                                id: authortitle
                                anchors.verticalCenter: parent.verticalCenter
                                width: root.width
                                text: root.author + " "
                                font.capitalization: Font.Capitalize
                                font.pixelSize: parent.height * 0.9
                                font.bold: true
                                color: "white"
                                visible: true
                                enabled: true
                                rightToLeft: true
                                delay: 4300
                                distance: get_marquee_distance(root.author, parent.width)

                                onDistanceChanged: {
                                    reset()
                                }
                            }
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
                                    triggerGuiEvent(previousAction, {})
                                }

                                contentItem: Kirigami.Icon {
                                    source: "media-skip-backward"
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
                                     root.currentState === MediaPlayer.PlayingState ? root.pause() : root.currentState === MediaPlayer.PausedState ? root.resume() : root.play()
                                }

                                background: Rectangle {
                                    color: "transparent"
                                }

                                contentItem: Kirigami.Icon {
                                    color: "white"
                                    source: root.currentState === MediaPlayer.PlayingState ? "media-playback-pause" : "media-playback-start"
                                }
                            }

                            Controls.Button {
                                id: nextButton
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.alignment: Qt.AlignVCenter
                                onClicked: {
                                    triggerGuiEvent(nextAction, {})
                                }

                                background: Rectangle {
                                    color: "transparent"
                                }

                                contentItem: Kirigami.Icon {
                                    source: "media-skip-forward"
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
                                    source: "media-playlist-repeat"
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
                                    source: "media-playlist-shuffle"
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
        anchors.bottom: parent.bottom
        width: parent.width
        height: Mycroft.Units.gridUnit * 6
        color: "transparent"

        RowLayout {
            anchors.top: parent.top
            anchors.topMargin: Mycroft.Units.gridUnit
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
                text: playerPosition ? formatedPosition(playerPosition) : ""
                color: "white"
            }

            Controls.Label {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                font.pixelSize: height * 0.9
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                text: playerDuration ? formatedDuration(playerDuration) : ""
                color: "white"
            }
        }

        Rectangle {
            id: spectrumAreaCentered
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: Mycroft.Units.gridUnit * 0.5
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.leftMargin: parent.width * 0.17
            anchors.rightMargin: parent.width * 0.17
            color: "transparent"

            Row {
                id: repRows
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4
                visible: spectrumVisible
                enabled: spectrumVisible
                z: -5

                Repeater {
                    id: rep
                    model: root.soundModelLength

                    delegate: Rectangle {
                        width: (spectrumAreaCentered.width - (repRows.spacing * root.soundModelLength)) / root.soundModelLength
                        radius: 3
                        opacity: root.currentState === MediaPlayer.PlayingState ? 1 : 0
                        height: 15 + root.spectrum[modelData] * root.spectrumHeight
                        anchors.bottom: parent.bottom

                        gradient: Gradient {
                            GradientStop {position: 0.05; color: height > root.spectrumHeight / 1.25 ? spectrumColorPeak : spectrumColorNormal}
                            GradientStop {position: 0.25; color: spectrumColorMid}
                            GradientStop {position: 0.50; color: spectrumColorNormal}
                            GradientStop {position: 0.85; color: spectrumColorMid}
                        }

                        Behavior on height {
                            NumberAnimation {
                                duration: 150
                                easing.type: Easing.Linear
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation{
                                duration: 1500 + root.spectrum[modelData] * parent.height
                                easing.type: Easing.Linear
                            }
                        }
                    }
                }
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
            visible: true
            opacity: 0.98
            value: playerPosition

            onPressedChanged: {
                root.seek(value)
                root.resume()
            }

            handle: Item {
                x: sliderVisualGrad.width - 10
                anchors.verticalCenter: parent.verticalCenter
                height: Kirigami.Units.iconSizes.large

                Rectangle {
                    id: hand
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: Kirigami.Units.iconSizes.medium
                    implicitHeight: Kirigami.Units.iconSizes.medium
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
                    id: sliderVisualGrad
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

            Connections {
                target: root
                onPlayerDurationChanged: {
                    seekableslider.to = root.playerDuration
                }
                onPlayerPositionChanged: {
                    seekableslider.value = root.playerPosition
                }
            }
        }
    }
}
 
