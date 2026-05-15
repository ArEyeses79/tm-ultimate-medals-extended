namespace UltimateMedalsExtended {
    shared class Config {
        // the medal identifier, required. Custom name settings are done through UME settings.
        // names may use ##... to add an identifier at the end of a name to distinguish 2 otherwise identical names; the ## and anything after is not included in the default display name
        string defaultName = '';

        // the color and icon used for the medal icon
        string icon = '';

        // the color and icon used for the 2nd medal icon drawn on top of the normal icon
        string iconOverlay = '';

        // if the medal is enabled in UME by default
        bool startEnabled = true;

        // custom color applied to the medal name and time (used for pb)
        string nameColor = '';

        /*
         * if this medal wins ties for equal times
         * most medals are 63, this is the default
         * pb medal is 127 (since if pb is equal to a medal then it obtains it)
         * records should be around 191 (since tie-ing a record doesn't beat it)
         */
        uint8 sortPriority = 63;

        /*
         * use the icon shape from the closest worse medal if any (otherwise its own icon)
         * medals with shareIcon false will be skipped
         * e.g. how pb medal shows the previous medal symbol as its icon
         */
        bool usePreviousIcon = false;
        // similar to usePreviousIcon but for iconOverlay
        bool usePreviousOverlayIcon = false;
        /*
         * use the icon color from the closest worse medal if any (otherwise its own icon)
         * medals with shareIcon false will be skipped
         * e.g. how pb medal uses the previous medal color for its icon
         */
        bool usePreviousColor = false;
        /*
         * similar to usePreviousColor but for iconOverlay
         * if the previous does not have an overlay color, will use its own overlay color
         */
        bool usePreviousOverlayColor = false;

        /*
         * if this medal should be included when a usePrevious medal is looking for the previous medal
         * e.g. if you're adding something that isn't a medal (such as leaderboard positions) with its own custom color/icon
         *     that wouldn't make sense for e.g. pb medal to use as its icon
         */
        bool shareIcon = true;

        // if this medal can have an empty ('unset') but still visible value, using uint(-1), such as pb before first finish
        bool allowUnset = false;

    }


    shared interface IMedal {
        /*
        * the config used for the medal
        * called once when adding the medal
        */
        Config GetConfig();

        /*
        * Will be called the first time your medal is needed on a map
        * (if your medal is off in UME settings it won't be called until/unless it is turned on)
        * May be called extra times, if your medal is always constant you can ignore additional calls with the same uid
        */
        void UpdateMedal(const string &in uid);

        /*
        * whether the medal has a time for the current map
        * e.g. if you use an api request this should return false until the request has finished and you have the medal time
        * the passed uid *should*, but is not guaranteed to, match the uid passed most recently to UpdateMedal
        */
        bool HasMedalTime(const string &in uid);

        // gets the medal's time for the current map
        uint GetMedalTime();

    }
}