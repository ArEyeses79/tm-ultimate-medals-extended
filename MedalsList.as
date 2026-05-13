
namespace MedalsList {
    array<MedalWrapper@> Medals = {};
    MedalWrapper@ pb = null;
    MedalWrapper@ session = null;
    MedalWrapper@ previous = null;

    MedalWrapper@ author = null;
    MedalWrapper@ trackmaster = null;
    MedalWrapper@ gold = null;
    MedalWrapper@ silver = null;
    MedalWrapper@ bronze = null;

    void addMedal(UltimateMedalsExtended::IMedal@ medal) {
        // if the plugin is disabled, it wouldn't have done its initial setup yet
        if (!hasCalledMain) {
            Main();
        }

        MedalWrapper@ mt = MedalWrapper(medal);
        if (cast<PbMedal>(mt.medal) !is null) {
            @pb = mt;
        } else if (mt.config.defaultName == "Session") {
            @session = mt;
        } else if (mt.config.defaultName == "Previous") {
            @previous = mt;
#if TURBO
        } else if (mt.config.defaultName == "Trackmaster") {
#else
        } else if (mt.config.defaultName == "Author") {
#endif
            @author = mt;
        } else if (mt.config.defaultName == "Gold") {
            @gold = mt;
        } else if (mt.config.defaultName == "Silver") {
            @silver = mt;
        } else if (mt.config.defaultName == "Bronze") {
            @bronze = mt;
        }
        for (uint i = 0; i < Medals.Length; i++) {
            if (Medals[i].config.defaultName == mt.config.defaultName) {
                if (Medals[i] is pb) {
                    throw('Cannot replace pb medal with non-pb medal');
                }
                Medals[i] = mt;
                return;
            }
        }
        Medals.InsertLast(mt);
        if (MapData::currentMap != '') {
            mt.onNewMap(MapData::currentMap);
        }
    }
    // MedalWrapper@ getMedal(const string &in defaultName) {
    //     for (uint i = 0; i < Medals.Length; i++) {
    //         if (Medals[i].config.defaultName == defaultName) {
    //             return Medals[i];
    //         }
    //     }
    //     return null;
    // }
    bool hasMedal(const string &in defaultName) {
        for (uint i = 0; i < Medals.Length; i++) {
            if (Medals[i].config.defaultName == defaultName) {
                return true;
            }
        }
        return false;
    }
    bool removeMedal(const string &in defaultName) {
        for (uint i = 0; i < Medals.Length; i++) {
            if (Medals[i].config.defaultName == defaultName) {
                if (Medals[i] is pb) {
                    @pb = null;
                }
                Medals.RemoveAt(i);
                return true;
            }
        }
        return false;
    }

    bool IsMedalEnabled(const string &in defaultName) {
        for (uint i = 0; i < Medals.Length; i++) {
            if (Medals[i].config.defaultName == defaultName) {
                return Medals[i].enabled;
            }
        }
        return false;
    }

    void onNewMap(const string &in uid) {
        for (uint i = 0; i < Medals.Length; i++) {
            Medals[i].onNewMap(uid);
        }
    }

    bool CheckRender() {
        bool visible = false;
        for (uint i = 0; i < Medals.Length; i++) {
            if (Medals[i].enabled) {
                Medals[i].refreshMedal(MapData::currentMap);
                if (Medals[i].enabled && Medals[i].hasMedalTime()) {
                    visible = true;
                }
            }
        }
        if (updated) {
            updated = false;
            Medals.SortAsc();
        }
        return visible;
    }

    void Render() {

        int numcols = 2;
        if (showMedalNames) {
            numcols++;
        }
        if (showDelta) {
            numcols++;
        }
        if (UI::BeginTable("medals", numcols, UI::TableFlags::SizingFixedFit)) {
            if (showColumns) {
                UI::TableNextRow();
                UI::TableNextColumn();
                // icon
                if (showMedalNames) {
                    UI::TableNextColumn();
                    UI::Text("Medal");
                }
                UI::TableNextColumn();
                if (MapData::gamemode == GameMode::Stunt) {
                    UI::Text("Points");
                } else if (MapData::gamemode == GameMode::Platform) {
                    UI::Text("Respawns");
                } else {
                    UI::Text("Time");
                }
                if (showDelta && pb.hasMedalTime()) {
                    UI::TableNextColumn();
                    UI::Text("Delta");
                }
            }
            for (uint i = 0; i < Medals.Length; i++) {
                Medals[i].RenderRow();
            }

            UI::EndTable();
        }
    }

    void RenderSettings() {
        UI::BeginTable("settings", 5, UI::TableFlags::SizingFixedFit);
        UI::TableNextRow();
        UI::TableNextColumn();
        UI::Text('Medal');
        UI::TableNextColumn();
        UI::Text('Display Name');
        UI::TableNextColumn();
        UI::Text('Enabled');
        UI::TableNextColumn();
        UI::Dummy(vec2(32, 0));
        UI::TableNextColumn();
        UI::Text('2-Layer Icon');

        for (uint i = 0; i < Medals.Length; i++) {
            Medals[i].RenderSettings();
        }
        UI::EndTable();
    }
}
