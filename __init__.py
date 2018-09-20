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
import re
from adapt.intent import IntentBuilder
from mycroft.messagebus.message import Message
from mycroft.skills.core import MycroftSkill, intent_handler
from mycroft.skills.audioservice import AudioService


class PlaybackControlSkill(MycroftSkill):
    def __init__(self):
        super(PlaybackControlSkill, self).__init__('Playback Control Skill')
        self.replies = {}

    def initialize(self):
        self.audio_service = AudioService(self.bus)
        self.add_event('play:query.response',
                       self.handle_play_query_response)

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
        if self.audio_service.is_playing:
            self.audio_service.stop()
            return True
        else:
            return False

    @intent_handler(IntentBuilder('').require('Play').require('Phrase'))
    def play(self, message):

        # Remove everything up to and including "Play"
        # NOTE: This requires a Play.voc which holds any synomyms for 'Play'
        #       and a .rx that contains each of those synonyms.  E.g.
        #  Play.voc
        #      play
        #      bork
        #  phrase.rx
        #      play (?P<Phrase>.*)
        #      bork (?P<Phrase>.*)
        # This really just hacks around limitations of the Adapt regex system,
        # which will only return the first word of the target phrase
        utt = message.data.get('utterance')
        phrase = re.sub('^.*?' + message.data['Play'], '', utt).strip()
        self.log.info("Looking for: "+phrase)

        # Now we will generate a query on the messsagebus for anyone who
        # wants to listen to the 'play.request' message.  E.g.:
        #   {
        #      "type": "play.query",
        #      "phrase": "the news" / "tom waits" / "madonna on Pandora" / "music"
        #   }
        #
        # One or more skills can reply with a 'play.request.reply', e.g.:
        #   {
        #      "type": "play.request.response",
        #      "target": "the news",
        #      "skill_id": "<self.skill_id>",
        #      "conf": "0.7",
        #      "callback_data": "<optional data>"
        #   }
        # This means the skill has a 70% confidence they can handle that
        # request.  The "callback_data" is optional, but can provide data
        # that eliminates the need to re-parse if this reply is chosen.
        #
        self.replies[phrase] = []
        self.bus.emit(Message('play:query', data={"phrase": phrase}))

        # TODO: Allow skills to notify us when the are workign on it, extending
        # the timeout by a few seconds
        self.schedule_event(self._play_query_timeout, 1,
                            data={"phrase": phrase}, name='PlayQueryTimeout')

    def handle_play_query_response(self, message):
        # Collect all replies until the timeout
        self.replies[message.data["phrase"]].append(message.data)

    def _play_query_timeout(self, message):
        # Look for any replies that have already arrived
        phrase = message.data["phrase"]
        self.log.info("Replies: "+str(self.replies))

        # Find response(s) with the highest confidence
        best = None
        ties = []
        for handler in self.replies[phrase]:
            if not best or handler["conf"] > best["conf"]:
                best = handler
                ties = []
            elif handler["conf"] == best["conf"]:
                ties.append(handler)

        if best:
            if ties:
                # TODO: Ask user to pick between ties or do it automagically
                pass

            # invoke best match
            self.bus.emit(Message('play:start',
                                  data={"skill_id": best["skill_id"],
                                        "phrase": phrase,
                                        "callback_data": best.get("callback_data")}
                                        ))
        else:
            self.speak_dialog("cant.play", data={"phrase":phrase})
        del self.replies[phrase]


def create_skill():
    return PlaybackControlSkill()
