
# CL-OCRSpace

 
 
`CL-OCRSpace`is [OCRSpace API](https://ocr.space/) on the command line. 
<!-- <br> It will let you automate scanning images of text and PDFs right from your terminal,  -->

<img src="https://github.com/KabueMurage/CL-OCRSpace/blob/main/Preview/AllPreview.gif?raw=true" align="middle" alt="preview.gif">


> OCRSpace API - A powerful Online OCR service that converts images of text documents into editable files by using Optical Character Recognition (OCR)



#### Some points worth pointing out : 

 <img src="https://i.imgur.com/iKrkHYn.png" align="left" alt="QRCode">
 
    1. To use this, register for your free OCR API key at https://rb.gy/xbimy0
    2. This program requires an active internet connection. 
    3. This program is indipendent and unofficial, This code is in no way affiliated with, authorized, maintained, sponsored or endorsed by OCRSpace.
    4. This program relies heavily on the OCRSpace API endpoint. Check the API performance and uptime at the API status page : https://status.ocr.space/
<br>
<br>
<hr>
<br>
    
### Installation

Add to [path](https://en.wikipedia.org/wiki/PATH_%28variable%29) or alternatively execute it in the directory containing  `CL-OCRSpace.exe`.<br>
Running `CL-OCRSpace.exe -v` should print the program version information to the standard output.

### Syntax & Usage

| Parameter | Description | Input type |Default Value|
| ----------|-------------|------------|-------------|
| **`-h`**| Print help information and exit.| none | none|
|`-v`| Print the version number and exit.| none | none|
| **`-k`**| Specify an API key to use. Retrieve a Key from https://rb.gy/xbimy0|*string*| *Null*|
| `-e`| Specify the OCR Engine to use. Allowed args are 1 and 2 <br> `CL-OCRSpace.exe "Receipt.png" -e 2 /ov`| *integer*|1|
| `-l` | Define the Output Language using its ISO 639-2 langauge code. <br> `CL-OCRSpace.exe "Receipt.png" -l eng` |*string* |*eng*|
|`-s`| Specify a separator character when overlay flag `/ov` is used.<br> `CL-OCRSpace.exe "Receipt.png" -s "#" /ov` |string| "\|"|
|**Switch** | **Switch description**|**Input Type** |**Default Value** |
|`/pf`|Request a searchable PDF and return its direct URL. This switch overrides printing<br>detected text to stdOut. <br> `CL-OCRSpace.exe "Receipt.png" /pf`| none| False|
|`/ov`| Return the scanned text with delimited coordinates of the bounding boxes for <br> each word detected, in the format (#Word\|#Left\|#TopPos\|#Height\|#Width).| none | False|
|`/as`| Allow Image upscaling. Useful for low-resolution Image and PDF scans. <br> `CL-OCRSpace.exe "Receipt.png" -e 2 /as` | none | False |
|`/tl`| Use table logic for scanning (table recognition). The parsed text result is returned line by line. Best for table OCR, receipt OCR, invoice processing and any other tabular document processing.<br> `CL-OCRSpace.exe "Receipt.png" /tl` | none | False |
|`/do`| Allow auto-detecting text orientation and auto-rotate (if needed).<br> If this flag is unissued, processing is done as is. <br> `CL-OCRSpace.exe "Receipt.png" /do` | none | True |
|`/pt`| Allow a PDF text layer. Relevant when a PDF is requested with '/pf' switch. <br> `CL-OCRSpace.exe "Receipt.png" /pf /pt`| none | False |
|`/vm`| Allow standard output verbosity mode. <br> `CL-OCRSpace.exe "Receipt.png" /vm` | none | False|
|`/dm`| Allow running in debug mode. Logs are written to CL-OCRSpace.log <br> `CL-OCRSpace.exe "Receipt.png" /dm`| none | False |

<hr>
<br>
    
#### Remarks
   - UNC paths are supported. A file name/path containing spaces need to be wrapped
   with double quotes. Otherwise it is rendered as an invalid URL/PATH
   to parse. Supported filetypes are PNG, GIF, PNG, JPG, TIF, BMP, JPEG & PDF.
   - Engine 1 (DEFAULT) is Faster , also supports Asian languages (i.e Chinese,
   Japanese, Korean), larger images & Multi-Page TIFF scans.
   - Engine 2 supports Western Latin Character languages only (English, German,
   French, etc), has Language auto-detection for Latin character languages,
   better at single number OCR/Single character OCR/Alphanumeric OCR in general,
   better at special characters OCR like @+-, and better with rotated text. Image
   size limit is 5000px width and 5000px height.
   - Flags are not case sensitive. 

#### Return values

    0 - Success
    1 - Error  : APIKey Invalid/unprovided.
    2 - Error  : No internet connection.
    5 - Error  : Unsupported filetype provided.
    6 - Error  : Unsupported file provided. See Remarks.
    

