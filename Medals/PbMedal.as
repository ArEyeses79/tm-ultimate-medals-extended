
class PbMedal : UltimateMedalsExtended::IMedal {
    UltimateMedalsExtended::Config GetConfig() override {
        UltimateMedalsExtended::Config c;
        c.defaultName = 'Pers. Best';
        c.icon = '\\$444' + Icons::Circle;
        c.nameColor = '\\$0ff';
        c.sortPriority = 127;
        c.usePreviousIcon = true;
        c.usePreviousColor = true;
        c.usePreviousOverlayIcon = true;
        c.usePreviousOverlayColor = true;
        c.shareIcon = false;
        c.allowUnset = true;
        return c;
    }

    // time of pb, uint(-1) for no pb yet
    uint medalTime = uint(-1);
    // if concept of pb is valid for this map (so not in editor)
    bool validMedalTime = false;
    string lastUid = '';

    void UpdateMedal(const string&in uid) override {
        if (uid != this.lastUid) {
            this.medalTime = uint(-1);
            this.lastUid = uid;
        }

        CGameCtnApp@ app = GetApp();

        if (app.Editor is null &&
#if TMNEXT
            app.Network.ClientManiaAppPlayground !is null &&
#endif
            !(MapData::gamemode == GameMode::Royal)) {
                this.validMedalTime = true;
        } else {
            this.validMedalTime = false;
        }
    }

    // special function for pb
    bool updateIfNeeded(uint newPb, const string &in uid) {
        if (newPb == this.medalTime) {return false;}
        if ((this.medalTime == uint(-1) && newPb != uint(-1)) || ((newPb < this.medalTime) ^^ MapData::highBetter)) {
            this.medalTime = newPb;
            return true;
        }
        return false;
    }

    bool HasMedalTime(const string&in uid) override {
#if TURBO
        if (GetApp().PlaygroundScript is null) {
            return false;
        }
#endif
        return this.validMedalTime;
    }
    uint GetMedalTime() override {
        return this.medalTime;
    }
}
