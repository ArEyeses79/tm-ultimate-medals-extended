
# Ultimate Medals Extended
## wow another medals plugin
Unlike Ultimate Medals, (which only shows ingame medals) and Ultimate Medals++ (which has to code in any extra medals it shows), Ultimate Medals Extended is designed so that each medal plugin can add a medal to it. This way, it can automatically support any new medal plugin that is created.

### Builtin medals:
- Personal Best
- Author
- Gold
- Silver
- Bronze
- Default Gold
- Default Silver (disabled)
- Default Bronze (disabled)
- Session best (disabled)
- Previous run (disabled)
### Supporting plugins:
- Warrior Medals
- Copium
- Champion Medals


## Exports
To use Ultimate Medals Extended as a dependency, you need to define a class implementing the `UltimateMedalsExtended::IMedal` interface
(defined and documented in Medals/IMedal.as).
You then pass it to `UltimateMedalsExtended::AddMedal`. (The other exports from are defined in Exports.as).
You must ensure that you remove medals when `OnDestroyed` is called, using `UltimateMedalsExtended::RemoveMedal(name)`, otherwise both plugins will crash if your plugin is reloaded / updated.


### Example usage as a dependency
In this example, the value of `exampleMedal` is set inside example medal plugin and is 0 when not avaliable.  
And it uses an internal variable `currentUID` for the map it has current example medal data for  
Note that 

```
#if DEPENDENCY_ULTIMATEMEDALSEXTENDED

class ExampleMedal : UltimateMedalsExtended::IMedal {
    UltimateMedalsExtended::Config GetConfig() override {
        UltimateMedalsExtended::Config c;
        c.defaultName = "Example Medal";
        c.icon = "\\$f0f" + Icons::Circle;
        return c;
    }

    void UpdateMedal(const string &in uid) override {}

    bool HasMedalTime(const string &in uid) override {
        return currentUID == uid && exampleMedal != 0;
    }
    uint GetMedalTime() override {
        return exampleMedal;
    }
}

void OnDestroyed() {
    UltimateMedalsExtended::RemoveMedal("Example Medal");
}

#endif
```

and in Main():

```
#if DEPENDENCY_ULTIMATEMEDALSEXTENDED
    UltimateMedalsExtended::AddMedal(ExampleMedal());
#endif
```

