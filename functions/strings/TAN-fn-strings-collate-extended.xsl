<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns="tag:textalign.net,2015:ns" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   version="3.0">

   <!-- TAN Function Library extended collate string functions. -->
   
   <!-- See also ../html/TAN-fn-html-diff-and-collate.xsl -->
   
   <xsl:function name="tan:get-collate-stats" as="element()?" visibility="public">
      <!-- Input: any output from tan:collate(); boolean -->
      <!-- Output: the output, wrapped in a <group> and preceded by statistics. If
         the boolean is true, then 3-way venn statistics will be included. -->
      <!-- For details, see comments at tan:infuse-diff-and-collate-stats(). -->
      <!--kw: strings -->
      <xsl:param name="collate-input" as="element()?"/>
      <xsl:param name="include-venns" as="xs:boolean"/>
      <xsl:apply-templates select="tan:infuse-diff-and-collate-stats($collate-input, (), $include-venns)" mode="tan:get-diff-stats"/>
   </xsl:function>
   

   <xsl:function name="tan:replace-collation" as="element()?" visibility="public">
      <!-- Input: two strings; the output of tan:collate() -->
      <!-- Output: the output, but an attempt is made to change every <c> and every <u> with the chosen witness 
         id (param 2) into the original string form (param 1). -->
      <!-- This is a companion function to tan:replace-diff(), but it has some inherent limitations. Diffs of 3 or
      more sources can be messy, and any attempt to replace every <u> with a particular version proves to be confusing 
      to interpret. Furthermore, tan:replace-diff() adjusts the output so that newly inserted characters
      are not repeated if they are applied equally to coordinate <a>s and <b>s. That is not possible for collate because
      of how chaotic the results can be. So the fallback method is to focus on getting the first witness right, and not
      worrying about the others. -->
      <!-- If the 2nd parameter is empty or doesn't match a particular witness id, then the first witness will be chosen.
      Intentionally supplying a bad 2nd parameter can be a good idea, if you are interested in only the dominant source, 
      since tan:collate() by default places at the top the witness with the least amount of divergence. -->
      <!-- Because only one witness is being recalibrated, it is possible to update the position values. But the other
      witness values will not be updated, so that the results can be correlated with the other witness texts if needed.
      Further, if a replacement involves that witness no longer attesting to that fragment, then it is changed to a <u>
      (or the <u> is retained) and the <wit> is dropped. -->
      <!--kw: strings, diff -->
      <xsl:param name="original-witness-string" as="xs:string?"/>
      <xsl:param name="original-witness-id" as="xs:string?"/>
      <xsl:param name="collate-output-to-replace" as="element()?"/>

      <xsl:variable name="picked-id-fixed" select="
            if ($original-witness-id = $collate-output-to-replace/tan:witness/@id) then
               $original-witness-id
            else
               $collate-output-to-replace/tan:witness[1]/@id"/>
      <xsl:variable name="picked-witness-text"
         select="string-join($collate-output-to-replace/*[tan:wit/@ref = $picked-id-fixed]/tan:txt)"/>
      <xsl:variable name="wit2-to-wit-diff"
         select="tan:diff($picked-witness-text, $original-witness-string, false())"/>

      <xsl:variable name="wit2-to-wit-diff-map" as="map(xs:integer, item()*)?"
         select="tan:diff-a-map($wit2-to-wit-diff)"/>

      <xsl:variable name="output-pass-1" as="element()?">
         <xsl:apply-templates select="$collate-output-to-replace" mode="tan:replace-collation">
            <xsl:with-param name="wit-id" tunnel="yes" select="$picked-id-fixed"/>
            <xsl:with-param name="wit-diff-map" tunnel="yes" select="$wit2-to-wit-diff-map"/>
         </xsl:apply-templates>
      </xsl:variable>

      <xsl:variable name="output-diagnostics-on" select="false()"/>
      <xsl:choose>
         <xsl:when test="$output-diagnostics-on">
            <xsl:message select="'Replacing output of tan:replace-collate() with diagnostic output'"/>
            <testing>
               <picked-id-fixed>
                  <xsl:value-of select="$picked-id-fixed"/>
               </picked-id-fixed>
               <orig-witness-text>
                  <xsl:value-of select="$original-witness-string"/>
               </orig-witness-text>
               <collate-witness-text>
                  <xsl:value-of select="$picked-witness-text"/>
               </collate-witness-text>
               <wit2-to-wit-diff>
                  <xsl:copy-of select="$wit2-to-wit-diff"/>
               </wit2-to-wit-diff>
               <!--<wit2-to-wit-map><xsl:value-of select="map:for-each($wit2-to-wit-diff-map, function($k, $v){string($k) || ' ' || serialize($v) || ' (' || string(count($v)) || '); '})"/></wit2-to-wit-map>-->
               <output-pass-1>
                  <xsl:copy-of select="$output-pass-1"/>
               </output-pass-1>
            </testing>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy-of select="$output-pass-1"/>
         </xsl:otherwise>
      </xsl:choose>


   </xsl:function>


   <xsl:mode name="tan:replace-collation" on-no-match="shallow-copy"/>

   <xsl:template match="tan:collation" mode="tan:replace-collation">
      <xsl:param name="wit-id" tunnel="yes" as="xs:string?"/>
      <xsl:param name="wit-diff-map" tunnel="yes" as="map(xs:integer, item()*)?"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="* except (tan:u | tan:c)"/>
         <xsl:iterate select="tan:u | tan:c">
            <xsl:param name="orig-last-pos" as="xs:integer" select="0"/>
            <xsl:param name="new-last-pos" as="xs:integer" select="0"/>

            <xsl:variable name="this-is-relevant" select="tan:wit/@ref = $wit-id"/>
            <xsl:variable name="these-txt-charpoints" select="string-to-codepoints(tan:txt)"/>
            <xsl:variable name="these-text-replacements" as="xs:string*">
               <xsl:for-each select="$these-txt-charpoints">
                  <xsl:variable name="this-pos" select="position()"/>
                  <xsl:variable name="this-map-value" as="item()*"
                     select="map:get($wit-diff-map, $orig-last-pos + $this-pos)"/>
                  <xsl:value-of select="string-join($this-map-value)"/>
               </xsl:for-each>
            </xsl:variable>
            <xsl:variable name="this-text-replacement"
               select="string-join($these-text-replacements)"/>
            <xsl:variable name="text-repl-len" select="string-length($this-text-replacement)"/>
            <xsl:variable name="this-is-empty" select="$text-repl-len lt 1"/>
            <xsl:variable name="ending-orig-pos" select="
                  if ($this-is-relevant) then
                     $orig-last-pos + count($these-txt-charpoints)
                  else
                     $orig-last-pos"/>
            <xsl:variable name="ending-new-pos" select="
                  if ($this-is-relevant) then
                     $new-last-pos + $text-repl-len
                  else
                     $new-last-pos"/>

            <xsl:choose>
               <!-- If the replacement is altogether empty, and this is the only witness, well, drop it. -->
               <xsl:when test="$this-is-relevant and $this-is-empty and count(tan:wit) eq 1"/>
               <xsl:when test="$this-is-relevant and $this-is-empty">
                  <!-- If it is being emptied out of this witness, demote the <c> to <u> (or keep it), and drop the <wit> -->
                  <u>
                     <xsl:copy-of select="tan:txt"/>
                     <xsl:copy-of select="tan:wit[not(@ref = $wit-id)]"/>
                  </u>
               </xsl:when>
               <xsl:when test="$this-is-relevant">
                  <xsl:copy>
                     <xsl:copy-of select="@*"/>
                     <txt>
                        <xsl:value-of select="$this-text-replacement"/>
                     </txt>
                     <wit ref="{$wit-id}" pos="{$new-last-pos + 1}"/>
                     <xsl:copy-of select="tan:wit[not(@ref = $wit-id)]"/>
                  </xsl:copy>

               </xsl:when>
               <xsl:otherwise>
                  <xsl:copy-of select="."/>
               </xsl:otherwise>
            </xsl:choose>

            <xsl:next-iteration>
               <xsl:with-param name="orig-last-pos" select="$ending-orig-pos"/>
               <xsl:with-param name="new-last-pos" select="$ending-new-pos"/>
            </xsl:next-iteration>
         </xsl:iterate>
      </xsl:copy>
   </xsl:template>





</xsl:stylesheet>
