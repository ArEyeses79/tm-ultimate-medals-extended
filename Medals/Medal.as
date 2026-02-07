
abstract class Medal : UltimateMedalsExtended::IMedal {
    UltimateMedalsExtended::Config GetConfig() override { return UltimateMedalsExtended::Config(); }
    uint medalTime;

    // would be abstract if that existed in angelscript
    void UpdateMedal(const string &in uid) override {}

    bool HasMedalTime(const string &in uid) override {
        return _hasIngameMedals();
    }
    uint GetMedalTime() override {
        return this.medalTime;
    }
}
bool _hasIngameMedals() {
    if (MapData::validationMode) {
        return PreviousRun::session != uint(-1) || MapData::validated;
    }
    return true;
}

abstract class DefaultMedal : Medal {
    bool validMedal = false;

    bool HasMedalTime(const string&in uid) override {
        if (MapData::validationMode) {
            if (!MapData::validated) {return false;}
            if (!(PreviousRun::session == uint(-1) || (MapData::highBetter ^^ getMap().TMObjective_AuthorTime < PreviousRun::session))) {
                return false;
            }
        }
        return validMedal;
    }
}
