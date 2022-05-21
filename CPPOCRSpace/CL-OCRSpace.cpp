/**
 *  Copyright (C) 2022 Kabue Murage
 *  All rights reserved.
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to
 *  deal in the Software without restriction, including without limitation the
 *  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 *  sell copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
 *  THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 *  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 *  IN THE SOFTWARE.
 */

#include "CL-OCRSpace-includes.h"

using namespace std;

// OCRSpace supported image file formats are png, jpg (jpeg), gif, tif (tiff) and bmp.
// For document ocr, the api supports the Adobe PDF format. Multi-page TIFF files are supported.
std::string sAllowedFiletypes[] = {
  ".pdf",
  ".gif",
  ".png",
  ".jpg",
  ".tif",
  ".bmp",
  ".pdf",
  ".jpeg",
  ""
};

// "CL-OCRSpace v1.0 by Kabue Murage.\n"
// "API info    : OCRSpace API V3.50\n"
// "Author      : Kabue Murage (dennisk@zainahtech.com)\n" 

std::string HelpInfo = "Usage  CL-OCRSpace  {IMG_URL|IMG_FQPN|HELP} [-h] [-k apikey] [-e engine] [-l lang] \\\n"
  "                    [-s delimiter] [-v] [[/ov] [/as] [/tl] [/do] [/pt] [/pf] [/vm] \\\n"
  "                    [/dm]]\n"
  "Options\n"
  "   -k   Define an API key to use. Retrieve a Key from https://rb.gy/xbimy0.\n"
  "   -e   Define the OCR Engine to use. Allowed values are 1 and 2.\n"
  "   -l   Define the Output Language using its ISO 639-2 langauge code.\n"
  "   -s   Define a separator character when overlay Switch /ov is used.'|' is the Default.\n"
  "   -h   Print help information and exit.\n"
  "   -v   Print the version number and exit.\n"
  "Switches\n"
  "   /pf  Request a searchable PDF and return its direct URL. This switch overrides printing \n"
  "        detected text to stdOut.\n"
  "   /ov  Return the scanned text with delimited coordinates of the bounding boxes for\n"
  "        each word detected, in the format (#Word|#Left|#TopPos|#Height|#Width).\n"
  "   /as  Allow Image upscaling. Useful for low-resolution Image and PDF scans.\n"
  "   /tl  Use table logic for scanning (table recognition). The parsed text result is\n"
  "        returned line by line. Best for table OCR, receipt OCR, invoice processing\n"
  "        and any other tabular document processing.\n"
  "   /do  Allow auto-detecting text orientation and auto-rotate (if needed). If this\n"
  "        switch is unissued, processing is done as is.\n"
  "   /pt  Allow a PDF text layer. Relevant when a PDF is requested with '/pf' switch.\n"
  "   /vm  Allow standard output verbosity mode.\n"
  "   /dm  Allow running in debug mode. Check CL-OCRSpace.log\n"
  "Remarks\n"
  "   - UNC paths are supported. A file name/path containing spaces need to be wrapped\n"
  "   with double quotes. Otherwise it is rendered and parseed as an invalid URL/PATH\n"
  "   Supported filetypes are PNG, GIF, PNG, JPG, TIF, BMP, JPEG & PDF.\n"
  "   - Engine 1 (DEFAULT) is Faster , also supports Asian languages (i.e Chinese,\n"
  "   Japanese, Korean), larger images & Multi-Page TIFF scans.\n"
  "   - Engine 2 supports Western Latin Character languages only (English, German,\n"
  "   French, etc), has Language auto-detection for Latin character languages,\n"
  "   better at single number OCR/Single character OCR/Alphanumeric OCR in general,\n"
  "   better at special characters OCR like @+-, and better with rotated text. Image\n"
  "   size limit is 5000px width and 5000px height.\n"
  "   - Switches may be either upper or lower case.\n"
  "Examples\n"
  "> CL-OCRSpace.exe \"https://s.4cdn.org/image/fp/logo-transparent.png\" -k abcdefgh1234 /tl\n"
  "> CL-OCRSpace.exe \"X:\\User\\Invoices\\Invoice.pdf\" -k abcdefgh1234\n"
  "> CL-OCRSpace.exe \"X:\\User\\Receipts Folder\\Reciept1.png\" -k abcdefgh1234 /as /tl\n"
  "Return Codes\n"
  "    0 - Success\n"
  "    1 - Error  : APIKey Invalid/unprovided.\n"
  "    2 - Error  : No internet connection.\n"
  "    5 - Error  : Unsupported filetype provided.\n"
  "    6 - Error  : Unsupported file provided.\n";

class OCRSpaceArgsParser {
  // Access specifier
  private:
    std::vector <std::string> tokens;
  public:
    OCRSpaceArgsParser(int & argc, char ** argv) {
      for (int i = 1; i < argc; ++i)
        this -> tokens.push_back(std::string(argv[i]));
    }
  // Member Functions= _CmdLine_Get()
  const std::string & _CmdLine_Get(const std::string & option) const {
    std::vector < std::string > ::const_iterator itr;
    itr = std::find(this -> tokens.begin(), this -> tokens.end(), option);
    if (itr != this -> tokens.end() && ++itr != this -> tokens.end()) {
      return *itr;
    }
    static
    const std::string empty_string("");
    return empty_string;
  }
  // Member Function _CmdLine_GetValByIndex()
  const std::string & _CmdLine_GetValByIndex(int &argc, char ** argv, int index, const std::string defaultvalue) {
    static std::string returnval(defaultvalue);
    // argc -1 : [0] is filename.
    if (index <= argc - 1) returnval = argv[index];
    return returnval;
  }
  // Member Function _CmdLine_KeyExists()
  bool _CmdLine_KeyExists(const std::string & option) const {
    return std::find(this -> tokens.begin(), this -> tokens.end(), option) !=
      this -> tokens.end();
  }
};

bool ends_with(const std::string filename, const std::string ext) {
  return ext.length() <= filename.length() && std::equal(ext.rbegin(), ext.rend(), filename.rbegin());
}

bool OCRSpaceIsFileSupported(const std::string filename) {
  // cout << " checking for :" << sAllowedFiletypes[a] << " Returned :" << ends_with(filename, sAllowedFiletypes[a]) << endl;
  for (unsigned int a = 0; sAllowedFiletypes[a].length(); a++) {
    if (ends_with(filename, sAllowedFiletypes[a]) == 1)
      return true;
  }
  return false;
}

// std::string url_encode(const std::string &value) {
//     ostringstream escaped;
//     escaped.fill('0');
//     escaped << hex;

//     for (std::string::const_iterator i = value.begin(), n = value.end(); i != n; ++i) {
//         std::string::value_type c = (*i);
//         // Keep alphanumeric and other accepted characters intact
//         if (isalnum((unsigned char) c) || c == '-' || c == '_' || c == '.' || c == '~') {
//             escaped << c;
//             continue;
//         }
//         // Any other characters are percent-encoded
//         escaped << uppercase;
//         escaped << '%' << setw(2) << int((unsigned char) c);
//         escaped << nouppercase;
//     }
//     return escaped.str();
// }

// void hexchar(unsigned char c, unsigned char &hex1, unsigned char &hex2){
//     hex1 = c / 16;
//     hex2 = c % 16;
//     hex1 += hex1 <= 9 ? '0' : 'a' - 10;
//     hex2 += hex2 <= 9 ? '0' : 'a' - 10;
// }

// std::string urlencode(std::string s){
//     const char *str = s.c_str();
//     std::vector<char> v(s.size());
//     v.clear();
//     for (size_t i = 0, l = s.size(); i < l; i++){
//         char c = str[i];
//         if ((c >= '0' && c <= '9') ||
//             (c >= 'a' && c <= 'z') ||
//             (c >= 'A' && c <= 'Z') ||
//             c == '-' || c == '_' || c == '.' || c == '!' || c == '~' ||
//             c == '*' || c == '\'' || c == '(' || c == ')')
//         {
//             v.push_back(c);
//         }
//         else if (c == ' ')
//         {
//             v.push_back('+');
//         }
//         else
//         {
//             v.push_back('%');
//             unsigned char d1, d2;
//             hexchar(c, d1, d2);
//             v.push_back(d1);
//             v.push_back(d2);
//         }
//     }

//     return std::string(v.cbegin(), v.cend());
// }

// ! ik really isn't the right choice for binary data but ill go for a basic string return because if
// ! successful it is converted to base64 string.
// std::string FileReadBin2B64Encoded(const std::string & filename){
//   // Prepare blank return
//   std::string returnval = "";
//   // open the file in binary mod
//   std::ifstream ifs(filename, ios::binary);
//   if(!ifs)
//     return returnval;

//   // std::vector<char> data = std::vector<char>(std::istreambuf_iterator<char>(ifs), std::istreambuf_iterator<char>());
//   // ! change to return vector instead.
//   std::string data = std::string(std::istreambuf_iterator<char>(ifs), std::istreambuf_iterator<char>());
  
//   using base64 = cppcodec::base64_url;
//   // auto base64dat = base64::encode(data)

//   // cout << endl <<"b64:" << base64::encode(data) << endl;

//   returnval = urlencode(base64::encode(data));
//   return returnval;
// }
int main(int argc, char ** argv) {

  // freopen("inputf.in", "r", stdin);
  // freopen("outputf.out", "w", stdout);

  // try {
  // argument handler.
  OCRSpaceArgsParser input(argc, argv);

  const std::string ImgURL_FQPN = input._CmdLine_GetValByIndex(argc, argv, 1, ""); // REQUIRED   : Should be IMG FQPN or IMG URL.
  const std::string OCRSpaceKey = input._CmdLine_Get("-k");                        // REQUIRED   : OCRSpace Key.
  // const std::string &file_out = input._CmdLine_Get("-o");                       // OPTIONAL   : For exporting results.
  // const std::string &file_in = input._CmdLine_Get("-i");                        // DEPRECATED : Refers from param 1
  
  if (input._CmdLine_KeyExists("-h") || input._CmdLine_KeyExists("/h")) {
    cerr << HelpInfo;
    return EXIT_SUCCESS;
  } else if (ImgURL_FQPN.empty() || OCRSpaceKey.empty()) {
    cout << dye::red("Expected ") << ((OCRSpaceKey.empty()) ? dye::on_red("-k") + " Parameter" : dye::on_red("<file>") + " argument") <<
    ".Run '" << dye::on_white(argv[0]) << dye::on_white(" -h") << "' for help.\n";
    return EXIT_FAILURE;
  }

  // ? Flags/Switches 
  const bool b_gDebugMode = (input._CmdLine_KeyExists("/dm") ? true : false);
  const int i_gVerboseMode = input._CmdLine_KeyExists("/vm");

  if (OCRSpaceIsFileSupported(ImgURL_FQPN)) {
    if (input._CmdLine_KeyExists("/test")) {
      cout << "Success, file is spported." << std::endl;
      return EXIT_FAILURE; // EXIT_SUCCESS
    }
    // do nothing..
    // cout << "Success, file is spported." << std::endl;
    // cout << FileReadBin2B64Encoded(ImgURL_FQPN) << endl;
    // return EXIT_SUCCESS; // EXIT_SUCCESS
  } else {
    cerr << dye::red("Error ::") <<  " unsupported filetype '" << dye::on_red(ImgURL_FQPN) << "' \n";
    return EXIT_FAILURE; // EXIT_SUCCESS
  }

  // At this point, Required params are provided and syntax is ok so declare API OCR Options..
  const int i_gOverlayReuired = input._CmdLine_KeyExists("/ov");
  const int i_gOCRSpaceImgAutoScale = input._CmdLine_KeyExists("/as");
  const int i_gTableProcLogic = input._CmdLine_KeyExists("/tl");
  const int i_gDetectOrientation = input._CmdLine_KeyExists("/do");
  const int i_gOCRSpacePDFHideTextLater = input._CmdLine_KeyExists("/pt");
  const int i_gOCRSpaceGenSearchablePDF = input._CmdLine_KeyExists("/pf");

if (b_gDebugMode) {
  cout << " ImgURL_FQPN   : " << ImgURL_FQPN << "\n" <<
  " OCRSpaceKey   : " << OCRSpaceKey << "\n" <<
  " overlay req   : " << i_gOverlayReuired << "\n" << 
  " table logic   : " << i_gTableProcLogic << "\n" <<
  " img autoscale : " << i_gOCRSpaceImgAutoScale << "\n" <<
  " PDFTextLayer  : " << i_gOCRSpacePDFHideTextLater << "\n" <<
  " Searchablepdf : " << i_gOCRSpaceGenSearchablePDF<< "\n" <<
  " detectOrient  : " << i_gDetectOrientation << "\n" <<
  " Debug         : " << b_gDebugMode << "\n";
} else {
  cout << "Success, Detected text : Hello world!" << std::endl;
}

  return EXIT_SUCCESS;
}
