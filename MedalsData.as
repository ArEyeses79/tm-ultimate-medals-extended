
namespace MedalsData {
    const string medalsDataFileName = IO::FromStorageFolder('medalsData.json');

    /*
    * medals data (including medals from exports)
    * 'id' is default medal name (required if the medal has any data)
    * 'enabled' is if the medal is enabled
    * 'name' is the custom medal name
    */
    Json::Value@ medalsData;

    /* save/load functions */
    void loadMedalsData() {
        if (IO::FileExists(medalsDataFileName)) {
            @medalsData = Json::FromFile(medalsDataFileName);
            if (medalsData.GetType() == Json::Type::Null) {
                warn('null medalsdata in file, resetting');
                @medalsData = Json::Array();
            }
        } else {
            @medalsData = Json::Array();
        }
    }
    void saveMedalsData() {
        if (medalsData is null) {
            // I believe this happens if the plugin is disabled
            trace('medalsdata not initialised, not saving');
            return;
        }
        if (medalsData.GetType() == Json::Type::Null) {
            warn('null medalsdata, not saving');
            return;
        }
        Json::ToFile(medalsDataFileName, medalsData);
    }

    /* utility functions */
    Json::Value@ _getOrAddMedalsData(const string &in medalId) {
        for (uint i = 0; i < medalsData.Length; i++) {
            if (medalsData[i]['id'] == medalId) {
                return medalsData[i];
            }
        }
        Json::Value@ md = Json::Object();
        md['id'] = medalId;
        medalsData.Add(md);
        return medalsData[medalsData.Length - 1];
    }

    /* update saved data functions (called when a medal changes its data) */

    // enables a medal if it has data saying its disabled (if no data, its enabled by default anyway)
    void enableMedal(const string &in medalId) {
        Json::Value@ md = _getOrAddMedalsData(medalId);
        md['enabled'] = true;
    }
    // disables a medal, creating medal data if needed
    void disableMedal(const string &in medalId) {
        Json::Value@ md = _getOrAddMedalsData(medalId);
        md['enabled'] = false;
    }

    // renames a medal, creating medal data if needed
    void renameMedal(const string &in medalId, const string &in name) {
        Json::Value@ md = _getOrAddMedalsData(medalId);
        if (name == medalId) {
            if (md.HasKey('name')) {
                md.Remove('name');
            }
        } else {
            md['name'] = name;
        }
    }

    // enables a medal's overlay if it has data saying its disabled (if no data, its enabled by default anyway)
    void enableMedalOverlay(const string &in medalId) {
        Json::Value@ md = _getOrAddMedalsData(medalId);
        md['overlay'] = true;
    }
    // disables a medal's overlay, creating medal data if needed
    void disableMedalOverlay(const string &in medalId) {
        Json::Value@ md = _getOrAddMedalsData(medalId);
        md['overlay'] = false;
    }


    /* get saved data functions (called when creating a new medal) */

    // gets the name for a medal
    string getMedalName(const string &in medalId) {
        for (uint i = 0; i < medalsData.Length; i++) {
            if (medalsData[i]['id'] == medalId) {
                if (medalsData[i].HasKey('name')) {
                    if (medalsData[i]['name'].GetType() == Json::Type::String) {
                        return medalsData[i]['name'];
                    } else {
                        medalsData[i].Remove('name');
                    }
                }
                break;
            }
        }
        int index = medalId.IndexOf('##');
        if (index != -1) {
            return medalId.SubStr(0, index);
        }
        return medalId;
    }
    // gets if a medal is enabled
    bool isMedalEnabled(const string &in medalId, bool startEnabled) {
        for (uint i = 0; i < medalsData.Length; i++) {
            if (medalsData[i]['id'] == medalId) {
                if (medalsData[i].HasKey('enabled')) {
                    if (medalsData[i]['enabled'].GetType() == Json::Type::Boolean) {
                        return medalsData[i]['enabled'];
                    } else {
                        medalsData[i].Remove('enabled');
                    }
                }
                return startEnabled;
            }
        }
        return startEnabled;
    }
    // gets if a medal has its overlay enabled
    bool isMedalOverlayEnabled(const string &in medalId, bool startEnabled) {
        for (uint i = 0; i < medalsData.Length; i++) {
            if (medalsData[i]['id'] == medalId) {
                if (medalsData[i].HasKey('overlay')) {
                    if (medalsData[i]['overlay'].GetType() == Json::Type::Boolean) {
                        return medalsData[i]['overlay'];
                    } else {
                        medalsData[i].Remove('overlay');
                    }
                }
                return startEnabled;
            }
        }
        return startEnabled;
    }
}

void OnSettingsSave(Settings::Section& section) {
    MedalsData::saveMedalsData();
}