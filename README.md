# DocX
[![Swift](https://github.com/shinjukunian/DocX/actions/workflows/swift.yml/badge.svg)](https://github.com/shinjukunian/DocX/actions/workflows/swift.yml)

A small framework that converts NSAttributedString to .docx Word files on iOS and macOS.

## Motivation

On iOS, `NSAttributedString.DocumentType` supports only HTML and Rich Text, while on macOS .doc and .docx are available options. Even then the .docx exporter on macOS supports only a subset of the attributes of NSAttributedString. 

This library is used in [SimpleFurigana for macOS](https://itunes.apple.com/de/app/simple-furigana/id997615882?l=en&mt=12) and [SimpleFurigana for iOS](https://itunes.apple.com/de/app/simple-furigana/id924351286?l=en&mt=8), hence the focus on furigana annotation export.

## Installation
### Swift Package Manager
Add 
```swift
.package(name: "DocX", url: "https://github.com/shinjukunian/DocX.git", .branch("master"))
```

to ```dependencies``` in your  ```Package.swift``` file. This requires Swift 5.3, which shipped with Xcode12.
Alternatively, add  ```DocX``` in Xcode via ```File->Swift Packages->Add Package Dependency```, paste ```https://github.com/shinjukunian/DocX.git``` as URL and specify ```master``` as branch.

### CocoaPods
Add 
```
pod 'DocX-Swift'
```
to your Podfile.

## Usage

```swift
let string = NSAttributedString(string: "This is a string", attributes: [.font: UIFont.systemFont(ofSize: UIFont.systemFontSize), .backgroundColor: UIColor.blue])
let url = URL(fileURLWithPath:"myPath")
try? string.writeDocX(to: url)
```
Starting from iOS 15 / macOS 12, you can use the new `AttributedString`.

```swift
var att=AttributedString("Lorem ipsum dolor sit amet")
att.font = NSFont(name: "Helvetica", size: 12)
att[att.range(of: "Lorem")!].backgroundColor = .blue
let url = URL(fileURLWithPath:"myPath")
try att.writeDocX(to: url)
```

Naturally, this works for Markdown as well:

```swift
let mD="~~This~~ is a **Markdown** *string*."
let att=try AttributedString(markdown: mD)
try att.writeDocX(to: url)
```

`DocXOptions` allow the customization of DocX output.

- you can optionally specify metadata using `DocXOptions`:

```swift
let font = NSFont(name: "Helvetica", size: 13)! //on macOS
let string = NSAttributedString(string: "The Foundation For Law and Government favours Helvetica.", attributes: [.font: font])

var options = DocXOptions()
options.author = "Michael Knight"
options.title = "Helvetica Document"

let url = URL(fileURLWithPath:"myPath")
try string.writeDocX(to: url, options:options)
```
- you can specify character and paragraph styling based on a style document using the `NSAttributedString.Key.characterStyleId` and `NSAttributedString.Key.paragraphStyleId` attributes. Use `DocXStyleConfiguration` to specify the style document.

- you can use `DocXStyleConfiguration` to specify that Word should use standard fonts instead of explicitly specified font names. This is useful for cross-platform compatibility when using Apple system fonts. Other font attributes (size, bold / italic) will be preserved if possible.

- you can specify a page size using `.pageDefinition`. Page definitions consist of a paper size and margins to determine the printable area. If no page definition is specified, Word will fall back to useful defaults based on the current system.

```Swift
let A4 = PageDefinition(pageSize: .A4) // an A4 page with defaults margins
let square = PageDefinition(pageSize: .init(width: Measurement(value: 10, unit: .centimeters), height: Measurement(value: 10, unit: .centimeters))) // a custom square page size with default (72 pt) margins)
let custom = PageDefinition(pageSize: .init(width: .init(value: 30, unit: .centimeters), height: .init(value: 20, unit: .centimeters)), pageMargins: .init(top: .init(value: 1, unit: .centimeters), bottom: .init(value: 1, unit: .centimeters), left: .init(value: 1, unit: .centimeters), right: .init(value: 1, unit: .centimeters))) // a page with custom paper and custom margins
```

See the attached sample projects (for iOS and macOS) for usage and limitations.
On iOS, DocX also includes a `UIActivityItemProvider` subclass (`DocXActivityItemProvider`) for exporting .docx files through `UIActivityViewController`.

`NSAttributedString` has no concept of pagination. For manual pagination, use 

```swift
try DocXWriter.write(pages:[NSAttributedString], to url:URL)
```
to render each `NSAttributedString` as a separate page.

![Screenshot macOS](/images/screenshot_mac.jpg)

A sample output on macOS opened in Word365.

![Screenshot Lenna](/images/lenna.jpg)

A sample output on macOS with an embedded image (via ```NSTextAttachment```). in the macOS sample application (which is a simple ```NSTextView```), this can be achieved using drag&drop. Note that there is little control over the placement of the image, the image will be inline with text. 

![Screenshot iOS](/images/screenshot_iOS.png)

A sample output on iOS opened in Word for iOS. Furigana annotations are preserved. The link is clickable.
Please note that Quicklook (on both platforms) only supports a limited number of attributes.

## Supported Attributes

- most things in `NSAttributedString.Key` (fonts, colors, underline, indents etc.) except
  - `NSAttributedString.Key.expansion`
  - `NSAttributedString.Key.kern`
  - `NSAttributedString.Key.ligature`
  - `NSAttributedString.Key.obliqueness`
  - `NSAttributedString.Key.superscript` (macOS only, doesnt really work for most fonts anyway). Use `NSAttributedString.Key.baselineOffset` with a positive value for superscript and a negative value for subscript instead
  - `NSAttributedString.Key.textEffect`
- `CTRubyAnnotation` for furigana (ruby) annotations in CoreText
- `NSTextAttachment` embedded images (inline with text)

For `AttributedString`, `DocX` supports the attributes present in `NSAttributedString`, i.e. most attributes in `AttributeScopes.AppKitAttributes` or `AttributeScopes.UIKitAttributes` (see above for omissions). For `AttributedStrings` initialized from Markdown (`AttributeScopes.FoundationAttributes`), `DocX` supports links (`AttributeScopes.FoundationAttributes.LinkAttribute`), **bold**, *italic*, and ~~strikethrough~~ (`AttributeScopes.FoundationAttributes.InlinePresentationIntentAttribute`), and inline images (`AttributeScopes.FoundationAttributes.ImageURLAttribute`). Please note that images are not rendered by `SwiftUI`'s `Text`.

Some attributes don't have a direct correspondence. For example `NSAttributedString` does (typically) not have the concept of a page size.  

## Dependencies

- my fork of [AEXML](https://github.com/shinjukunian/AEXML), many thanks to the original author [tadija](https://github.com/tadija/AEXML)
- [ZipFoundation](https://github.com/weichsel/ZIPFoundation)

## Alternatives

- [WKDocReader](https://github.com/Wekwa/WKDocReader) to read old-school .doc files
- [BSDocxRipperZipper](https://github.com/SlayterDev/BSDocxRipperZipper) which supports both reading and writing, but only for a subset of attributes.

## References

- [OfficeOpenXML Specification](http://officeopenxml.com/anatomyofOOXML.php)
- [this blog post on Ruby annotations](https://blogs.msdn.microsoft.com/murrays/2014/12/27/ruby-text-objects/)
- [this article on the file structure of the .docx format](https://www.toptal.com/xml/an-informal-introduction-to-docx)

## Licence
MIT

