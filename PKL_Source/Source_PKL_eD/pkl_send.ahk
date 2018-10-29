﻿pkl_Send( ch, modif = "" )		; Process a single char with mods for send, w/ OS DK & special char handling
{
	static SpaceWasSentForSystemDKs = 0
	
	if ( getKeyInfo( "CurrNumOfDKs" ) == 0 ) {		; No active DKs
		SpaceWasSentForSystemDKs = 0
	} else {
		setKeyInfo( "CurrBaseKey_", ch )			; DK(s) active, so record the key as Base key
		if ( SpaceWasSentForSystemDKs == 0 )		; If there is an OS dead key that needs a Spc sent, do it
			Send {Space}
		SpaceWasSentForSystemDKs = 1
		Return
	}
	
	if ( 32 < ch ) {			;&& ch < 128 (using pre-Unicode AHK)
		char := "{" . Chr(ch) . "}"
		if ( inStr( getDeadKeysInCurrentLayout(), Chr(ch) ) )
			char .= "{Space}"
	} else if ( ch == 32 ) {
		char = {Space}
	} else if ( ch == 9 ) {
		char = {Tab}
	} else if ( ch > 0 && ch <= 26 ) {
		; http://en.wikipedia.org/wiki/Control_character#How_control_characters_map_to_keyboards
		char := "^" . Chr( ch + 64 )	; Send Ctrl char
	} else if ( ch == 27 ) {
		char = ^{VKDB}	; Ctrl + [ (OEM_4) alias Escape				; eD TODO: Is this robust with ANSI/ISO VK?
	} else if ( ch == 28 ) {
		char = ^{VKDC}	; Ctrl + \ (OEM_5) alias File Separator(?)
	} else if ( ch == 29 ) {
		char = ^{VKDD}	; Ctrl + ] (OEM_6) alias Group Separator(?)
;	} else {			; Unicode character
;		sendU(ch)
;		Return
	}
	pkl_SendThis( modif, char )
}

pkl_SendThis( modif, toSend )	; Actually send a char/string, processing Alt/AltGr states
{
	toggleAltGr := _getAltGrState()
	if ( toggleAltGr )
		_setAltGrState( 0 )		; Release LCtrl+RAlt temporarily if applicable
	; Alt + F to File menu doesn't work without Blind if the Alt button is pressed:
	prefix := ( inStr( modif, "!" ) && getKeyState("Alt") ) ? "{Blind}" : ""
	Send, %prefix%%modif%%toSend%
	if ( toggleAltGr )
		_setAltGrState( 1 )
}

pkl_ParseSend( entry, mode = "Input" )							; Parse/Send Keypress/Extend/DKs/Strings w/ prefix
{
;	static parse := { "%" : "{Raw}" , "=" : "{Blind}" , "*" : "" }
	prf := SubStr( entry, 1, 1 )
	if ( not InStr( "%$*=@&", prf ) )
		Return false											; Not a recognized prefix-entry form
	sendPref := -1
	ent := SubStr( entry, 2 )
	if        ( prf == "%" ) {									; Literal/ligature by {Raw}
		SendInput %   "{Raw}" . ent
	} else if ( prf == "$" ) {									; Literal/ligature by SendMessage
		pkl_SendMessage( ent )
	} else if ( ent == "{CapsLock}" ) {							; CapsLock toggle
		togCap := ( getKeyState("CapsLock", "T") ) ? "Off" : "On"
		SetCapsLockState % togCap
	} else if ( prf == "*" ) {									; * : Omit {Raw} etc; use special !+^#{} AHK syntax
		sendPref := ""
	} else if ( prf == "=" ) {									; = : Send {Blind} - as above w/ current mod state
		sendPref := "{Blind}"
	} else if ( prf == "@" ) {									; Named dead key (may vary between layouts!)
		pkl_DeadKey( ent )
	} else if ( prf == "&" ) {									; Named ligature (may vary between layouts!)
		pkl_Ligature( ent )
	}
	if ( sendPref != -1 ) {
		if ( mode == "SendThis" && ent ) {
			pkl_SendThis( "", sendPref . ent )					; Used by _keyPressed()
		} else {
			SendInput %       sendPref . ent
		}
	}
	Return % prf												; Return the recognized prefix
}

pkl_SendMessage( string )										; Send a string robustly by char messages, so that mods don't get stuck etc
{																; SendInput/PostMessage don't wait for the send to finish; SendMessage does
	Critical													; Source: https://autohotkey.com/boards/viewtopic.php?f=5&t=36973
	WinGet, hWnd, ID, A 										; Note: Seems to be faster than SendInput for long strings only?
	ControlGetFocus, vClsN, ahk_id%hWnd% 	; "If this line doesn't work, try omitting vCtlClsN to send directly to the window"
	Loop, Parse, string
		SendMessage, 0x102, % Ord( A_LoopField ), 1, %vClsN%, ahk_id%hWnd%	; 0x100 = WM_CHAR sends a character input message
}

pkl_SendClipboard( string ) 									; Send a string quickly via the Clipboard (may fail if the clipboard is big)
{
	Critical
	clipSaved := ClipboardAll									; Save the entire contents of the clipboard to a variable
;	Clipboard := Clipboard										; Cast the clipboard content as text (use expression to avoid trimming)
	Clipboard := string
	ClipWait 1													; Wait some seconds for the clipboard to contain text
	if ( ErrorLevel ) {
		Content := ( Clipboard ) ? Clipboard : "<empty>"
		pklWarning( "DEBUG: Clipboard not ready! Content:`n" . Content )
	}
	Send ^v 													; Wait 50-250 ms(?) after pasting before changing clipboard.
	Sleep 250													; See https://autohotkey.com/board/topic/10412-paste-plain-text-and-copycut/
	Clipboard := clipSaved
	VarSetCapacity( clipSaved, 0 )								; Could probably just use := "" here, especially for large contents.
}

_strSendMode( string, strMode )
{
	if ( not string )
		Return true
	if        ( strMode == "Input"     ) {				; Send by the standard SendInput {Raw} method
		SendInput {Raw}%string%							; - May take time, and any modifiers released meanwhile will get stuck!
	} else if ( strMode == "Message"   ) {				; Send by SendMessage WM_CHAR system calls
		pkl_SendMessage( string )						; - Robust as it waits for sending to finish, but a little slow.
	} else if ( strMode == "Paste" ) {					; Send by pasting from the Clipboard, preserving its content.
		pkl_SendClipboard( string )						; - Quick, but may fail if the timing is off. Best for non-parsed send.
	} else {
		pklWarning( "Send mode '" . strMode . "' unknown.`nString '" . ligName . "' not sent." )
		Return false
	}	; end if strMode
	Return true
}

pkl_Ligature( ligName )											; Send named literal ligature/hotstrings from a file
{
	ligFile := getLayInfo( "ligFile" )							; The file containing named ligature tables
	strMode := pklIniRead( "strMode", "Message", ligFile )		; Mode for sending strings: "Input", "Message", "Paste"
	brkMode := pklIniRead( "brkMode", "+Enter" , ligFile )		; Mode for handling line breaks: "+Enter", "n", "rn"
	theString := pklIniRead( ligName, , ligFile, "ligatures" )	; Read the named ligature's entry (w/ comment stripping)
	if ( SubStr( theString, 1, 11 ) == "<Multiline>" ) {		; Multiline string entry
		Loop % SubStr( theString, 13 ) {
			IniRead, val, %ligFile%, ligatures, % ligName . "-" . Format( "{:02}", A_Index )
			mltString .= val									; IniRead is a bit faster than pklIniRead() (1-2 s on a 34 line str)
		}
		theString := mltString
	}
	theString := strEsc( theString )							; Replace \# escapes
	if ( brkMode == "+Enter" ) {
		Loop, Parse, theString, `n, `r							; Parse by lines, sending Enter key presses between them
		{														; - This is more robust since apps use different breaks
			if ( A_Index > 1 )
				SendInput +{Enter}								; Send Shift+Enter, which should be robust for msg boards.
;				WinGet, hWnd, ID, A 							; Use SendMessage to send Enter then wait for it to happen.
;				ControlGetFocus, vClsN, ahk_id%hWnd%
;				SendMessage, 0x100, 0x0D, 0, %vClsN%, ahk_id%hWnd%	; 0x100 = WM_KEYDOWN. Sends a Windows key input message.
;				SendMessage, 0x101, 0x0D, 0, %vClsN%, ahk_id%hWnd%	; 0x100 = WM_KEYUP, 0x0D = VK_RETURN = {Enter}.
;				ControlSend, %vClsN%, +{Enter}					; Try ControlSend instead.
;				Control, EditPaste, +{Enter}, %vClsN%			; Try Control, EditPaste instead.
				Sleep 50										; Wait so the Enter gets time to work. Need ~50 ms?
			if ( not _strSendMode( A_LoopField , strMode ) )	; Try to send by the chosen method
				Break
		}	; end Loop Parse
	} else {													; Send string as a single block with line break characters
		StrReplace( theString, "`r`n", "`n" )					; Ensure that any existing `r`n are kept as single line breaks
		if ( brkMode == "rn" )
			StrReplace( theString, "`n", "`r`n" )
		_strSendMode( theString , strMode ) 					; Try to send by the chosen method
	}	; end if brkMode
;	Send {LShift Up}{LCtrl Up}{LAlt Up}{LWin Up}{RShift Up}{RCtrl Up}{RAlt Up}{RWin Up}	; Remove mods to clean up?
;	for ix, mod in [ "LShift", "RShift", "Shift", "Ctrl", "Alt", "Win", "AltGr" ] {		; Why doesn't this work?
;		setModifierState( mod, 0 )								; Because we can't wait for the actual send to finish, I think!
}

;-------------------------------------------------------------------------------------
;
; Set/get mod key states
;     Process states of modifiers. Used by Send, and in PKL_main.
;

setModifierState( modifier, isdown )
{
	getModifierState( modifier, isdown, 1 )
}

getModifierState( modifier, isdown = 0, set = 0 )
{
	if ( modifier == "AltGr" )
		Return _getAltGrState( isdown, set ) ; For better performance
	
	if ( set == 1 ) {
		if ( isdown == 1 ) {
			setKeyInfo( "ModState_" . modifier, 1 )
			Send {%modifier% Down}
		} else {
			setKeyInfo( "ModState_" . modifier, 0 )
			Send {%modifier% Up}
		}
	} else {
		Return getKeyInfo( "ModState_" . modifier )
	}
}

_setAltGrState( isdown )
{
	_getAltGrState( isdown, 1 )
}

_getAltGrState( isdown = 0, set = 0 )
{
	static AltGr := 0
	if ( set == 1 ) {
		if ( isdown == 1 ) {
			AltGr = 1
			Send {LCtrl Down}{RAlt Down}
		} else {
			AltGr = 0
			Send {RAlt Up}{LCtrl Up}
		}
	} else {
		Return AltGr
	}
}
