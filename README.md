# DocX
A small framework that converts NSAttributedString to .docx Word files on iOS and macOS.

## Motivation

On iOS, `NSAttributedString.DocumentType` supports only HTML and Rich Text, while on macOS .doc and .docx are available options. Even then .docx exporter on macOS supports only a subset of the attributes os NSAttributedString. 

This library is used in [SimpleFurigana for macOS](https://itunes.apple.com/de/app/simple-furigana/id997615882?l=en&mt=12) and [SimpleFurigana for iOS](https://itunes.apple.com/de/app/simple-furigana/id924351286?l=en&mt=8), hence the focus on furigana annotation export.

## Installation

Clone this repository ~~(and its submodules)~~ and add the DocX ~~and the ZipArchive~~ frameworks to 'Embeded Binaries'. 

DocX now relies in the Swift package manager for its dependencies. Hence Xcode will take care of these steps for you, you only need to add the DocX framework to your app.

Once SPM supports resources (likely in Swift 5.2), DocX will become a proper swift package.
The framework provides an extension on NSAttributedString to export the string as a .docx file.

## Usage

```swift
let string = NSAttributedString(string: "This is a string", attributes: [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize), .backgroundColor: UIColor.blue])
let url = URL(fileURLWithPath:"myPath")
try? string.writeDocX(to: url)
```

See the attached sample projects (for iOS and macOS) for usage and limitations.
On iOS, DocX also includes a `UIActivityItemProvider` subclass (`DocXActivityItemProvider`) for exporting .docx files through `UIActivityViewController`.

![Screenshot macOS](/images/screenshot_mac.jpg)

A sample output on macOS opened in Word365.

![Screenshot iOS](/images/screenshot_iOS.png)

A sample output on iOS opened in Word for iOS. Furigana annotations are preserved. The link is clickable.
Please note that Quicklook (on both platforms) only supports a limited number of attributes.

## Supported Attributes

- most things in `NSAttributedString.Key` except
  - `NSAttributedString.Key.expansion`
  - `NSAttributedString.Key.kern`
  - `NSAttributedString.Key.ligature`
  - `NSAttributedString.Key.obliqueness`
  - `NSAttributedString.Key.superscript` (macOS only, doesnt really work for most fonts anyway)
  - `NSAttributedString.Key.textEffect`
- `CTRubyAnnotation` for furigana (ruby) annotations in CoreText

Some attributes don't have a direct correspondence. For example `NSAttributedString` does (typically) not have the concept of a page size.  

## Dependencies

- my fork of [AEXML](https://github.com/shinjukunian/AEXML), many thanks to the original author [tadija](https://github.com/tadija/AEXML)
- [ZipArchive](https://github.com/ZipArchive/ZipArchive). I could not get any of the native Swift Zip libraries to work with the .docx folder structure.

## Alternatives

- [WKDocReader](https://github.com/Wekwa/WKDocReader) to read old-school .doc files
- [BSDocxRipperZipper](https://github.com/SlayterDev/BSDocxRipperZipper) which supports both reading and writing, but only for a subset of attributes.

## References

- [OfficeOpenXML Specification](http://officeopenxml.com/anatomyofOOXML.php)
- [this blog post on Ruby annotations](https://blogs.msdn.microsoft.com/murrays/2014/12/27/ruby-text-objects/)
- [this article on the file structure of the .docx format](https://www.toptal.com/xml/an-informal-introduction-to-docx)

## Licence
MIT

