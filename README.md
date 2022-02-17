
# CL-OCRSpace
`CL-OCRSpace`is [OCRSpace API](https://ocr.space/) on the command line. <br> It will let you automate scanning images of text and PDFs right from your terminal, 

> OCRSpace API - A powerful Online OCR service that converts images of text documents into editable files by using Optical Character Recognition (OCR)



#### Some points worth pointing out : 

 <img src="https://i.imgur.com/iKrkHYn.png" align="left" alt="QRCode">
 
    1. Register at https://rb.gy/xbimy0 for your free OCR API key.
    2. This program requires an active internet connection. 
    3. This program is indipendent and unofficial, This code is in no way affiliated with, authorized, maintained, sponsored or endorsed by OCRSpace.
    4. This program relies heavily on the OCRSpace API endpoint. www.google.com
<br>
<br>
<hr>
<br>
    
### Installation

Add to [path](https://en.wikipedia.org/wiki/PATH_%28variable%29) or alternatively execute it in the directory containing  `CL-OCRSpace.exe`.<br>
Running `CL-OCRSpace.exe -ver` should print the version information to the standard output.

### Syntax & Usage

| Parameter | Description | Input type |Default Value|
| ----------|-------------|------------|-------------|
| **`-h`**| Print help information to standard output.| none | none
| **`-k`**| Specify an API key to use. Retrieve a Key from https://rb.gy/xbimy0|*string*| *Null*|
| `-e`| Specify the OCR Engine to use. Allowed args are 1 and 2 <br> `CL-OCRSpace.exe "Receipt.png" -e 2 /ov`| *integer*|1|
| `-l` | Specify the Output Language using an ISO 639-2 langauge code <br> `CL-OCRSpace.exe "Receipt.png" -l eng` |*string* |*eng*|
|`-s`| Specify a separator character when overlay flag /ov is used.<br>Should be 1 character in length |string| "\|"|
|`-p`| Requests a searchable PDF file. If an output is specified, the pdf is downloaded.<br> Otherwise, overrides printing detected text prints the pdf URL.|string|

