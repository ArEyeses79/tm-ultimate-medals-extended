enum GameMode {
    None,
    Race,
    RaceClones,
    Stunt,
    Platform,
    Royal
}

namespace MapData {

    bool highBetter = false;
    GameMode gamemode = GameMode::None;

    string currentMap = '';
    uint64 timeEnterMap = 0;
    bool validationMode = false;

    bool hasLoadedReplayEditor = false;
    bool validated = false;

#if TURBO
    bool needCheckTurboPb = false;
#endif

    void updateGamemode() {
        CGameCtnApp@ app = GetApp();
        gamemode = GameMode::None;
        string gm = cast<CTrackManiaNetworkServerInfo@>(app.Network.ServerInfo).CurGameModeStr;
        if (gm.Contains('Race') || gm.Contains('Obstacle')) {
            gamemode = GameMode::Race;
#if TMNEXT
            if (IsClones(app.RootMap)) {
                gamemode = GameMode::RaceClones;
            }
#endif
        } else if (gm.Contains('Stunt')) {
            gamemode = GameMode::Stunt;
        } else if (gm.Contains('Platform')) {
            gamemode = GameMode::Platform;
        } else if (gm.Contains('Royal')) {
            gamemode = GameMode::Royal;
        }
        if (gamemode == GameMode::None) {
            gm = getMap().MapType;
            if (gm.Contains('Race') || gm.Contains('Obstacle')) {
                gamemode = GameMode::Race;
#if TMNEXT
                if (IsClones(app.RootMap)) {
                    gamemode = GameMode::RaceClones;
                }
#endif
            } else if (gm.Contains('Stunt')) {
                gamemode = GameMode::Stunt;
            } else if (gm.Contains('Platform')) {
                gamemode = GameMode::Platform;
            } else if (gm.Contains('Royal')) {
                gamemode = GameMode::Royal;
            }
        }

        highBetter = gamemode == GameMode::Stunt;
    }

    void updateValidated() {
        CGameCtnApp@ app = GetApp();
        CGameCtnChallenge@ map = getMap();
        if (map.TMObjective_AuthorTime != uint(-1)) {
            validated = true;
            return;
        }
        CGameCtnEditorFree@ editor = cast<CGameCtnEditorFree>(app.Editor);
        if (editor !is null) {
#if TMNEXT || MP4
            auto pluginMapType = editor.PluginMapType;
            validated = pluginMapType !is null && pluginMapType.ValidationStatus == CGameEditorPluginMapMapType::EValidationStatus::Validated;
#elif TURBO
            auto pluginMapType = editor.EditorMapType;
            validated = pluginMapType !is null && pluginMapType.ValidationStatus == CGameCtnEditorPluginMapType::EValidationStatus::Validated;
#endif
            return;
        }

#if TMNEXT
        CGameEditorMediaTracker@ replay = cast<CGameEditorMediaTracker>(app.Editor);
#elif MP4 || TURBO
        CGameCtnMediaTracker@ replay = cast<CGameCtnMediaTracker>(app.Editor);
#endif
        if (replay !is null &&
            map.MapInfo.Kind == 6) { // unnamed enum - in progress
                validated = false;
        } else {
            validated = true;
        }
        return;
    }

#if TMNEXT
    uint _nextUpdate = 0;
#else
    uint64 _nextUpdate = 0;
#endif

    void Update() {
        CGameCtnApp@ app = GetApp();
        CGameCtnChallenge@ map = getMap();
        
        if (map is null) {
            currentMap = '';
            return;
        }
#if TMNEXT
        CSmArenaClient@ playground = cast<CSmArenaClient>(app.CurrentPlayground);
#elif MP4 || TURBO
        CGamePlayground@ playground = app.CurrentPlayground;
#endif
        CGameCtnEditorFree@ editor = cast<CGameCtnEditorFree>(app.Editor);
        if (!showValidation && editor !is null || (editor !is null && (playground is null || playground.GameTerminals.Length == 0))) {
            currentMap = '';
            return;
        }
        if (showValidation && editor !is null) {
            // check if in test mode
#if TMNEXT
            CSmEditorPluginMapType@ pluginMapType = cast<CSmEditorPluginMapType>(editor.PluginMapType);
            if ((pluginMapType is null || pluginMapType.Mode.ClientManiaAppUrl.Contains('RaceTest'))) {
                currentMap = '';
                return;
            }
#elif MP4
            if (app.PlaygroundScript is null || app.PlaygroundScript.MapName == "") {
                currentMap = '';
                return;
            }
#endif
            validationMode = true;
        } else {
            validationMode = false;
        }
#if TMNEXT
        CGameEditorMediaTracker@ replay = cast<CGameEditorMediaTracker>(app.Editor);
#elif MP4 || TURBO
        CGameCtnMediaTracker@ replay = cast<CGameCtnMediaTracker>(app.Editor);
#endif
        if (!showReplayEditor && replay !is null) {
            currentMap = '';
            return;
        }
        if (showReplayEditor && replay !is null && 
            map.MapInfo.Kind == 6) { // unnamed enum - in progress
                currentMap = '';
                return;
        }

        if (app.Editor !is null && editor is null && replay is null) {
            // unknown editor e.g. skin editor, not enabled
            currentMap = '';
            return;
        }

        if (map.IdName != currentMap) {
            currentMap = map.IdName;
            timeEnterMap = Time::Now;
#if TURBO
            needCheckTurboPb = true;
#endif
            hasLoadedReplayEditor = false;
            updateGamemode();
            updateValidated();
            PreviousRun::onNewMap();
            MedalsList::onNewMap(currentMap);
        }

#if TURBO
        PreviousRun::Update();
#else
        if (validationMode || 
            (MedalsList::session.enabled || MedalsList::previous.enabled)) {
                PreviousRun::Update();
        }
#endif

        // check if pb needs updating
        // to save performance, only check for pb every half a second
#if TMNEXT
        if (_nextUpdate > app.TimeSinceInitMs) {return;}
        _nextUpdate = app.TimeSinceInitMs + 500;
#else
        if (_nextUpdate > Time::Now) {return;}
        _nextUpdate = Time::Now + 500;
#endif

        if (MedalsList::pb is null || !MedalsList::pb.enabled) {return;}
        
        if (showReplayEditor && replay !is null) {
            // replay editor doesn't load until after first entering map, so pb needs to re-detect that it is now invalid
            if (!hasLoadedReplayEditor) {
                MedalsList::onNewMap(currentMap);
                hasLoadedReplayEditor = true;
            }
        }

        if (app.Editor !is null) {
            // in editor, no pb
            return;
        }
        CTrackManiaNetwork@ network = cast<CTrackManiaNetwork>(app.Network);
#if TMNEXT
        if (network.ClientManiaAppPlayground !is null) {
            CGameUserManagerScript@ userMgr = network.ClientManiaAppPlayground.UserMgr;
            MwId userId;
            if (userMgr.Users.Length > 0) {
                userId = userMgr.Users[0].Id;
            } else {
                userId.Value = uint(-1);
            }

            CGameScoreAndLeaderBoardManagerScript@ scoreMgr = network.ClientManiaAppPlayground.ScoreMgr;
            string gamemodeid = 'TimeAttack';
            if (gamemode == GameMode::RaceClones) {
                gamemodeid = 'TimeAttackClone';
            } else if (gamemode == GameMode::Stunt) {
                gamemodeid = 'Stunt';
            } else if (gamemode == GameMode::Platform) {
                gamemodeid = 'Platform';
            } else if (gamemode == GameMode::Royal) {
                return;
            }
            cast<PbMedal>(MedalsList::pb.medal).updateIfNeeded(scoreMgr.Map_GetRecord_v2(userId, currentMap, "PersonalBest", "", gamemodeid, ""), currentMap);
        }
#elif MP4
        if (network.TmRaceRules !is null && network.TmRaceRules.ScoreMgr !is null) {
            // this method only works in solo
            CGameScoreAndLeaderBoardManagerScript@ scoreMgr = network.TmRaceRules.ScoreMgr;
            cast<PbMedal>(MedalsList::pb.medal).updateIfNeeded(scoreMgr.Map_GetRecord(network.PlayerInfo.Id, currentMap, ""), currentMap);
        } else {
            // on servers
            
            // todo: maybe do whatever Ultimate Medals does with local replays

            // check session pb
            if (playground !is null && playground.GameTerminals.Length > 0 &&
                cast<CTrackManiaPlayer>(playground.GameTerminals[0].GUIPlayer) !is null &&
                cast<CTrackManiaPlayer>(playground.GameTerminals[0].GUIPlayer).Score !is null) {
                    uint sessionPb = uint(cast<CTrackManiaPlayer>(playground.GameTerminals[0].GUIPlayer).Score.BestTime);
                    cast<PbMedal>(MedalsList::pb.medal).updateIfNeeded(sessionPb, currentMap);
            }
        }
#elif TURBO
        if (network.TmRaceRules !is null && needCheckTurboPb) {
            network.TmRaceRules.DataMgr.RetrieveRecordsNoMedals(currentMap, network.PlayerInfo.Id);
            startnew(FindTurboPB, network.TmRaceRules.DataMgr);
        }
#endif
    }

#if TURBO
    void FindTurboPB(ref@ d) {
        yield();
        auto dataMgr = cast<CGameDataManagerScript>(d);
        if ((dataMgr) !is null) {
            for (uint i = 0; i < dataMgr.Records.Length; i++) {
                if (dataMgr.Records[i].GhostName == "Solo_BestGhost") {
                    cast<PbMedal>(MedalsList::pb.medal).updateIfNeeded(dataMgr.Records[i].Time, currentMap);
                    needCheckTurboPb = false;
                    break;
                }
            }
        }
    }
#endif
}
