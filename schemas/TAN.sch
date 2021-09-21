<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" queryBinding="xslt2">
   <title>Schematron tests for all TAN files.</title>
   <ns prefix="tan" uri="tag:textalign.net,2015:ns"/>
   <xsl:param name="tan:validation-mode-on" as="xs:boolean" select="true()" static="yes"/>
   <xsl:include href="../functions/TAN-function-library.xsl"/>
   
   <phase id="terse">
      <active pattern="terse-true"/>
      <active pattern="core-tests"/>
   </phase>
   <phase id="normal">
      <active pattern="normal-true"/>
      <active pattern="core-tests"/>
   </phase>
   <phase id="verbose">
      <active pattern="verbose-true"/>
      <active pattern="core-tests"/>
   </phase>
   <phase id="off">
      <active pattern="verbose-off"/>
   </phase>

   <pattern id="terse-true">
      <xsl:param name="tan:validation-is-terse" select="true()" as="xs:boolean"/>
   </pattern>
   <pattern id="normal-true">
      <xsl:param name="tan:validation-is-normal" select="true()" as="xs:boolean"/>
   </pattern>
   <pattern id="verbose-true">
      <xsl:param name="tan:validation-is-verbose" select="true()" as="xs:boolean"/>
   </pattern>
   <pattern id="verbose-off">
      <xsl:param name="tan:validation-is-empty" select="true()" as="xs:boolean"/>
   </pattern>
   <pattern id="core-tests">
      <title>Core Schematron tests for all TAN files.</title>
      
      <!-- This empty rule prevents checking TEI's <text>, which is always shallowly skipped in validation. -->
      <rule context="*:text"/>
      
      <!-- diagnostics, testing -->
      <rule context="/processing-instruction()[1]">
         <report test="false()" role="warning">New Schematron tests in effect.</report>
      </rule>
      
      <rule context="*">
         <let name="this-q-ref" value="generate-id(.)"/>
         <let name="this-name" value="name(.)"/>
         <let name="this-checked-for-errors"
            value="tan:get-via-q-ref($this-q-ref, $tan:self-expanded[1])"/>
         <let name="has-include-or-which-attr" value="exists(@include) or exists(@which)"/>
         <let name="relevant-fatalities" value="
               if ($has-include-or-which-attr = true()) then
                  $this-checked-for-errors//tan:fatal[not(@xml:id = $tan:errors-to-squelch)]
               else
                  $this-checked-for-errors/(self::*, tan:range)/(self::*, *[@attr])/tan:fatal[not(@xml:id = $tan:errors-to-squelch)]"/>
         <let name="relevant-errors" value="
               if ($has-include-or-which-attr = true()) then
                  $this-checked-for-errors//tan:error[not(@xml:id = $tan:errors-to-squelch)]
               else
                  $this-checked-for-errors/(self::*, tan:range)/(self::*, *[@attr])/tan:error[not(@xml:id = $tan:errors-to-squelch)]"/>
         <let name="relevant-warnings" value="
               if ($has-include-or-which-attr = true()) then
                  $this-checked-for-errors//tan:warning[not(@xml:id = $tan:errors-to-squelch)]
               else
                  $this-checked-for-errors/(self::*, tan:range)/(self::*, *[@attr])/tan:warning[not(@xml:id = $tan:errors-to-squelch)]"/>
         <let name="relevant-info" value="
               if ($has-include-or-which-attr = true()) then
                  $this-checked-for-errors//tan:info
               else
                  $this-checked-for-errors/(self::*, tan:range)/(self::*, *[@attr])/tan:info"/>
         <let name="help-offered" value="
               if ($has-include-or-which-attr = true()) then
                  $this-checked-for-errors//tan:help
               else
                  $this-checked-for-errors/(self::*, tan:range)/(self::*, *[@attr])/tan:help"/>
         <let name="relevant-problems"
            value="($relevant-fatalities, $relevant-errors, $relevant-warnings)"/>
         <let name="relevant-items" value="($relevant-problems, $relevant-info, $help-offered)"/>
         <let name="inclusion-errors" value="
               if ($this-name = 'inclusion') then
                  $this-checked-for-errors//(tan:fatal, tan:error, tan:warning)[not(@xml:id = $tan:errors-to-squelch)]
               else
                  ()"/>
         
         <!-- SQF FIX CONTAINERS -->
         <let name="these-fixes"
            value="($this-checked-for-errors/(self::*, *[@attr])/tan:fix, $relevant-items/tan:fix)"/>
         <let name="self-replacements" value="$these-fixes[@type = 'replace-self']"/>
         <let name="text-replacements" value="$these-fixes[@type = 'replace-text']"/>
         <let name="content-to-prepend" value="$these-fixes[@type = 'prepend-content']"/>
         <let name="content-to-append" value="$these-fixes[@type = 'append-content']"/>
         <let name="attributes-to-copy" value="$these-fixes[@type = 'copy-attributes']"/>
         <let name="replacement-attributes" value="$these-fixes[@type = 'replace-attributes']"/>
         <let name="self-deletions" value="$these-fixes[@type = 'delete-self']"/>
         <let name="which-expansions" value="$these-fixes[@type = 'expand-which']"/>

         <!-- For diagnostic tests, where reported errors are actually successes -->
         <let name="preceding-node" value="
               if ($tan:doc-is-error-test) then
                  preceding-sibling::node()[1]
               else
                  ()"/>
         <let name="preceding-comment" value="
               if ($tan:doc-is-error-test) then
                  ($preceding-node/self::comment(), $preceding-node/preceding-sibling::node()[1]/self::comment())[1]
               else
                  ()"/>
         <let name="these-intended-error-codes" value="
               tan:error-codes($preceding-comment)[($tan:internet-available and not(. = ('wrn09', 'wrn10')))
               or (not($tan:internet-available) and not(. = 'wrn11'))]"/>
         <!-- In diagnostic test files, if the internet is available drop non-internet warnings, and vice-versa -->

         <let name="intended-codes-missing" value="
               if ($tan:doc-is-error-test) then
                  $these-intended-error-codes[not(. = $relevant-items/@xml:id)]
               else
                  ()"/>
         <let name="unexpected-actual-errors" value="
               if ($tan:doc-is-error-test) then
                  $relevant-problems[not(@xml:id = $these-intended-error-codes)]
               else
                  ()"/>


         <report test="exists($relevant-fatalities) and not($tan:doc-is-error-test)" role="fatal"
               ><value-of select="tan:error-report($relevant-fatalities)"/></report>
         <report test="exists($relevant-errors) and not($tan:doc-is-error-test)" sqf:fix="tan-sqf"
               ><value-of select="tan:error-report($relevant-errors)"/></report>
         <report test="exists($relevant-warnings) and not($tan:doc-is-error-test)" role="warning"
            sqf:fix="tan-sqf"><value-of select="tan:error-report($relevant-warnings)"/></report>
         <report test="exists($relevant-info) and not($tan:doc-is-error-test)" role="info"><value-of
               select="$relevant-info/tan:message"/></report>
         <report test="exists($inclusion-errors) and not($tan:doc-is-error-test)" role="warning"
            >Included document has the following errors: <value-of
               select="tan:error-report($inclusion-errors)"/></report>
         <report test="exists($help-offered) and not($tan:doc-is-error-test)" role="warning"
            sqf:fix="tan-sqf">
            <value-of select="$help-offered/tan:message"/>
         </report>

         <report test="$tan:doc-is-error-test and exists($intended-codes-missing)">Expected: <value-of
               select="
                  for $i in $intended-codes-missing
                  return
                     concat($i, ' (', tan:error($i)/tan:rule, ')')"/></report>
         <report test="$tan:doc-is-error-test and exists($unexpected-actual-errors)">Unexpected errors:
               <value-of select="
                  for $i in $unexpected-actual-errors
                  return
                     concat($i/@xml:id, ' ', $i/tan:message, ' (', $i/tan:rule, ')')"
            /></report>

         <!-- SQFs -->
         <sqf:group id="tan-sqf" use-when="$has-include-or-which-attr = false()">
            <sqf:fix id="replace-self" use-when="exists($self-replacements)">
               <sqf:description>
                  <sqf:title>Replace self with: <value-of
                        select="tan:xml-to-string($self-replacements[1]/node())"/></sqf:title>
               </sqf:description>
               <!--<sqf:replace select="$self-replacements[1]/node()"/>-->
               <sqf:replace
                  select="tan:copy-indentation($self-replacements[1], .)/(node() except node()[1]/self::text())"
               />
            </sqf:fix>
            <sqf:fix id="replace-text" use-when="exists($text-replacements)">
               <sqf:description>
                  <sqf:title>Replace text with: <value-of select="$text-replacements[1]"
                     /></sqf:title>
               </sqf:description>
               <let name="text-node-number"
                  value="count($text-replacements[1]/../preceding-sibling::text()) + 1"/>
               <sqf:replace match="text()[$text-node-number]" select="$text-replacements[1]/text()"
               />
            </sqf:fix>
            <sqf:fix id="replace-text-2" use-when="exists($text-replacements[2])">
               <sqf:description>
                  <sqf:title>Replace text with: <value-of select="$text-replacements[2]"
                     /></sqf:title>
               </sqf:description>
               <let name="text-node-number"
                  value="count($text-replacements[2]/../preceding-sibling::text()) + 1"/>
               <sqf:replace match="text()[$text-node-number]" select="$text-replacements[2]/text()"
               />
            </sqf:fix>
            <sqf:fix id="prepend-content" use-when="exists($content-to-prepend)">
               <sqf:description>
                  <sqf:title>Prepend content with: <value-of
                        select="tan:xml-to-string($content-to-prepend/node())"/></sqf:title>
               </sqf:description>
               <sqf:add position="first-child" select="$content-to-prepend/node()"/>
            </sqf:fix>
            <sqf:fix id="append-content" use-when="exists($content-to-append)">
               <sqf:description>
                  <sqf:title>Append content with: <value-of
                        select="tan:xml-to-string($content-to-append/node())"/></sqf:title>
               </sqf:description>
               <sqf:add position="last-child" select="$content-to-append/node()"/>
            </sqf:fix>
            <sqf:fix id="copy-attributes" use-for-each="$attributes-to-copy/*">
               <sqf:description>
                  <sqf:title>Insert <value-of
                        select="tan:xml-to-string($sqf:current/@*)"/></sqf:title>
               </sqf:description>
               <sqf:replace>
                  <xsl:copy>
                     <xsl:copy-of select="@*"/>
                     <xsl:copy-of select="$sqf:current/@*"/>
                     <xsl:copy-of select="node()"/>
                  </xsl:copy>
               </sqf:replace>
            </sqf:fix>
            <sqf:fix id="add-master-location"
               use-when="exists($these-fixes[@type = 'add-master-location'])">
               <sqf:description>
                  <sqf:title>Add master-location element after &lt;name&gt;</sqf:title>
                  <sqf:p>Insert a &lt;master-location> immediately after &lt;name>, with the current
                     file's URL.</sqf:p>
               </sqf:description>
               <sqf:add position="after" select="$these-fixes[@type = 'add-master-location']/*"
                  match="/*/tan:head/tan:name[last()]"/>
            </sqf:fix>

            <sqf:fix id="replace-one-attribute" use-for-each="$replacement-attributes/descendant-or-self::*/@*">
               <sqf:description>
                  <sqf:title>Replace first @<value-of select="name($sqf:current)"/> with <value-of select="$sqf:current"/>
                     in self or descendants</sqf:title>
               </sqf:description>
               <sqf:replace match="(.//@*[name() = name($sqf:current)])[1]"
                  target="{name($sqf:current)}" node-type="attribute" select="string($sqf:current)"
               />
            </sqf:fix>
            <sqf:fix id="replace-all-attributes" use-for-each="$replacement-attributes/descendant-or-self::*/@*">
               <sqf:description>
                  <sqf:title>Replace every @<value-of select="name($sqf:current)"/> with <value-of select="$sqf:current"/>
                     in self or descendants</sqf:title>
               </sqf:description>
               <sqf:replace match="(.//@*[name() = name($sqf:current)])"
                  target="{name($sqf:current)}" node-type="attribute" select="string($sqf:current)"/>
            </sqf:fix>

            <sqf:fix id="self-deletion" use-when="exists($self-deletions)">
               <sqf:description>
                  <sqf:title>Delete this element</sqf:title>
               </sqf:description>
               <sqf:delete/>
            </sqf:fix>

            <sqf:fix id="current-date">
               <sqf:description>
                  <sqf:title>Change date to today's date, <value-of select="current-date()"
                     /></sqf:title>
               </sqf:description>
               <sqf:replace match="@when" target="when" node-type="attribute" use-when="@when"
                  select="current-date()"/>
               <sqf:replace match="@ed-when" target="ed-when" node-type="attribute"
                  use-when="@ed-when" select="current-date()"/>
               <sqf:replace match="@when-accessed" target="when-accessed" node-type="attribute"
                  use-when="@when-accessed" select="current-date()"/>
            </sqf:fix>
            <sqf:fix id="current-date-time">
               <sqf:description>
                  <sqf:title>Change date to today's date + time, <value-of
                        select="current-dateTime()"/></sqf:title>
               </sqf:description>
               <sqf:replace match="@when" target="when" node-type="attribute" use-when="@when"
                  select="current-dateTime()"/>
               <sqf:replace match="@ed-when" target="ed-when" node-type="attribute"
                  use-when="@ed-when" select="current-dateTime()"/>
               <sqf:replace match="." target="when-accessed" node-type="attribute"
                  use-when="@when-accessed" select="current-dateTime()"/>
            </sqf:fix>
            <sqf:fix id="expand-which" use-for-each="$which-expansions">
               <sqf:description>
                  <sqf:title>Replace @which with IRI + name pattern for <value-of select="$sqf:current/tan:name[1]"/></sqf:title>
               </sqf:description>
               <sqf:delete match="@which"/>
               <sqf:add position="first-child">
                  <xsl:copy-of
                     select="tan:copy-indentation($sqf:current, .)/node()"
                  />
               </sqf:add>
            </sqf:fix>
            
         </sqf:group>

      </rule>

   </pattern>
</schema>
