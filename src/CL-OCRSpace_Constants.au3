#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.14.5
 Author:         Kabue Murage

 Script Function:
	Template AutoIt script.

#ce ----------------------------------------------------------------------------

Global $s_gCMDstdout = Null, $s_gLogFile = Null

Global Const $DEFAULT_PROCESSING_ENGINE = 1
Global Const $DEFAULT_PROCESSING_LANGUAGE = 'eng'
; Global $a_AllowedFileTypes[]=["" , "", "", ""]


Global Enum $SUCCESSERL, $ERROR_INVALID_APIKEY, $ERROR_CLIENT_INTERNET, $ERROR_INVALID_FILETYPE, $ERROR_INVALID_FILE
