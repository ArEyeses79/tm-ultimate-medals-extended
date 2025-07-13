[Setting category="Window" name="Enable plugin window"]
bool showInterface = true;

[Setting category="Window" name="Show map name"]
bool showMapName = true;

#if DEPENDENCY_NADEOSERVICES
[Setting category="Window" name="Show map author original name"]
bool showMapAuthor = true;

[Setting category="Window" name="Show map author current name"]
bool showCurrentAuthorName = true;
#else
[Setting category="Window" name="Show map author"]
bool showMapAuthor = true;

// ensure it doesn't crash from this missing
bool showCurrentAuthorName = false;
#endif

[Setting category="Window" name="Show map comment" description="An 'i' icon will appear if the map has a comment"]
bool showComment = true;

[Setting category="Window" name="Remove map/author name colors"]
bool removeColors = false;

[Setting category="Window" name="Show column titles"]
bool showColumns = true;

[Setting category="Window" name="Show medal names"]
bool showMedalNames = true;

[Setting category="Window" name="Show medal name colors" if="showMedalNames"]
bool showMedalNameColors = true;

[Setting category="Window" name="Show delta time"]
bool showDelta = true;

[Setting category="Window" name="Toggle with interface"]
bool requireInterface = false;

[Setting category="Window" name="Toggle with Openplanet overlay"]
bool requireOverlay = false;

[Setting category="Window" name="Show in validation" description="\\$ff0\\$z Currently doesn't update until you exit validation"]
bool showValidation = true;

[Setting category="Window" name="Show in replay editor"]
bool showReplayEditor = false;

#if TMNEXT
[Setting category="Window" name="Show 'session best/previous run' when enabled but blank"
description="It will only show if it's different to PB and won't show on servers unless you have MLFeed installed and enabled"]
#else
[Setting category="Window" name="Show 'session best/previous run' when enabled but blank"
description="It will only show if it's different to PB"]
#endif
bool showSessionBlank = true;

#if TMNEXT
[Setting category="Window" name="Show icon overlays"]
bool showIconOverlays = true;
#endif

[Setting category="Window" name="Location"]
vec2 windowPos = vec2(0, 170);

[Setting category="Window" name="Allow dragging"]
bool windowDrag = false;


// maybe custom font? Not sure if anyone uses that in ultimate medals

void RenderMenu() {
    if (UI::MenuItem("\\$db4" + Icons::Circle + "\\$z Ultimate Medals Extended", "", showInterface)) {
        showInterface = !showInterface;
    }
}

// window shown without table for one frame in order to clear table width bug
bool windowWasShownLastFrame = false;

void Render() {
    if (!showInterface) {
        windowWasShownLastFrame = false;
        return;
    }
    if (requireInterface && !UI::IsGameUIVisible()) {
        windowWasShownLastFrame = false;
        return;
    }
    if (requireOverlay && !UI::IsOverlayShown()) {
        windowWasShownLastFrame = false;
        return;
    }
    
    if (MapData::currentMap == '') {
        windowWasShownLastFrame = false;
        return;
    }
    CGameCtnChallenge@ map = getMap();
    if (map is null) {
        windowWasShownLastFrame = false;
        return;
    }

#if MP4
    auto app = cast<CTrackMania>(GetApp());
    if (app.LoadedManiaTitle !is null && app.LoadedManiaTitle.BaseTitleId == "SMStorm") {
        windowWasShownLastFrame = false;
        return;
    }
#endif

    if (!MedalsList::CheckRender()) {
        windowWasShownLastFrame = false;
        return;
    }

    if (windowDrag) {
        UI::SetNextWindowPos(int(windowPos.x), int(windowPos.y), UI::Cond::Once);
    } else {
        UI::SetNextWindowPos(int(windowPos.x), int(windowPos.y), UI::Cond::Always);
    }
    UI::SetNextWindowSize(0, 0, UI::Cond::Always);
    
    int windowFlags = UI::WindowFlags::NoTitleBar | UI::WindowFlags::NoCollapse | UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoDocking;
    if (!UI::IsOverlayShown()) {
            windowFlags |= UI::WindowFlags::NoInputs;
    }

    UI::Begin("Ultimate Medals Extended", windowFlags);
    windowPos = vec2(UI::GetWindowPos().x/UI::GetScale(), UI::GetWindowPos().y/UI::GetScale());

    if (!windowWasShownLastFrame) {
        windowWasShownLastFrame = true;
        UI::End();
        return;
    }

    if (showMapName || showMapAuthor || showCurrentAuthorName) {
        UI::BeginGroup();
        if (UI::BeginTable("header", 1, UI::TableFlags::SizingFixedFit)) {
            if (showMapName) {
                UI::TableNextRow();
                UI::TableNextColumn();
                string name = map.MapName;
                if (name == "") {
                    name = map.MapInfo.NameForUi;
                }
#if TURBO
                if (map.AuthorLogin == "Nadeo") {
                    name = "#" + name;
                }
#endif
                if (removeColors) {
                    UI::Text(Text::StripFormatCodes(name));
                } else {
                    UI::Text(Text::OpenplanetFormatCodes(name));
                }
                if (showComment && !(showMapAuthor || showCurrentAuthorName) && map.Comments.Length > 0) {
                    UI::SameLine();
                    UI::Text('\\$68f' + Icons::InfoCircle);
                }
            }
            if (showMapAuthor || showCurrentAuthorName) {
                UI::TableNextRow();
                UI::TableNextColumn();
                string authorName = map.AuthorNickName;

#if DEPENDENCY_NADEOSERVICES
                if (showCurrentAuthorName && authorName != "Nadeo") {
                    const string name = Accounts::GetAuthorName(MapData::currentMap);
                    if (name.Length > 0 && name != authorName) {
                        if (!showMapAuthor) {
                            authorName = name;
                        } else {
                            authorName += ' (' + name + ')';
                        }
                    }
                }
#endif

                if (removeColors) {
                    UI::TextDisabled('By ' + Text::StripFormatCodes(authorName));
                } else {
                    UI::TextDisabled('By ' + Text::OpenplanetFormatCodes(authorName));
                }
                if (showComment && map.Comments.Length > 0) {
                    UI::SameLine();
                    UI::Text('\\$68f' + Icons::InfoCircle);
                }
            }
            UI::EndTable();
        }

        UI::EndGroup();

        if (showComment && map.Comments.Length > 0 && UI::IsItemHovered()) {
            UI::BeginTooltip();
            UI::PushTextWrapPos(200);
            UI::TextWrapped(map.Comments);
            UI::PopTextWrapPos();
            UI::EndTooltip();
        }
    }

    MedalsList::Render();

    UI::End();
    
}

[SettingsTab name="Medals"]
void RenderSettings() {
    MedalsList::RenderSettings();
}