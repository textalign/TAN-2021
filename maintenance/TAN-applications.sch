<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" 
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   queryBinding="xslt2"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process">
   <sch:title>Schematron tests for maintaining the TAN application library</sch:title>
   <sch:ns uri="http://www.w3.org/1999/XSL/Transform" prefix="xsl"/>
   <sch:ns uri="tag:textalign.net,2015:ns" prefix="tan"/>
   
   <xsl:include href="TAN-application-maintenance.xsl"/>
   
   <sch:let name="is-configuration-file" value="contains(base-uri(.), 'configuration')"/>
   <sch:let name="is-blank-configuration-file" value="$is-configuration-file and count(/*/*) eq 1"/>
   
   <sch:let name="top-level-comments" value="/*/comment()"/>
   <sch:let name="welcome-message" value="/*/comment()[contains(normalize-space(.), $tan:welcome-message-starter)]"/>
   <sch:let name="app-description" value="/*/comment()[contains(normalize-space(.), normalize-space($tan:app-description))]"/>
   <sch:let name="app-primary-input-message" value="/*/comment()[matches(normalize-space(.), '^(Primary|Catalyzing) input:')]"/>
   <sch:let name="app-secondary-input-message" value="/*/comment()[matches(normalize-space(.), '^Secondary input:')]"/>
   <sch:let name="app-primary-output-message" value="/*/comment()[matches(normalize-space(.), '^Primary output:')]"/>
   <sch:let name="app-secondary-output-message" value="/*/comment()[matches(normalize-space(.), '^Secondary output:')]"/>
   <sch:let name="app-to-do-warning" value="
         /*/comment()[let $i := normalize-space(.)
         return
            every $j in $tan:app-to-do-list//text()
               satisfies contains($i, normalize-space($j))]"/>
   
   <sch:let name="version-statement"
      value="/*/comment()[starts-with(normalize-space(lower-case(.)), 'version')]"/>
   
   <sch:let name="app-preamble"
      value="/*/comment()[normalize-space(.) eq $tan:standard-app-preamble-norm]"/>

   <sch:let name="config-preamble-1"
      value="/*/comment()[normalize-space(.) eq $tan:config-file-preamble-1-norm]"/>
   <sch:let name="config-preamble-2"
      value="/*/comment()[normalize-space(.) eq $tan:config-file-preamble-2-norm]"/>
   
   <sch:let name="app-output-examples-not-mentioned" value="
         for $i in $tan:app-output-examples/*
         return
            (if (exists($top-level-comments[every $j in $i//text()
               satisfies contains(normalize-space(.), normalize-space($j))])) then
               ()
            else
               $i)"/>
   
   <sch:let name="all-parameter-names" value="/*/xsl:param/@name"/>
   
   <sch:let name="parent-directory-name" value="analyze-string(base-uri(.), '.+/([^/]+)/[^/]+$')/*:match/*:group"></sch:let>
   
   
   <sch:pattern>
      <sch:rule context="/*[$is-configuration-file]">
         <sch:assert test="exists($config-preamble-1)" sqf:fix="config-preamble-1">Every blank
            configuration file must include the first preamble.</sch:assert>
         <sch:assert test="exists($config-preamble-2)" sqf:fix="config-preamble-2">Every blank
            configuration file must include the second preamble.</sch:assert>
         
         <sqf:fix id="config-preamble-1">
            <sqf:description>
               <sqf:title>Add preamble 1 to the blank configuration file</sqf:title>
            </sqf:description>
            <sqf:add match="." position="first-child">
               <xsl:value-of select="'&#xa;'"/>
               <xsl:copy-of select="$tan:config-file-preamble-1-comment"/>
            </sqf:add>
         </sqf:fix>
         <sqf:fix id="config-preamble-2">
            <sqf:description>
               <sqf:title>Add preamble 2 to the blank configuration file</sqf:title>
            </sqf:description>
            <sqf:add match="." position="first-child">
               <xsl:value-of select="'&#xa;'"/>
               <xsl:copy-of select="$tan:config-file-preamble-2-comment"/>
            </sqf:add>
         </sqf:fix>
      </sch:rule>
      <sch:rule context="/*">
         <sch:assert test="tan:cfn(.) eq $parent-directory-name">The local filename must be
            identical to the name of its parent directory.</sch:assert>
         
         <sch:assert test="exists($tan:main-application)">There must be a main application
            available, through a single xsl:include.</sch:assert>
         <sch:assert test="exists($tan:app-iri)">Every TAN application must include in the main
            stylesheet an xsl:param whose name is tan:stylesheet-iri, declaring the application's
            IRI.</sch:assert>
         <sch:assert test="exists($tan:app-name)">Every TAN application must include in the main
            stylesheet an xsl:param whose name is tan:stylesheet-name, declaring the name of the
            application.</sch:assert>
         <sch:assert test="exists($tan:app-primary-input-desc)">Every TAN application must include
            in the main stylesheet an xsl:param whose name is tan:stylesheet-primary-input-desc,
            describing the expected primary input.</sch:assert>
         <sch:assert test="exists($tan:app-secondary-input-desc)">Every TAN application must include
            in the main stylesheet an xsl:param whose name is tan:stylesheet-secondary-input-desc,
            describing the expected secondary input.</sch:assert>
         <sch:assert test="exists($tan:app-primary-output-desc)">Every TAN application must include
            in the main stylesheet an xsl:param whose name is tan:stylesheet-primary-output-desc,
            describing the expected primary output.</sch:assert>
         <sch:assert test="exists($tan:app-secondary-output-desc)">Every TAN application must include
            in the main stylesheet an xsl:param whose name is tan:stylesheet-secondary-output-desc,
            describing the expected secondary output.</sch:assert>
         <sch:assert test="exists($tan:app-change-message)">Every TAN application must include in the main
            stylesheet an xsl:param whose name is tan:stylesheet-change-message, declaring the change being 
            performed by the application.</sch:assert>
         <sch:assert test="exists($tan:app-change-log)">Every TAN application must include in the main
            stylesheet an xsl:param whose name is tan:stylesheet-change-log, which takes a sequence
            of elements named change, and attributes @who and @when, listing changes made to the
            application.</sch:assert>
         
         <sch:assert test="$tan:configuration-file-exists">Every TAN application must be accompanied
            by at least one configuration file.</sch:assert>
         
         <sch:report test="exists($app-output-examples-not-mentioned)"
            sqf:fix="add-example-output-comment">
            <sch:value-of select="count($app-output-examples-not-mentioned)"/> output examples have
            not yet been provided as comments.</sch:report>
         <sch:report test="exists($tan:example-locations-not-available)" role="warning"><sch:value-of
               select="count($tan:example-locations-not-available)"/> examples are not available:
               <sch:value-of select="string-join($tan:example-locations-not-available, ', ')"
            /></sch:report>
         
         <sch:report test="exists($tan:app-description) and not(exists($app-description))" sqf:fix="add-description-comment">Every TAN
            application must include a comment describing the application.</sch:report>
         <sch:report test="not(exists($app-primary-input-message))"
            sqf:fix="add-primary-input-comment">Every TAN application must include a message stating
            describing its primary input</sch:report>
         <sch:report test="not(exists($app-secondary-input-message))"
            sqf:fix="add-secondary-input-comment">Every TAN application must include a message
            stating describing its secondary input</sch:report>
         <sch:report test="not(exists($app-primary-output-message))"
            sqf:fix="add-primary-output-comment">Every TAN application must include a message
            stating describing its primary output</sch:report>
         <sch:report test="not(exists($app-secondary-output-message))"
            sqf:fix="add-secondary-output-comment">Every TAN application must include a message
            stating describing its secondary output</sch:report>
         <sch:assert test="exists($welcome-message)" sqf:fix="add-welcome-comment">Every TAN
            application must include a comment welcoming the user to the application, identifiable
            by its starter: <sch:value-of select="$tan:welcome-message-starter"/></sch:assert>
         <sch:assert test="exists($version-statement)" sqf:fix="version-statement">Every TAN
            application must include a version statement.</sch:assert>
         <sch:assert test="exists($app-preamble)" sqf:fix="std-app-preamble">Every TAN application
            must include the standard preamble.</sch:assert>
         
         <sch:assert test="exists(comment()[contains(., 'PARAMETERS')])">There must be a comment
            with the text PARAMETERS, preceding all parameters</sch:assert>
         
         <sch:report test="exists($tan:app-to-do-list) and not(exists($app-to-do-warning))"
            sqf:fix="add-to-do-list">Every TAN application with an active list of development points
            must include a comment itemizing the things that need yet to be done.</sch:report>
         
         <sqf:fix id="add-example-output-comment" use-for-each="$app-output-examples-not-mentioned">
            <sqf:description>
               <sqf:title>Add output comment for <sch:value-of select="string-join($sqf:current/*)"/></sqf:title>
            </sqf:description>
            <sqf:add match="/*/comment()[1]" position="after">
               <xsl:value-of select="'&#xa;'"/>
               <xsl:comment><xsl:value-of select="string-join($sqf:current/*, '&#xa;')"/></xsl:comment>
            </sqf:add>
         </sqf:fix>
         
         <sqf:fix id="add-description-comment">
            <sqf:description>
               <sqf:title>Add description to TAN application</sqf:title>
            </sqf:description>
            <sqf:add match="/*/comment()[1]" position="after">
               <xsl:value-of select="'&#xa;'"/>
               <xsl:copy-of select="$tan:app-description-comment"/>
            </sqf:add>
         </sqf:fix>
         <sqf:fix id="add-primary-input-comment">
            <sqf:description>
               <sqf:title>Add primary input description to TAN application</sqf:title>
            </sqf:description>
            <sqf:add match="/*/comment()[1]" position="after">
               <xsl:value-of select="'&#xa;'"/>
               <xsl:copy-of select="$tan:app-primary-input-comment"/>
            </sqf:add>
         </sqf:fix>
         <sqf:fix id="add-secondary-input-comment">
            <sqf:description>
               <sqf:title>Add secondary input description to TAN application</sqf:title>
            </sqf:description>
            <sqf:add match="/*/comment()[1]" position="after">
               <xsl:value-of select="'&#xa;'"/>
               <xsl:copy-of select="$tan:app-secondary-input-comment"/>
            </sqf:add>
         </sqf:fix>
         <sqf:fix id="add-primary-output-comment">
            <sqf:description>
               <sqf:title>Add primary output description to TAN application</sqf:title>
            </sqf:description>
            <sqf:add match="/*/comment()[1]" position="after">
               <xsl:value-of select="'&#xa;'"/>
               <xsl:copy-of select="$tan:app-primary-output-comment"/>
            </sqf:add>
         </sqf:fix>
         <sqf:fix id="add-secondary-output-comment">
            <sqf:description>
               <sqf:title>Add secondary output description to TAN application</sqf:title>
            </sqf:description>
            <sqf:add match="/*/comment()[1]" position="after">
               <xsl:value-of select="'&#xa;'"/>
               <xsl:copy-of select="$tan:app-secondary-output-comment"/>
            </sqf:add>
         </sqf:fix>
         <sqf:fix id="add-welcome-comment">
            <sqf:description>
               <sqf:title>Add welcome to TAN application</sqf:title>
            </sqf:description>
            <sqf:add match="/*/comment()[1]" position="after">
               <xsl:value-of select="'&#xa;'"/>
               <xsl:copy-of select="$tan:welcome-message-comment"/>
            </sqf:add>
         </sqf:fix>
         <sqf:fix id="version-statement">
            <sqf:description>
               <sqf:title>Add version statement to TAN application</sqf:title>
            </sqf:description>
            <sqf:add match="/*/comment()[1]" position="after">
               <xsl:value-of select="'&#xa;'"/>
               <xsl:copy-of select="$tan:version-statement"/>
            </sqf:add>
         </sqf:fix>
         <sqf:fix id="std-app-preamble">
            <sqf:description>
               <sqf:title>Add standard preamble to TAN application</sqf:title>
            </sqf:description>
            <sqf:add match="." position="first-child">
               <xsl:value-of select="'&#xa;'"/>
               <xsl:copy-of select="$tan:standard-app-preamble-comment"/>
            </sqf:add>
         </sqf:fix>
         <sqf:fix id="add-to-do-list">
            <sqf:description>
               <sqf:title>Add to-do list to TAN application</sqf:title>
            </sqf:description>
            <sqf:add match="/*/comment()[1]" position="after">
               <xsl:for-each select="$tan:to-do-list-comment">
                  <xsl:value-of select="'&#xa;'"/>
                  <xsl:copy-of select="."/>
               </xsl:for-each>
            </sqf:add>
         </sqf:fix>
      </sch:rule>
      
      <sch:rule context="xsl:include">
         <sch:let name="warning-comment" value="preceding-sibling::comment()[1]"/>
         <sch:assert sqf:fix="include-warning-statement"
            test="normalize-space($warning-comment) eq $tan:standard-inclusion-warning-norm"
            >Every xsl:include must be immediately preceded by a comment warning the
            user on how to use it.</sch:assert>
         
         <sqf:fix id="include-warning-statement">
            <sqf:description>
               <sqf:title>Add include warning to TAN application</sqf:title>
            </sqf:description>
            <sqf:add position="before">
               <xsl:copy-of select="$tan:standard-inclusion-warning-comment"/>
               <xsl:value-of select="'&#xa;'"/>
            </sqf:add>
         </sqf:fix>
      </sch:rule>
      
      <sch:rule context="/*/comment()">
         <sch:let name="is-version-statement" value=". is $version-statement"/>
         <sch:let name="comment-lines" value="tokenize(., '\n')"/>
         <sch:let name="parameters-referred-to" value="analyze-string(., '\$([a-zA-Z][\w-]+)')"/>
         <sch:let name="parameters-mentioned-but-not-here"
            value="$parameters-referred-to/*:match/*:group[not(. = $all-parameter-names)]"/>
         <sch:let name="is-primary-input-desc" value=". is $app-primary-input-message"/>
         <sch:let name="is-secondary-input-desc" value=". is $app-secondary-input-message"/>
         <sch:let name="is-primary-output-desc" value=". is $app-primary-output-message"/>
         <sch:let name="is-secondary-output-desc" value=". is $app-secondary-output-message"/>
         <sch:let name="expected-message" value="
               if ($is-primary-input-desc) then
                  ($tan:app-primary-input-comment)
               else
                  if ($is-secondary-input-desc) then
                     ($tan:app-secondary-input-comment)
                  else
                     if ($is-primary-output-desc) then
                        ($tan:app-primary-output-comment)
                     else
                        if ($is-secondary-output-desc) then
                           ($tan:app-secondary-output-comment)
                        else
                           ()
               "/>
         <sch:report
            test="$is-version-statement and not(contains(., $tan:main-app-history/*[1]/@when))"
            sqf:fix="replace-with-version-statement">The version of this application should be
               <sch:value-of select="$tan:main-app-history/*[1]/@when"/></sch:report>
         <sch:report test="
               some $i in $comment-lines
                  satisfies string-length($i) gt ($total-indentation + $maximum-column-width-for-comments)"
            sqf:fix="reformat-comment" role="warning">In top-level comments, lines are normally no
            longer than <sch:value-of select="$maximum-column-width-for-comments"/> characters
            wide.</sch:report>
         <sch:report test="exists($parameters-mentioned-but-not-here)" role="warning"><sch:value-of
               select="count($parameters-mentioned-but-not-here)"/> parameters are mentioned, but
            are not here: <sch:value-of select="string-join($parameters-referred-to/*:match, ', ')"
            />. If a parameter is mentioned by name in the stylesheet, it should be seen
            here.</sch:report>
         <sch:report sqf:fix="replace-with-expected-message"
            test="string-length($expected-message) gt 0 and not(contains(normalize-space(.), normalize-space($expected-message)))"
            > Comment is expected to contain the following message: <sch:value-of
               select="$expected-message"/>
         </sch:report>
         
         <sch:report test="contains(., 'PARAMETERS') and exists(preceding-sibling::xsl:param)">The
            PARAMETERS header must precede any xsl:param</sch:report>
         
         
         <sqf:fix id="replace-with-version-statement">
            <sqf:description>
               <sqf:title>Replace with version statement</sqf:title>
            </sqf:description>
            <sqf:replace select="$tan:version-statement"/>
         </sqf:fix>
         <sqf:fix id="reformat-comment" xml:space="preserve">
            <sqf:description>
               <sqf:title>Reformat comment</sqf:title>
            </sqf:description>
            <sqf:replace xml:space="preserve"
               select="tan:reformat-comment(., $total-indentation, $maximum-column-width-for-comments)"
            />
         </sqf:fix>
         <sqf:fix id="replace-with-expected-message">
            <sqf:description>
               <sqf:title>Replace with expected message</sqf:title>
            </sqf:description>
            <sqf:replace select="$expected-message"/>
         </sqf:fix>
      </sch:rule>
      
      <sch:rule context="/*/xsl:variable">
         <sch:let name="warning-comment" value="preceding-sibling::comment()[1]"/>
         
         <sch:assert test="@name eq 'calling-stylesheet-uri'">The only global variable allowed in a
            TAN application interface is $calling-stylesheet-uri</sch:assert>
         <sch:assert sqf:fix="variable-warning-statement"
            test="normalize-space($warning-comment) eq $tan:calling-stylesheet-variable-warning-norm"
            >The global xsl:variable for a calling stylesheet uri must be immediately preceded by a
            comment warning the user not to change it.</sch:assert>
         
         <sqf:fix id="variable-warning-statement">
            <sqf:description>
               <sqf:title>Add include warning to TAN application</sqf:title>
            </sqf:description>
            <sqf:add position="before">
               <xsl:copy-of select="$tan:calling-stylesheet-variable-warning-comment"/>
               <xsl:value-of select="'&#xa;'"/>
            </sqf:add>
         </sqf:fix>
      </sch:rule>
   </sch:pattern>
   
   
</sch:schema>