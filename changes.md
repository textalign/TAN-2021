# Changes since version 2021

Below are listed significant changes that have been made since version 2021 to the Text Alignment Network. See the git log of the dev branch for a complete account of all changes.

## Not yet reflected in Guidelines

### General

* New Schematron mode added: off. Some TAN files can take a very long time to validate, and the user might need faster response. The off mode allows users to easily turn Schematron validation on and off.
* New parameter `$tan:validation-truncation-point`. The default setting of this parameter looks to a pseudo-attribute `@truncate` in the Schematron processing instruction. Any integer stipulates the limit of children of `<body>` that should be evaluated. This helps speed up Schematron validation on lengthy files. Keep in mind, however, that this does not apply to the sources. A lengthy class 2 file may have a truncation point, but evaluation of the sources may still take quite a while.
* Allowed `@ref` items to be separated by a semicolon as well as a comma.
* New function `tan:int-to-syr()`.