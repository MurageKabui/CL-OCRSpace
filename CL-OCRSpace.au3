#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=icons8-ocr-48.ico
#AutoIt3Wrapper_Outfile=CL-OCRSpace.exe
#AutoIt3Wrapper_Change2CUI=y
#AutoIt3Wrapper_Res_Comment=API aided OCR Commandline Utility Run /? For help
#AutoIt3Wrapper_Res_Description=CL-OCRSpace  -API aided OCR Commandline Util. Run /? For help
#AutoIt3Wrapper_Res_Fileversion=1.0.1.72
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=p
#AutoIt3Wrapper_Res_ProductName=CL-OCRSpace
#AutoIt3Wrapper_Res_CompanyName=Kabue Murage
#AutoIt3Wrapper_Res_LegalCopyright=© Dennis Murage kabue
#AutoIt3Wrapper_Res_LegalTradeMarks=Kabue Murage
#AutoIt3Wrapper_AU3Check_Parameters=-q -d -w 1 -w 2 -w 3 -w 4 -w 5 -w 6 -w 7
#AutoIt3Wrapper_Run_Tidy=y
#Tidy_Parameters=/rel /sci 1 /gdf
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/so /rm
#AutoIt3Wrapper_Res_Field=Build|2016-01-14
#AutoIt3Wrapper_Res_Field=Compile date|%longdate% %time%
#AutoIt3Wrapper_Res_Field=AutoIt Version|%AutoItVer%
#AutoIt3Wrapper_Res_Language=1033
#AutoIt3Wrapper_Res_LegalCopyright=Kabue Murage 2019
#AutoIt3Wrapper_Res_Field=Coded by|Kabue Murage
#AutoIt3Wrapper_UseUpx=n
#AutoIt3Wrapper_Run_After=upx.exe --brute --crp-ms=999999 --all-methods --all-filters "%out%"
; #AutoIt3Wrapper_UPX_Parameters=--brute --crp-ms=999999 --all-methods --all-filters
; #AutoIt3Wrapper_UPX_Parameters=--best --lzma
; #AutoIt3Wrapper_Run_After=del /f /q "%scriptdir%\%scriptfile%_stripped.au3"


#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#include-once
; #Autoit3Wrapper_If_Compile
;     #AutoIt3Wrapper_Run_Au3Check=N
;     #AutoIt3Wrapper_Run_Tidy=N
; #AutoIt3Wrapper_EndIf
; #AutoIt3Wrapper_AU3Check_Stop_OnWarning=y
#include <WinAPIConv.au3>
#include <File.au3>
#include <Date.au3>
#include <array.au3>
#include "Json.au3"
#include "CL-OCRSpace_Constants.au3"

Opt("MustDeclareVars", 0)
#cs ----------------------------------------------------------------------------
 AutoIt Version  : 3.3.14.5
 Author          : Kabue Murage
 Script Function : Unofficial Commandline Utility to work with the OCRSpace API.
 Date            : Feb 10th 2022
#ce ----------------------------------------------------------------------------
Global $bDebug = _CmdLine_KeyExists('dm')
If $bDebug Then $s_gLogFile = StringTrimRight(@ScriptName, 4) & ".log"

Global $bVerbose = _CmdLine_KeyExists('vm')
Global Const $s_gIMG_FQPN = _CmdLine_GetValByIndex(1, '')   ; ! Mandatory Param!    ; Str type.
Global Const $v_gOCRSpaceAPIKey = _CmdLine_Get("k", Null) ; ! Mandatory Param!    ; Variant type. Presented as str
; ConsoleWrite("total : " & $CmdLine[0] & @CRLF)

Switch $s_gIMG_FQPN
	Case "", "help", "-h", "/h"
		; Dump Help Info
		ConsoleWrite(HelpInfo() & @CRLF)
		Exit ($SUCCESSERL)
	Case "ver", "-v"
		ConsoleWrite(FileGetVersion(@ScriptFullPath) & @CRLF)
		Exit ($SUCCESSERL)
EndSwitch

If ($CmdLine[0] < 3) Then
	ConsoleWrite(HelpInfo() & @CRLF & " Error : Expected a minimum of 3 parameters. Run '" & @ScriptName & " -h' for help." & @CRLF)
	Exit (9)
EndIf

If (FileExists($s_gIMG_FQPN) And StringInStr(FileGetAttrib($s_gIMG_FQPN), "D") = 0) Then
	Switch StringLower(StringTrimLeft($s_gIMG_FQPN, StringInStr($s_gIMG_FQPN, ".", 0, -1)))
		Case "pdf", "gif", "png", "jpg", "tif", "bmp", "pdf", "jpeg"
			; do nothing ..
			; Supported image file formats are png, jpg (jpeg), gif, tif (tiff) and bmp.
			; For document ocr, the api supports the Adobe PDF format. Multi-page TIFF files are supported.
		Case Else
			If $bVerbose Then ConsoleWrite("Unsupported filetype provided." & @CRLF)
			Exit (5)
	EndSwitch

ElseIf _PathIsURLA__($s_gIMG_FQPN) Then
	;Continue..
Else
	If $bVerbose Then ConsoleWrite("Unsupported file provided." & @CRLF)
	Exit (6) ; ! unsupported file.
	; Return SetError(2, 0, "unsupported type !")
EndIf

If ($v_gOCRSpaceAPIKey = Null) Then
	If $bVerbose Then ConsoleWrite("Error : No APIKey Provided! Run '" & @ScriptName & " -h' for help." & @CRLF)
	Exit ($ERROR_INVALID_APIKEY)
ElseIf Not IsConnected() Then
	If $bVerbose Then ConsoleWrite("Error: Check internet connection. Run '" & @ScriptName & " -h' for help." & @CRLF)
	Exit ($ERROR_CLIENT_INTERNET)
EndIf

Global Const $i_gOCRSpaceProcEngine = _CmdLine_Get("e", $DEFAULT_PROCESSING_ENGINE)   ; ? of type int to API. Converts to bool
Global Const $v_gOCRSpaceProcLang = _CmdLine_Get("l", $DEFAULT_PROCESSING_LANGUAGE)   ; ? of type str to API.

; Setup Properties via Bool Switches /flags
Global Const $b_gOCROverlayRequired = _CmdLine_KeyExists('ov')         ; ? - overlay
Global Const $b_gOCRSpaceImgAutoScale = _CmdLine_KeyExists('as')     ; ? - Auto scaling
Global Const $b_gTableProcLogic = _CmdLine_KeyExists('tl')             ; ? - Table Logic
Global Const $b_gDetectOrientation = _CmdLine_KeyExists('do')         ; ? - Detect orientation
Global Const $b_gOCRSpacePDFHideTextLater = (_CmdLine_KeyExists('pt') ? False : True) ; invert option.
Global Const $b_gOCRSpaceGenSearchablePDF = _CmdLine_KeyExists("pf") ; ? - Searchable PDF file
Global $s_lDelimiter = _CmdLine_Get("s", '|')
; A directory where user wants to save the file.
Global $s_FileOutput = _CmdLine_Get("o", @ScriptDir)
$s_FileOutput = (PathIsValid($s_FileOutput) ? $s_FileOutput : @ScriptDir)

Global $OCROptions = _OCRSpace_SetUpOCR($v_gOCRSpaceAPIKey, $i_gOCRSpaceProcEngine, $b_gTableProcLogic, $b_gDetectOrientation, $v_gOCRSpaceProcLang, $b_gOCROverlayRequired, $b_gOCRSpaceImgAutoScale, $b_gOCRSpacePDFHideTextLater, $b_gOCRSpaceGenSearchablePDF)

Switch @error
	Case 1
		Exit ($ERROR_INVALID_APIKEY)
	Case Else
EndSwitch

;  $b_gOCROverlayRequired is parsed from commandline as bool,. convert to int.
Global $sText_Detected = _OCRSpace_ImageGetText($OCROptions, $s_gIMG_FQPN, (($b_gOCROverlayRequired) ? 1 : 0), "SEARCHABLE_URL")
; If @error = 111 Then
; ConsoleWrite(@error & " ==> " & @extended & " ==> " & $sText_Detected & @CRLF & " ==> " & @CRLF)
If ($b_gOCROverlayRequired And IsArray($sText_Detected)) Then         ; return array data ; Parsing the array ..

	; If requested delimeter is longer than 3 characters
	$s_lDelimiter = ((StringLen($s_lDelimiter) > 3) ? '|' : $s_lDelimiter)

	For $i = 0 To UBound($sText_Detected, 1) - 1
		$s_gCMDstdout &= $sText_Detected[$i][0] & $s_lDelimiter & $sText_Detected[$i][1] & $s_lDelimiter & $sText_Detected[$i][2] & $s_lDelimiter & $sText_Detected[$i][3] & $s_lDelimiter & $sText_Detected[$i][4] & @CRLF
	Next
Else
	$s_gCMDstdout = $sText_Detected
EndIf

; if $s_FileOutput
; if _CmdLine_KeyExists('of') then

; Else
ConsoleWrite((($b_gOCRSpaceGenSearchablePDF) ? Eval("SEARCHABLE_URL") : $s_gCMDstdout) & @CRLF)
; EndIf
Exit

; ================================================================================================================================
Func HelpInfo()
	; "       CL-OCRSpace.exe file --option <argument> /Switch" & @CRLF & _
	; "A CLI Swiss army knife for perfect OCR via the OCRSpace API v3.5" & @CRLF & @CRLF & _
	Local $sHelpString = _
			@ScriptName & " v" & FileGetVersion(@ScriptName) & @CRLF & _
			"Description : Use OCR to convert images and PDFs to text." & @CRLF & _
			"API info    : OCRSpace API V3.50" & @CRLF & _
			"Author      : Kabue Murage (dennisk@zainahtech.com)" & @CRLF & @CRLF & _
			"Usage :" & @ScriptName & " {IMG_URL|IMG_FQPN|HELP} [-h] [-k apikey] [-e engine] [-l lang] \" & @CRLF & _ ; [-l lang]
			"                       [-s delimiter] [-v] [[/ov] [/as] [/tl] [/do] [/pt] [/pf] [/vm] \" & @CRLF & _
			"                       [/dm]]" & @CRLF & _
			"Options" & @CRLF & _
			"   -h   Print help information and exit." & @CRLF & _
			"   -v   Print the version number and exit." & @CRLF & _
			"   -k   Define an API key to use. Retrieve a Key from https://rb.gy/xbimy0." & @CRLF & _
			"   -e   Define the OCR Engine to use. Allowed values are 1 and 2." & @CRLF & _
			"   -l   Define the Output Language using its ISO 639-2 langauge code." & @CRLF & _
			"   -s   Define a separator character when overlay Switch /ov is used.'|' is the Default." & @CRLF & @CRLF & _
			"Switches" & @CRLF & _
			"   /pf  Request a searchable PDF and return its direct URL. This switch overrides printing " & @CRLF & _
			"        detected text to stdOut." & @CRLF & _
			"   /ov  Return the scanned text with delimited coordinates of the bounding boxes for" & @CRLF & _
			"        each word detected, in the format (#Word|#Left|#TopPos|#Height|#Width)." & @CRLF & _
			"   /as  Allow Image upscaling. Useful for low-resolution Image and PDF scans." & @CRLF & _
			"   /tl  Use table logic for scanning (table recognition). The parsed text result is" & @CRLF & _
			"        returned line by line. Best for table OCR, receipt OCR, invoice processing" & @CRLF & _
			"        and any other tabular document processing." & @CRLF & _
			"   /do  Allow auto-detecting text orientation and auto-rotate (if needed). If this" & @CRLF & _
			"        switch is unissued, processing is done as is." & @CRLF & _
			"   /pt  Allow a PDF text layer. Relevant when a PDF is requested with '/pf' switch." & @CRLF & _
			"   /vm  Allow standard output verbosity mode." & @CRLF & _
			"   /dm  Allow running in debug mode. Logs are written to " & StringTrimRight(@ScriptName, 4) & ".log" & @CRLF & @CRLF & _
			"Remarks" & @CRLF & _
			"   - UNC paths are supported. A file name/path containing spaces need to be wrapped" & @CRLF & _
			"   with double quotes. Otherwise it is rendered as an invalid URL/PATH" & @CRLF & _
			"   to parse. Supported filetypes are PNG, GIF, PNG, JPG, TIF, BMP, JPEG & PDF." & @CRLF & _
			"   - Engine 1 (DEFAULT) is Faster , also supports Asian languages (i.e Chinese," & @CRLF & _
			"   Japanese, Korean), larger images & Multi-Page TIFF scans." & @CRLF & _
			"   - Engine 2 supports Western Latin Character languages only (English, German," & @CRLF & _
			"   French, etc), has Language auto-detection for Latin character languages," & @CRLF & _
			"   better at single number OCR/Single character OCR/Alphanumeric OCR in general," & @CRLF & _
			"   better at special characters OCR like @+-, and better with rotated text. Image" & @CRLF & _
			"   size limit is 5000px width and 5000px height." & @CRLF & _
			"   - Switches may be either upper or lower case." & @CRLF & @CRLF & _
			"Examples" & @CRLF & _
			">" & @ScriptName & ' "https://s.4cdn.org/image/fp/logo-transparent.png" -k abcdefgh1234 /tl' & @CRLF & _
			">" & @ScriptName & ' "X:\User\Invoices\Invoice.pdf" -k abcdefgh1234' & @CRLF & _
			">" & @ScriptName & ' "X:\User\Receipts Folder\Reciept1.png" -k abcdefgh1234 /as /tl' & @CRLF & @CRLF & _
			"Return Codes" & @CRLF & _
			"    0 - Success" & @CRLF & _
			"    1 - Error  : APIKey Invalid/unprovided." & @CRLF & _
			"    2 - Error  : No internet connection." & @CRLF & _
			"    5 - Error  : Unsupported filetype provided." & @CRLF & _
			"    6 - Error  : Unsupported file provided. See Remarks." ;  (Can verify with DOS variable %errorlevel%)
	Return SetError(0, 0, $sHelpString)
EndFunc   ;==>HelpInfo

; #FUNCTION# ================================================================================================================================
; Name...........:  _OCRSpace_SetUpOCR()
; Author ........:  Kabue Murage
; Description ...:  Validates and Sets up the OCR settings in retrospect.
;
; Syntax.........:  _OCRSpace_SetUpOCR($s_APIKey , $i_OCREngineID = 1 , $b_IsTable = False, $b_DetectOrientation = True, $s_LanguageISO = "eng", $b_IsOverlayRequired = False, $b_AutoScaleImage = False, $b_IsSearchablePdfHideTextLayer = False)
;
; Parameters ....:
; $s_APIKey              - [Required] The key provided by OCRSpace. (http://eepurl.com/bOLOcf)
; $i_OCREngineID         - [Optional] The OCR Engine to use. Can either be 1 or 2 (DEFAULT : 1)
;               Features of OCR Engine 1:
;                        - Supports more languages (including Asian languages like Chinese, Japanese and Korean)
;                        - Faster.
;                        - Supports larger images.
;                        - Multi-Page TIFF scan support.
;               Features of OCR Engine 2:
;                        - Western Latin Character languages only (English, German, French,...)
;                        - Language auto-detect. It does not matter what OCR language you select, as long as it uses Latin characters
;                          Usually better at single number OCR, single character OCR and alphanumeric OCR in general
;                          (e. g. SUDOKO, Dot Matrix OCR, MRZ OCR, Single digit OCR, Missing 1st letter after OCR, ... )
;                        - Usually better at special characters OCR like @+-...
;                        - Usually better with rotated text (Forum: Detect image spam)
;                        - Image size limit 5000px width and 5000px height
;
; $b_IsTable             - [Optional] True or False (DEFAULT : False)
;                          If set to true, the OCR logic makes sure that the parsed text result is always returned line by line. This switch
;                          is recommended for table OCR, receipt OCR, invoice processing and all other type of input documents that have a table
;                          like structure.
;
; $b_DetectOrientation   - [Optional] True or False (DEFAULT : True)
;                          If set to true, the image is correctly rotated the TextOrientation parameter is
;                          returned in the JSON response. If the image is not rotated, then TextOrientation=0
;                          otherwise it is the degree of the rotation, e. g. "270".
;
; $s_LanguageISO         - [Optional] (DEFAULT : eng)
;                          Language used for OCR. If no language is specified, English eng is taken as default.
;                          IMPORTANT: The API uses an ISO 639-2 Code, so it's explictly limited to 3 characters, never less!
;               Engine 1:
;                          Arabic=ara, Bulgarian=bul, Chinese(Simplified)=chs, Chinese(Traditional)=cht, Croatian = hrv, Czech = cze
;                          Danish = dan, Dutch = dut, English = eng, Finnish = fin, French = fre, German = ger, Greek = gre, Hungarian = hun
;                          Korean = kor, Italian = ita, Japanese = jpn, Polish = pol ,Portuguese = por, Russian = rus, Slovenian = slv
;                          Spanish = spa, Swedish = swe, Turkish = tur
;               Engine 2:
;                         Engine2 has automatic Western language detection, so this value will be ignored.
;
; $b_IsOverlayRequired  - [Optional] Default = False.  If true, returns the coordinates of the bounding boxes for each word.
;                         If false, the OCR'ed text is returned only as a
;                         text block (THIS MAKES THE JSON REPONSE SMALLER). Overlay data can be used, for example, to show text over the image.
;
; $b_AutoScaleImage     - [Optional] True or False (DEFAULT : False)
;                         If set to true, the image is upscaled. This can improve the OCR result significantly,
;                         especially for low-resolution PDF scans. The API uses scale=false by default.
;
; $b_IsSearchablePdfHideTextLayer
;                       - [Optional] True or False (DEFAULT : False)
;                         If true, the text layer is hidden (not visible)
;
;
; Return values .: Success : Returns an array to use in _OCRSpace_ImageGetText @error set to 0.
;                : Failure : @error Switch set to non zero on failure.
; Modified.......:
; Remarks .......: Auto validates incorrect options by ensuring they are of valid filetypes
; Related .......: _OCRSpace_ImageGetText()
; Link ..........:
; Example .......: 0
; ============================================================================================================================================
Func _OCRSpace_SetUpOCR($s_APIKey, $i_OCREngineID = 1, $b_IsTable = False, $b_DetectOrientation = True, $s_LanguageISO = "eng", $b_IsOverlayRequired = False, $b_AutoScaleImage = False, $b_IsSearchablePdfHideTextLayer = False, $b_IsCreateSearchablePdf = False)
	If ($s_APIKey = "") Then Return SetError(1, 0, "Invalid key")
	Local $a_lSetUp[9][2]
	If $bDebug Then LogWrite(@NumParams & "/key:" & $s_APIKey & "/engine:" & $i_OCREngineID & "/table:" & $b_IsTable & "/orientation:" & $b_DetectOrientation & "/lang:" & $s_LanguageISO & "/overlay:" & $b_IsOverlayRequired & "/scale:" & $b_AutoScaleImage & "/pdftextlayer:" & $b_IsSearchablePdfHideTextLayer & "/pdfsearchable:" & $b_IsCreateSearchablePdf, $s_gLogFile)

	$a_lSetUp[0][0] = "apikey" ; ! Required!
	$a_lSetUp[0][1] = $s_APIKey
	$a_lSetUp[1][0] = "detectOrientation"
	$a_lSetUp[1][1] = (IsBool($b_DetectOrientation) ? $b_DetectOrientation : True)
	$a_lSetUp[2][0] = "OCREngine"
	$a_lSetUp[2][1] = ((Int($i_OCREngineID) = 2) ? 2 : 1)
	$a_lSetUp[3][0] = "isOverlayRequired"
	$a_lSetUp[3][1] = (IsBool($b_IsOverlayRequired) ? $b_IsOverlayRequired : False)
	$a_lSetUp[4][0] = "language" ; ISO (632-B Lang Prefix), length 3 ..
	$a_lSetUp[4][1] = (((StringIsAlpha($s_LanguageISO) And StringLen($s_LanguageISO) = 3)) ? $s_LanguageISO : "eng")
	$a_lSetUp[5][0] = "isCreateSearchablePdf"
	$a_lSetUp[5][1] = (IsBool($b_IsCreateSearchablePdf) ? $b_IsCreateSearchablePdf : False)
	$a_lSetUp[6][0] = "isSearchablePdfHideTextLayer"
	$a_lSetUp[6][1] = (IsBool($b_IsSearchablePdfHideTextLayer) ? $b_IsSearchablePdfHideTextLayer : False)
	$a_lSetUp[7][0] = "scale"
	$a_lSetUp[7][1] = (IsBool($b_AutoScaleImage) ? $b_AutoScaleImage : False)
	$a_lSetUp[8][0] = "isTable"
	$a_lSetUp[8][1] = (IsBool($b_IsTable) ? $b_IsTable : False)

	Return SetError(((IsArray($a_lSetUp) = 1) ? 0 : 1), UBound($a_lSetUp), $a_lSetUp)
EndFunc   ;==>_OCRSpace_SetUpOCR

Func LogWrite($text, $file)
	Return _FileWriteLog($file, _NowTime() & ":" & $text & @CRLF, 1)
EndFunc   ;==>LogWrite
; #FUNCTION# =======================================================================================================================
; Title .........: _OCRSpace_ImageGetText
; Author ........: Kabue Murage
; Description ...: Retrieves text from an image using the OCRSpace API
; Syntax.........: _OCRSpace_ImageGetText($aOCR_OptionsHandle, $sImage_UrlOrFQPN, $iReturnType = 0, $sURLVar = "")
; Link ..........:
; Parameters ....:  $aOCR_OptionsHandle      - The reference array variable  as created by _OCRSpace_SetUpOCR()
;                :  $sImage_UrlOrFQPN        - A valid : Path to an image you want OCR'ed from your PC or URL to an image you want OCR'ed.
;                   $iReturnType               0 return detected text only.
;                                              1 return an array
; Return values .: Success : Returns the detected text of type specified at $iReturnType
;                             -  If a searchable PDF was requested ,its url will be assigned to the string $sURLVar, so to get it evaluate it!
;                             -  @error Switch set to 111 if no error occoured.
;                             -  @extended is set to the Processing Time In Milliseconds
;                  Failure : Returns "" and @error Switch set to non-zero ;
;                           1 - If UNSET options or error initializing options.
;                           2 - If $sImage_UrlOrFQPN is not a valid Image or URL.
;                           3 - If an error occurs opening a local file specified.
;                           4 - If a searchable pdf was requested and a string to declare the result url is undefined.
;                           5 - An unsupported filetype parsed.
;                           6 - Failed to create http request object
;                           7 - Failed to parse json returned by OCRSpace
;                           8 - $sURLVar is not a valid string.
; Remarks .......: - Setup your OCR options beforehand using _OCRSpace_SetUpOCR. Also note that the URL method is easy and fast to use, compared to uploading a local file.
;                  - StringLeft(@error, 2) shows if used OCR Engine completed successfully, partially or failed with error.
;                           1 - Parsed Successfully (Image / All pages parsed successfully)
;                           2 - Parsed Partially (Only few pages out of all the pages parsed successfully)
;                           3 - Image / All the PDF pages failed parsing (This happens mainly because the OCR engine fails to parse an image)
;                           4 - Error occurred when attempting to parse (This happens when a fatal error occurs during parsing )
;
;   * =========================================
;   *       $__ErrorCode_
;   * ====================================
;   ? 0  : File not found
;   ? 1  : Success
;   ? 10 : OCR Engine Parse Error
;   ? 20 : Timeout
;   ? 30 : Validation Error
;   ? 99 : Unknown Error
; ===============================================================================================================================
Func _OCRSpace_ImageGetText($aOCR_OptionsHandle, $sImage_UrlOrFQPN, $iReturnType = 0, $sURLVar = "__OCRSPACE_SEARCHABLE_PDFLINK")

	Local $oError = ObjEvent("AutoIt.Error", "___OCRSpace__COMErrFunc")
	#forceref $oError

	If Not (IsArray($aOCR_OptionsHandle) And UBound($aOCR_OptionsHandle, $UBOUND_COLUMNS) <> 5) Then Return SetError(1, 0, "")
	If Not IsString($sURLVar) Then Return SetError(8, 0, "")

	Local $s_lExt, $s_lParams__
	Local $i_lAPIRespStatusCode__
	Local $d_ImgBinDat__
	Local $h_lFileOpen__

	; If a searchable pdf was requested and the URL string to be set to is undefined.
	If ($aOCR_OptionsHandle[5][1]) Then
		Switch $sURLVar
			Case Default, -1, ""
				$sURLVar = "__OCRSPACE_SEARCHABLE_PDFLINK"
			Case Else
				$sURLVar = (StringLen($sURLVar) > 1) ? $sURLVar : "__OCRSPACE_SEARCHABLE_PDFLINK"
		EndSwitch
	EndIf

	Local $h_lRequestObj__ = Null

	If (FileExists($sImage_UrlOrFQPN) And StringInStr(FileGetAttrib($sImage_UrlOrFQPN), "D") = 0) Then
		$s_lExt = StringLower(StringTrimLeft($sImage_UrlOrFQPN, StringInStr($sImage_UrlOrFQPN, ".", 0, -1)))
		Switch $s_lExt
			Case "pdf", "gif", "png", "jpg", "tif", "bmp", "pdf", "jpeg"
				; do nothing ..
				; Supported image file formats are png, jpg (jpeg), gif, tif (tiff) and bmp.
				; For document ocr, the api supports the Adobe PDF format. Multi-page TIFF files are supported.
			Case Else
				If $bDebug Then LogWrite("invalid filetype provided", $s_gLogFile)
				Return SetError(5, 0, "")
		EndSwitch

		$h_lFileOpen__ = FileOpen($sImage_UrlOrFQPN, 16) ; $FO_BINARY
		If $h_lFileOpen__ = -1 Then
			If $bDebug Then LogWrite("Requested file failed to open in binary mode.", $s_gLogFile)
			Return SetError(3, 0, "")
		EndIf

		$d_ImgBinDat__ = FileRead($h_lFileOpen__)
		FileClose($h_lFileOpen__)
		$s_lb64Dat__ = _Base64Encode($d_ImgBinDat__)
		$s_lEncb64Dat__ = __URLEncode_($s_lb64Dat__)

		$h_lRequestObj__ = __POSTObjCreate()
		If $h_lRequestObj__ = -1 Then Return SetError(6, 0, "")

		$h_lRequestObj__.Open("POST", "https://api.ocr.space/parse/image", False) ; Let's Go!

		$s_lParams__ = "base64Image=data:" & ($s_lExt = "pdf" ? "application/" & $s_lExt : "image/" & $s_lExt) & ";base64," & $s_lEncb64Dat__ & "&"

		; Append all Prameters..
		For $i = 1 To UBound($aOCR_OptionsHandle) - 1
			$s_lParams__ &= StringLower($aOCR_OptionsHandle[$i][0] & "=" & $aOCR_OptionsHandle[$i][1] & "&")
		Next
		$s_lParams__ = StringTrimRight($s_lParams__, 1)

		$h_lRequestObj__.SetRequestHeader($aOCR_OptionsHandle[0][0], $aOCR_OptionsHandle[0][1])
		$h_lRequestObj__.SetRequestHeader("Content-Type", "application/x-www-form-urlencoded")
		$h_lRequestObj__.Send($s_lParams__)

	ElseIf _PathIsURLA__($sImage_UrlOrFQPN) Then
		; The important limitation of the GET api endpoint is it only allows image and
		; PDF submissions via the URL method as only HTTP POST requests can supply additional
		; data to the server in the message body...

		$h_lRequestObj__ = _GETObjCreate()
		If $h_lRequestObj__ = -1 Then Return SetError(6, 0, "")

		; Every option for this api call is to be parsed inside the URL! So , all the parameters can
		; be appended to create a valid url. So by design, a GET api cannot support file uploads
		; (file parameter) or BASE64 strings (base64image) method..

		$s_lParams__ = "https://api.ocr.space/parse/ImageUrl?" & $aOCR_OptionsHandle[0][0] & "=" & $aOCR_OptionsHandle[0][1] & "&url=" & $sImage_UrlOrFQPN & "&"
		For $i = 1 To UBound($aOCR_OptionsHandle) - 1
			$s_lParams__ &= StringLower($aOCR_OptionsHandle[$i][0] & "=" & $aOCR_OptionsHandle[$i][1] & "&")
		Next
		; Trim a trailing ampersand.
		$s_lParams__ = StringTrimRight($s_lParams__, 1)

		$h_lRequestObj__.Open("GET", $s_lParams__, False)
		$h_lRequestObj__.Send()
	Else
		Return SetError(2, 0, "unsupported type !")
	EndIf

	$h_lRequestObj__.WaitForResponse()
	$s_lAPIResponseText__ = $h_lRequestObj__.ResponseText
	$i_lAPIRespStatusCode__ = $h_lRequestObj__.Status
	; Release the object.
	$h_lRequestObj__ = Null

	; extended utf-8 charset incase the json contains accents i.e characters like àèéìòù
	$s_lAPIResponseText__ = _WinAPI_WideCharToMultiByte($s_lAPIResponseText__, 65001)
	Switch Int($i_lAPIRespStatusCode__)
		Case 200
			; If ($aOCR_OptionsHandle[3][1]) And ($iReturnType = 1) Then
			; ConsoleWrite("Overlay info requested as an array :)" & @CRLF)
			; EndIf
			Local $o_lJson__ = _JSON_Parse($s_lAPIResponseText__)
			If Not @error Then
				$__ErrorCode_ = Null
				$s_lDetectedTxt__ = _JSON_Get($o_lJson__, "ParsedResults[0].ParsedText")            ; Returned
				$s_lProcessingTimeInMs = _JSON_Get($o_lJson__, "ProcessingTimeInMilliseconds")      ; Set to @extended.
				; The exit code shows if OCR completed successfully, partially or failed with error.
				$i_lOCREngineExitCode = _JSON_Get($o_lJson__, "OCRExitCode")                     ; Set to 1 if completed all successfully
				$__ErrorCode_ &= $i_lOCREngineExitCode
				; The exit code returned by the parsing engine. Set to extended..
				$i_lFileParseExitCode = _JSON_Get($o_lJson__, "ParsedResults[0].FileParseExitCode")
				$i_lFileParseExitCode = (StringLeft($i_lFileParseExitCode, 1) = "-") ? StringTrimLeft($i_lFileParseExitCode, 1) : $i_lFileParseExitCode
				$__ErrorCode_ &= $i_lFileParseExitCode
				$s__lSearchablePDFURL_ = _JSON_Get($o_lJson__, "SearchablePDFURL")

				Assign($sURLVar, $s__lSearchablePDFURL_, $ASSIGN_FORCEGLOBAL)

				$i_lErrorOnProcessing = (_JSON_Get($o_lJson__, "IsErroredOnProcessing") ? 0 : 1) ; IsErroredOnProcessing is initially bool.
				$__ErrorCode_ &= $i_lErrorOnProcessing

				Switch $iReturnType
					Case 0, Default, -1
						Return SetError($__ErrorCode_, $s_lProcessingTimeInMs, $s_lDetectedTxt__)
					Case 1
						If Not ($aOCR_OptionsHandle[3][1]) Then
							; ConsoleWrite("Overlay info was NOT requested at _OCRSpace_SetUpOCR()" & @CRLF)
							If $bDebug Then LogWrite(@NumParams & "Overlay info was NOT requested at _OCRSpace_SetUpOCR()", $s_gLogFile)
							; return a stractured array nevertheless
							Local $aRet[1][2]

							$aRet[0][0] = StringLen($aRet)
							$aRet[0][1] = $s_lDetectedTxt__
							Return SetError(($__ErrorCode_ = 111 ? 0 : $__ErrorCode_), $s_lProcessingTimeInMs, $aRet)
						EndIf

						Local $a_lOverlayArray__[0][5]
						Local $i_lEnumAllJSONObj__ = 0, $i_lEnumLinesJSONObj__ = 0, $i_lEnum_row__ = 0
						Local $s_lWordText__, $i_lWordPosLeft__, $i_lWordPosTop__, $i_lWordHeight__, $i_lWordWidth__

						While True
							$s_lWordText__ = _JSON_Get($o_lJson__, "ParsedResults[0].TextOverlay.Lines[" & $i_lEnumLinesJSONObj__ & "].Words[" & $i_lEnumAllJSONObj__ & "].WordText")
							If ($s_lWordText__ = "") Then
								$i_lEnumLinesJSONObj__ += 1
								$i_lEnumAllJSONObj__ = 0
								$s_lWordText__ = _JSON_Get($o_lJson__, "ParsedResults[0].TextOverlay.Lines[" & $i_lEnumLinesJSONObj__ & "].Words[" & $i_lEnumAllJSONObj__ & "].WordText")
							EndIf
							$i_lWordPosLeft__ = _JSON_Get($o_lJson__, "ParsedResults[0].TextOverlay.Lines[" & $i_lEnumLinesJSONObj__ & "].Words[" & $i_lEnumAllJSONObj__ & "].Left")
							; If reached at EOO, then exitloop without wasting time..
							If @error Then ExitLoop 1
							$i_lWordPosTop__ = _JSON_Get($o_lJson__, "ParsedResults[0].TextOverlay.Lines[" & $i_lEnumLinesJSONObj__ & "].Words[" & $i_lEnumAllJSONObj__ & "].Top")
							$i_lWordHeight__ = _JSON_Get($o_lJson__, "ParsedResults[0].TextOverlay.Lines[" & $i_lEnumLinesJSONObj__ & "].Words[" & $i_lEnumAllJSONObj__ & "].Height")
							$i_lWordWidth__ = _JSON_Get($o_lJson__, "ParsedResults[0].TextOverlay.Lines[" & $i_lEnumLinesJSONObj__ & "].Words[" & $i_lEnumAllJSONObj__ & "].Width")

							; Redim the rows of our 2D array..
							ReDim $a_lOverlayArray__[UBound($a_lOverlayArray__, $UBOUND_ROWS) + 1][UBound($a_lOverlayArray__, $UBOUND_COLUMNS)]
							$a_lOverlayArray__[$i_lEnum_row__][0] = $s_lWordText__
							$a_lOverlayArray__[$i_lEnum_row__][1] = $i_lWordPosLeft__
							$a_lOverlayArray__[$i_lEnum_row__][2] = $i_lWordPosTop__
							$a_lOverlayArray__[$i_lEnum_row__][3] = $i_lWordHeight__
							$a_lOverlayArray__[$i_lEnum_row__][4] = $i_lWordWidth__

							$i_lEnumAllJSONObj__ += 1
							$i_lEnum_row__ += 1
						WEnd
						; ? Check all possibible values for the error code.
						If ($__ErrorCode_ = 111) Then $__ErrorCode_ = 0

						Return SetError($__ErrorCode_, $s_lProcessingTimeInMs, $a_lOverlayArray__)
				EndSwitch
			EndIf
		Case Else
			If $bDebug Then LogWrite("Error : API Status code:" & $i_lAPIRespStatusCode__, $s_gLogFile)
	EndSwitch
	Return SetError(1, $i_lAPIRespStatusCode__, $s_lAPIResponseText__)
EndFunc   ;==>_OCRSpace_ImageGetText


Func ___OCRSpace__COMErrFunc()
	If Not IsConnected() Then
		; ConsoleWrite("No Internet Connection!" & @CRLF)
		If $bDebug Then LogWrite("No Internet Connection!", $s_gLogFile)

		; SetError(800, 0, -1)
	EndIf
	; Do nothing special, just check @error after suspect functions.
EndFunc   ;==>___OCRSpace__COMErrFunc


Func IsConnected()

	Local Const $NETWORK_ALIVE_LAN = 0x1         ; net card connection
	Local Const $NETWORK_ALIVE_WAN = 0x2         ; RAS (internet) connection
	Local Const $NETWORK_ALIVE_AOL = 0x4         ; AOL

	Local $aRet, $iResult = False

	$aRet = DllCall("sensapi.dll", "int", "IsNetworkAlive", "int*", 0)

	If BitAND($aRet[1], $NETWORK_ALIVE_LAN) Then $iResult = "LAN connected"
	If BitAND($aRet[1], $NETWORK_ALIVE_WAN) Then $iResult = "WAN connected"
	If BitAND($aRet[1], $NETWORK_ALIVE_AOL) Then $iResult = "AOL connected"

	Return $iResult
EndFunc   ;==>IsConnected

Func _CmdLine_SwitchDisabled($sKey)
	For $i = 1 To $CmdLine[0]
		; Return (StringRegExp($CmdLine[$i], "\-([a-zA-Z]*)" & $sKey & "([a-zA-Z]*)")) ? True : False
		If StringRegExp($CmdLine[$i], "\-([a-zA-Z]*)" & $sKey & "([a-zA-Z]*)") Then
			Return True
		EndIf
	Next
	; Return False
EndFunc   ;==>_CmdLine_SwitchDisabled

Func _CmdLine_SwitchEnabled($sKey)
	For $i = 1 To $CmdLine[0]
		If StringRegExp($CmdLine[$i], "\+([a-zA-Z]*)" & $sKey & "([a-zA-Z]*)") Then
			Return True
		EndIf
	Next
	Return False
EndFunc   ;==>_CmdLine_SwitchEnabled

Func _CmdLine_SwitchExists($sKey)
	For $i = 1 To $CmdLine[0]
		If StringRegExp($CmdLine[$i], "(\+|\-)([a-zA-Z]*)" & $sKey & "([a-zA-Z]*)") Then
			Return True
		EndIf
	Next
	Return False
EndFunc   ;==>_CmdLine_SwitchExists

Func _CmdLine_Get($sKey, $mDefault = Null)
	For $i = 1 To $CmdLine[0]
		If $CmdLine[$i] = "/" & $sKey Or $CmdLine[$i] = "-" & $sKey Then     ; Or $CmdLine[$i] = "--" & $sKey
			If $CmdLine[0] >= $i + 1 Then
				Return $CmdLine[$i + 1]
			EndIf
		EndIf
	Next
	Return $mDefault
EndFunc   ;==>_CmdLine_Get

Func _CmdLine_GetValByIndex($iIndex, $mDefault = Null)
	If $CmdLine[0] >= $iIndex Then
		Return $CmdLine[$iIndex]
	Else
		Return $mDefault
	EndIf
EndFunc   ;==>_CmdLine_GetValByIndex

Func _CmdLine_KeyExists($sKey)
	For $i = 1 To $CmdLine[0]
		If $CmdLine[$i] = "/" & $sKey Or $CmdLine[$i] = "-" & $sKey Then     ; or $CmdLine[$i] = "--" & $sKey
			Return True
		EndIf
	Next
	Return False
EndFunc   ;==>_CmdLine_KeyExists

Func _CmdLine_ValueExists($sValue)
	For $i = 1 To $CmdLine[0]
		If $CmdLine[$i] = $sValue Then
			Return True
		EndIf
	Next
	Return False
EndFunc   ;==>_CmdLine_ValueExists



; #INTERNAL_USE_ONLY#============================================================================================================
; Name...........: _PathIsURLA__
; Description ...: Uses shlwapi.dll to determine a valid URL.
;                  prefer this to implimenting a long Regex for it
; Syntax.........:_PathIsURLA__()
; Return values .: Success - true : if $_sPath is a valid URL/URI
; Modified ......: Kabue Murage
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================

Func _PathIsURLA__($_sPath)
	Local $_aCall = DllCall("shlwapi.dll", "BOOL", "PathIsURLA", "STR", $_sPath)
	If @error = 0 And IsArray($_aCall) Then
		Return $_aCall[0] = 1
	EndIf
	Return False
EndFunc   ;==>_PathIsURLA__


; #INTERNAL_USE_ONLY#============================================================================================================
; Name...........: __URLEncode_
; Description ...: Returns an inline URL encoded string.
; Syntax.........:__URLEncode_()
; Return values .: Success - An inline URL encoded string.
; Modified ......: Kabue Murage
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __URLEncode_($urlText)
	Local $url = "", $acode
	For $i = 1 To StringLen($urlText)
		$acode = Asc(StringMid($urlText, $i, 1))
		Select
			Case ($acode >= 48 And $acode <= 57) Or ($acode >= 65 And $acode <= 90) Or ($acode >= 97 And $acode <= 122)
				$url = $url & StringMid($urlText, $i, 1)
			Case $acode = 32
				$url = $url & "+"
			Case Else
				$url = $url & "%" & Hex($acode, 2)
		EndSelect
	Next
	Return $url
EndFunc   ;==>__URLEncode_

; #INTERNAL_USE_ONLY#============================================================================================================
; Name...........: _Base64Encode
; Description ...: Returns a Base64 code for the data parsed.
; Syntax.........:_Base64Encode()
; Return values .: Success - A Base64 code for the data parsed.
; Modified ......: Kabue Murage
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _Base64Encode($Data, $LineBreak = 76)
	Local $Opcode = _
			'0x5589E5FF7514535657E8410000004142434445464748494A4B4C4D4E4F505152535455565758595A61626364656' & _
			'66768696A6B6C6D6E6F707172737475767778797A303132333435363738392B2F005A8B5D088B7D108B4D0CE98F0000000FB6' & _
			'33C1EE0201D68A06880731C083F901760C0FB6430125F0000000C1E8040FB63383E603C1E60409C601D68A0688470183F9017' & _
			'6210FB6430225C0000000C1E8060FB6730183E60FC1E60209C601D68A06884702EB04C647023D83F90276100FB6730283E63F' & _
			'01D68A06884703EB04C647033D8D5B038D7F0483E903836DFC04750C8B45148945FC66B80D0A66AB85C90F8F69FFFFFFC6070' & _
			'05F5E5BC9C21000'
	Local $CodeBuffer = DllStructCreate('byte[' & BinaryLen($Opcode) & ']')
	DllStructSetData($CodeBuffer, 1, $Opcode)
	$Data = Binary($Data)
	Local $Input = DllStructCreate('byte[' & BinaryLen($Data) & ']')
	DllStructSetData($Input, 1, $Data)
	$LineBreak = Floor($LineBreak / 4) * 4
	Local $OputputSize = Ceiling(BinaryLen($Data) * 4 / 3)
	$OputputSize = $OputputSize + Ceiling($OputputSize / $LineBreak) * 2 + 4

	Local $Ouput = DllStructCreate('char[' & $OputputSize & ']')
	DllCall('user32.dll', 'none', 'CallWindowProc', 'ptr', DllStructGetPtr($CodeBuffer), _
			'ptr', DllStructGetPtr($Input), _
			'int', BinaryLen($Data), _
			'ptr', DllStructGetPtr($Ouput), _
			'uint', $LineBreak)
	Return DllStructGetData($Ouput, 1)
EndFunc   ;==>_Base64Encode



; #INTERNAL_USE_ONLY#============================================================================================================
; Name...........: __POSTObjCreate
; Description ...: Returns a POST object handle.
; Syntax.........:__POSTObjCreate()
; Return values .: Success -A valid Winhttprequest v5.1 object handle to use for POST requests.
; Modified ......: Kabue Murage
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func __POSTObjCreate()
	Local $o_lHTTP = ObjCreate("winhttp.winhttprequest.5.1")
	Return SetError(@error, 0, ((IsObj($o_lHTTP) = 1) ? $o_lHTTP : -1))
EndFunc   ;==>__POSTObjCreate


; #INTERNAL_USE_ONLY#============================================================================================================
; Name...........: _GETObjCreate
; Description ...: Returns a GET object handle.
; Syntax.........:_GETObjCreate()
; Return values .: Success -A valid Winhttprequest v5.1 object handle to use for GET requests.
; Modified ......: Kabue Murage
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: No
; ===============================================================================================================================
Func _GETObjCreate()
	Local $o_lHTTP
	$o_lHTTP = ObjCreate("winhttp.winhttprequest.5.1")
	Return SetError(@error, 0, ((IsObj($o_lHTTP) = 1) ? $o_lHTTP : -1))
EndFunc   ;==>_GETObjCreate



; #FUNCTION# ====================================================================================================================
; Name ..........: PathIsValid
; Description ...: Checks if the path is valid  or not
; Syntax ........: PathIsValid($Path)
; Parameters ....: $Path                - the path string to check.
; Return values .: 1 if the path is valid and 0 if the path is not valid
; Author ........: gil900
; Modified ......:
; Remarks .......:
; Related .......:
; Link ..........:
; Example .......: yes
; ===============================================================================================================================
Func PathIsValid($Path)
	Local $var = StringSplit($Path, "\", 1)
	If StringLen($var[1]) = 2 And StringRight($var[1], 1) = ":" And StringIsASCII($var[1]) And StringIsAlpha(StringLeft($var[1], 1)) Then
		;Return 1
		If $var[0] > 1 Then
			Local $Excluded[9] = [8, "?", "*", '"', "<", ">", "|", "/", ":"]
			For $a = 2 To $var[0]
				If $var[$a] = "" And $a > 2 Or StringIsSpace($var[$a]) Then Return 0
				If StringStripWS($var[$a], 3) <> $var[$a] Then Return 0
				For $a2 = 1 To $Excluded[0]
					If StringInStr($var[$a], $Excluded[$a2]) > 0 Then Return 0

				Next
			Next
			Return 1
		Else
			Return 1
		EndIf
	Else
		Return 0
	EndIf
EndFunc   ;==>PathIsValid
