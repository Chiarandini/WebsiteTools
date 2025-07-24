# WebsiteTools

WebsiteTools is designed to facilitate the management and creation of web content for my website, such as blog posts, notes, and books, directly from Neovim. This plugin automates the processes like content creation, LaTeX template application, and deployment to a specified website.

## Features

-   Create new blog posts, notes, and books with automatic LaTeX template application.
-   Easily copy content to website directories.
-   Update and manage webpage links for blogs and books.
-   Deploy website changes efficiently for angular.
-   Edit LaTeX templates with customizable viewing options.

## Setup

### Requirements

-   Neovim
-   Angular
-   LaTeX installation for template processing

### Installation

```lua
--
{
    'Chiarandini/WebsiteTools',
    config = function()
        require('WebsiteTools').setup(
        { -- links here
            -- ...
        }
        )
    end,
}
```

### Configuration

Make sure the following paths are updated in the `setup` function according to your environment:

-   `blog_source_code_url`: Source directory for blog LaTeX files.
-   `blog_webpage_url`: Webpage component file for blogs.
-   `blog_public_post_url`: Public directory for blog PDFs.
-   `blog_latex_template`: Template file for blog LaTeX documents.
-   `books_pdf_url`: Directory for books PDFs.
-   `books_webpage_url`: Webpage component file for books.
-   `books_latex_template`: Template file for books LaTeX documents.
-   `notes_source_code_url`: Source directory for notes LaTeX files.
-   `notes_pdf_url`: Directory for notes PDFs.
-   `notes_webpage_url`: Webpage component file for notes.
-   `notes_latex_template`: Template file for notes LaTeX documents.
-   `website_dir`: Base directory of your website project.

## Usage

### Commands

-   `:lua require('WebsiteTools').createNewBlog()`: Create a new blog.
-   `:lua require('WebsiteTools').createNewNote()`: Create a new note.
-   `:lua require('WebsiteTools').createNewBook()`: Create a new book.
-   `:lua require('WebsiteTools').updateBlogPage()`: Update the blog page with a new entry.
-   `:lua require('WebsiteTools').publishToWebsite()`: Build and deploy the website.
-   `:lua require('WebsiteTools').copyBlogToWebsite()`: Copy a blog's PDF to the website directory.
-   `:lua require('WebsiteTools').copyBooksToWebsite()`: Copy a book's PDF to the website directory.
-   `:lua require('WebsiteTools').editBlogTemplate("vsplit")`: Edit the blog template in a vertical split (customizable).
-   `:lua require('WebsiteTools').editNotesTemplate("float")`: Edit the notes template in a floating window (default).
-   `:lua require('WebsiteTools').editBooksTemplate("tab")`: Edit the books template in a new tab.

### Key Bindings

Non provided.
