# Workflow

!! = next item to tackle.
! = closest point to release achieved

## From a fresh release

1. Make copy of the directory of the last stable release, putting down target year, e.g., `TAN-2021/`.
1. Make a branch called `dev` and switch to it.
1. Empty the changes.md file.
1. Set `$tan:TAN-version-is-under-development` to true().
1. Set `$tan:TAN-version` to expected value, and add the older value to `$tan:previous-TAN-versions`.
 
## General checklist

Below is an ordered list of resources, sorted by importance. The goal is to get through the entire list, so as to launch the new release. But any changes made to an item toward the top of the list shifts work to that point, from which the workflow must restart. 

1. **to-do**. 
    * The [to-do list](../TAN%20to-do%20list.txt) will always be with you, and will have ideas that might take many years to bring to life. Work should move ahead only if it does not contain any desiderata critical to the planned release.
1. **schemas**. 
    * Primary edits should be made in the .rnc file. 
    * While changes are still fresh in mind, edit relevant parts of the guidelines.
    * The schema inline documentation is authoritative, so should be clear and accurate. 
    * Any altered .rnc schemas must be converted, along with its dependencies, to .rng. 
    * Any changes to the core or class 1 schema require new transforms on the `.odd` file.
    * Adding or deleting any files requires rebuilding `collection.xml`. Run the maintenance `collection-generator.xsl`
    * Document any changes in `changes.md`.
    * All files should validate. 
1. **vocabularies**. 
    * All files should validate. You should expect warnings on `<master-location>` since you haven't pushed the new version. 
    * Make sure master locations point to a URL reflecting the future release
    * Deleting or adding a file requires repopulating the collection files.
1. **functions/errors**.
    * [TAN-errors.xml](functions/errors/TAN-errors.xml) should be valid when running the `missing and strays` mode of Schematron validation.
    * Every test TAN file should validate.
    * Deleting or adding a file requires repopulating the collection file. Before doing so, check to see if something special has been done to the collection file to make the error test files operate.
1. **examples**.
    * Every example file should validate, perhaps with warnings.
    * Any TAN element or attribute should be represented by at least one example file.  To be checked when refreshing the Guidelines.
    * Deleting or adding a file requires repopulating the TAN catalog file.
    * Make sure any master-locations point to the future version
1. **other TAN collections**. Do as for examples (above), but don't commit changes, unless if done in a dev branch, because these will be useless without the dev release available.
    * Aristotle collection
    * Language library
    * Bible collection
    * Qur'an collection
    * CLIO collection
    * Evagrius collection.
    * pseudo-Methodios
1.   **functions**.
    * There should be no matches on `test\d+`. 
    * Check functions with dated comments to see if they should be deleted; search with regex for `20(1[7-9]|2[01])`.
    * Check for templates surnamed -old -copy or -off.
    * Make sure `tan:expand-doc-test()` is empty
    * Deleting or adding a file requires repopulating the collection files.
    * While changes are still fresh in mind, edit relevant parts of the guidelines.
    * All files should validate.
    * Set `tan:TAN-version-is-under-development` to false().
    * Some functions are part of other projects, e.g., regex and docx. Validation will tell you if these are out of sync with the masters. If you make changes, use the local `TAN/inclusions/[directory]` path to make a copy of the file, and there use git to commit and push to the source repo.
    * Commit all TAN files except applications and guidelines to git
1. **author**
    * Test all the author functions.
1. **applications and utilities**
    * Go through each transformation scenario, and test each one prefaced APP, SETUP, and UTIL. Make sure the description accounts for any significant parameter settings.
    * Make sure that each official utility is prefaced UTIL and each application, APP and is exported to a temporary scenarios file, normally under `/maintenance/scenarios`. 
    * Import the master scenarios into the official `tan.frameworks` file. Options > Preferences > Document Type Association > TAN > Edit > Transformation. Then delete all, then import the scenarios exported in the last step.
    * Create a new xpr file in the main directory, `TAN.xpr`
    * * Configure it to look for frameworks in the project directory: Options > Preferences > Document Type Association > Locations. In project mode add ${pd}. 
    * * Set up master files, adding the main applications and utilities.
    * * Ensure that the PDF can be generated: Options > Preferences > XML > PDF Output > FO Processors and there increase the memory allowance to 600MB.
1. **guidelines**
    * Generate new inclusions.
    * Edit thoroughly, including dependencies.
    * Run `populate TAN guidelines.xsl` against itself.
    * Validate Guidelines.
    * Generate PDF.
    * Generate chunked HTML. 
1. **processors**
    * Make sure the processor directory is empty. Perhaps in the future SaxonHE will be included.
1. **output**
    * Should be empty except for the readme file and folders with select dependencies.
1. **tutorials**
    * Revise tutorials for new version
    * Note: Tutorials were FTP via git bash: `git ftp init -u "tanftp@textalign.net" -p "[PASSWORD]" "ftp://ftp.tanarchive.net/release/TAN-tutorials"`
1. **generally**
    * Check there aren't any phantom files, e.g., output in the examples subdirectory, copies of functions.
    * Check each README.md one more time. Remove references to development branches, etc.
    * Check changes.md one more time.
    * Commit everything in TAN and push to git 

## Preparation for new clean git repo and work for the next version

1. !! In the directory 
[../server/index-template.html](../server/index-template.html) update all components. Refresh contents using 
[../server/make webpage.xsl](../server/make%20webpage.xsl).
1. On the server create a subdirectory: release/\[name of version\], e.g., `release/TAN-2021`.
1. On the local drive, create a new directory with the name of what will likely be the next version, e.g., `TAN-2022`.
1. Clone the current repo, dev branch, into the next version but without recursion, e.g., `git clone --branch dev https://github.com/textalign/TAN-2020.git TAN-2022`
1. In the new directory delete the subfolder `.git` (but not the other git files).
1. With Git Bash, go to the new directory and enter `git init`.
1. Delete the empty subdirectories for the submodules.
1. Before you add any more files or issue any more commands, go through the submodules one by one in git bash and add them:
   * `git submodule add https://github.com/Mottie/tablesorter.git output/js/tablesorter`
   * `git submodule add https://github.com/benfred/venn.js.git output/js/venn.js`
1. Now, finally, `git add` the directories that pertain to the master branch, `git commit`. That will be most of the subdirectories except *-awaiting-development, maintenance, tests. Also, don't include `tan-dev.xpr`.
1. At this point you are ready to push to the new git repository. In github create the new repo holder, then back on the command line enter:
   * `git remote add origin https://github.com/textalign/TAN-2021.git`
   * `git push -u origin master`
1. Make new branch `git branch dev`
1. Now set up git for FTP via git bash: `git ftp init -u "tanftp@textalign.net" -p "[PASSWORD]" "ftp://ftp.tanarchive.net/release/TAN-2021"`
1. Hand copy the pdf and xhtml files into the FTP server's appropriate subdirectories of `release/TAN-2021/guidelines`
1. Switch to dev branch and edit `changes.md`. Add development directories then commit them. Now `git push origin dev`

Don't forget there are lots of extra files left over from the previous version, and only relevant will need to be brought over one at a time. That's a good chance to see what matters, and what doesn't.


## Pushing new version

1. CHECK MASTER-LOCATION LINKS IN EXAMPLES
    * Every example should validate, without warnings at `<master-location>`.
1. Test website links
1. Check xhtml documentation css
1. Git commit all the TAN libraries mentioned above.
1. Git push TAN libraries.
1. Validate select TAN library files that have `<master-location>`.
1. ! !! Put out group announcement
1. Put out tweet