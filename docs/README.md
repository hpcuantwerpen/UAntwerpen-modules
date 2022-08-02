# UAntwerpen-modules documentation overview

See [the index.md file](docs-mkdocs/index.md) or the
[GitHub pages for this repository](https://hpcuantwerpen.github.io/UAntwerpen-modules).

(For now the [GitHub pages are on the klust GitHub account](https://klust.github.io/UAntwerpen-modules))

[Directory structure as seen on GitHub](directory_structure.md)


## Processing the documentation

This documentation is rendered via [MkDocs](https://www.mkdocs.org/),
which makes it very easy to preview the result of the changes you make locally.

* First, install ``mkdocs``, including the `material` theme and additional plugins:

      pip install mkdocs mkdocs-material mkdocs-git-revision-date-localized-plugin

  You may want to do this in a virtual environment if you have more mkdocs configurations
  with different versions of Python packages.

* Go into the `config` subdirectory of this directory to build the documentation.

* Start the MkDocs built-in dev-server to preview the tutorial as you work on it:

      make preview

  or

      mkdocs serve

  Visit http://127.0.0.1:8000 to see the local live preview of the changes you make.

* If you prefer building a static preview you can use ``make`` or ``mkdocs build``,
  which should result in a ``site/`` subdirectory that contains the rendered documentation.

