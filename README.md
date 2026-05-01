# Writer
Writer aims to create an open source alternative to propetiery applications in the field of distraction-free text-editing.

## Features


### Content Blocks


Writer supports the `iainc/Markdown-Content-Blocks` spec as standalone lines inside markdown or plain-text documents.

#### Supported syntax

- `/chapter.md`
- `/sections/intro.txt "Introduction"`
- `/tables/budget.csv 'Budget Overview'`
- `https://example.com/diagram.png (System Diagram)`

Rules:

- The content block must occupy its own line, optionally indented by up to three spaces.
- Local file paths must follow the content block spec and begin with `/`.
- Online content blocks are limited to image URLs with supported file extensions.
- Optional captions can use double quotes, single quotes, or parentheses.

#### Supported block types

- `.md`, `.markdown`, `.txt`: transcluded into the document and rendered through the markdown pipeline
- `.csv`, `.tsv`: rendered as tables
- Common code file extensions such as `.swift`, `.js`, `.ts`, `.py`, `.json`, `.html`, `.css`: rendered as fenced code blocks
- Common image formats such as `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.svg`: rendered as images

Missing, recursive, malformed, or unsupported content blocks render as warning blocks in preview and export output instead of failing silently.

## Themes
Writer has themes. They are well designed.

