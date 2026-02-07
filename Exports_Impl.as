
namespace UltimateMedalsExtended {

    void AddMedal(IMedal@ medal) {
        MedalsList::addMedal(medal);
    }

    bool RemoveMedal(const string &in defaultName) {
        return MedalsList::removeMedal(defaultName);
    }

    bool HasMedal(const string &in defaultName) {
        return MedalsList::hasMedal(defaultName);
    }

    bool IsMedalEnabled(const string &in defaultName) {
        return MedalsList::IsMedalEnabled(defaultName);
    }

    bool IsEditorValidation() {
        return MapData::currentMap != '' && MapData::validationMode;
    }

    bool HasIngameMedals() {
        return MapData::currentMap != '' && _hasIngameMedals();
    }

    uint GetAuthorMedal() {
        MedalWrapper@ m = MedalsList::author;
        if (m is null) {
            warn('Author medal not found, was it removed by another plugin?');
            return uint(-1);
        }
        return m.getMedalTime();
    }
    uint GetGoldMedal() {
        MedalWrapper@ m = MedalsList::gold;
        if (m is null) {
            warn('Gold medal not found, was it removed by another plugin?');
            return uint(-1);
        }
        return m.getMedalTime();
    }
    uint GetSilverMedal() {
        MedalWrapper@ m = MedalsList::silver;
        if (m is null) {
            warn('Silver medal not found, was it removed by another plugin?');
            return uint(-1);
        }
        return m.getMedalTime();
    }
    uint GetBronzeMedal() {
        MedalWrapper@ m = MedalsList::bronze;
        if (m is null) {
            warn('Bronze medal not found, was it removed by another plugin?');
            return uint(-1);
        }
        return m.getMedalTime();
    }

    uint GetSessionBest() {
        return PreviousRun::session;
    }
    uint GetPreviousRun() {
        return PreviousRun::previous;
    }

}