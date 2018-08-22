# Copyright 2018 Mycroft AI Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from adapt.intent import IntentBuilder
from mycroft.messagebus.message import Message
from mycroft.skills.core import MycroftSkill, intent_handler
from mycroft.skills.audioservice import AudioService


class PlaybackControlSkill(MycroftSkill):
    def __init__(self):
        super(PlaybackControlSkill, self).__init__('Playback Control Skill')

    def initialize(self):
        self.log.info('initializing Playback Control Skill')
        self.audio_service = AudioService(self.bus)

    # Handle common audio intents.  'Audio' skills should listen for the
    # common messages:
    #   self.add_event('mycroft.audio.service.next', SKILL_HANDLER)
    #   self.add_event('mycroft.audio.service.prev', SKILL_HANDLER)
    #   self.add_event('mycroft.audio.service.pause', SKILL_HANDLER)
    #   self.add_event('mycroft.audio.service.resume', SKILL_HANDLER)

    @intent_handler(IntentBuilder('').require('Next').require("Track"))
    def handle_next(self, message):
        self.audio_service.next()

    @intent_handler(IntentBuilder('').require('Prev').require("Track"))
    def handle_prev(self, message):
        self.audio_service.prev()

    @intent_handler(IntentBuilder('').require('Pause'))
    def handle_pause(self, message):
        self.audio_service.pause()

    @intent_handler(IntentBuilder('').one_of('PlayResume', 'Resume'))
    def handle_play(self, message):
        """Resume playback if paused"""
        self.audio_service.resume()

    def stop(self, message=None):
        self.log.info("Stopping audio")
        self.bus.emit(Message('mycroft.audio.service.stop'))


def create_skill():
    return PlaybackControlSkill()
