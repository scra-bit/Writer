import XCTest
import Markdown

final class HTMLVisitorTests: XCTestCase {
    
    // MARK: - Heading Tests
    
    func testVisitHeadingLevel1() {
        let markdown = "# Title"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<h1>Title</h1>\n")
    }
    
    func testVisitHeadingLevel2() {
        let markdown = "## Heading 2"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<h2>Heading 2</h2>\n")
    }
    
    func testVisitHeadingLevel3() {
        let markdown = "### Heading 3"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<h3>Heading 3</h3>\n")
    }
    
    func testVisitHeadingLevel4() {
        let markdown = "#### Heading 4"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<h4>Heading 4</h4>\n")
    }
    
    func testVisitHeadingLevel5() {
        let markdown = "##### Heading 5"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<h5>Heading 5</h5>\n")
    }
    
    func testVisitHeadingLevel6() {
        let markdown = "###### Heading 6"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<h6>Heading 6</h6>\n")
    }
    
    func testVisitHeadingWithContent() {
        let markdown = "# Hello World"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<h1>Hello World</h1>\n")
    }
    
    // MARK: - Paragraph Tests
    
    func testVisitParagraph() {
        let markdown = "This is a paragraph."
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<p>This is a paragraph.</p>\n")
    }
    
    func testVisitParagraphMultipleSentences() {
        let markdown = "This is the first sentence. This is the second sentence."
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<p>This is the first sentence. This is the second sentence.</p>\n")
    }
    
    // MARK: - Text Tests
    
    func testVisitText() {
        let markdown = "Plain text content"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<p>Plain text content</p>\n")
    }
    
    func testVisitTextWithSpecialCharacters() {
        let markdown = "Text with <special> characters"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<p>Text with &lt;special&gt; characters</p>\n")
    }
    
    // MARK: - Strong Tests
    
    func testVisitStrong() {
        let markdown = "**bold text**"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<p><strong>bold text</strong></p>\n")
    }
    
    func testVisitStrongWithinParagraph() {
        let markdown = "This is **bold** text."
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<p>This is <strong>bold</strong> text.</p>\n")
    }
    
    // MARK: - Emphasis Tests
    
    func testVisitEmphasis() {
        let markdown = "*italic text*"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<p><em>italic text</em></p>\n")
    }
    
    func testVisitEmphasisWithinParagraph() {
        let markdown = "This is *italic* text."
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<p>This is <em>italic</em> text.</p>\n")
    }
    
    // MARK: - Inline Code Tests
    
    func testVisitInlineCode() {
        let markdown = "`inline code`"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<p><code>inline code</code></p>\n")
    }
    
    func testVisitInlineCodeWithinParagraph() {
        let markdown = "Use `print()` to output."
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<p>Use <code>print()</code> to output.</p>\n")
    }
    
    // MARK: - Code Block Tests
    
    func testVisitCodeBlock() {
        let markdown = """
        ```
        code block content
        ```
        """
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<pre><code>code block content</code></pre>\n")
    }
    
    func testVisitCodeBlockWithLanguage() {
        let markdown = """
        ```swift
        let x = 42
        ```
        """
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<pre><code class=\"language-swift\">let x = 42</code></pre>\n")
    }
    
    func testVisitCodeBlockWithPython() {
        let markdown = """
        ```python
        print("Hello")
        ```
        """
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<pre><code class=\"language-python\">print(\"Hello\")</code></pre>\n")
    }
    
    func testVisitCodeBlockEmpty() {
        let markdown = "```\n```"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<pre><code></code></pre>\n")
    }
    
    // MARK: - Link Tests
    
    func testVisitLink() {
        let markdown = "[Example](https://example.com)"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<p><a href=\"https://example.com\">Example</a></p>\n")
    }
    
    func testVisitLinkWithText() {
        let markdown = "[Click here](https://example.com/path)"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<p><a href=\"https://example.com/path\">Click here</a></p>\n")
    }
    
    func testVisitLinkEmpty() {
        let markdown = "[](https://example.com)"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<p><a href=\"https://example.com\"></a></p>\n")
    }
    
    // MARK: - Image Tests
    
    func testVisitImage() {
        let markdown = "![alt text](image.png)"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<p><img src=\"image.png\" alt=\"alt text\"></p>\n")
    }
    
    func testVisitImageWithTitle() {
        let markdown = "![alt text](image.png \"Image Title\")"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<p><img src=\"image.png\" alt=\"alt text\" title=\"Image Title\"></p>\n")
    }
    
    func testVisitImageWithAltText() {
        let markdown = "![A beautiful sunset](sunset.jpg)"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<p><img src=\"sunset.jpg\" alt=\"A beautiful sunset\"></p>\n")
    }
    
    func testVisitImageWithoutAltText() {
        let markdown = "![](image.png)"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<p><img src=\"image.png\" alt=\"\"></p>\n")
    }
    
    // MARK: - Block Quote Tests
    
    func testVisitBlockQuote() {
        let markdown = """
        > This is a blockquote
        """
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<blockquote>\n<p>This is a blockquote</p>\n</blockquote>\n")
    }
    
    func testVisitBlockQuoteMultipleLines() {
        let markdown = """
        > Line one
        > Line two
        """
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<blockquote>\n<p>Line one\nLine two</p>\n</blockquote>\n")
    }
    
    // MARK: - Unordered List Tests
    
    func testVisitUnorderedList() {
        let markdown = """
        - Item 1
        - Item 2
        - Item 3
        """
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<ul>\n<li>Item 1</li>\n<li>Item 2</li>\n<li>Item 3</li>\n</ul>\n")
    }
    
    func testVisitUnorderedListSingleItem() {
        let markdown = "- Single item"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<ul>\n<li>Single item</li>\n</ul>\n")
    }
    
    func testVisitUnorderedListNestedContent() {
        let markdown = """
        - Item with **bold**
        - Item with *italic*
        """
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<ul>\n<li>Item with <strong>bold</strong></li>\n<li>Item with <em>italic</em></li>\n</ul>\n")
    }
    
    // MARK: - Ordered List Tests
    
    func testVisitOrderedList() {
        let markdown = """
        1. First item
        2. Second item
        3. Third item
        """
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<ol>\n<li>First item</li>\n<li>Second item</li>\n<li>Third item</li>\n</ol>\n")
    }
    
    func testVisitOrderedListSingleItem() {
        let markdown = "1. Only item"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<ol>\n<li>Only item</li>\n</ol>\n")
    }
    
    // MARK: - List Item Tests
    
    func testVisitListItem() {
        let markdown = "- Just one item"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<ul>\n<li>Just one item</li>\n</ul>\n")
    }
    
    func testVisitListItemWithParagraph() {
        let markdown = "- Item with\n  multiple lines"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<ul>\n<li>Item with multiple lines</li>\n</ul>\n")
    }
    
    // MARK: - Thematic Break Tests
    
    func testVisitThematicBreak() {
        let markdown = "---"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<hr>\n")
    }
    
    func testVisitThematicBreakAsterisk() {
        let markdown = "***"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<hr>\n")
    }
    
    func testVisitThematicBreakUnderscore() {
        let markdown = "___"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<hr>\n")
    }
    
    // MARK: - Soft Break Tests
    
    func testVisitSoftBreak() {
        let markdown = "Line 1  \nLine 2"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<p>Line 1\nLine 2</p>\n")
    }
    
    // MARK: - Line Break Tests
    
    func testVisitLineBreak() {
        let markdown = "Line 1\nLine 2"
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<p>Line 1<br>\nLine 2</p>\n")
    }
    
    // MARK: - Table Tests
    
    func testVisitTable() {
        let markdown = """
        | Column 1 | Column 2 |
        |----------|----------|
        | Cell 1   | Cell 2   |
        """
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<table>\n<thead>\n<tr><td>Column 1</td><td>Column 2</td></tr>\n</thead>\n<tbody>\n<tr><td>Cell 1</td><td>Cell 2</td></tr>\n</tbody>\n</table>\n")
    }
    
    func testVisitTableHead() {
        let markdown = """
        | Header 1 | Header 2 |
        |----------|----------|
        | Data     | Data     |
        """
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertTrue(html.contains("<thead>"))
        XCTAssertTrue(html.contains("<tr><td>Header 1</td><td>Header 2</td></tr>"))
    }
    
    func testVisitTableBody() {
        let markdown = """
        | Header |
        |--------|
        | Row 1  |
        | Row 2  |
        """
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertTrue(html.contains("<tbody>"))
        XCTAssertTrue(html.contains("<tr><td>Row 1</td></tr>"))
        XCTAssertTrue(html.contains("<tr><td>Row 2</td></tr>"))
    }
    
    func testVisitTableRow() {
        let markdown = """
        | Col 1 | Col 2 |
        |-------|-------|
        | A     | B     |
        """
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertTrue(html.contains("<tr><td>A</td><td>B</td></tr>"))
    }
    
    func testVisitTableCell() {
        let markdown = """
        | Cell Content |
        |--------------|
        """
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertTrue(html.contains("<td>Cell Content</td>"))
    }
    
    func testVisitTableMultipleRows() {
        let markdown = """
        | A | B | C |
        |---|---|---|
        | 1 | 2 | 3 |
        | 4 | 5 | 6 |
        | 7 | 8 | 9 |
        """
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<table>\n<thead>\n<tr><td>A</td><td>B</td><td>C</td></tr>\n</thead>\n<tbody>\n<tr><td>1</td><td>2</td><td>3</td></tr>\n<tr><td>4</td><td>5</td><td>6</td></tr>\n<tr><td>7</td><td>8</td><td>9</td></tr>\n</tbody>\n</table>\n")
    }
    
    // MARK: - Document Tests
    
    func testVisitDocument() {
        let markdown = "# Title\n\nParagraph content."
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "<h1>Title</h1>\n<p>Paragraph content.</p>\n")
    }
    
    func testVisitDocumentMultipleElements() {
        let markdown = """
        # Heading
        
        Paragraph one.
        
        Paragraph two.
        
        ## Subheading
        
        More content.
        """
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertTrue(html.contains("<h1>Heading</h1>"))
        XCTAssertTrue(html.contains("<p>Paragraph one.</p>"))
        XCTAssertTrue(html.contains("<p>Paragraph two.</p>"))
        XCTAssertTrue(html.contains("<h2>Subheading</h2>"))
        XCTAssertTrue(html.contains("<p>More content.</p>"))
    }
    
    func testVisitDocumentEmpty() {
        let markdown = ""
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "")
    }
    
    func testVisitDocumentWhitespaceOnly() {
        let markdown = "   \n   \n   "
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        XCTAssertEqual(html, "")
    }
    
    // MARK: - Combined Elements Tests
    
    func testVisitMultipleMarkdownElements() {
        let markdown = """
        # Document Title
        
        This is a paragraph with **bold**, *italic*, and `code`.
        
        - List item 1
        - List item 2
        
        [A link](https://example.com)
        
        ![An image](image.jpg)
        
        > A blockquote
        
        ---
        
        Another paragraph.
        """
        let document = Document(parsing: markdown)
        var visitor = HTMLVisitor()
        let html = document.accept(&visitor)
        
        XCTAssertTrue(html.contains("<h1>Document Title</h1>"))
        XCTAssertTrue(html.contains("<strong>bold</strong>"))
        XCTAssertTrue(html.contains("<em>italic</em>"))
        XCTAssertTrue(html.contains("<code>code</code>"))
        XCTAssertTrue(html.contains("<ul>"))
        XCTAssertTrue(html.contains("<li>List item 1</li>"))
        XCTAssertTrue(html.contains("<a href=\"https://example.com\">A link</a>"))
        XCTAssertTrue(html.contains("<img src=\"image.jpg\" alt=\"An image\">"))
        XCTAssertTrue(html.contains("<blockquote>"))
        XCTAssertTrue(html.contains("<hr>"))
        XCTAssertTrue(html.contains("<p>Another paragraph.</p>"))
    }
}