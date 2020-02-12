//made by boringcactus
//derived from https://github.com/Coltaho/Autosplitters/blob/master/MegaManZero3/MMZ3autosplit.asl

state("Sayonara Wild Hearts"){}

startup {
    settings.Add("anypct", true, "Any% (split when level changes; only works in Album Arcade)");
    settings.Add("allriddles", false, "All Riddles (split when riddle status changes)");
    settings.Add("riddle0", true, "Aries A", "allriddles");
    settings.Add("riddle1", true, "Taurus A", "allriddles");
    settings.Add("riddle2", true, "Gemini A", "allriddles");
    settings.Add("riddle3", true, "Cancer A", "allriddles");
    settings.Add("riddle4", true, "Leo A", "allriddles");
    settings.Add("riddle5", false, "Virgo A", "allriddles");
    settings.Add("riddle6", true, "Libra A", "allriddles");
    settings.Add("riddle7", true, "Scorpius A", "allriddles");
    settings.Add("riddle8", true, "Sagittarius A", "allriddles");
    settings.Add("riddle9", true, "Capricornus A", "allriddles");
    settings.Add("riddle10", true, "Aquarius A", "allriddles");
    settings.Add("riddle11", true, "Pisces A", "allriddles");
    settings.Add("riddle12", false, "Aries B", "allriddles");
    settings.Add("riddle13", false, "Taurus B", "allriddles");
    settings.Add("riddle14", false, "Gemini B", "allriddles");
    settings.Add("riddle15", true, "Cancer B", "allriddles");
    settings.Add("riddle16", true, "Leo B", "allriddles");
    settings.Add("riddle17", true, "Virgo B", "allriddles");
    settings.Add("riddle18", true, "Libra B", "allriddles");
    settings.Add("riddle19", true, "Scorpius B", "allriddles");
    settings.Add("riddle20", true, "Sagittarius B", "allriddles");
    settings.Add("riddle21", true, "Capricornus B", "allriddles");
    settings.Add("riddle22", true, "Aquarius B", "allriddles");
    settings.Add("riddle23", false, "Pisces B", "allriddles");
    
    vars.findpointers = (Action<Process, int>)((proc, mymodulesize) => {
        print("--Scanning for pointers!--");
        
        vars.menuinstance = IntPtr.Zero;
        vars.gameprofile = IntPtr.Zero;
        vars.scorehandler = IntPtr.Zero;
        
        var menuscantest = new SigScanTarget(60, "55488bec5657488bf14883ec2049bb????????????????41ffd34883c42085c07418488bce4883ec2049bb????????????????41ffd34883c42048b8????????????????");
        var profilescantest = new SigScanTarget(11, "55488BEC564883EC0848B8????????????????488B004885C00F85????????48B9????????????????4883EC2049BB????????????????41FFD34883C420488945F0488BC833D24883EC2049BB????????????????");
        var mainlogicscantest = new SigScanTarget(0x8E, "55488bec4883ec1048894df80fb645f885c00f8474000000");
        var menuptr = IntPtr.Zero;
        var profileptr = IntPtr.Zero;
        var mainlogicptr = IntPtr.Zero;

        foreach (var page in proc.MemoryPages()) {
            var scanner = new SignatureScanner(proc, page.BaseAddress, (int)page.RegionSize);       
            if(menuptr == IntPtr.Zero) {
                menuptr = scanner.Scan(menuscantest);
            }
            if (profileptr == IntPtr.Zero) {
                profileptr = scanner.Scan(profilescantest);
            }
            if (mainlogicptr == IntPtr.Zero) {
                mainlogicptr = scanner.Scan(mainlogicscantest);
            }
            if (menuptr != IntPtr.Zero && profileptr != IntPtr.Zero && mainlogicptr != IntPtr.Zero) {
                break;
            }
        }
        
        if (menuptr == IntPtr.Zero || profileptr == IntPtr.Zero || mainlogicptr == IntPtr.Zero)
            throw new Exception("--Couldn't find a pointer I want! Something's on fire!");
        
        menuptr = (IntPtr)proc.ReadValue<ulong>((IntPtr)menuptr);
        vars.menuinstance = proc.ReadValue<ulong>((IntPtr)menuptr);
        profileptr = (IntPtr)proc.ReadValue<ulong>((IntPtr)profileptr);
        vars.gameprofile = proc.ReadValue<ulong>((IntPtr)profileptr);
        mainlogicptr = (IntPtr)proc.ReadValue<ulong>((IntPtr)mainlogicptr);
        mainlogicptr = (IntPtr)proc.ReadValue<ulong>((IntPtr)mainlogicptr);
        vars.scorehandler = (IntPtr)proc.ReadValue<ulong>((IntPtr)mainlogicptr + 0xC0);
    });
    
    vars.GetWatcherList = (Func<IntPtr, IntPtr, IntPtr, MemoryWatcherList>)((menuinstance, gameprofile, scorehandler) => {
        return new MemoryWatcherList
        {
            new MemoryWatcher<int>((IntPtr)menuinstance + 0xCF4) { Name = "level" },
            new MemoryWatcher<int>((IntPtr)menuinstance + 0xE04) { Name = "menuviewstate" },
            new MemoryWatcher<int>((IntPtr)gameprofile + 0x20) { Name = "achievements" },
            new MemoryWatcher<int>((IntPtr)scorehandler + 0x84) { Name = "score" },
        };
    });
}

init {
    vars.menuinstance = IntPtr.Zero;
    vars.gameprofile = IntPtr.Zero;
    vars.watchers = new MemoryWatcherList();
    
    vars.findpointers(game, modules.First().ModuleMemorySize);
    vars.watchers = vars.GetWatcherList((IntPtr)vars.menuinstance, (IntPtr)vars.gameprofile, (IntPtr)vars.scorehandler);
}

start {
    return vars.watchers["menuviewstate"].Changed && vars.watchers["menuviewstate"].Current == 7;
}

update {
    vars.watchers.UpdateAll(game);
}

reset {
    if (settings["anypct"]) {
        return vars.watchers["level"].Current == 24;
    }
}

split {
    if (settings["anypct"]) {
        bool nextLevel = vars.watchers["level"].Changed && vars.watchers["level"].Current != 1;
        bool unbrokeHeart = vars.watchers["score"].Changed && vars.watchers["score"].Current == vars.watchers["score"].Old + 100000;
        return nextLevel || unbrokeHeart;
    } else if (settings["allriddles"]) {
        if (vars.watchers["achievements"].Changed) {
            var delta = vars.watchers["achievements"].Current ^ vars.watchers["achievements"].Old;
            var id = Convert.ToString(delta, 2).Length - 1;
            return settings["riddle" + id];
        }
    }
}
