
namespace UltimateMedalsExtended {

    // Adds a medal. If a medal with that name already exists, it is overwritten
    import void AddMedal(IMedal@ medal) from "UltimateMedalsExtended";

    import bool RemoveMedal(const string &in defaultName) from "UltimateMedalsExtended";

    // if a medal name already exists
    import bool HasMedal(const string &in defaultName) from "UltimateMedalsExtended";

    // if a medal name is enabled
    import bool IsMedalEnabled(const string &in defaultName) from "UltimateMedalsExtended";

    /*
     * exports for plugins which want to display in editor
     * and need to know the medal times from the current validation session (or before)
     */

    /*
     * whether the current map is in editor validate mode
     * (and the setting to show in validation is enabled)
     */
    import bool IsEditorValidation() from "UltimateMedalsExtended";

    /*
     * gets whether the ingame medals will be valid/displayed for the current map
     * in normal play this should be always true
     * in editor validation, this is true if either the map was already validated or if there is a session pb
     * *warning* the return value from this function is whether the medals will be valid *after* UpdateMedal,
     * so don't access the medal times during UpdateMedal; wait until GetMedalTime instead
     * (this is best practice anyway since medal times can change during editor validation)
     */
    import bool HasIngameMedals() from "UltimateMedalsExtended";

    /*
     * gets the time currently displayed for author medal (or trackmaster in turbo)
     * only valid if HasIngameMedals returns true
     */
    import uint GetAuthorMedal() from "UltimateMedalsExtended";
    /*
     * gets the time currently displayed for gold medal
     * only valid if HasIngameMedals returns true
     */
    import uint GetGoldMedal() from "UltimateMedalsExtended";
    /*
     * gets the time currently displayed for silver medal
     * only valid if HasIngameMedals returns true
     */
    import uint GetSilverMedal() from "UltimateMedalsExtended";
    /*
     * gets the time currently displayed for bronze medal
     * only valid if HasIngameMedals returns true
     */
    import uint GetBronzeMedal() from "UltimateMedalsExtended";

    /*
     * gets the session best time
     * a value of uint(-1) is used when no time is stored
     * if IsEditorValidation() is true, finishes will always be tracked
     * otherwise, finishes are only tracked when one of the relevant medals is enabled
     */
    import uint GetSessionBest() from "UltimateMedalsExtended";
    /*
     * gets the previous run time
     * a value of uint(-1) is used when no time is stored
     * if IsEditorValidation() is true, finishes will always be tracked
     * otherwise, finishes are only tracked when one of the relevant medals is enabled
     */
    import uint GetPreviousRun() from "UltimateMedalsExtended";
}