namespace PreviousRun {
    uint session = uint(-1);
    uint previous = uint(-1);

    uint gold = uint(-1);
    uint silver = uint(-1);
    uint bronze = uint(-1);

    void onNewMap() {
        session = uint(-1);
        previous = uint(-1);

        setMedals();
    }

    // sets the medal times from the session pb (for editor validation)
    void setMedals() {
        if (session == uint(-1)) {
            gold = uint(-1);
            silver = uint(-1);
            bronze = uint(-1);
        } else {
            gold = getAutoGold(session);
            silver = getAutoSilver(session);
            bronze = getAutoBronze(session);
        }
    }

#if TMNEXT
    uint checkFinished() {
        if (MapData::gamemode == GameMode::Royal) {
            return checkFinishedRoyal();
        }
        CGameCtnApp@ app = GetApp();
        CGamePlayground@ playground = cast<CGamePlayground>(app.CurrentPlayground);
        if (playground !is null && playground.GameTerminals.Length > 0 && (playground.GameTerminals[0].UISequence_Current == CGamePlaygroundUIConfig::EUISequence::Finish || (MapData::gamemode == GameMode::Stunt && playground.GameTerminals[0].UISequence_Current == CGamePlaygroundUIConfig::EUISequence::UIInteraction))) {
            CSmArenaRulesMode@ playgroundScript = cast<CSmArenaRulesMode>(app.PlaygroundScript);
            if (playgroundScript !is null) {
                CSmPlayer@ player = cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer);
                if (player !is null) {
                    CGameGhostScript@ ghost = playgroundScript.Ghost_RetrieveFromPlayer(cast<CSmScriptPlayer>(player.ScriptAPI));
                    if (ghost !is null) {
                        uint score = uint(-1);
                        if (MapData::gamemode == GameMode::Race || MapData::gamemode == GameMode::RaceClones) {
                            if (ghost.Result.Time > 0 && ghost.Result.Time < uint(-1)) {
                                score = ghost.Result.Time;
                            }
                        } else if (MapData::gamemode == GameMode::Stunt) {
                            // note this gets session PB (Nando). And seems equivalent to .StuntsScore
                            score = ghost.Result.Score;
                        } else if (MapData::gamemode == GameMode::Platform) {
                            score = ghost.Result.NbRespawns;
                        }
                        playgroundScript.DataFileMgr.Ghost_Release(ghost.Id);
                        return score;
                    }
                }
            } else {
#if DEPENDENCY_MLFEEDRACEDATA
                Meta::Plugin@ plugin = Meta::GetPluginFromID("MLFeedRaceData");
                if (plugin !is null && plugin.Enabled) {
                    const MLFeed::HookRaceStatsEventsBase_V4@ raceData = MLFeed::GetRaceData_V4();
                    if (raceData !is null && raceData.LocalPlayer !is null) {
                        return raceData.LocalPlayer.lastCpTime != 0 ? raceData.LocalPlayer.lastCpTime : uint(-1);
                    }
                }
#endif
            }
        }
        return uint(-1);
    }

    array<uint> royalTimes = {0, 0, 0, 0};
    uint checkFinishedRoyal() {
        // finish data type is already royal
        CGameCtnApp@ app = GetApp();
        CSmArenaClient@ playground = cast<CSmArenaClient>(app.CurrentPlayground);
        if (playground !is null && playground.GameTerminals.Length > 0 && (playground.GameTerminals[0].UISequence_Current == CGamePlaygroundUIConfig::EUISequence::Finish)) {
            CSmArenaRulesMode@ playgroundScript = cast<CSmArenaRulesMode>(app.PlaygroundScript);
            if (playgroundScript !is null) {
                CSmPlayer@ player = cast<CSmPlayer>(playground.GameTerminals[0].GUIPlayer);
                if (player !is null && player.CurrentLaunchedRespawnLandmarkIndex >= 0 && player.CurrentLaunchedRespawnLandmarkIndex < playground.Arena.MapLandmarks.Length) {
                    CGameGhostScript@ ghost = playgroundScript.Ghost_RetrieveFromPlayer(cast<CSmScriptPlayer>(player.ScriptAPI));
                    if (ghost !is null) {
                        uint score = uint(-1);
                        if (ghost.Result.Time > 0 && ghost.Result.Time < uint(-1)) {
                            score = ghost.Result.Time;
                        }
                        playgroundScript.DataFileMgr.Ghost_Release(ghost.Id);
                        uint section = playground.Arena.MapLandmarks[player.CurrentLaunchedRespawnLandmarkIndex].Order;
                        if (0 < section && 5 > section) {
                            royalTimes[section - 1] = score;
                            for (uint i = section; i < 4; i++) {
                                royalTimes[i] = uint(-1);
                            }
                        } else if (section == 5) {
                            return royalTimes[0] + royalTimes[1] + royalTimes[2] + royalTimes[3] + score;
                        } else {
                            print('invalid royal section: ' + section);
                        }
                    }
                }
            }
        }
        return uint(-1);
    }
#elif MP4
    uint checkFinished() {
        CGameCtnApp@ app = GetApp();
        CGameCtnPlayground@ playground = cast<CGameCtnPlayground@>(app.CurrentPlayground);
        if (playground !is null && playground.PlayerRecordedGhost !is null) {
            if (MapData::gamemode == GameMode::Race) {
                return playground.PlayerRecordedGhost.RaceTime;
            } else if (MapData::gamemode == GameMode::Stunt) {
                return playground.PlayerRecordedGhost.StuntsScore;
            } else if (MapData::gamemode == GameMode::Platform) {
                return playground.PlayerRecordedGhost.NbRespawns;
            }
        }
        return uint(-1);
    }
#elif TURBO
    uint checkFinished() {
        CGameCtnApp@ app = GetApp();
        CGameCtnPlayground@ playground = cast<CGameCtnPlayground@>(app.CurrentPlayground);
        if (playground !is null && playground.PlayerRecordedGhost !is null) {
            return playground.PlayerRecordedGhost.RaceTime;
        } else {
            auto network = cast<CTrackManiaNetwork>(app.Network);
            if (network.TmRaceRules !is null
                && network.TmRaceRules.Players.Length > 0
                && network.TmRaceRules.Players[0] !is null
                && network.TmRaceRules.Players[0].Score !is null
                && network.TmRaceRules.Players[0].Score.PrevRace !is null
            ) {  // this score seems to be in multiple places like pg.gt[0]
                return network.TmRaceRules.Players[0].Score.PrevRace.Time;
            }
        }
        return uint(-1);
    }
#endif

    void Update() {
        uint finish = checkFinished();
        if (finish == uint(-1)) {return;}
        previous = finish;
        cast<PbMedal>(MedalsList::pb.medal).updateIfNeeded(finish, MapData::currentMap);
        if (session == uint(-1) || (MapData::highBetter ^^ previous < session)) {
            session = previous;
            if (MapData::validationMode) {
                setMedals();
            }
        }
    }
}