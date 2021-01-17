/*
 * Copyright 2020 by Aditya Mehra <aix.m@outlook.com>
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

import QtQuick 2.9
import QtQuick.Controls 2.3 as Controls
import QtQuick.Layouts 1.3
import org.kde.kirigami 2.8 as Kirigami
import QtGraphicalEffects 1.0
import Mycroft 1.0 as Mycroft

Mycroft.Delegate {
    id: root
    skillBackgroundSource: testModel.image
    property int switchWidth: Kirigami.Units.gridUnit * 19
    property alias thumbnail: albumimg.source
    readonly property bool horizontal: width > switchWidth
    readonly property bool wideMode: width > 600
    
    // Should All Be Replaced With SessionData
    // Assumption Track_Length is always in milliseconds
    // Assumption current_Position is always in milleseconds and relative to track_length if track_length = 530000, position values range from 0 to 530000
    
    property var testModel: {"image": "https://d1csarkz8obe9u.cloudfront.net/posterpreviews/mixtape-album-cover-art-design-template-68450756e786f85861314fa7d49d8366.jpg?ts=1586223871", "track": "Escaping The Stars", "album": "Unknown", "skill": "skill-soundcloud", "track_length": 530000, "current_position": 0, "status": "Paused" }
    property var playerDuration: testModel.track_length
    property real playerPosition: testModel.current_position
    property var playerState: testModel.status
    property var nextAction: "playbackControl.nextAction"
    property var previousAction: "playbackControl.previousAction"
    
    Controls.ButtonGroup {
        id: autoPlayRepeatGroup
        buttons: autoPlayRepeatGroupLayout.children
    }
    
    Component.onCompleted: {
        console.log(playerDuration)
    }
    
    Item {
        anchors.fill: parent
        
        Kirigami.Heading {
            id: songtitle
            text: "Escaping The Stars"
            level: root.horizontal ? 1 : 3
            width: parent.width
            height: paintedHeight
            horizontalAlignment: root.horizontal ? Text.AlignLeft : Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
            font.capitalization: Font.Capitalize
            visible: true
            enabled: true
        }
        
        GridLayout {
            anchors {
                top: root.horizontal ? undefined : songtitle.bottom
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                bottomMargin: Kirigami.Units.gridUnit
            }
            columns: root.horizontal ? 2 : 1
            height: implicitHeight

            Image {
                id: albumimg
                fillMode: Image.PreserveAspectCrop
                visible: true
                enabled: true
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.maximumWidth: root.horizontal ? Kirigami.Units.gridUnit * 7 : Kirigami.Units.gridUnit * 4
                Layout.maximumHeight: root.horizontal ? Kirigami.Units.gridUnit * 7 : Kirigami.Units.gridUnit * 4
                Layout.minimumWidth: root.horizontal ? Kirigami.Units.gridUnit * 5 : Kirigami.Units.gridUnit * 2.5
                Layout.minimumHeight: root.horizontal ? Kirigami.Units.gridUnit * 5 : Kirigami.Units.gridUnit * 2.5
                Layout.alignment: root.horizontal ? Qt.AlignBottom : Qt.AlignHCenter | Qt.AlignTop
                source: testModel.image
                layer.enabled: true
                layer.effect: DropShadow {
                    horizontalOffset: 1
                    verticalOffset: 2
                    spread: 0.2
                }
            }
            
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignBottom
                spacing: -Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: root.horizontal ? 1 : 0
                    Layout.alignment: root.horizontal ? Qt.AlignLeft : Qt.AlignBottom
                    spacing: Kirigami.Units.largeSpacing

                    Controls.RoundButton {
                        id: previousButton
                        Layout.minimumWidth: Kirigami.Units.iconSizes.small
                        Layout.minimumHeight: width
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.maximumWidth: Kirigami.Units.gridUnit * 3
                        Layout.maximumHeight: width
                        Layout.alignment: Qt.AlignVCenter
                        focus: false
                        icon.source: "images/media-seek-backward.svg"
                        KeyNavigation.right: playButton
                        KeyNavigation.down: seekableslider
                        onClicked: {
                            triggerGuiEvent(previousAction, {})
                        }

                        background: Rectangle {
                            Kirigami.Theme.colorSet: Kirigami.Theme.Button
                            radius: width
                            color: previousButton.activeFocus ? Kirigami.Theme.highlightColor : Qt.rgba(0.2, 0.2, 0.2, 1)
                            layer.enabled: true
                            layer.effect: DropShadow {
                                horizontalOffset: 1
                                verticalOffset: 2
                            }
                        }

                        Keys.onReturnPressed: {
                            clicked()
                        }
                    }

                    Controls.RoundButton {
                        id: playButton
                        Layout.minimumWidth: Kirigami.Units.gridUnit * 3
                        Layout.minimumHeight: width
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.maximumWidth: Kirigami.Units.gridUnit * 4
                        Layout.maximumHeight: width
                        Layout.alignment: Qt.AlignVCenter
                        focus: false
                        icon.source: playerState === "Playing" ? "images/media-playback-pause.svg" : "images/media-playback-start.svg"
                        KeyNavigation.left: previousButton
                        KeyNavigation.right: nextButton
                        KeyNavigation.down: seekableslider
                        onClicked: {
                            if (playerState != "Playing"){
                                triggerGuiEvent("playbackControl.playAction", {})
                            } else {
                                triggerGuiEvent("playbackControl.pauseAction", {})
                            }
                        }

                        background: Rectangle {
                            Kirigami.Theme.colorSet: Kirigami.Theme.Button
                            radius: width
                            color: playButton.activeFocus ? Kirigami.Theme.highlightColor : Qt.rgba(0.2, 0.2, 0.2, 1)
                            layer.enabled: true
                            layer.effect: DropShadow {
                                horizontalOffset: 1
                                verticalOffset: 2
                            }
                        }

                        Keys.onReturnPressed: {
                            clicked()
                        }
                    }

                    Controls.RoundButton {
                        id: nextButton
                        Layout.minimumWidth: Kirigami.Units.iconSizes.small
                        Layout.minimumHeight: width
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.maximumWidth: Kirigami.Units.gridUnit * 3
                        Layout.maximumHeight: width
                        Layout.alignment: Qt.AlignVCenter
                        focus: false
                        icon.source: "images/media-seek-forward.svg"
                        KeyNavigation.left: playButton
                        KeyNavigation.down: seekableslider
                        onClicked: {
                            triggerGuiEvent(nextAction, {})
                        }

                        background: Rectangle {
                            Kirigami.Theme.colorSet: Kirigami.Theme.Button
                            radius: width
                            color: nextButton.activeFocus ? Kirigami.Theme.highlightColor : Qt.rgba(0.2, 0.2, 0.2, 1)
                            layer.enabled: true
                            layer.effect: DropShadow {
                                horizontalOffset: 1
                                verticalOffset: 2
                            }
                        }

                        Keys.onReturnPressed: {
                            clicked()
                        }
                    }

                    Item {
                        Layout.minimumWidth: Kirigami.Units.largeSpacing * 3
                        Layout.fillHeight: true
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: wideMode ? nextButton.height : nextButton.height * 2
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                        GridLayout {
                            id: autoPlayRepeatGroupLayout
                            width: wideMode ? nextButton.width * 2 : nextButton.width
                            height: parent.height
                            anchors.right: parent.right
                            columns: wideMode ? 2 : 1
                            columnSpacing: 0

                            Controls.RoundButton {
                                id: repeatButton
                                Layout.minimumWidth: Kirigami.Units.iconSizes.small
                                Layout.minimumHeight: width
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.maximumWidth: Kirigami.Units.gridUnit * 3
                                Layout.maximumHeight: width
                                Layout.alignment: wideMode ?  Qt.AlignRight : Qt.AlignRight | Qt.AlignVCenter
                                focus: false
                                checkable: true
                                checked: false
                                icon.source: "images/media-playlist-repeat.svg"
                                KeyNavigation.left: playButton
                                KeyNavigation.down: seekableslider
                                
                                onClicked: {
                                    if(checked) {
                                        triggerGuiEvent("playbackControl.setRepeat", {"repeat": true})
                                    } else {
                                        triggerGuiEvent("playbackControl.setRepeat", {"repeat": false})
                                    }
                                }
                                
                                onCheckedChanged: {
                                    if(checked) {
                                        repeatButtonBg.border.width = Kirigami.Units.smallSpacing * 0.5
                                        repeatButtonBg.border.color = Kirigami.Theme.linkColor
                                    } else {
                                        repeatButtonBg.border.width = 0
                                        repeatButtonBg.border.color = "transparent"
                                    }
                                }

                                background: Rectangle {
                                    id: repeatButtonBg
                                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                    radius: width
                                    color: repeatButton.activeFocus ? Kirigami.Theme.highlightColor : Qt.rgba(0.2, 0.2, 0.2, 1)
                                    layer.enabled: true
                                    layer.effect: DropShadow {
                                        horizontalOffset: 1
                                        verticalOffset: 2
                                    }
                                }

                                Keys.onReturnPressed: {
                                    clicked()
                                }
                            }

                            Controls.RoundButton {
                                id: autoPlayButton
                                Layout.minimumWidth: Kirigami.Units.iconSizes.small
                                Layout.minimumHeight: width
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                Layout.maximumWidth: Kirigami.Units.gridUnit * 3
                                Layout.maximumHeight: width
                                Layout.alignment: wideMode ?  Qt.AlignRight : Qt.AlignRight | Qt.AlignVCenter
                                focus: false
                                checkable: true
                                checked: false
                                icon.source: "images/media-playlist-play.svg"
                                KeyNavigation.left: playButton
                                KeyNavigation.down: seekableslider
                                
                                onClicked: {
                                    if(checked) {
                                        triggerGuiEvent("playbackControl.setAutoPlay", {"autoplay": true})
                                    } else {
                                        triggerGuiEvent("playbackControl.setAutoPlay", {"autoplay": false})
                                    }
                                }
                                
                                onCheckedChanged: {
                                    if(checked) {
                                        autoPlayButtonBg.border.width = Kirigami.Units.smallSpacing * 0.5
                                        autoPlayButtonBg.border.color = Kirigami.Theme.linkColor
                                    } else {
                                        autoPlayButtonBg.border.width = 0
                                        autoPlayButtonBg.border.color = "transparent"
                                    }
                                }

                                background: Rectangle {
                                    id: autoPlayButtonBg
                                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                                    radius: width
                                    color: autoPlayButton.activeFocus ? Kirigami.Theme.highlightColor : Qt.rgba(0.2, 0.2, 0.2, 1)
                                    layer.enabled: true
                                    layer.effect: DropShadow {
                                        horizontalOffset: 1
                                        verticalOffset: 2
                                    }
                                }

                                Keys.onReturnPressed: {
                                    clicked()
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.topMargin: Kirigami.Units.smallSpacing
                    Layout.alignment: Qt.AlignBottom
                    spacing: Kirigami.Units.smallSpacing
                    Layout.fillWidth: true
                    visible: true
                    enabled: true

                    Controls.Slider {
                        id: seekableslider
                        to: playerDuration
                        Layout.fillWidth: true
                        property bool sync: false
                        value: playerPosition

                        onValueChanged: {
                            if (!sync)
                                triggerGuiEvent("playbackControl.playerSeek", {"value": value})
                        }

                        Keys.onLeftPressed: {
                            var l = 0
                            l = seekableslider.position - 0.05
                            seekableslider.value = seekableslider.valueAt(l);
                        }

                        Keys.onRightPressed: {
                            var l = 0
                            l = seekableslider.position + 0.05
                            seekableslider.value = seekableslider.valueAt(l);
                        }
                    }

                    Controls.Label {
                        id: positionLabel
                        readonly property int minutes: Math.floor(playerDuration / 60000)
                        readonly property int seconds: Math.round((playerDuration % 60000) / 1000)
                        text: minutes + ":" + seconds
                    }
                }
            }
        }
    }
}

