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
    id: delegate

    property var videoListModel: sessionData.videoListBlob.videoList
    property var currentSongUrl: sessionData.currenturl
    property var currenttitle: sessionData.currenttitle
    property Component emptyHighlighter: Item{}

    skillBackgroundSource: "https://source.unsplash.com/weekly?music"
    
    onVideoListModelChanged: {
        leftSearchView.forceLayout()
    }

    Keys.onBackPressed: {
        parent.parent.parent.currentIndex--
        parent.parent.parent.currentItem.contentItem.forceActiveFocus()
    }
    
    function getImageSoure(source){
        switch(source){
            case "Spotify":
                return "images/Sources/Spotify.png";
                break;
            case "Bandcamp":
                return "images/Sources/Bandcamp.png";
                break;
            case "Soundcloud":
                return "images/Sources/Soundcloud.png";
                break;
        }
    }
    
    
    // Test Playlist Model Should Be Replaced By Playlist Model From sessionData
    ListModel {
        id: testModel
        ListElement {
          Title: "Give Life Back To Music"
          Artist: "Daft Punk"
          ImageUrl: "https://cdna.artstation.com/p/assets/images/images/005/587/778/large/josh-matts-daftpunkposter-b.jpg?1492210876"
          Duration: "5:40"
          Source: "Spotify"
        }
        ListElement {
            Title: "One More Time"
            Artist: "Daft Punk"
            ImageUrl: "https://www.roadtovr.com/wp-content/uploads/2019/09/daft-punk-vr-one-more-time.jpg"
            Duration: "2:40"
            Source: "Bandcamp"   
        }
        ListElement {
            Title: "Get Lucky (feat. Pharrell Williams)"
            Artist: "Daft Punk"
            ImageUrl: "https://upload.wikimedia.org/wikipedia/en/7/71/Get_Lucky.jpg"
            Duration: "3:40"
            Source: "Soundcloud"
        }
    }
    
    ColumnLayout {
        id: recentlyPlayerColumn
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        Kirigami.Heading {
            id: watchItemList
            text: "Your Playlist"
            level: 2
        }
        
        Kirigami.Separator {
            id: sept2
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            z: 100
        }
        
        ListView {
            id: leftSearchView
            keyNavigationEnabled: true
            model: testModel     // Test Playlist Model Should Be Replaced By Playlist Model From sessionData
            focus: false
            interactive: true
            bottomMargin: delegate.controlBarItem.height + Kirigami.Units.largeSpacing
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Kirigami.Units.largeSpacing
            currentIndex: 0
            highlightRangeMode: ListView.StrictlyEnforceRange
            snapMode: ListView.SnapToItem
            
            delegate: Controls.Control {
                width: parent.width
                height: Kirigami.Units.gridUnit * 4
                
                background: Rectangle {
                    Kirigami.Theme.colorSet: Kirigami.Theme.Button
                    color: Qt.rgba(0.2, 0.2, 0.2, 1)
                    layer.enabled: true
                    layer.effect: DropShadow {
                        horizontalOffset: 1
                        verticalOffset: 2
                    }
                }

                
                contentItem: Item {
                    width: parent.width
                    height: parent.height

                    RowLayout {
                        id: delegateItem
                        anchors.fill: parent
                        anchors.margins: Kirigami.Units.smallSpacing
                        spacing: Kirigami.Units.largeSpacing

                        Image {
                            id: videoImage
                            source: model.ImageUrl
                            Layout.preferredHeight: parent.height
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                            Layout.alignment: Qt.AlignHCenter
                            fillMode: Image.Stretch
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            
                            Controls.Label {
                                id: videoLabel
                                Layout.fillWidth: true
                                text: model.Title
                                wrapMode: Text.WordWrap
                                color: "white"
                            }
                            Controls.Label {
                                id: artistLabel
                                Layout.fillWidth: true
                                text: model.Artist
                                opacity: 0.8
                                color: "white"
                            }
                        }
                        
                        Controls.Label {
                            id: durationTime
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            color: "white"
                            opacity: 0.8
                            text: model.Duration
                        }
                        
                        Kirigami.Separator {
                            Layout.fillHeight: true
                            Layout.preferredWidth: 1
                        }
                        
                        Image {
                            id: songSource
                            Layout.preferredHeight: Kirigami.Units.iconSizes.huge + Kirigami.Units.largeSpacing
                            Layout.preferredWidth: Kirigami.Units.iconSizes.huge + Kirigami.Units.largeSpacing
                            Layout.alignment: Qt.AlignHCenter
                            fillMode: Image.PreserveAspectFit
                            source: getImageSoure(model.Source)
                        }
                    }
                }
            }
        }
    }
    
    Component.onCompleted: {
        leftSearchView.forceActiveFocus()
    }
}

