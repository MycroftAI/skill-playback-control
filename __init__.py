# Copyright 2016 Mycroft AI, Inc.
#
# This file is part of Mycroft Core.
#
# Mycroft Core is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Mycroft Core is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Mycroft Core.  If not, see <http://www.gnu.org/licenses/>.

from os.path import dirname, abspath

from adapt.intent import IntentBuilder
from mycroft.messagebus.message import Message
from mycroft.configuration import ConfigurationManager
from mycroft.skills.core import MycroftSkill
from mycroft.skills.audioservice import AudioService

from mycroft.util.log import getLogger

logger = getLogger(abspath(__file__).split('/')[-2])
__author__ = 'forslund'


class PlaybackControlSkill(MycroftSkill):
    def __init__(self):
        super(PlaybackControlSkill, self).__init__('Playback Control Skill')
        logger.info('Playback Control Inited')

    def initialize(self):
        logger.info('initializing Playback Control Skill')
        self.audio_service = AudioService(self.emitter)

        # Register common intents, these include basically all intents
        # except the intents to start playback (which should be implemented by
        # specific audio skills
        intent = IntentBuilder('NextIntent').require('NextKeyword')
        self.register_intent(intent, self.handle_next)

        intent = IntentBuilder('PrevIntent').require('PrevKeyword')
        self.register_intent(intent, self.handle_prev)

        intent = IntentBuilder('PauseIntent').require('PauseKeyword')
        self.register_intent(intent, self.handle_pause)

        intent = IntentBuilder('PlayIntent') \
            .one_of('PlayKeyword', 'ResumeKeyword')
        self.register_intent(intent, self.handle_play)

    def handle_next(self, message):
        self.audio_service.next()

    def handle_prev(self, message):
        self.audio_service.prev()

    def handle_pause(self, message):
        self.audio_service.pause()

    def handle_play(self, message):
        """Resume playback if paused"""
        self.audio_service.resume()

    def stop(self, message=None):
        logger.info("Stopping audio")
        self.emitter.emit(Message('mycroft.audio.service.stop'))


def create_skill():
    return PlaybackControlSkill()
