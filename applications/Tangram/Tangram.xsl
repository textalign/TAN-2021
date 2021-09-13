<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
   xmlns:html="http://www.w3.org/1999/xhtml" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:array="http://www.w3.org/2005/xpath-functions/array"
   exclude-result-prefixes="#all" version="3.0">

   <!--  Welcome to Tangram, the TAN application that finds and scores clusters of words (ngrams)
      shared across two groups of texts -->
   
   <!-- This application searches for and scores clusters of words shared across two groups of texts, allowing
      you to look for quotations, paraphrases, or shared topics. When configured correctly, Tangram can
      also find idioms and collocations. Each input file, which may come in a variety of formats (TAN,
      TEI, other XML formats, plain text, Word documents) must be assigned to one or both of two groups,
      each group representing a work. Members of a work-group can be from different languages. Users can
      specify how many ngrams ("words") should be found, and how far apart they can be from each other.
      Ngram order is disregarded (e.g., ngram "shear", "blue", "sheep" would match ngram "sheep", "blue",
      "shear"). Tangram first normalizes and tokenizes each text according to language rules. Each token
      is converted to one or more aliases. If lexico-morphological data is available through a TAN-A-lm
      file, or if there is a TAN-A-lm language library for the language of the text being processed, a
      token may be replaced by multiple lexemes (e.g., "rung" would attract aliases "ring" and "rung");
      otherwise, a case-insensitive generic form of the word is used. Then each text in group 1 is
      compared to each text in group 2 that shares the same language. For each pair of texts, Tangram
      identifies clusters of tokens that share the same alias. It then consolidates adjacent clusters of
      ngrams, and scores the results based upon several criteria. Grouped clusters are then converted
      into a primitive TAN-A file consisting of claims that identify parallel passages of each pair of
      texts, and the output is rendered as sortable HTML, to facilitate better study of the results.
      Tangram was written primarily to support quotation detection in ancient Greek and Latin texts,
      which has rather demanding requirements. Because of these objectives, Tangram frequently operates
      in quadratic or cubic time, so can be quite time-consuming to run. A feature allows the user to
      save intermediate stages as temporary files, to reduce processing time. -->
   <!-- Version 2021-09-06-->
   

   <!-- This master stylesheet is the public interface for the application. The parameters you will most
      likely want to change are listed and documented below, to help you customize the application to suit
      your needs. If you are relatively new to XSLT, or TAN applications, see Using TAN Applications and
      Utilities in the TAN Guidelines for general instructions. If you want to avoid changing the master
      application file, use the accompanying configuration file. Or make a copy of this file and edit and
      run it directly. Or create and configure a transformation scenario in Oxygen, defining the relevant
      parameters as you like. If you are comfortable with XSLT, try creating your own stylesheet, then
      import this one, and customize the process. To access the code base, follow the link in the
      <xsl:include> at the bottom of this file. -->

   <!-- DESCRIPTION -->

   <!-- Primary input: any XML file, including this one (input is ignored) -->
   <!-- Secondary input: one or more files allocated to two groups; perhaps temporary files; perhaps
      TAN-A-lm files, either associated with secondary input, or part of a language catalog -->
   <!-- Primary output: perhaps diagnostics -->
   <!-- Secondary output: (1) an XML file with TAN-A claims identifying quotations or parallels, with the
      most likely at the top; (2) an HTML file that renders #1 in a more legible format. -->
   
   
   <!-- WARNING: CERTAIN FEATURES HAVE YET TO BE IMPLEMENTED-->
   <!-- * Support the method pioneered by Shmidman, Koppel, and Porat:
      https://arxiv.org/abs/1602.08715v2 
      * Make sure texts run against themselves work.
      * Incorporate simpler tablesorter javascript
   -->

   <!-- Nota bene: -->
   <!-- 
      * This application is one of the most experimental, and may not perform as expected. It has been 
      successfully tested on several dozen classical Greek texts. 
      * A file may be placed in both groups, to explore cases of self-quotation or 
      repetition. 
      * This process can take a very long time for lengthy texts, particuarly at the stage where a 1gram 
      gets added to an Ngram, because the process takes quadratic time. Many messages could appear during
      tan:add-1gram(), updating progress through perhaps long routines. It is recommended that you save
      intermediate steps, to avoid having to repeat steps on subsequent runs. -->
   
   <!-- Processing time example: two texts in group 1 of about 4.4K and 2.6K words against a single
      text in group 2 of about 137K words took 319 seconds to build up to a set of unconsolidated token
      aliases. One text from group 1 had an associated TAN-A-lm annotation and the text from group 2 did
      as well. There was a TAN-A-lm library associated with the language (Greek). When the program was
      run again without changing parameters, it took only 11 seconds to get to that same stage, because
      of the saved temporary files. That same set of texts took 1,219 seconds (20 minutes) to develop
      into a 3gram, with chops at common Greek stop words and skipping the most common 1% token aliases.
      When run again, based on temporary files, it took only 23 seconds. That is, saving intermediate
      steps could save you hours of time. -->
   
   

   <!-- PARAMETERS -->
   
   <!-- Any parameter below whose name begins "tan:" is a global parameter, and corresponds to a
      parameter in the parameters subdirectory. It is repeated here, because one commonly wishes to 
      make special exceptions from the default, for this particular application. -->
   
   <!-- STEP ONE: PICK YOUR DIRECTORIES AND FILES AND GROUP TEXTS -->
   
   <!-- Where directories of interest hold the target files? The following parameters are provided 
        as examples, and for convenince, in case you want to have several commonly used directories 
        handy. The main parameter can then be bound to the directory or directories you want. -->
   <xsl:param name="directory-1-uri" select="'../../examples'" as="xs:string?"/>
   <xsl:param name="directory-2-uri" select="'../../../library-arithmeticus/evagrius/cpg2439'" as="xs:string?"/>
   <xsl:param name="directory-3-uri" select="'../../../library-arithmeticus/bible'" as="xs:string?"/>
   <xsl:param name="directory-4-uri" select="'../../../library-arithmeticus/aristotle'" as="xs:string?"/>
   <xsl:param name="directory-5-uri" select="'../../../pre-TAN/evagrius'" as="xs:string?"/>
   
   <!-- What directory or directories has the main input files? Any relative path will be calculated relative 
        to this application file. Multiple directories may be supplied. Results can be filtered below. -->
   <xsl:param name="tan:main-input-relative-uri-directories" as="xs:string+"
      select="$directory-1-uri, $directory-2-uri, $directory-3-uri"/>
   
   <!-- What pattern must each filename match (a regular expression, case-insensitive)? Of the files 
        in the directories chosen, only those whose names match this pattern will be included. A null 
        or empty string means ignore this parameter. -->
   <xsl:param name="tan:input-filenames-must-match-regex" as="xs:string?" select="'xml|docx'"/>
   <!-- nt\.grc.+Copy|gribomont|2441|orat -->
   
   <!-- What pattern must each filename NOT match (a regular expression, case-insensitive)? Of the files 
        in the directories chosen, any whose names match this pattern will be excluded. A null 
        or empty string means ignore this parameter. -->
   <xsl:param name="tan:input-filenames-must-not-match-regex" as="xs:string?" select="'Copy'"/>
   
   <!-- What pattern must each filename match for it to be included in group one? A null or
      empty string will include every file. -->
   <xsl:param name="group-one-filenames-regex" as="xs:string?" select="''"/>
   
   <!-- What pattern must each filename match for it to be included in group two? A null or
      empty string will include every file. -->
   <xsl:param name="group-two-filenames-regex" as="xs:string?" select="''"/>
   
   <!-- If a particular file does not explicitly declare the language, what should the fallback value 
      be? Expected is an ISO code. -->
   <xsl:param name="fallback-language" as="xs:string?" select="'grc'"/>
   
   <!-- What tokenization patterns should be used for what languages? This parameter must hold 
      a map, each of whose map entries consist of a key pointing to a language code and a value
      of a regular expression defining what is meant by "word." Any text not matchings this pattern
      will be ignored.
   -->
   <xsl:param name="tokenization-map" as="map(xs:string,xs:string)">
      <xsl:map>
         <xsl:map-entry key="'eng'" select="$tan:token-definition-default/@pattern/string()"/>
         <xsl:map-entry key="'grc'" select="$tan:token-definition-default/@pattern/string()"/>
         <xsl:map-entry key="'lat'" select="$tan:token-definition-default/@pattern/string()"/>
      </xsl:map>
   </xsl:param>

   
   <!-- STEP TWO: EXCLUDE, INCLUDE, OR ADJUST INPUT -->
   
   <!-- This application matches two texts on the principle of the same Ngrams found in each text. An
      Ngram is, a cluster of N tokens or words. This 
      application takes a relatively loose approach to matching Ngrams in two texts. 
      The tokens in an Ngram may be out of order, and there may be intervening tokens (by some
      called skip-grams; adjustable below).
         An Ngram will be built in steps, going from 1grams to 2grams to 3grams, etc. Some of the
      parameter values below accept multiple values, each one corresponding to each of the steps.
      If a particular Ngram step lacks an explicit value in such a multiple-value parameter, the last
      value will be applied. Values greater than N will be ignored.
   -->
   
   <!-- What is value of n in ngram? Put another way, what is the minimum number of words that must 
      exist for a cluster in one text to be matched with a cluster in another? Normally 3 is ideal.
      Anything below 1 is not allowed. The value of 1 would simply find all token matches between any
      two texts, including very common words. Going to 4 and higher is normally not necessary because
      at the end of the process, adjacent Ngram clusters are consolidated into a larger one. 
   -->
   <xsl:param name="target-ngram-n" as="xs:integer" select="3"/>
   
   <!-- How far away can a token be from any other token for it to be included in an ngram? Normally 2 
      is ideal, because it permits for each of the two versions no more than one unmatched token in 
      the new Ngram. Anything below 1 is treated as a value of 1, which disallows any missing tokens.
      Values 3 and upward will spread the net further, but will increasingly allow false positives.
      This parameter permits multiple values. The first value corresponds to the building of a 2gram, 
      the second to a 3gram, and so forth. 
         An example: suppose text 1 has "funding of the government" and text 2 has "government funding". 
      This pair produces two 1grams of "funding" and "government". In synthesizing them into a 2gram,
      the 1grams will be discarded if the ngram-aura value is 1, because each member of the 1gram must
      be within the aura value of the other 1gram. The 1grams will be converted to a 2gram, however, if 
      the aura is 1 or higher.
   -->
   <xsl:param name="ngram-auras" as="xs:integer+" select="2"/>
   <xsl:param name="ngram-aura-diameters" as="xs:integer+" select="3"/>
   
   <!-- When a single text is prepared for Ngram matching, each token is converted to one or more alias 
      values, to better attract matches in the other text. Those aliases are then consolidated and 
      arranged in decreasing frequency, which means that the beginning of the data is likely to be 
      populated with very common but probably uninteresting aliases. If you like, a percentage of the 
      most common token aliases can be excluded when building Ngrams. This not only produces richer 
      results, but reduces processing time. 
   -->
   
   <!-- In 2016, Avi Shmidman, Moshe Koppel, and Ely Porat proposed a method to find quotations in large
      corpora by reducing each token the two letters that are most frequently used in the language. 
      https://arxiv.org/abs/1602.08715v2. Generally speaking, this application looks first for lexico-
      morphological data specific to the source, then to the language. Failing that, it will reduce
      the token to its lowercase form, without diacriticals. You can override that fallback method to 
      the SKP one by setting this value to true. The SKP method will also treat tokens as lowercase
      and without diacriticals. Two other adjustments are provided below.
   -->
   <xsl:param name="use-skp-fallback-alias-routine" as="xs:boolean" select="false()"/>
   
   <!-- If using the SKP method, how many letters maximum should be returned? -->
   <xsl:param name="skp-letter-maximum" as="xs:integer" select="2"/>
   
   <!-- If usin the SKP method, should the letters returned be the most frequent (true) or
      least (false)? -->
   <xsl:param name="skp-use-most-frequent-letters" as="xs:boolean" select="true()"/>
   
   <!-- What percentage of the most common tokens (actually, token aliases) should be ignored? Must be
      between 0 (ignore nothing) and 1 (ignore everything). If multiple values are supplied, the largest
      will be applied to building 1grams, the second largest to 2grams, and so forth. If an ngram step
      lacks a value, the smallest one will be applied. In texts with numerous words, 0.05 tends to be a
      steep cut; 0.001 a rather thin cut. If you know something about the language, try using the
      $skip-token-alias-map in combination with a thin cut.
 -->
   <xsl:param name="cut-most-frequent-aliases-per-ngram" as="xs:decimal+"
      select="0.01"/>
   
   <!-- Should most frequent token aliases be cut only if they are frequent in both texts? -->
   <xsl:param name="cut-frequent-aliases-only-if-frequent-in-both-texts" as="xs:boolean" select="true()"/>
   
   <!-- Should token aliases be skipped if they are found in $skip-token-alias-map for a given language? -->
   <xsl:param name="apply-skip-token-alias-map" as="xs:boolean" select="true()"/>
   
   <!-- What alias values should be ignored? The parameter takes a map, with one map entry per language
      code. There is a special map entry with a key '*' that will apply to every alias value, regardless
      of language. The entries are comparable to so-called stopwords, but remember, these apply to token 
      ALIASES, not to the tokens themselves. -->
   <xsl:param name="skip-token-alias-map" as="map(xs:string,xs:string*)">
      <xsl:map>
         <xsl:map-entry key="'*'"/>
         <xsl:map-entry key="'grc'" select="'ΑΒΓ', 'αὐτός', 'γάρ', 'δέ', 'διά', 'εἰ', 'εἰμί', 'εἰς', 'καί', 
            'κατά', 'λέγω', 'μή', 'οὐ', 'οὐδέ', 'οὕτος', 'οὕτω(ς)', 'οὗτος', 'πρός', 'σός', 'σύ', 'τέ', 
            'τίς', 'τε', 'τις', 'τοῖς', 'τοῦ', 'τοῦτο', 'τό', 'τῷ', 'φημί', 'ἀλλά', 'ἐάν', 'ἐγώ', 'ἐκ', 
            'ἐν', 'ἐπί', 'ἑαυτοῦ', 'ἤ', 'ἤ2', 'ὁ', 'ὅ', 'ὅς', 'ὅστις', 'ὅτι', 'ὡς'"/>
         <!-- The Greek section responds to the Perseus database of lexemes, so there are some strange-looking
         entries, e.g., ἤ2. Not every preposition is listed, e.g., ἄνω, because some are not overly common.
         λέγω is removed because it is common, and because it normally signals a quotation to come and is 
         noromally not part of a quotation. YMMV. -->
      </xsl:map>
   </xsl:param>
   
   
   
   <!-- Should select intermediate results be saved along the way? If true, time-consuming operations
      will save intermediate results saved in the chosen temporary directory, so that if the same 
      routine is run again, with limited changes to some of the parameters, the application can pick
      up from previous stages that are not affected by the changes in parameters. -->
   <xsl:param name="tan:save-and-use-intermediate-steps" static="yes" select="true()" as="xs:boolean"/>
   
   <!-- When looking for saved intermediate steps in the temporary directory, should the application
      be strict in its analysis of any factors that might have changed? If false, then the application
      will verify previous steps quickly but perhaps at the expense of accuracy. For example, if you
      change a letter in a source, a non-strict check, which looks only at the length of the text,
      will assume that everything is the same. If you choose true for this parameter, be prepared for
      longer analysis. But even when the parameter is true, the application will not check to see if
      any TAN-A-lm libraries have changed, because on thousands of files that would take a very long time.
      If you make changes to the TAN-A-lm files that support this application, it is best to simply delete
      the files in the temporary drive and restart afresh. Also note, when switching this value,
      previously saved stages using the other method will be ignored.
   -->
   <xsl:param name="verify-intermediate-steps-strictly" as="xs:boolean" select="false()"/>
   
   <!-- Note, the temporary directory where intermediate steps is established by the parameter
      temporary-file-directory in ../../parameters/params-application.xsl. Normally you'll want to keep
      your temporary files in a central location where you can remember to clear them out. The files that
      are saved there are given filenames associated with the hash value of the file being saved, so
      overwriting of a temporary file is nearly impossible.
         If you want to dictate exactly where temporary files should go for this application, simply copy
      the parameter and paste in here, replacing it with the value that you prefer. -->
   


   <!-- STEP THREE: ADJUST THE HTML OUTPUT -->
   

   <!-- Where is the HTML template that should be used as the basis for the output? Expected: a 
      resolved uri, e.g., file:/c:/users/~user/documents/my-template.html -->
   <xsl:param name="html-template-uri-resolved" select="resolve-uri('incl/tangram-template.html')"/>
   
   
   <!-- How many words context should be supplied on either side of a cluster? -->
   <xsl:param name="extra-context-token-count" as="xs:integer" select="5"/>
   
   <!-- What is the preferred title to put in the HTML page?  -->
   <xsl:param name="preferred-html-title" as="xs:string?"/>
   <!-- What is the preferred subtitle to put in the HTML page? -->
   <xsl:param name="preferred-html-subtitle" as="xs:string?"/>
   <!-- What introductory material should be supplied after the title/subtitle? Can be text, html, 
      among other things. -->
   <xsl:param name="introductory-text" as="item()*"/>
   
   
   <!-- For what directory is the output intended? This is important to reconcile any relative
      links. -->
   <xsl:param name="output-directory-uri" as="xs:string"
      select="$tan:default-output-directory-resolved"/>
   
   <!-- What is the base output filename? The XML file will be given an .xml extension and the HTML
      file an .html one. -->
   <xsl:param name="output-base-filename" as="xs:string" select="'parallels-' || $tan:today-iso"/>
   
   


   <!-- THE APPLICATION -->

   <!-- The main engine for the application is in this file, and in other files it links to. Feel free to 
      explore, but make alterations only if you know what you are doing. If you make changes, make a copy 
      of the original file first. -->
   <xsl:include href="incl/Tangram%20core.xsl"/>
   <!-- Please don't change the following variable. It helps the application figure out where your directories
    are. -->
   <xsl:variable name="calling-stylesheet-uri" as="xs:anyURI" select="static-base-uri()"/>
   
</xsl:stylesheet>
