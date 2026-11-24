## Main Menu 1.2.1

A controller-first game launcher for iPhone, built for landscape.

### What's new in 1.2.1
- **Shortcut setup guide** in Settings, with a one-tap install of the shared `Main Menu Launch` Shortcut, a button to build it yourself, and a test button.
- The App Store search in the Library now shows what it is doing (searching, number of results, or an error).

### What's new since 1.1
- **Console-style home.** A single row of game tiles, big poster art, and the selected game's name and launch method underneath.
- **Game art from SteamGridDB.** Paste a free API key in Settings and posters are fetched automatically. In a game's editor, "Choose game art" lets you search a title and pick a different poster.
- **Search the whole App Store** from the Library to add any game, not only the ones in the URL scheme list.
- **External display.** Plug the phone into a monitor (USB-C or AirPlay) and Main Menu fills the screen. The phone drops to a black, minimum-brightness standby and stays awake. Tap it to wake for 20 seconds, or turn this off in Settings.
- **One shared Shortcut** for games without a URL scheme, instead of one Shortcut per game.
- Each build now has its own version number, so Feather and Birds Eye show updates.

### Setting up the shared Shortcut (once)
1. Open Shortcuts and create a new shortcut named exactly `Main Menu Launch`.
2. Add the action **Open App** and set its app to the **Shortcut Input** variable.
3. In each game's editor, set "App name for the Shortcut" to the name under the game's icon on your Home Screen.

Games with a URL scheme, such as Genshin Impact, launch directly and don't need the Shortcut.

### Install
This is an unsigned IPA. Import it into Feather and sign it, or add the Birds Eye source to get it with updates. The bundle ID is `dev.elder.mainmenu`, so it installs next to older builds that used a different ID.

### Controls
D-pad or left stick to move, A to launch or select, X and Y for the extra actions shown in the bottom bar, B or Menu to go home, LB and RB to switch tabs.
