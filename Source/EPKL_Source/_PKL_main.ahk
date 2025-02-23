﻿;; ================================================================================================
;;  EPiKaL PKL - EPKL
;;  Portable Keyboard Layout (Máté Farkas, -2010)   [https://github.com/Portable-Keyboard-Layout]
;;  edition DreymaR    (Øystein Bech-Aase, 2015-)   [https://github.com/DreymaR/BigBagKbdTrixPKL]
;; ================================================================================================
;

;;  ####################### user area #######################
/*
TOFIX	- CSGO's problem: We're still not quite out of the woods regarding buffer overflow, it seems.
			- I can't reproduce it on https://keyboardchecker.com/
			- He holds a key for 0.5–1.5 s and it sticks. Longer, and it may not stick?
			- He detects a KeyDown after the KeyUp, that may be the trouble?
				- He deleted all similar key presses in the buffer. That worked for him.
TOFIX	- For the NNO WinLay, it registers SC00D as "1" and SC01B as "0:6"; they should be "1:6" (àá) and "0:1:6" (äâã), resp.?! How come some states get lost?!
			- Might using ToUnicodeEx make a difference?
			- Reverting to listing DKs in the settings sounds like a defeat now...
TOFIX	- SwiSh/FliCK modifiers don't stay active while held but effectivly become one-shot. And AltGr messes w/ them. Happened both on QW_LG and QWRCT.
			- The vmods don't need to be sticky for this to happen.
			- Are they turned off somewhere on release? That'd account for them working only once.
WIP 	- Further getWinLayDKs() development
			- What to do w/ the detect/get/setCurrentWinLayDeadKeys() fns?
			- Get rid of the systemDeadKeys setting, and update setCurrentWinLayDeadKeys() accordingly... unless it's still needed for pkl_Send()?!?
			- Get rid of [DefaultLocaleTxt] and [DeadKeysFromLocID] in EPKL_Tables.ini and all language files?
			- getCurrentWinLayDeadKeys() is checked in pkl_Send(). It's chr based though. Make another dic based on chars, in getWinLayDKs()? But ToAscii doesn't give them?
			- What about pkl_CheckForDKs() in pkl_send.ahk?
TOFIX	- Alt and/or Shift get stuck off, so I can't switch to unread Discord channels by Extend+A+S+U/E ?
WIP 	- Make the Settings GUI write to a Layout_Override.ini, making it from a template in root?
			- Explain therein that it should be used in the layout directories.
TOFIX	- Somehow, the MSKLC Colemak[eD] does ð but not Đ? Others are okay it appears. Affects key mapped (eD2VK, System…) layouts. All other mappings seem okay.
WIP 	- 
*/

;; ================================================================================================
;;  eD TOFIX/WIP:
;	- WIP: 

;	- TOFIX: pkl_init runs through the layout twice. Is that really necessary, or does it simply double startup time?!

;	- TODO: The newLID pklJanitor routine doesn't quite work, since the locale gets preloaded on EPKL startup or smth. Need to restart EPKL then? Or just parts?

;	- TODO: A layout2/3/4 setting in layout files that can define Swish/Flick layers. Allows for instance a Greek layout added as Swish/Flick layers.
;	- TODO: Lockable modifiers would be nice, especially for SwiSh/FliCK. For instance, RCtrl+SwiSh could lock/unlock SwiSh.

;	- WIP: For the System layout having state help images makes no sense. Remedy this? Use LayInfo("shiftStates"). But atm, not having the shift states active ruins OS DKs.
;	- WIP: It would be cool to make the Vim Help Sheet for Colemak available as a state image? Could, e.g., have it on state1 and show it whenever Shift is pressed.
;		- Could fix that using my colemak-vim-helpsheet.svg files.
;		- Ideally, different images depending on ergo mods. At least, ISO/ANS -(A)-- + CA-- + CAWS.
;		- The smallest text on the help image may not render well at the standard help image resolution?

;	- TOFIX: The findWinLayVKs() fn is doing something wrong now? Trying to use the whole SCVKdic produces lots of strange entries...?!
;		- Maybe I'm thinking all wrong about this though! There are two different issues at play: Where the OEM keys actually are, and how to remap keys.
;		- Therefore, OEM keys should probably be treated differently from remapped keys (AZERTY, Cmk-CAWS etc). In some cases, a key can be both! Char-to-VK?
;	- TOFIX: Need to SC remap the OEMdic or layouts with ergo remaps will get it wrong. Example: Ctrl+Z on Angle stopped working when remapping QW_LG VK by SC.
;		- In pkl_init, make a pdic[SC] = VK where SC is the remapped SC codes for the OEM keys, and VK what VK they're mapped to (or -1 if VKey mapped)
;		- And/or a VK(ANSI)-to-VK(OS-layout) remap pdic?
;		- Just detect every single VK code from the OS layout: It'd fix all our VK troubles, and account for such things as my CAWS OS layout.
;	- WIP: Detect OS VK codes for all keys instead of just a select subset, so OS layouts like AZERTY and Colemak-CAWS work as they should.

;	- WIP: With SC remaps, can we now actually remap the System layout? For instance, passthrough the OS layout but add AngleWideSym to it?!?
;		- No, doesn't work; the SC don't get remapped at all. Ah well.
;		- Consider which System mods to support. It may not make sense to add Curl there? But I want the right Extend etc.

;	- TOFIX: In the Layout Selector GUI, choosing first `VK` then `ANS/ISO-Orth` lands you with a faulty selection (`Colemak\Cmk-VK-_` etc).
;		- If choosing it by arrows then proceeding to, say, `ANS`, the error remains. The boxes for Variant and Mods will be blank.
;		- Isn't the GUI updated after choosing KbdType? Doesn't _uiCheckLaySet() find LayVari and LayMods for an `-Orth` KbdType?

;	- WIP: A layout_Override.ini file too? So people (like me) can have a non-version controlled file for their personal layout changes.
;		- Writing to the layout.ini file with the KeyMapper GUI should create an override if not present, like with the other overrides.

;	- TODO: Instead of getLayInfo( "ExtendKey" ), use an array that allows multiple keys to be used as Extend.
;		- Next, specify which layer(s) goes which which key so you can have different Extend keys.

;	- WIP: Bg update according to Kharlamov: Lose duplicate ъ (one on y and one on =+)
;		- I think the bulgarian =+ position should house Ѝ ѝ
;		- It's a precomposed letter used for homophone distinctions and is present on newer bulgarian layouts
;		- Also, there seems to be no ё in bulmak (for russian), even though there's still the russian ы э
;		- (The ё could be on `AltGr+/`, since that only houses a duplicate slash and the non-cyrillic ¿)? No, breaks the Latin layer?
;	- WIP: Belarus/Ukrainia variants? Kharlamov in Mods-n-Layers (messID 961236439591432222 ff):
;		- Belarusian can use russian with И и changed to І і, Щ щ changed to Ў ў, and Ъ ъ changed to Ґ ґ
;		    (not used in the official orthography, but used in the still-popular 1918 orthography)
;		- Russian letters should also be accessible seeing how belarus is officially bilingual
;		- The ’ [Cmk-eD AltGr+F] apostrophe too, it's a letter in belarusian
;		- The national layout uses `'` so the current mapping may suffice
;		- Maybe put ’ on the iso key instead of double acute?
;		- For better phonetic mapping, Ў ў should be mapped to W w due to making the same sound

;	- TODO: More GUI settings?
;		- A Hotkeys settings panel?
;		- Menu language choice (on the Settings tab), with a dropdown choice of the actual language files present?

;	- TODO: A debug hotkey to generate a set of help images on the fly using default settings? Just call the make image fn() then sleep 600 then hit Enter, basically.

;	- TODO: Make a lock variant of modifiers. Which ones?

;	- WIP: Since Compose tables can be case sensitive now, do the same for DKs? Then scrap the silly `<K>+`-type DK entry syntax - keep <#> syntax?
;		- Read in all DK tables in use at startup instead of each entry as needed then? Faster use, slower startup, more memory usage. Acceptable?

;	- TODO: Allow a BaseLayout stack: Variant,Options/Script,Base... ?
;		- Make BaseVariants so we don't have to repeat ourselves for locales. The layout.ini could just hold the ergo remaps.
;		- The Cmk-Kyr BaseLayout could for instance base itself on the Cmk-eD BaseLayout and then Cmk-Ru-CAWS on Cmk-Kyr w/ remaps; Bg with its own variant.
;		- Guard against infinite recursion. Limit LayStack depth to a few more layers? Two more could be nice, for instance one locale plus one with extra composes?
;		- Figure out a way to sort out the img_ entries too, without manually editing all of them? Soft/hard? Extend(@X)/Geometric(@H)?
;	- TODO: Could the [layout] section be composed from includes of other sections? Such as [Numbers], [Symbols], [Letters], [Others]?
;		- This would facilitate hybrid layout types such as VK-numbers (to allow Win+Number shortcuts), VK-letters/eD-symbols...

;	- TODO: Add a Help button with a more generic help screen for the first Settings UI panel?
;	- TODO: Move the text for the Settings UI help text to the language files?!
;		- Make a separate .ini file section for it. Then read in the whole section and process it?

;	- TOFIX: Hiding a DK image triggered by an AltGr+<key> DK fails: The AltGr help image gets stuck instead if it happens too fast. Affects hiding 'DKs'.
;	- WIP: The CoDeKey sends repeated spaces when held down. Is this desirable? Could we specify no output by default for a DK?
;	- WIP: Ensure PrtScn is sent right for the CoDeKey and other DKs. Need PrtScn (all active windows), Alt+PrtScn (active window) and Win+PrtScn (full screen)
;	- WIP: Check out https://www.autohotkey.com/boards/viewtopic.php?f=6&t=77668&sid=15853dc42db4a0cc45ec7f6ce059c2dc about image flicker.
;		- May not work with WinSet, Transparent; I'm using that with the Help Images.
;	- TOFIX: Some new DK sequences don't work, like `~22A2   =  ~22AC	; ⊢ ⇒ ⊬`. Others like `~2228   =  ~22BD	; ∨ ⇒ ⊽` work. What gives?
;		- Also iota/upsilon with dialytika and tonos don't work...?
;	- TOFIX: When selecting downwards with Extend and then using Extend-copy, sometimes an 'EXT' character (?) is made instead.

;	- TOFIX: Win+V can't paste when using ergo-modded layouts like AWide. However, with CAWS and Vanilla it works.
;		- Is this because of the VK detection making an error? The ones that work both have V in its old place.

;	- TODO: Flesh out menu entries in the Settings UI? For instance, ANS ⇒ ANS(I), AWide ⇒ AWide (Angle+Wide) etc. Use a dictionary of string replacements?

;	- TODO: Move all override (and settings?) files to the Data folder? More compatible w/ the PortableApps format (backup++), but less clear?

;	- TEST: To avoid DK images stuck in the AltGr state, use a slight delay before showing the image if it's DK? It's a dirty hack, but could it help?
;		- Would destroying the GUI on DK activation help at all?

;	- WIP: Decide on supporting DK images and suchlike only for Cmk vanilla, CA and CAWS. Drop CAW support for sanity; link to CAWS in files.
;		- There is also AWide support today. But... I don't think a lot of people use it? And they can always be asked to generate their own.

;	- WIP: Add "What about gaming?" to README. Explain send method vs VK (also Compose etc). Mention MSKLC CAWS and SharpKeys.
;	- WIP: Introduce the marvelous Compose key in the README! Need more documentation on its merits. Also the new CoDeKey (dual-role Compose/Dead Key).
;		- Become a Great Composer!

;	- TODO: Can we have a separate user working dir, so users have their settings elsewhere? Very nice idea!
;		- https://github.com/DreymaR/BigBagKbdTrixPKL/issues/34
;		- Make and look for overrides in the working dir, and defaults in the script dir.
;		- Add a syntax or setting that lets the user specify using a layout dir (and BaseLayout?) in the working dir. Or just look for it there first, if different?
;			- `User\` or `~\` could point to working dir, and `.\` continue to point to script dir? Need to make all file-reading operations aware of this!?
;		- Might use a switch of working dir for some operations? Or, should things like the HIG just assume working dir and anyone wishing to use it must adjust?
;			- This would make sense, in letting a user set individual settings in their working dir and getting images there too.
;		- By default, the working dir can be Data which is the right place for it in the PortableApps standard (for backup).

;	- WIP: Instead of doing the atKbdType() this-and-that routine, make a fn to interpret all @ codes and add it as a switch for pklIniRead()?
;		- This would allow the use of all @ codes in all LayStack files

;	- WIP: "Add Layout" functionality in GUI, to select multiple active layouts without editing files manually.
;		- Use the ComboBox functionality, that lets you have a DDL with a manually editable field on top.
;		- Use an Add button? The button adds layout, line becomes <lay1>, then add is grayed out until something's changed. Could I avoid an extra button?
;		- Or... a cheeky Join button that uses RegExReplace to merge the topmost two GUI override entries?! Too risky and error-prone for newbs.

;	- WIP: In the Janitor timer: Update the OS dead keys and OEM VKs as necessary. Register current LID and check for changes.

;	- TODO: Get started on the Arabic phonetic layout!

;	- WIP: Revisit the ISO key for several locale variants as the new Compose key is so powerful. Spanish? Probably not Scandi/German? Or?

;	- WIP: Make README.md for the main layout and layout variant folders, so they may be showcased on the GitHub site.
;		- This way, people may read, e.g., IndyRad/QI analysis on the GitHub page in Markdown rather than the unattractive comment-in-file format.
;		- Update correspondence between the Locale Forum topic and these pages: Link to EPKL in the topic, get info from the topic.

;	- WIP: Mother-of-DKs (MoDK), e.g., on Extend tap! Near endless possibilities, especially if dead keys can chain.
;		- MoDK idea: Tap Ext for chaining DK layer (e.g., {Ext,a,e} for e acute – é?). But how best to organize them? Mnemonically is not so ergonomic.

;	- WIP: Dual-role modifiers. Allow home row modifiers like for instance Dusty from Discord uses: ARST and OIEN can be Alt/Win/Shift/Ctrl when held. Define both KeyDn/Up.
;		- In EPKL_Settings, set a tapOrModTapTime. In layout, use SC### = VK/ModName first entries. The key works normally when tapped, and the Mod is stored separately.
;		- Redefine the dual-role Extend key as a generic tapOrMod key. Treating Extend fully as a mod, it can also be ToM (or sticky?).
;		- TOFIX: ToM-tap gets transposed when typing fast, the key is sluggish. But if the tap time is set too low, the key can't be tapped instead.
;			- To fix this, registered interruption. So if something is hit before the mod timer the ToM tap is handled immediately.
;			- However, Spc isn't handled correctly!? It still gets transposed.
;		- Make a stack of active ToM keys? Ensuring that they get popped correctly. Nah...?
;		- Should I support multi-ToM or not? Maybe two, but would need another timer then like with OSM.

;	- TOFIX: Help images show 3–4× at startup with a slightly longer Sleep to hopefully avoid a minimize-to-taskbar bug on the first hide image.
;		- It still doesn't work as it should, but the problem is hard to reproduce.
;	- TOFIX: Looks like there are multiple EPKL instances in the Tray now? Is that true? Can it be GUI windows? Refresh related? Mouseover removes them.
;	- TOFIX: Ext-Shift may get stuck until Ext is released. Not sure exactly how.
;	- TOFIX: Help images for Colemak-Mirror don't show the apostrophe on AltGr even though it's functional and defined equivalently to the base state one.
;		- Debug on 6_BS doesn't show any differences; looks like &quot; is still generated.
;	- FIXED: Removed pressing LCtrl for AltGr (as in pkl_keypress.ahk now!). And changed to {Text} send.
;		- Does it fix the problem with upgrading to a newer AHK version?!? No! LCtrl still gets stuck upon AltGr in AHK v1.1.28+.
;	- TOFIX: Update to newer AHK! v1.1.28.00 worked mostly but not for AltGr which sends Alt and gets Ctrl stuck. v1.1.27.07 works fully.
;		- AHK version history: "Optimised detection of AltGr on Unicode builds. This fixes a delay which occurred at startup (v1.1.27) or the first Send call (earlier)."
;		- After update past v1.1.28, we can use StrSplit() with MaxParts to allow layout variant names with hyphens in them!
;		- Should then be able to go to v1.1.30.03 right away, but check for v1.1.31? That version has added an actual switch command, though!!!
;	- TOFIX: Setting a hotkey to, e.g., <^<+6 (LeftCtrl & LeftShift & 6) doesn't work.
;	- TOFIX: If a DK is selected very fast, the AltGr DK state image may get stuck until release. This happened after adding the DK img refresh-once timer?
;		- Renamed any state6 DK images that contained only a base key release on Spc, to miminize this issue. DKs like Ogonek still have it.
;	- TOFIX: The ToM MoDK Ext doesn't always take when tapped quickly. Say I have period on {Ext-tap,i}. I'll sometimes get i and/or a space instead.
;		- Seems that {tap-Ext,i} very fast doesn't take (producing i or nothing instead of ing)? Unrelated to the ToM term.
;	- TOFIX: Mapping a key to a modifier makes it one-shot?!
;	- TOFIX: Redo the AltGr implementation.
;		- Make a mapping for LCtrl & RAlt, with the layout alias AltGr?! That'd pick up the OS AltGr, and we can then do what we like with it.
;		- Treat EPKL AltGr as a normal mod, just that it sends <^>! - shouldn't that work? Maybe an alias mapping AltGr = <^>!
;	- TOFIX: The NBSP mapping (AltGr+Spc), in Messenger at least, sends Home or something that jumps to the start of the line?! The first time only, and then normal Space?
;	- TOFIX: Remapping to LAlt doesn't quite work? Should we make it recognizeable as a modifier? Trying 'SC038 = LAlt VK' also disabled Extend?
;	- TEST: ToM Ctrl on a letter key? Shift may be too hard to get in flow, but Ctrl on some rare keys like Q or D/H would be much better than awkward pinky chording.
;		- It works well! But then after a while it stops working?

;; ================================================================================================
;;  eD TONEXT:
;	- TODO: Once ToUnicode() and DetectDK() are working, it should be possible to generate help images from VK/SC layouts too?!
;	- SwiSh/FliCK should be the ideal way of implementing mirrored typing?
;		- Need to solve them being effectivly one-shot now, then. They should be able to be held down reliably.
;		- For fun, could make a mirror layout for playing the crazy game Textorcist: Typing with one hand, mirroring plus arrowing with the other!
;	- TODO: OS DK detection sucks. Go through all SC### and send their four states? (Only if the OS layout has AltGr; can we detect that by DLL?)
;		- Also store the DK characters in a better format? Just a string like ´¨`^~ is unclear and tricky.
;	- TODO: Ext layers by app/window? Like auto-Suspend. Could be handy for ppl w/ apps using odd shortcuts.
;	- TODO: Look into this Github README template? https://github.com/Louis3797/awesome-readme-template
;	- TODO: Make key presses involving the Win key send VK codes. This'll preserve Win+‹key› shortcuts without using ## mappings.
;	- TOFIX: The HIG doesn't make space between dual accents anymore? They coalesce on AltGr+8 now.
;		- Sort of fixed it by making the new disp0 entry that can display any string on the DK's key in the help image.
;	- TODO: Rework the GUI submit to allow multi-submit/reset on tabs that have more than one submit. 
;		- Maybe make the submit routine callable with arrays so it loops before asking for a restart?
;	- TODO: IPA Compose sequences, based on my old IPA DK ideas. Vowels with numbers according to position?
;	- TODO: Make a "base compose output" that a Compose key releases whenever no sequence is recognized? Like the Basechar of a DK. Useful for locale layouts?
;	- TODO: UI Idea: Show the state0 (and state3 if available) image of the chosen layout, in the picker?! Preferably with the right background. 
;		- Possible to extract the pic from pkl_gui_image?
;	- TODO: Personal override files for extend, compose, powerstrings etc? One override file with sections? Some overrides (remaps, DKs) in layouts.
;	- TODO: Is the main README still too long? Put the layout tutorial in a Layouts README? Also make a tutorial for simply using the CkAWS remap or something.
;	- TODO: A Wide mod that supports the QI;x or CTGAP bottom-right-half-row. Where he has `_B _H SL PD CM`, make the Wide mod `SL _B _H PD` and move CM up.
;		- Or... Would that suck? It replaces the safe E-SL SFB with E-B which is much worse?
;	- TODO: Add QWERTZ and AZERTY layouts? There are now remaps for them, and the rest should be doable with OEM VK detection.
;	- TODO: Provide a swap-LAlt-n-Caps RegEdit script, and a reversal one. Maybe add some more codes in the comments, see my old RegEdit scripts.
;	- TODO: Harmonize Ext and folder mod names? And/or make a shorthand for the @E=@C@H@O battery in addition to @K in layout files? And also the short variant like CAW(S)?
;		- Could expand, e.g., CurlAWide to CurlAngleWide for the layout name only? Or use long names like CurlAWideSym consistently?
;		- Make long names more consistent? Like 4 letters per mod, CurlAnglWideSyms ? Nah, too anal. Better to keep with CurlAWideSym, and that's long enough really.
;		- Use CAngle or CA--, etc? CAngle is more intuitive, but CA more consistent with CAW(S). 
;	- TODO: Make a matrix image template, and use it for the Curl variants w/o Angle. 
;		- Maybe that should be a separate KbdType, but we also need ANS/ISO info for the VK conversions. ASM/ISM KbdTypes?
;	- TOFIX: I messed up Gui Show for the images earlier, redoing it for each control with new img titles each time. Maybe now I could make transparent color work? No...?
;	- TOFIX: If a layout have fewer states (e.g., missing state2) the BaseLayout fills in empty mappings in the last state! Hard to help? Mark the states right in the layout.
;	- TOFIX: Pressing a DK twice should release basechar1 (s1) but basechar0 (s0) is still released. Not sure why.

;; ================================================================================================
;;  eD TODO:
;	- TODO: Make the CoDeKey follow the StickyTime timer? So you'll only use it as CoDeKey in flow. No, it'd need its own timer.
;	- TODO: Could I turn around the Compose method, to be leader key after all? But how to input then? Without looking sucks. In a pop-up box?
;	- TODO: Color markings for keys in HIG images! Could have a layer of bold key overlays and mark the keys we want with colors through entries in the HIG settings file.
;		- markColors = #c00:_E/_N/_K, #990:_B/_T/_F, #009:_J     ; Tarmak2 colors
;		- markColors = <CSV of marking specs>, similar to the remaps. Could have Tarmak1,Tarmak2,Tarmak3,#009:_J ?
;		- See https://forum.colemak.com/topic/1858-learn-colemak-in-steps-with-the-tarmak-layouts/p4/#p23659
;		- Allow a section in layout.ini too!
;		- Mark differently by state, as in the Tarmak images
;	- TODO: Make state images and DK image dirs ISO/ANSI aware?! Generate both in the HIG each time (plus Ortho?). Make layouts that can handle both. 
;		- How to handle special mappings? Could have [layout_###] sections.
;	- TODO: I never use the SendMessage parse prefix. Cannibalize it for a strEsc() send? Or add that as €\ prefix instead?
;	- Mod ensemble: For lr in [ "", "L", "R" ], For mod in [ "Shift", "Ctrl", "Alt", "Win" ] ? May not always need the empties? Also add [ "CapsLock", "Extend", "SGCaps" ] ?
;	- TODO: Redo the @Ʃ_@Ç formalism, adding @K to @E(@C@H@O) by a hyphen instead of an underscore? Would that be a benefit in any way? Or just a lot of work?
;	- TODO: Hotstrings? May have to wait for AHK v1.1.28 to use the Hotstring() fn? Or is there somewhere in this script we could insert definitions?
;	- TODO: Consider a remap for each Ext layer? Would make things messier, but allows separate Ext1 and Ext2 maps, e.g., for the SL-BS switch.
;		- Allow mapSC_extend2 etc entries in the LayStack. If not specified, use the _extend one for all.
;	- TODO: Add ABNT keys to the HIG template?
;	- TODO: Record macro? Or just a way to set entries for a certain DK layer in the Settings UI? Say, the Ext-tap layer(s). Could have backup DK layers and a Reset button.
;	- TODO: Make EPKL able to hold more than one layout in memory at once?! This would make dual layouts smoother, and using layouts as layers (Greek, mirroring etc) possible.
;		- With SGCaps modifier layers, the need for this may be alleviated?
;	- TODO: Since no hotkeys are set for normal key Up, Ext release and Ext mod release won't be registered? Should this be remedied?
;	- TODO: Rework the modifier Up/Down routine? 
;		- A function pklSetMods( set = 0, mods = [ "mod1", "mod2", ... (can be just "all")], side = [ "L", "R" ] ) could be nice? pkl_keypress, pkl_deadkey, in pkl_utility
;	- TODO: Replace today's AltGr handling with an AltGr modifier. You'd have to map, e.g., RAlt = AltGr Modifier, but then all the song-and-dance of today would be gone.
;		- Note that we both need to handle the AltGr EPKL modifier and whether the OS layout has an AltGr key producing LCtrl+RAlt on a RAlt press.
;		- Also allow ToM/Sticky AltGr. Very very nice since AltGr mappings are usually one-shot.
;		- Define a separate AHK hotkey for LCtrl+RAlt (=AltGr in Windows)? That might make things simpler.
;	- TODO: VK mappings don't happen on normal keys. Simple VK code states don't get translated to VK##. Only used when the key is VK mapped.
;	- TODO: Instead of CompactMode, allow the Layouts_Default (or _Override) to define a whole layout if desired. Specify LayType "Here" or suchlike?
;		- At any rate, all those mappings common to eD and VK layouts could just be in the Layouts_Default.ini file. That's all from the modifiers onwards.
;	- TODO: Import KLC. Use a layout header template.
;		- Could have a section of RegEx conversions with name tags in the template, which gets used and then cut out.
;		- Each such entry could have a tagName = ## SplitBy JoinBy <regex>
;			- Allow both RegExReplace and RegExMatch entries? The latter should use O) match objects?
;			-  The ## denotes how many numbered entries should be run on this string. This could have sublevels, like ##-##-##.
;			- SplitBy loops through elements of the string, recursively if subentries also split. Then it's rejoined with JoinBy (necessary, or just regex that?).
;			- Can we SplitBy words, like \nDEADKEY\t ?
;		- Then in the template there's something like $$tagName$$ where the result is to be inserted.
;		- For DK full names, the KEYNAME_DEAD entries could be converted (cut out ACCENT/SIGN, _ for spaces?, cut away parentheses, title case). Update my names accordingly?
;		- In addition to MSKLC format, allow Aldo Gunsing's KLFC! https://github.com/39aldo39/klfc And maybe Keyboard Layout Editor's KLE (or do that via KLFC).
;	- TODO: Make pklParseSend() work for DK chaining (one DK releases another)!
;		- Today, a special DK entry will set the PVDK (DK queue) to ""; to chain dead keys this should this happen for @ entries?
;		- Removing that isn't enough though? And actually, should a dk chaining start anew? So, replicate the state and effect of a normal layout DK press.
;		- Chaining DKs opens up for interesting possibilities, like a Mother-of-Dead-Keys key (MoDK)! Could that be on Extend-tap, possibly with a timeout? Or on Backspace?
;			- See Jaroslaw's MoDK topic in the Forum: https://forum.colemak.com/topic/2501-my-current-programming-symbols-layout/#p22527
;			- Placing all my DKs on MoDK sequences will fill up a layer. So maybe only the most interesting ones? But how to make it mnemonic?
;			- Example: Tap-dance {Ext,t,n} -> ñ; {Ext,a,A} -> Á; {Ext,0-9} IPA DKs.
;			- For good measure, could have different DKs on different states of the same key! Wow. The ToM formalism should support this actually!
;	- TODO: With the Compose method, look into IME-like behavior?
;		- This would allow "proper" Vietnamese, phonetic Kyrillic etc layouts instead of dead keys which work "the wrong way around".
;		- Could make special compose keys for accents? E.g., you type a^ and the ^ key is a Compose key producing â.
;	- TODO: Make EPKL work with the .exe outside a .zip file? 
;		- You could then download the release .zip, put the .exe outside, change then rezip any settings you want to, then the .exe will use the archive.
;		- This may be desirable for people running EPKL from an URL. It's easier to handle two files than several folders.
;	- TODO: Try out <one Shift>+<other Shift> = Caps? How to do that? Some kind of ToM, where the Shift is Shift when held but Caps when (Shift-)tapped?
;	- TODO: The key processing timers generate autorepeat? Is this desirable? It messes with the ToM keys? Change it so the hard down sends only down and not down/up keys?
;	- TODO: Keylogging for gathering typing stats. Which stats? 1-2-3-grams, characters-before-backspace...
;	- TODO: A help fn to make layout images? Make the image large and opaque, then make a screenshot w/ GIMP and crop it. Or can I use the Windows Snipping Tool (Win+Shift+S)?
;	- TODO: AHK2Exe update from AutoHotKey v1.1.26.1 to v1.1.30.03 (released April 5, 2019) or whatever is current now. 	;eD WIP: Problem w/ AltGr?
;		- New Text send mode for PowerStrings, if desired. Should handle line breaks without the brkMode setting.
;	- TODO: Make the Japanese layout now, since dead keys support literals/ligatures and DK tables in layout.ini are possible.
;	- TODO: Hebrew layout. Eventually, Arabic too.
;	- TODO: Mirrored one-hand typing as Remap, Extend or other layer?
;		- For Extend, would need a separate Ext modifier for it? E.g., NumPad0 or Down for foot or right-arm switching. But is that too clunky?
;		- SGCaps could work, but would require each layout to have SGC mappings to allow mirroring then. And a separate SGC modifier.
;		- Layout switching is usually done by restarting EPKL which is too clunky. But if we could have a switch modifier that temporarily activates the next layout...?
;		- This would require preloading more than one layout which takes a bit of reworking. Possibly... Allow an alt-set of the remap only, remapping on the fly w/ a mod?
;		- Mirroring as a remap can now use minicycles of many two-key loops. For instance, |  QU |  SC /  MN |  SL | for two separate swaps.
;	- TODO: A set of IPA dk, maybe on AltGr+Shift symbol keys? Could also be chained from a MoDK?
;	- TODO: Lose CompactMode from the Settings file. The LayStack should do it.
;		- Instead of a setting in Settings, allow all of the layout to reside in EPKL_Layouts_Default (or Override). If detected, use root images if available.
;		- If no layout.ini is found, give a short Debug message on startup explaining that the root level default/override layout, if defined, will be used. Or just do it?

;; ================================================================================================
;;  eD ONHOLD:
;	- Allow a mapping like Modifier(#), to add # to the modifier level? Use it as single-argument mapping entry. Modifier(8) would be SwiSh.
;	- Instead of having to make special literal entries (`→` or similar) for unshifted characters in shifted states, make all character sends use Unicode/Text?
;		- Issue: With Sticky Shift, the 2nd state mapping is sent shifted which is wrong if it was mapped to be something unshifted. Normal Shift does not.
;		- Sticky Shift just holds down the Shift key which leads to this effect. Should I make sure the state map is sent unblind?
;		- Only happens for single-character mappings. Mappings that aren't a key name aren't sent as "keys" by AHK.
;		- Conclusion: Not a good idea to send as text categorically, as non-"key" sending breaks Win+‹key› shortcuts.
;	- Try out a swap-side layout instead of the mirrored one? More strain on weak fingers, but fewer SFBs I should think.
;		- Is the brain equally good at side-swapping and mirroring?
;	- Make it so that if the hotkey queue overflows it's reset and you lose, say, the last 10 keys in it? Is that actually safer? No, don't think so?
;		- Need a way to count the hotkeys then, without spending much resources. The size of pklHotKeyBuffer should be an indication, as it's usually 'SC###¤' repeated.
;		- Only necessary to intervene on hotkey #31? Then stop the first 16 or so timers and flush the corresponding pklHotKeyBuffer entries.
;	- Make @K a compound (ANS/ISO-Trad/Orth/Splt/etc)? ANS/ISO is needed for VK codes, and the form factor for images and layout subvariants. kbdType vs kbdForm?
;		- Could keep everything in kbdType and adjust the reading of it to use the first and second substring.
;		- However, it may not be necessary at all. Using a kbdType like ANS-Orth seems to work just fine for now. The VK-related kbdType is in layout.ini anyway.
;	- Hardcode Tab instead of using &Tab after all? It's consistent to have both the whitespace characters Spc & Tab hardcoded this way.
;	- A dynamic key press indicator for help images, showing not just modifier layer but every press. Will it be fast enough? Needs a position table for each KbdForm.
;	- Make a Setting for which fn to run as Debug, so I don't have to recompile to switch debug fn()? Maybe overmuch, as the debug fn often needs recompiling anyway?
;	- Allow Remaps to use @K so that the layouts don't have to?!? Too confusing?
;	- Remove all the CtrlAltIsAltGr stuff? If laptops don't have RAlt (>!), they can just map a key to AltGr Mod instead? Won't allow using <^<! as AltGr (<^>!) though...
;	- Shift sensitive multi-Extend? When mapping for the NumPad layer, it'd be nice to have $/¢, €/£ etc. This allows many more potential mappings! 4×4-level Extend?!
;		- In most cases though, that'd be useful mostly for releasing more different glyphs. This is better done with dead keys, as these avoid heavy chording.
;	- Allow escaped semicolons (`;) in iniRead?
;	- Remove the Layouts submenu? Make it optional by .ini?
;	- Greek polytonic accents? U1F00-1FFE for circumflex(perispomeni), grave(varia), macron, breve. Not in all fonts! Don't use oxia here, as it's equivalent to tonos?
;	- Extend lock? E.g., LShift+Mod2+Ext locks Ext2. Maybe too confusing. But for, say, protracted numeric entry it could be useful?
;	- Some kaomoji have non-rendering glyphs, particularly eyes. Kawaii (Messenger), Joy face, Donger (Discord on phone). Just document and leave it at that.
;	- Go back on the Paste Extend key vs Ext1/2? It's ugly and a bit illogical since the layers are otherwise positional. But I get confused using Ext+D for Ctrl+V.
;	- Allow assigning several keys as Extend Modifier?
;	- An EPKL sample layout.ini next to the original PKL one, to illustrate the diffs? Or, let the contents of the main README be enough?
;	- Auto language detection doesn't follow keyboard setup but system language. If you use a Non-English keyboard but Windows uses English, the auto language is English.


;;  ####################### main      #######################
#NoEnv
#Persistent
#NoTrayIcon
#InstallKeybdHook
#SingleInstance         Force   							; eD WIP: Is something wonky with this now? I get lots of apparent EPKL instances in the System Tray...?
#MaxThreadsPerHotkey    3
#MaxThreadsBuffer       Off 								; We'll turn it on later in pkl_init, so it's off for program hotkeys and on for key press ones.
#MaxHotkeysPerInterval  300
#MaxThreads             32
#MaxMem                 128 								; Default 64 Mb. We need more than that for HIG image generation in its search-n-replace loop.

SendMode Event
SetKeyDelay -1  											; The Send key delay wasn't set in PKL, defaulted to 10. AHK direct key remapping uses -1. What's most robust?
SetBatchLines, -1   										; This script never sleeps (default is every 10 ms)
Process, Priority, , R  									; Real-time process priority (default is N for Normal; H for High in old PKL; R for Realtime is max)
SetWorkingDir, %A_ScriptDir% 								; Should "ensure consistency" 	; eD WIP: Can we have a separate user working dir, so users have their settings elsewhere?
StringCaseSense, On 										; All string comparisons are case sensitive (AHK default is Off) 	; eD WIP: But InStr() is still caseless by def.?

setPklInfo( "pklName", "EPiKaL Portable Keyboard Layout" ) 					; EPKL Name
setPklInfo( "pklVers", "1.4.0" ) 											; EPKL Version
setPklInfo( "pklComp", "AHK v1.1.27.07" ) 									; Compilation info
setPklInfo( "pklHome", "https://github.com/DreymaR/BigBagKbdTrixPKL" )  	; URL used to be http://pkl.sourceforge.net/
setPklInfo( "pklHdrA", ";`r`n;;  " ) 										; A header used when generating EPKL files
setPklInfo( "pklHdrB", "`r`n"
		. ";;  for Portable Keyboard Layout by Máté Farkas [https://github.com/Portable-Keyboard-Layout]" . "`r`n"
		. ";;  edition DreymaR (Øystein Bech-Aase, 2015-)  [https://github.com/DreymaR/BigBagKbdTrixPKL]" . "`r`n;`r`n" )

setPklInfo( "initStart", A_TickCount )  					; eD DEBUG: Time EPKL startup
;;  Global variables are now largely replaced by the get/set info framework, and initialized in the init fns
	; global HotKeyBuffer = [] 								; Keeps track of the buffer of up to 30 pressesd keys in ###KeyPress() fns
;	global UIsel 											; Variable for UI selection (use Control names to see which one) 	; NOTE: Can't use an object variable for UI (yet)
Gosub setUIGlobals 											; Set the globals needed for the settings UI (is this necessary?)
arg = %1% 													; Layout from command line parameter, if any
initPklIni( arg ) 											; Read settings from pkl.ini (now PklSet and PklLay)
initLayIni() 												; Read settings from layout.ini and layout part files
activatePKL()
;pklDebug( "Time since init start: " . A_TickCount - getPklInfo( "initStart" ) . " ms", 1 )   	; eD DEBUG

Return  													; end of main

;;  ####################### labels    #######################

;;  eD WIP: Map AltGr to RAlt to prevent trouble?!
;;  The order of AltGr is always LCtrl then RAlt. Custom combos always have the * (wildcard) mod so they obey any mod state.
;;  In order to make a combo hotkey for LCtrl&RAlt, we also need to handle the first key on its own (https://www.autohotkey.com/docs/Hotkeys.htm#combo)
;;  "For standard modifier keys, normal hotkeys typically work as well or better than "custom" combinations. For example, <+s:: is recommended over LShift & s::."
;;  Possible issue: These hotkeys are generated after the others, since initPklIni() is already run. Should this part be handled in the init part? What about any LCtrl hotkey in the layout?
;#if GetKeyState( "LCtrl", "P" )
;RAlt::
;#if
;LControl & RAlt:: 	; This works but mapping to RAlt produces "Invalid hotkey", why!? Also, it repeats.
;<^>!:: 				; eD WIP: This isn't working?! Maybe an #if GetKeyState( "RAlt", "P" ) will do the trick?
;	pklDebug( "Gotcha, AltGr!", 0.5 )
;Return
;LControl & RAlt::Send {RAlt Down} 	; This alone gets AltGr stuck
;LControl Up & RAlt Up::Send {RAlt Up} 	; This doesn't work!?

; processKeyPress0:     ; Timer/Buffer removed - CSGO
; processKeyPress1:
; processKeyPress2:
; processKeyPress3:
; processKeyPress4:
; processKeyPress5:
; processKeyPress6:
; processKeyPress7:
; processKeyPress8:
; processKeyPress9:
; processKeyPress10:
; processKeyPress11:
; processKeyPress12:
; processKeyPress13:
; processKeyPress14:
; processKeyPress15:
; processKeyPress16:
; processKeyPress17:
; processKeyPress18:
; processKeyPress19:
; processKeyPress20:
; processKeyPress21:
; processKeyPress22:
; processKeyPress23:
; processKeyPress24:  	; eD WIP: What's the ideal size of this cycle? Does #MaxThreads apply?
; processKeyPress25:
; processKeyPress26:
; processKeyPress27:
; processKeyPress28:
; processKeyPress29:
; processKeyPress30:
; 	runKeyPress()
; Return

keypressDown: 			; *SC###    hotkeys         ; Now sent directly
	Critical
	_keyPressed(SubStr( A_ThisHotkey, 2 )) 	; SubStr removes leading '*'
Return

keypressUp:  			; *SC### UP 			    ; Also sent directly			
	Critical
	Send % "{Blind}{" . getKeyInfo( SubStr( A_ThisHotkey, 2, -3 ) . "ent1" ) . "  UP}"
Return

modifierDown: 			; *SC###    (call fn as HKey to translate to modifier name)
	Critical
	setModifierState( getKeyInfo( SubStr( A_ThisHotkey, 2     ) . "ent1" ), 1 )
Return

modifierUp:
	Critical
	setModifierState( getKeyInfo( SubStr( A_ThisHotkey, 2, -3 ) . "ent1" ), 0 )
Return

tapOrModDown: 			; *SC###
	Critical
	setTapOrModState(   SubStr( A_ThisHotkey, 2     ), 1 )
Return

tapOrModUp:
	Critical
	setTapOrModState(   SubStr( A_ThisHotkey, 2, -3 ), 0 )
Return

showAbout: 													; Menu "About..."
	pkl_about()
Return

changeSettings: 											; Menu "Layout/Settings..."
	pklSetUI()
Return

keyHistory: 												; Menu "AHK Key History..."
	KeyHistory
Return

;detectCurrentWinLayDeadKeys: 								; Menu "Detect dead keys..."
;	setCurrentWinLayDeadKeys( detectCurrentWinLayDeadKeys() )
;Return

showHelpImage:
	pkl_showHelpImage()
Return

showHelpImageOnce: 											; Used as a one-time refresh when necessary
	pkl_showHelpImage()
Return

toggleHelpImage:    										; Menu "Display help image"
	pkl_showHelpImage( 2 )
Return

zoomHelpImage: 												; Menu "Zoom help image"
	pkl_showHelpImage( 5 )
Return

moveHelpImage: 												; Hotkey "Move help image"
	pkl_showHelpImage( 6 )
Return

opaqHelpImage: 												; Hotkey "Opaque/Transparent image"
	pkl_showHelpImage( 7 )
Return

rerunNextLayout: 											; Menu "Change layout"
	changeLayout( getLayInfo( "NextLayout" ) )
Return

rerunSameLayout:    										; Menu "Refresh EPKL"
	activeLay   := getLayInfo( "ActiveLay" ) 				; Layout code (path) of the active layout
	numLayouts  := getLayInfo( "NumOfLayouts" ) 			; The number of listed layouts
	Loop % numLayouts { 									; Use the layout # instead of its code, to reflect any PKL Settings list changes
		theLayout   := getLayInfo( "layout" . A_Index . "code", theCode )
		actLayNum   := ( theLayout == activeLay ) ? A_Index : actLayNum
	}
	changeLayout( "UseLayPos_" . actLayNum ) 				; Rerun the same layout, telling pkl_init to use position.
Return

changeLayoutMenu: 											; Menu "Layouts"
	changeLayout( getLayInfo( "layout" . A_ThisMenuItemPos . "code" ) )
Return

suspendOn:
	Suspend, On
	Goto afterSuspend
Return

suspendOff:
	Suspend, Off
	Goto afterSuspend
Return

toggleSuspend:  											; Menu "Suspend"
	Suspend
	Goto afterSuspend
Return

afterSuspend:
	if ( A_IsSuspended ) {
		pkl_showHelpImage(  3 )
		Menu, Tray, Icon, % getLayInfo( "Ico_OffFile" ), % getLayInfo( "Ico_OffNum_" )
	} else {
		pkl_showHelpImage( -3 )
		Menu, Tray, Icon, % getLayInfo( "Ico_On_File" ), % getLayInfo( "Ico_On_Num_" )
	}
Return

exitPKL: 													; Menu "Exit"
	ExitApp
Return

doNothing:
Return

getWinInfo:
	getWinInfo() 										; Show the active window's title/process(exe)/class
Return

epklDebugUtil:  										; eD DEBUG/UTILITY/WIP: This entry is activated by the Debug hotkey
	nr  := pklIniRead( "whichUtility", 1 )
	pklToolTip( "Running Debug/Utility routine " . nr . "`n(specified in Settings)", 1.5 )
	debug%nr%() 										; Run the specified debug# routine
Return

  debug1() {
	KeyHistory  										; Show AHK Key History      as by the View -> Key history menu  (shown)
} debug2() {
	ListHotkeys 										; Show AHK hotkeys          as by the View -> Hotkeys     menu  (hidden)
} debug3() {
	ListVars 											; Show AHK global variables as by the View -> Variables   menu  (hidden)
} debug4() {
	ListLines   										; Show AHK script (flow relevant) line execution history        (hidden)
} debug5() {
	getWinInfo() 										; Show the active window's title/process(exe)/class             (EPKL)
} debug6() {
;	getWinLayDKs()  									; eD WIP: Improved WinLayDK detection
;	pklDebug( "getWinLayDKs:`n" . getPklInfo("WinLayDKs")[0x10], 1 )  ; eD DEBUG
	pklDebugCustomRoutine() 							; eD DEBUG – usually: Show OS & EPKL VK codes for the OEM keys
;	importLayouts() 									; eD TODO: Import a MSKLC layout file to EPKL format
;	importComposer() 									; eD DONE: Import an X11 Compose file to EPKL format
} debug7() {
	detectCurrentWinLayDeadKeys()   					; The old PKL DeadKey detection routine                         (hidden)
} 	; end debug#

;;  ####################### functions #######################

#Include pkl_init.ahk
#Include pkl_gui_image.ahk	; pkl_gui was too long; it's been split into help image and menu/about parts
#Include pkl_gui_menu.ahk
#Include pkl_gui_settings.ahk
#Include pkl_keypress.ahk
#Include pkl_send.ahk
#Include pkl_deadkey.ahk
#Include pkl_utility.ahk	; Various functions such as pkl_activity.ahk were merged into this file
#Include pkl_get_set.ahk
#Include pkl_ini_read.ahk
#Include pkl_import.ahk 	; Import module, converting MSKLC layouts to EPKL format, and other import/conversion
#Include pkl_make_img.ahk	; Help image generator, calling Inkscape with an SVG template

;;  #######################  modules  #######################

; #Include ext_Uni2Hex.ahk ; HexUC by Laszlo Hars - moved into pkl_init.ahk
; #Include ext_MenuIcons.ahk ; MI.ahk (http://www.autohotkey.com/forum/viewtopic.php?t=21991) - obviated
; #Include ext_SendUni.ahk ; SendU by Farkas et al - obviated by Unicode AHK v1.1
; #Include ext_HashTable.ahk ; Merged w/ CoHelper then obviated by AHK v1.1 associative arrays
; #Include getVKeyCodeFromName.ahk ; (was VirtualKeyCodeFromName) - replaced w/ read from tables .ini file
; #Include getLangStrFromDigits.ahk ; http://www.autohotkey.com/docs/misc/Languages.htm - replaced w/ .ini
; #Include ext_IniRead.ahk ; http://www.autohotkey.net/~majkinetor/Ini/Ini.ahk - replaced with pkl_iniRead
; #Include getDeadKeysOfSystemsActiveLayout.ahk - replaced w/ read from tables .ini file
; #Include A_OSVersion.ahk - moved into this file then removed as OSVersion <= VISTA are no longer supported
; #Include getGlobal.ahk - moved into pkl_getset.ahk then removed as it was only used for one variable
; #Include iniReadBoolean.ahk - moved into pkl_iniRead and tweaked
; #Include detectDeadKeysInCurrentLayout.ahk - moved into pkl_deadkey.ahk
; #Include pkl_locale.ahk - moved into pkl_get_set.ahk