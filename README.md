## Introduction
Simple script to convert a blog backup exported from Google Blogger into a LaTeX document. Typical use-case could be automatically generating a PDF e-book of a blog.

## Usage
1. Export your blog in Google Blogger by going to "Settings->Other->Blog tools->Export Blog". This will give you an Atom-format XML file. 
2. Then in a terminal run "perl blogger_to_latex.pl exported_blog.xml".

## Todo:
* Rewrite script to process any valid Atom-format file.
* Add extra command-line arguments to support further processing of the LaTeX document.
