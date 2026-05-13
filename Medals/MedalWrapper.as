bool updated = false;
string getEmptyTime() {
    if (MapData::gamemode == GameMode::Stunt) {
        return '\u2212\u2212\u2212\u2212';
    } else if (MapData::gamemode == GameMode::Platform) {
        return '\u2212';
    } else {
        return '\u2212:\u2212\u2212.\u2212\u2212\u2212';
    }
}

class MedalWrapper {
    UltimateMedalsExtended::IMedal@ medal;

    // config settings
    UltimateMedalsExtended::Config config;

    // medal data (duplicate of medalsData)
    bool enabled;
    string name;
    bool overlayEnabled;

    uint cacheTime = 0;
    bool validCacheTime = false;

    string enabledMapCache = '';

    MedalWrapper(UltimateMedalsExtended::IMedal@ medal) {
        @this.medal = medal;
        this.config = this.medal.GetConfig();
        if (this.config.defaultName == '') {
            throw('Medal Config must have a defaultName specified');
        } else if ((this.config.usePreviousIcon || this.config.usePreviousColor || this.config.usePreviousOverlayIcon || this.config.usePreviousOverlayColor) && this.config.shareIcon) {
            warn('Medals using another icon should have sharing their icon disabled');
        }
        this.enabled = MedalsData::isMedalEnabled(this.config.defaultName, this.config.startEnabled);
        this.name = MedalsData::getMedalName(this.config.defaultName);
        this.overlayEnabled = MedalsData::isMedalOverlayEnabled(this.config.defaultName, true);
    }


    // called when loading a new map in case you aren't automatically starting your own api requests
    void onNewMap(const string &in uid) {
        if (!this.enabled) {return;}
        this.enabledMapCache = uid;
        this.medal.UpdateMedal(uid);
    }
    // called when a medal is enabled, to check if it needs to call onNewMap
    void onEnable() {
        if (this.enabledMapCache != MapData::currentMap) {
            this.onNewMap(MapData::currentMap);
        }
    }


    // refresh function called to refresh medals, to check if sorting is needed, before each medal is then accessed in render
    void refreshMedal(const string &in uid) {
        if (!this.enabled) {return;}
        bool wasValidCache = this.validCacheTime;
        this.validCacheTime = this.medal.HasMedalTime(uid);
        if (this.validCacheTime) {
            uint newmedal = this.medal.GetMedalTime();
            if (newmedal != cacheTime || !wasValidCache) {
                updated = true;
                this.cacheTime = newmedal;
            }
        } else {
            this.cacheTime = 0;
        }
    }
    bool hasMedalTime() {
        return this.validCacheTime;
    }
    uint getMedalTime() {
        return this.cacheTime;
    }

    /*
     * compare function to compare 2 medals.
     * if they are equal but one is pb, then pb will be 'better'
     * unset pb will always be 'worse'
     */
    int opCmp(MedalWrapper@ other) final {
        if (!this.validCacheTime) {
            if (!other.validCacheTime) {
                return 0;
            }
            return -1;
        } else if (!other.validCacheTime) {
            return 1;
        }

        if (this.config.allowUnset && this.cacheTime == uint(-1)) {
            // this is pb with no time so should be last
            if (other.config.allowUnset && other.cacheTime == uint(-1)) {
                if (this.config.sortPriority < other.config.sortPriority) {
                    return 1;
                } else if (other.config.sortPriority < this.config.sortPriority) {
                    return -1;
                } else {
                    return this.config.defaultName.opCmp(other.config.defaultName);
                }
            }
            return 1;
        }
        if (other.config.allowUnset && other.cacheTime == uint(-1)) {
            // other is pb with no time so should be last
            return -1;
        }

        if (MapData::highBetter) {
            if (this.cacheTime < other.cacheTime) {
                return 1;
            } else if (this.cacheTime > other.cacheTime) {
                return -1;
            }
        } else {
            if (this.cacheTime > other.cacheTime) {
                return 1;
            } else if (this.cacheTime < other.cacheTime) {
                return -1;
            }
        }
        if (this.config.sortPriority < other.config.sortPriority) {
            return 1;
        } else if (other.config.sortPriority < this.config.sortPriority) {
            return -1;
        } else {
            return this.config.defaultName.opCmp(other.config.defaultName);
        }
    }

    string formatTime(uint time) {
        if (MapData::gamemode == GameMode::Stunt) {
            return tostring(time);
        } else if (MapData::gamemode == GameMode::Platform) {
            return tostring(time);
        } else {
            return Time::Format(time);
        }
    }
    string formatDelta() {
        if (this is MedalsList::pb) {return '';}
        if (this.config.allowUnset && this.cacheTime == uint(-1)) {return '';}
        bool pbValid = MedalsList::pb.hasMedalTime();
        if (!pbValid) {
            // this should be checked before delta column is created
            return '';
        }
        uint pbTime = MedalsList::pb.getMedalTime();
        if (pbTime == uint(-1)) {
            return '\\$777\u2007' + getEmptyTime();
        }

        string color = '';
        if (pbTime == this.cacheTime) {
            color = '\\$777';
        } else if ((pbTime > this.cacheTime) ^^ MapData::highBetter) {
            color = '\\$f77';
        } else {
            color = '\\$77f';
        }
        if (this.cacheTime < pbTime) {
            return color + '+' + this.formatTime(pbTime - this.cacheTime);
        } else if (this.cacheTime > pbTime) {
            return color + '\u2212' + this.formatTime(this.cacheTime - pbTime);
        } else {
            return color + '\u2007' + this.formatTime(0);
        }
    }

    void RenderRow() {
        if (!this.enabled) {return;}
        if (!this.hasMedalTime()) {return;}
        UI::TableNextRow();
        UI::TableNextColumn();
        if (this.config.usePreviousColor || this.config.usePreviousIcon || this.config.usePreviousOverlayColor || this.config.usePreviousOverlayIcon) {
            string icon = '';
            string iconOverlay = '';
            const vec2 pos = UI::GetCursorPos();
            MedalWrapper@ previous = null;
            int i = MedalsList::Medals.Find(this);
            while (i < int(MedalsList::Medals.Length) - 1 && (!MedalsList::Medals[i+1].config.shareIcon || !MedalsList::Medals[i+1].enabled || !MedalsList::Medals[i+1].hasMedalTime())) {
                i++;
            }
            if (i < int(MedalsList::Medals.Length) - 1) {
                @previous = MedalsList::Medals[i+1];
            }
            if (previous is null) {
                icon = this.config.icon;
            } else if (this.config.usePreviousIcon && this.config.usePreviousColor) {
                icon = previous.config.icon;
            } else if (this.config.usePreviousIcon) {
                icon = GetFormatColor(this.config.icon) + Text::StripOpenplanetFormatCodes(previous.config.icon);
            } else if (this.config.usePreviousColor) {
                icon = GetFormatColor(previous.config.icon) + Text::StripOpenplanetFormatCodes(this.config.icon);
            } else {
                icon = this.config.icon;
            }
            UI::Text(icon);
            if ((!this.config.usePreviousOverlayIcon && this.config.iconOverlay != "" && this.overlayEnabled) || (this.config.usePreviousOverlayIcon && previous !is null && previous.config.iconOverlay != "" && previous.overlayEnabled)) {
                if (previous is null) {
                    iconOverlay = this.config.iconOverlay;
                } else if (this.config.usePreviousOverlayIcon && this.config.usePreviousOverlayColor) {
                    iconOverlay = previous.config.iconOverlay;
                } else if (this.config.usePreviousOverlayIcon) {
                    iconOverlay = Text::StripOpenplanetFormatCodes(previous.config.iconOverlay);
                    if (iconOverlay != "") {
                        iconOverlay = GetFormatColor(this.config.iconOverlay) + iconOverlay;
                    }
                } else if (this.config.usePreviousOverlayColor) {
                    iconOverlay = GetFormatColor(previous.config.iconOverlay);
                    if (iconOverlay != "") {
                        iconOverlay += Text::StripOpenplanetFormatCodes(this.config.iconOverlay);
                    } else {
                        iconOverlay = this.config.iconOverlay;
                    }
                } else {
                    iconOverlay = this.config.iconOverlay;
                }
                if (iconOverlay.Length > 0) {
                    UI::SetCursorPos(pos);
                    UI::Text(iconOverlay);
                }
            }
        } else if (this.config.iconOverlay != "" && this.overlayEnabled) {
            const vec2 pos = UI::GetCursorPos();
            UI::Text(this.config.icon);
            UI::SetCursorPos(pos);
            UI::Text(this.config.iconOverlay);
        } else {
            UI::Text(this.config.icon);
        }
        if (showMedalNames) {
            UI::TableNextColumn();
            UI::Text((showMedalNameColors ? this.config.nameColor : "") + this.name);
        } else if (UI::BeginItemTooltip()) {
            UI::Text((showMedalNameColors ? this.config.nameColor : "") + this.name);
            UI::EndTooltip();
        }
        UI::TableNextColumn();
        if (this.config.allowUnset) {
            if (this.cacheTime != uint(-1)) {
                UI::Text(this.config.nameColor + this.formatTime(this.cacheTime));
            } else {
                UI::Text(this.config.nameColor + getEmptyTime());
            }
        } else {
            UI::Text(this.config.nameColor + this.formatTime(this.cacheTime));
        }

        if (showDelta && MedalsList::pb.hasMedalTime()) {
            UI::TableNextColumn();
            UI::Text(this.formatDelta());
        }
    }

    void RenderSettings() final {
        UI::TableNextRow();
        UI::TableNextColumn();
        UI::Text(this.config.defaultName);

        UI::TableNextColumn();
        UI::SetNextItemWidth(200.f);
        string newname = UI::InputText('##na:'+this.config.defaultName, this.name);
        if (newname != this.name) {
            this.name = newname;
            MedalsData::renameMedal(this.config.defaultName, this.name);
        }

        UI::TableNextColumn();
        bool newenabled = UI::Checkbox('##en:'+this.config.defaultName, this.enabled);
        if (newenabled != this.enabled) {
            this.enabled = newenabled;
            if (this.enabled) {
                MedalsData::enableMedal(this.config.defaultName);
                this.onEnable();
            } else {
                MedalsData::disableMedal(this.config.defaultName);
            }
        }

        UI::TableNextColumn();
        UI::TableNextColumn();
        if (this.config.iconOverlay != "") {
            newenabled = UI::Checkbox('##oe:'+this.config.defaultName, this.overlayEnabled);
            if (newenabled != this.overlayEnabled) {
                this.overlayEnabled = newenabled;
                if (this.overlayEnabled) {
                    MedalsData::enableMedalOverlay(this.config.defaultName);
                } else {
                    MedalsData::disableMedalOverlay(this.config.defaultName);
                }
            }
        }
    }
}

const string HEX = '01234567890ABCDEFabcdef';

string GetFormatColor(const string &in text) {
    int i = 0;
    string result = '';
    while (i < text.Length - 1) {
        if (text.SubStr(i, 1) == '\\') {
            i++;
            if (text.SubStr(i, 1) == '$') {
                i++;
                // in a formatting string
                if (HEX.Contains(text.SubStr(i, 1))) {
                    // in a color formatting string
                    // only use the most recent color
                    result = '\\$' + text.SubStr(i, 1);
                    i++;
                    if (HEX.Contains(text.SubStr(i, 1))) {
                        result += text.SubStr(i, 1);
                        i++;
                        if (HEX.Contains(text.SubStr(i, 1))) {
                            result += text.SubStr(i, 1);
                            i++;
                        }
                    }
                }
            }
        }
        i++;
    }
    return result;
}
