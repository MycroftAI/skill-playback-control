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
import random
from adapt.intent import IntentBuilder
from mycroft.skills.core import MycroftSkill, intent_handler
from mycroft.skills.common_play_skill import CommonPlaySkill, CPSMatchLevel,\
    CPSTrackStatus, CPSMatchType
from mycroft.skills.audioservice import AudioService
from os.path import join, exists
from threading import Lock


STATUS_KEYS = ['track', 'artist', 'album', 'image']


class PlaybackControlSkill(CommonPlaySkill):
    def __init__(self):
        super(PlaybackControlSkill, self).__init__('Playback Control Skill')
        self.query_replies = {}     # cache of received replies
        self.query_extensions = {}  # maintains query timeout extensions
        self.has_played = False
        self.lock = Lock()
        self.playback_status = CPSTrackStatus.END_OF_MEDIA
        self.playback_data = {"playing": None,
                              "playlist": [],
                              "disambiguation": []}
        self.supported_media = [t for t in CPSMatchType]

    # TODO: Make this an option for voc_match()?  Only difference is the
    #       comparison using "==" instead of "in"
    def voc_match_exact(self, utt, voc_filename, lang=None):
        """ Determine if the given utterance contains the vocabulary provided

        Checks for vocabulary match in the utterance instead of the other
        way around to allow the user to say things like "yes, please" and
        still match against "Yes.voc" containing only "yes". The method first
        checks in the current skill's .voc files and secondly the "res/text"
        folder of mycroft-core. The result is cached to avoid hitting the
        disk each time the method is called.

        Args:
            utt (str): Utterance to be tested
            voc_filename (str): Name of vocabulary file (e.g. 'yes' for
                                'res/text/en-us/yes.voc')
            lang (str): Language code, defaults to self.long

        Returns:
            bool: True if the utterance has the given vocabulary it
        """
        lang = lang or self.lang
        cache_key = lang + voc_filename

        if cache_key not in self.voc_match_cache:
            # Check for both skill resources and mycroft-core resources
            voc = self.find_resource(voc_filename + '.voc', 'vocab')
            if not voc:
                voc = self.resolve_resource_file(join('text', lang,
                                                      voc_filename + '.voc'))

            if not voc or not exists(voc):
                raise FileNotFoundError(
                        'Could not find {}.voc file'.format(voc_filename))

            with open(voc) as f:
                self.voc_match_cache[cache_key] = f.read().splitlines()

        # Check for exact match
        if utt and any(i.strip() == utt
                       for i in self.voc_match_cache[cache_key]):
            return True
        return False

    def initialize(self):
        self.audio_service = AudioService(self.bus)
        self.add_event('play:query.response',
                       self.handle_play_query_response)
        self.add_event('play:status',
                       self.handle_cps_status)
        self.add_event('play:status.query',
                       self.handle_cps_status_query)
        self.gui.register_handler('next', self.handle_next)
        self.gui.register_handler('prev', self.handle_prev)

        self.clear_gui_info()
    # Handle common audio intents.  'Audio' skills should listen for the
    # common messages:
    #   self.add_event('mycroft.audio.service.next', SKILL_HANDLER)
    #   self.add_event('mycroft.audio.service.prev', SKILL_HANDLER)
    #   self.add_event('mycroft.audio.service.pause', SKILL_HANDLER)
    #   self.add_event('mycroft.audio.service.resume', SKILL_HANDLER)

    def clear_gui_info(self):
        """Clear the gui variable list."""
        # Initialize track info variables
        for k in STATUS_KEYS:
            self.gui[k] = ''
        self.playback_data = {"playing": None,
                              "playlist": [],
                              "disambiguation": []}
        self.playback_status = CPSTrackStatus.END_OF_MEDIA

    @intent_handler(IntentBuilder('NextCommonPlay')
                    .require('Next').one_of("Track", "Playing").require("Playlist"))
    def handle_next(self, message):
        self.audio_service.next()

    @intent_handler(IntentBuilder('PrevCommonPlay')
        .require('Prev').one_of("Track", "Playing").require("Playlist"))
    def handle_prev(self, message):
        self.audio_service.prev()

    @intent_handler(IntentBuilder('PauseCommonPlay')
                    .require('Pause').require("Playing"))
    def handle_pause(self, message):
        # TODO audio service should emit the pause status instead
        self.playback_status = CPSTrackStatus.PAUSED
        self.audio_service.pause()

    @intent_handler(IntentBuilder('ResumeCommonPlay')
                    .one_of('PlayResume', 'Resume').require("Playing"))
    def handle_resume(self, message):
        """Resume playback if paused"""
        self.audio_service.resume()

    def stop(self, message=None):
        self.clear_gui_info()

        self.log.info('Audio service status: '
                      '{}'.format(self.audio_service.track_info()))
        if self.audio_service.is_playing:
            self.audio_service.stop()
            return True
        else:
            return False

    def converse(self, utterances, lang="en-us"):
        if (utterances and self.has_played and
                self.voc_match_exact(utterances[0], "converse_resume")):
            # NOTE:  voc_match() will overmatch (e.g. it'll catch "play next
            #        song" or "play Some Artist")
            self.audio_service.resume()
            return True
        else:
            return False

    # generic play intents
    @intent_handler("play.intent")
    def generic_play(self, message):
        self._play(message, CPSMatchType.GENERIC)

    @intent_handler("music.intent")
    def play_music(self, message):
        self._play(message, CPSMatchType.MUSIC)

    @intent_handler("video.intent")
    def play_video(self, message):
        self._play(message, CPSMatchType.VIDEO)

    @intent_handler("audiobook.intent")
    def play_audiobook(self, message):
        self._play(message, CPSMatchType.AUDIOBOOK)

    @intent_handler("game.intent")
    def play_game(self, message):
        self._play(message, CPSMatchType.GAME)

    @intent_handler("radio.intent")
    def play_radio(self, message):
        self._play(message, CPSMatchType.RADIO)

    @intent_handler("podcast.intent")
    def play_podcast(self, message):
        self._play(message, CPSMatchType.PODCAST)

    @intent_handler("news.intent")
    def play_news(self, message):
        self._play(message, CPSMatchType.NEWS)

    # playback selection
    def _play(self, message, media_type=CPSMatchType.GENERIC):
        phrase = message.data.get("query", "")

        will_resume = self.playback_status == CPSTrackStatus.PAUSED \
                      and not bool(phrase.strip())
        if not will_resume:
            # empty string means "resume" will be used,
            # speech sounds wrong in that case
            self.speak_dialog("just.one.moment", wait=True)

        # TODO debug log should print a string not an int for media type
        self.log.info("Resolving {media} Player for: {query}".format(
            media=media_type, query=phrase))
        self.enclosure.mouth_think()

        # Now we place a query on the messsagebus for anyone who wants to
        # attempt to service a 'play.request' message.  E.g.:
        #   {
        #      "type": "play.query",
        #      "phrase": "the news" / "tom waits" / "madonna on Pandora"
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
        self.query_replies[phrase] = []
        self.query_extensions[phrase] = []

        self.bus.emit(message.forward('play:query',
                                      data={"phrase": phrase,
                                            "media_type": media_type}))

        self.schedule_event(self._play_query_timeout, 1,
                            data={"phrase": phrase, "media_type": media_type},
                            name='PlayQueryTimeout')

    def handle_play_query_response(self, message):
        with self.lock:
            search_phrase = message.data["phrase"]

            if ("searching" in message.data and
                    search_phrase in self.query_extensions):
                # Manage requests for time to complete searches
                skill_id = message.data["skill_id"]
                if message.data["searching"]:
                    # extend the timeout by 5 seconds
                    self.cancel_scheduled_event("PlayQueryTimeout")
                    self.schedule_event(self._play_query_timeout, 5,
                                        data={"phrase": search_phrase},
                                        name='PlayQueryTimeout')

                    # TODO: Perhaps block multiple extensions?
                    if skill_id not in self.query_extensions[search_phrase]:
                        self.query_extensions[search_phrase].append(skill_id)
                else:
                    # Search complete, don't wait on this skill any longer
                    if skill_id in self.query_extensions[search_phrase]:
                        self.query_extensions[search_phrase].remove(skill_id)
                        if not self.query_extensions[search_phrase]:
                            self.cancel_scheduled_event("PlayQueryTimeout")
                            self.schedule_event(self._play_query_timeout, 0,
                                                data={"phrase": search_phrase},
                                                name='PlayQueryTimeout')

            elif search_phrase in self.query_replies:
                # Collect all replies until the timeout
                self.query_replies[message.data["phrase"]].append(message.data)

    def _play_query_timeout(self, message):
        with self.lock:
            # Prevent any late-comers from retriggering this query handler
            search_phrase = message.data["phrase"]
            self.query_extensions[search_phrase] = []
            self.enclosure.mouth_reset()

            # Look at any replies that arrived before the timeout
            # Find response(s) with the highest confidence
            best = None
            ties = []
            self.log.debug("CommonPlay Resolution: {}".format(search_phrase))
            for handler in self.query_replies[search_phrase]:
                self.log.debug("    {} using {}".format(handler["conf"],
                                                        handler["skill_id"]))
                if not best or handler["conf"] > best["conf"]:
                    best = handler
                    ties = []
                elif handler["conf"] == best["conf"]:
                    ties.append(handler)

            if best:
                if ties:
                    # TODO: Ask user to pick between ties or do it
                    # automagically
                    pass

                # invoke best match
                self.gui.show_page("controls.qml", override_idle=True)

                self.log.info("Playing with: {}".format(best["skill_id"]))

                will_resume = self.playback_status == CPSTrackStatus.PAUSED \
                              and not bool(search_phrase.strip())
                start_data = {"skill_id": best["skill_id"],
                              "phrase": search_phrase,
                              "trigger_stop": not will_resume,
                              "callback_data": best.get("callback_data")}
                self.bus.emit(message.forward('play:start', start_data))
                self.has_played = True
            elif self.voc_match(search_phrase, "Music"):
                self.speak_dialog("setup.hints")
            else:
                self.log.info("   No matches")
                self.speak_dialog("cant.play", data={"phrase": search_phrase})

            if search_phrase in self.query_replies:
                del self.query_replies[search_phrase]
            if search_phrase in self.query_extensions:
                del self.query_extensions[search_phrase]

    def update_current_song(self, data):
        self.playback_data["playing"] = data
        for key in STATUS_KEYS:
            self.gui[key] = data.get(key, '')
        self.set_context("Playing",
                         "playback underway: " + str(data["status"]))

    def update_playlist(self, data):
        self.set_context("Playlist", "playlist exists")
        self.playback_data["playlist"].append(data)
        # sort playlist by requested order
        self.playback_data["playlist"] = sorted(
            self.playback_data["playlist"],
            key = lambda i: int(i['playlist_position']) or 0)


    # playback status
    def handle_cps_status(self, message):
        status = message.data["status"]

        if status == CPSTrackStatus.PLAYING:
            # skill is handling playback internally
            self.update_current_song(message.data)
            self.playback_status = status
        elif status == CPSTrackStatus.PLAYING_AUDIOSERVICE:
            # audio service is handling playback
            self.update_current_song(message.data)
            self.playback_status = status
        elif status == CPSTrackStatus.PLAYING_GUI:
            # gui is handling playback
            self.update_current_song(message.data)
            self.playback_status = status

        elif status == CPSTrackStatus.DISAMBIGUATION:
            # alternative results
            self.playback_data["disambiguation"].append(message.data)
        elif status == CPSTrackStatus.QUEUED:
            # skill is handling playback and this is in playlist
            self.update_playlist(message.data)
        elif status == CPSTrackStatus.QUEUED_GUI:
            # gui is handling playback and this is in playlist
            self.update_playlist(message.data)
        elif status == CPSTrackStatus.QUEUED_AUDIOSERVICE:
            # audio service is handling playback and this is in playlist
            self.update_playlist(message.data)

        elif status == CPSTrackStatus.PAUSED:
            # media is not being played, but can be resumed anytime
            # a new PLAYING status should be sent once playback resumes
            self.playback_status = status
        elif status == CPSTrackStatus.BUFFERING:
            # media is buffering, might want to show in ui
            # a new PLAYING status should be sent once playback resumes
            self.playback_status = status
        elif status == CPSTrackStatus.STALLED:
            # media is stalled, might want to show in ui
            # a new PLAYING status should be sent once playback resumes
            self.playback_status = status
        elif status == CPSTrackStatus.END_OF_MEDIA:
            # if we add a repeat/loop flag this is the place to check for it
            self.playback_status = status

    def handle_cps_status_query(self, message):
        #  update playlist / current song in audio service,
        #  audio service should also react to 'play:status' for live updates
        #  but it can sync anytime with 'play:status.query'
        self.bus.emit(message.reply('play:status.response',
                                    self.playback_data))

    # handle "play {media_type}" generic queries to mean "resume"
    def CPS_match_query_phrase(self, phrase, media_type):
        if self.playback_status == CPSTrackStatus.PAUSED:
            if not phrase.strip() or self.voc_match(phrase, "Resume"):
                return (phrase, CPSMatchLevel.EXACT, self.playback_data)
        return None

    def CPS_start(self, phrase, data):
        self.audio_service.resume()


def create_skill():
    return PlaybackControlSkill()
