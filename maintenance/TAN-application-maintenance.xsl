<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   expand-text="yes"
   version="3.0">
   <!-- This stylesheet is to hold core values and operations to assist the Schematron validation 
      unit for testing the validity of TAN applications. -->
   
   <xsl:include href="../functions/TAN-function-library.xsl"/>
   
   <xsl:variable name="top-level-comment-depth" as="xs:integer" select="2"/>
   <xsl:variable name="each-indentation-amount" as="xs:integer" select="3"/>
   <xsl:variable name="total-indentation" as="xs:integer" select="$top-level-comment-depth * $each-indentation-amount"/>
   <xsl:variable name="maximum-column-width-for-comments" as="xs:integer" select="100"/>
   
   <xsl:variable name="tan:include-to-main-application" select="/*/xsl:include[1]"/>
   <xsl:variable name="tan:main-application"
      select="doc(resolve-uri($tan:include-to-main-application/@href, base-uri()))"/>
   
   <xsl:variable name="tan:app-iri" as="element()?" select="$tan:main-application/*/xsl:param[@name eq 'tan:stylesheet-iri']"/>
   <xsl:variable name="tan:app-name" as="element()?" select="$tan:main-application/*/xsl:param[@name eq 'tan:stylesheet-name']"/>
   <xsl:variable name="tan:app-description" as="element()?" select="$tan:main-application/*/xsl:param[@name eq 'tan:stylesheet-description']"/>
   <xsl:variable name="tan:app-primary-input-desc" as="element()?" select="$tan:main-application/*/xsl:param[@name eq 'tan:stylesheet-primary-input-desc']"/>
   <xsl:variable name="tan:app-secondary-input-desc" as="element()?" select="$tan:main-application/*/xsl:param[@name eq 'tan:stylesheet-secondary-input-desc']"/>
   <xsl:variable name="tan:app-primary-output-desc" as="element()?" select="$tan:main-application/*/xsl:param[@name eq 'tan:stylesheet-primary-output-desc']"/>
   <xsl:variable name="tan:app-secondary-output-desc" as="element()?" select="$tan:main-application/*/xsl:param[@name eq 'tan:stylesheet-secondary-output-desc']"/>
   <xsl:variable name="tan:app-output-examples" as="element()?" select="$tan:main-application/*/xsl:param[@name eq 'tan:stylesheet-output-examples']"/>
   <xsl:variable name="tan:app-activity" as="element()?" select="$tan:main-application/*/xsl:param[@name eq 'tan:stylesheet-activity']"/>
   <xsl:variable name="tan:app-change-message" as="element()?" select="$tan:main-application/*/xsl:param[@name eq 'tan:stylesheet-change-message']"/>
   <xsl:variable name="tan:app-change-log" as="element()?" select="$tan:main-application/*/xsl:param[@name eq 'tan:stylesheet-change-log']"/>
   <xsl:variable name="tan:app-to-do-list" as="element()?" select="$tan:main-application/*/xsl:param[@name eq 'tan:stylesheet-to-do-list']"/>
   
   <xsl:variable name="tan:app-local-uri-collection" as="xs:anyURI*" select="uri-collection($tan:doc-parent-directory)"/>
   <xsl:variable name="tan:configuration-file-exists" as="xs:boolean" select="
         some $i in $tan:app-local-uri-collection
            satisfies contains($i, 'configuration')"/>
   
   <xsl:variable name="tan:welcome-message-starter" select="
         'Welcome to ' || (if (exists($tan:app-name)) then
            (substring($tan:app-name/@select, 2, string-length($tan:app-name/@select) - 2) || ', ')
         else
            ()) || 'the TAN application' || (if (exists($tan:app-activity)) then
            (' that ' || substring($tan:app-activity/@select, 2, string-length($tan:app-activity/@select) - 2))
         else
            ())"/>
   <xsl:variable name="tan:welcome-message-comment" as="comment()"
      select="tan:text-to-comment($tan:welcome-message-starter, $total-indentation, $maximum-column-width-for-comments)"/>
   
   <xsl:variable name="tan:app-description-comment" as="comment()"
      select="tan:text-to-comment($tan:app-description, $total-indentation, $maximum-column-width-for-comments)"
   />
   <xsl:variable name="tan:app-primary-input-comment" as="comment()"
      select="tan:text-to-comment('Primary input: ' || $tan:app-primary-input-desc, $total-indentation, $maximum-column-width-for-comments)"
   />
   <xsl:variable name="tan:app-secondary-input-comment" as="comment()"
      select="tan:text-to-comment('Secondary input: ' || $tan:app-secondary-input-desc, $total-indentation, $maximum-column-width-for-comments)"
   />
   <xsl:variable name="tan:app-primary-output-comment" as="comment()"
      select="tan:text-to-comment('Primary output: ' || $tan:app-primary-output-desc, $total-indentation, $maximum-column-width-for-comments)"
   />
   <xsl:variable name="tan:app-secondary-output-comment" as="comment()"
      select="tan:text-to-comment('Secondary output: ' || $tan:app-secondary-output-desc, $total-indentation, $maximum-column-width-for-comments)"
   />
   
   <xsl:variable name="tan:main-app-history" as="element()*" select="tan:get-doc-history($tan:main-application)"/>
   
   <xsl:variable name="tan:version-statement" as="comment()">
      <xsl:comment> Version {$tan:main-app-history/*[1]/@when}</xsl:comment>
   </xsl:variable>
   
   <xsl:variable name="tan:standard-app-preamble" as="xs:string">This master stylesheet is the
      public interface for the application. The parameters you will most likely want to change are
      listed and documented below, to help you customize the application to suit your needs. If you
      are relatively new to XSLT, or TAN applications, see Using TAN Applications and Utilities in
      the TAN Guidelines for general instructions. If you want to avoid changing the master
      application file, use the accompanying configuration file. Or make a copy of this file and
      edit and run it directly. Or create and configure a transformation scenario in Oxygen,
      defining the relevant parameters as you like. If you are comfortable with XSLT, try creating
      your own stylesheet, then import this one, and customize the process. To access the code base,
      follow the link in the &lt;xsl:include> at the bottom of this file. </xsl:variable>
   <xsl:variable name="tan:standard-app-preamble-norm" as="xs:string"
      select="normalize-space($tan:standard-app-preamble)"/>
   <xsl:variable name="tan:standard-app-preamble-comment" as="comment()"
      select="tan:text-to-comment($tan:standard-app-preamble-norm, $total-indentation, $maximum-column-width-for-comments)"/>
   
   <xsl:variable name="tan:config-file-preamble-1" as="xs:string">Use this file to build
      configurations for specific projects. Do so by copying from the master application file select
      &lt;xsl:param> elements that you wish to customize, paste them in this document, and change
      the settings to what you prefer. Remember that any parameter you do not redefine here will be
      given the value specified in the master XSLT file.</xsl:variable>
   <xsl:variable name="tan:config-file-preamble-2" as="xs:string">You may wish to make a copy of
      this file for each configuration, with a meaningful filename. If you are using Oxygen XML
      Editor, you should also adjust the entries in Configure Transformation Scenario(s)
      dialogue.</xsl:variable>
   <xsl:variable name="tan:config-file-preamble-1-norm" as="xs:string"
      select="normalize-space($tan:config-file-preamble-1)"/>
   <xsl:variable name="tan:config-file-preamble-2-norm" as="xs:string"
      select="normalize-space($tan:config-file-preamble-2)"/>
   <xsl:variable name="tan:config-file-preamble-1-comment" as="comment()"
      select="tan:text-to-comment($tan:config-file-preamble-1-norm, $total-indentation, $maximum-column-width-for-comments)"
   />
   <xsl:variable name="tan:config-file-preamble-2-comment" as="comment()"
      select="tan:text-to-comment($tan:config-file-preamble-2-norm, $total-indentation, $maximum-column-width-for-comments)"
   />
   
   <xsl:variable name="tan:standard-inclusion-warning" as="xs:string">The main engine for the
      application is in this file, and in other files it links to. Feel free to explore, but make
      alterations only if you know what you are doing. If you make changes, make a copy of the
      original file first.</xsl:variable>
   <xsl:variable name="tan:standard-inclusion-warning-norm" as="xs:string"
      select="normalize-space($tan:standard-inclusion-warning)"/>
   <xsl:variable name="tan:standard-inclusion-warning-comment" as="comment()"
      select="tan:text-to-comment($tan:standard-inclusion-warning-norm, $total-indentation, $maximum-column-width-for-comments)"/>
   
   <xsl:variable name="tan:calling-stylesheet-variable-warning" as="xs:string">Please don't change
      the following variable. It helps the application figure out where your directories are.
   </xsl:variable>
   <xsl:variable name="tan:calling-stylesheet-variable-warning-norm" as="xs:string"
      select="normalize-space($tan:calling-stylesheet-variable-warning)"/>
   <xsl:variable name="tan:calling-stylesheet-variable-warning-comment" as="comment()"
      select="tan:text-to-comment($tan:calling-stylesheet-variable-warning, $total-indentation, $maximum-column-width-for-comments)"/>
   
   <xsl:variable name="tan:example-locations-not-available" as="element()*"
      select="$tan:app-output-examples//*:location[not(unparsed-text-available(.))]"/>

   <xsl:variable name="tan:to-do-list-items" as="comment()*" select="
         for $i in $tan:app-to-do-list//text()[matches(., '\S')]
         return
            tan:text-to-comment('* ' || $i, $total-indentation, $maximum-column-width-for-comments)"
   />
   <xsl:variable name="tan:to-do-list-comment" as="comment()+">
      <xsl:sequence
         select="tan:text-to-comment('WARNING: CERTAIN FEATURES HAVE YET TO BE IMPLEMENTED', $total-indentation, $maximum-column-width-for-comments)"
      />
      <xsl:comment><xsl:value-of select="string-join($tan:to-do-list-items, '&#xa;' || tan:fill(' ', $total-indentation))"/></xsl:comment>
   </xsl:variable>
   
   <xsl:function name="tan:text-to-comment" as="comment()">
      <xsl:param name="input-text" as="xs:string"/>
      <xsl:param name="indentation-amount" as="xs:integer"/>
      <xsl:param name="maximum-column-width" as="xs:integer"/>
      
      <xsl:variable name="message-text-rewrapped" as="xs:string"
         select="tan:reformat-text($input-text, $indentation-amount, $maximum-column-width, 5, true())"/>
      
      <xsl:comment><xsl:value-of select="' ' || string-join($message-text-rewrapped) || ' '"/></xsl:comment>
   </xsl:function>
   
   <xsl:function name="tan:reformat-text" as="xs:string?">
      <!-- Input: any text that lends itself to space-based tokenization; three integers; a boolean -->
      <!-- Output: the text rewrapped; each line will begin with the amount of space specified by the
         first integer, and the amount of text in the line will not exceed the second. The third integer
         is a first-line offset, and the first line will be adjusted accordingly. If the boolean 
         is true, then the initial space will be preserved as-is, otherwise the indentation will be 
         applied there as well. -->
      <!-- This function should be applied paragraph-by-paragraph, to preserve initial indentations. -->
      <!-- The first-line offset is important for comments, where the first four characters and a customary
         space take up the first five columns. -->
      <xsl:param name="input-text" as="xs:string?"/>
      <xsl:param name="left-margin-count" as="xs:integer"/>
      <xsl:param name="maximum-column-count" as="xs:integer"/>
      <xsl:param name="first-line-offset" as="xs:integer"/>
      <xsl:param name="preserve-initial-space" as="xs:boolean"/>
      
      
      <xsl:variable name="new-line-indentation" as="xs:string" select="tan:fill(' ', $left-margin-count)"/>
      <xsl:variable name="initial-space" as="xs:string?" select="
            if ($preserve-initial-space) then
               analyze-string($input-text, '^ +')/*:match
            else
               $new-line-indentation"/>
      <xsl:variable name="text-rewrapped" as="xs:string*">
         <xsl:iterate select="tokenize(normalize-space($input-text), ' ')">
            <xsl:param name="current-pos" select="string-length($initial-space) - $left-margin-count + 1 + $first-line-offset"/>
            <xsl:variable name="current-word-length" as="xs:integer" select="string-length(.)"/>
            <xsl:variable name="is-overrun" as="xs:boolean"
               select="$current-pos + $current-word-length gt $maximum-column-count"/>
            <xsl:variable name="next-pos" as="xs:integer" select="
                  if ($is-overrun) then
                     $current-word-length + 1
                  else
                     ($current-pos + $current-word-length + 1)"/>
            
            <xsl:choose>
               <xsl:when test="$is-overrun">
                  <xsl:value-of select="'&#xa;' || $new-line-indentation || ."/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:if test="position() gt 1">
                     <xsl:value-of select="' '"/>
                  </xsl:if>
                  <xsl:value-of select="."/>
               </xsl:otherwise>
            </xsl:choose>
            
            <xsl:next-iteration>
               <xsl:with-param name="current-pos" select="$next-pos"/>
            </xsl:next-iteration>
         </xsl:iterate>
         
      </xsl:variable>
      
      <xsl:sequence select="$initial-space || string-join($text-rewrapped)"/>
      
   </xsl:function>
   
   <xsl:function name="tan:reformat-comment" as="comment()">
      <!-- Input: a comment, two integers -->
      <!-- Output: the comment, reformatted with new lines indented the number of spaces specified by the first
         parameter, and of a length no greater than the value specified by the second. -->
      <!-- If a given input line begins with more space than the indentation length, the balance will be assumed
         to be intentional extra indentation. -->
      <xsl:param name="comment-to-reformat" as="comment()"/>
      <xsl:param name="indentation-length" as="xs:integer"/>
      <xsl:param name="maximum-column-count" as="xs:integer"/>
      
      <xsl:variable name="comment-to-reformat-lines" as="xs:string*" select="tokenize($comment-to-reformat, '\r?\n')"/>
      <xsl:variable name="most-common-indentation" as="xs:string?">
         <xsl:for-each-group select="$comment-to-reformat-lines" group-by="analyze-string(., '^ +')/*:match">
            <xsl:sort select="count(current-group())" order="descending"/>
            <xsl:if test="position() eq 1">
               <xsl:value-of select="current-grouping-key()"/>
            </xsl:if>
         </xsl:for-each-group> 
      </xsl:variable>
      <xsl:variable name="most-common-indentation-length" as="xs:integer" select="string-length($most-common-indentation)"/>
      <xsl:variable name="indentation" as="xs:string" select="tan:fill(' ', $indentation-length)"/>
      
      <xsl:variable name="new-comment-lines" as="xs:string*">
         <xsl:iterate select="$comment-to-reformat-lines">
            <xsl:param name="text-to-place" as="xs:string?"/>
            
            <xsl:on-completion select="$text-to-place"/>
            
            <xsl:variable name="current-text" as="xs:string" select="."/>
            <xsl:variable name="current-indent" as="xs:string?" select="analyze-string($current-text, '^ +')/*:match"/>
            <xsl:variable name="intentional-indent" as="xs:string?" select="
                  if (string-length($current-indent) gt $most-common-indentation-length)
                  then
                     tan:fill(' ', string-length($current-indent) - $most-common-indentation-length)
                  else
                     ()"/>
            <xsl:variable name="is-blank-line" as="xs:boolean" select="not(matches($current-text, '\S'))"/>
            <xsl:variable name="is-new-first-line" as="xs:boolean" select="exists($intentional-indent)"/>
            <xsl:variable name="is-initial-line" as="xs:boolean" select="position() eq 1"/>
            <xsl:variable name="first-line-offset" as="xs:integer" select="
                  if ($is-initial-line) then
                     $indentation-length + 5
                  else
                     0"/>
            
            <xsl:variable name="current-text-to-place" as="xs:string?" >
               <xsl:choose>
                  <xsl:when test="$is-blank-line">
                     <xsl:sequence select="$text-to-place"/>
                  </xsl:when>
                  <xsl:when test="$is-new-first-line and (string-length($text-to-place) gt 0)">
                     <xsl:sequence select="$text-to-place"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:sequence
                        select="string-join(($text-to-place, normalize-space($current-text)), ' ')"
                     />
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:variable>
            

            <xsl:variable name="current-text-reformatted" as="xs:string"
               select="tan:reformat-text($current-text-to-place, $indentation-length, $maximum-column-count, $first-line-offset, true())"
            />
            <xsl:variable name="current-text-reformatted-lines" as="xs:string*"
               select="tokenize($current-text-reformatted, '\n')"/>
            <xsl:variable name="text-to-place-now" as="xs:string?">
               <xsl:choose>
                  <xsl:when test="$is-blank-line">
                     <xsl:copy-of select="string-join(($current-text-reformatted, '&#xa;'))"/>
                  </xsl:when>
                  <xsl:when test="$is-new-first-line and (position() gt 1)">
                     <xsl:copy-of select="$current-text-reformatted || '&#xa;'"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:copy-of select="
                           string-join(for $i in $current-text-reformatted-lines[position() ne last()]
                           return
                              ($i || '&#xa;'))"/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:variable>
            <xsl:variable name="text-to-push-ahead" as="xs:string?">
               <xsl:choose>
                  <xsl:when test="$is-blank-line"/>
                  <xsl:when test="$is-new-first-line">
                     <xsl:sequence select="$indentation || $intentional-indent || normalize-space($current-text)"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:sequence select="$current-text-reformatted-lines[last()]"/>
                  </xsl:otherwise>
               </xsl:choose>
            </xsl:variable>
            
            <xsl:variable name="diagnostics-on" as="xs:boolean" select="false()"/>
            <xsl:if test="$diagnostics-on">
               <xsl:message select="'Diagnostics on, tan:reformat-comment(), iteration ' || position()"/>
               <xsl:message select="'Most common indentation length: ' || $most-common-indentation-length"/>
               <xsl:message select="'Current text: [' || $current-text || ']'"/>
               <xsl:message select="'Intentional indent: [' || $intentional-indent || ']'"/>
               <xsl:message select="'Is blank line?', $is-blank-line"/>
               <xsl:message select="'Is new first line? ', $is-new-first-line"/>
               <xsl:message select="'Current text to place: [' || $current-text-to-place || ']'"/>
               <xsl:message select="'Current text reformatted: [' || $current-text-reformatted || ']'"/>
               <xsl:message select="'Current text reformatted line count: ', count($current-text-reformatted-lines)"/>
               <xsl:message select="'Text to place now: [' || $text-to-place-now || ']'"/>
               <xsl:message select="'Text to push ahead: [' || $text-to-push-ahead || ']'"/>
            </xsl:if>
            
            <xsl:copy-of select="$text-to-place-now"/>
            
            <xsl:next-iteration>
               <xsl:with-param name="text-to-place" select="$text-to-push-ahead"/>
            </xsl:next-iteration>
            
            
         </xsl:iterate>
      </xsl:variable>
      
      <xsl:comment><xsl:value-of select="' ' || string-join($new-comment-lines) || ' '"/></xsl:comment>
   </xsl:function>
   
   <xsl:variable name="another-comment" select="doc('../applications/explore/explore%20text%20parallels.xsl')/*/comment()[2]"/>
   <xsl:variable as="comment()" name="test-text-comment">
      <xsl:comment> This application searches for and scores clusters of words shared across two groups of 
      texts, allowing you to look for quotations, paraphrases,
      or shared topics. When configured correctly, Tangram can also find idioms and collocations.
                 Each input file, which may come in a variety of formats (TAN, TEI, other XML formats, plain
      text, Word documents) must be assigned to one or both of two groups, each group representing a
      work. Members of a work-group can be from different languages. Users can specify how many
      ngrams ("words") should be found, and how far apart they can be from each other. Ngram order
      is disregarded (e.g., ngram "shear", "blue", "sheep" would match ngram "sheep", "blue",
      "shear"). Tangram first normalizes and tokenizes each text according to language rules. Each
      token is converted to one or more aliases. If lexico-morphological data is available through a
      TAN-A-lm file, or if there is a TAN-A-lm language library for the language of the text being
      processed, a token may be replaced by multiple lexemes (e.g., "rung" would attract aliases
      "ring" and "rung"); otherwise, a case-insensitive generic form of the word is used. Then each
      text in group 1 is compared to each text in group 2 that shares the same language. For each
      pair of texts, Tangram identifies clusters of tokens that share the same alias. It then
      consolidates adjacent clusters of ngrams, and scores the results based upon several criteria.
      Grouped clusters are then converted into a primitive TAN-A file consisting of claims that
      identify parallel passages of each pair of texts, and the output is rendered as sortable HTML,
      to facilitate better study of the results. Tangram was written primarily to support quotation
      detection in ancient Greek and Latin texts, which has rather demanding requirements. Because
      of these objectives, Tangram frequently operates in quadratic or cubic time, so can be quite
      time-consuming to run. A feature allows the user to save intermediate stages as temporary
      files, to reduce processing time.    
      </xsl:comment>
      </xsl:variable>
   
   <xsl:param name="diagnostic-output" as="xs:boolean" static="yes" select="false()"/>
   <xsl:output indent="false" use-when="$diagnostic-output"/>
   <xsl:template match="/" use-when="$diagnostic-output">
      <!-- for diagnostics only -->
      <xsl:message select="'Diagnostic output on for ' || static-base-uri()"/>
      <diagnostics>
         <text-reformatted><xsl:copy-of select="tan:reformat-text($tan:standard-app-preamble, 8, 80, true())"/></text-reformatted>
         <xsl:text>&#xa;</xsl:text>
         <another-text-comment-reformatted><xsl:copy-of select="tan:reformat-comment($another-comment, 8, 80)"/></another-text-comment-reformatted>
         <text-comment-reformatted><xsl:copy-of select="tan:reformat-comment($test-text-comment, 8, 80)"/></text-comment-reformatted>
      </diagnostics>
   </xsl:template>
   
</xsl:stylesheet>