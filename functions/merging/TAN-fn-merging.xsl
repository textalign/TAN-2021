<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns="tag:textalign.net,2015:ns" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library merging functions. -->
   
   <xsl:function name="tan:merge-expanded-docs" as="document-node()?" visibility="public">
      <!-- Input: Any TAN documents that have been expanded at least tersely -->
      <!-- Output: A document that is a collation of the documents. There is one <head> per source, but only one <body>, with contents merged. -->
      <!-- Templates will be placed in the appropriate function file, e.g., class 1 merge templates are in TAN-class-1-functions.xsl -->
      <!-- Class 1 merging: All <div>s with the same <ref> values are grouped together. If the class 1 files are sources of a class 2 file, it is assumed that all actions in the <adjustments> have already been performed. -->
      <!-- Class 2 merging: TBD -->
      <!-- Class 3 merging: TBD -->
      <!-- NB: Class 1 files must have their hierarchies in proper order; use reset-hierarchy beforehand if you're unsure -->
      <!--kw: merging, files -->
      <xsl:param name="expanded-docs" as="document-node()*"/>
      <xsl:apply-templates select="$expanded-docs[1]" mode="tan:merge-tan-docs">
         <xsl:with-param name="documents-to-merge" select="$expanded-docs[position() gt 1]"/>
      </xsl:apply-templates>
   </xsl:function>
   
   <!-- Currently, merging is not defined for class 2 or class 3 files. -->
   
   <xsl:mode name="tan:merge-tan-docs" on-no-match="shallow-copy"/>
   
   <xsl:template match="document-node()" mode="tan:merge-tan-docs">
      <xsl:param name="documents-to-merge" as="document-node()*"/>
      <xsl:document>
         <xsl:copy-of select="$documents-to-merge/*/preceding-sibling::node()"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="elements-to-merge" select="$documents-to-merge/*"/>
         </xsl:apply-templates>
         <xsl:copy-of select="$documents-to-merge/*/following-sibling::node()"/>
      </xsl:document>
   </xsl:template>
   
   <!-- Class 1 merging -->
   
   <xsl:template match="/tan:TAN-T | /tei:TEI" mode="tan:merge-tan-docs">
      <!-- A merged TAN-T file is a collation of multiple TAN-T(EI) files, with each head preserved intact, and the 
      single body consisting of a hierarchy of divs grouped by a common reference scheme, dictated by @n. 
      This function has assumed the following principles, most important first:
      - merged output need not have everything needed to reconstruct the original sources, but the data must permit 
      enough differentiation among sources to facilitate a variety of later uses, and therefore different configurations:
      - each part of a merged version should keep its relative order
      - in a merge, <div>s should be sorted by numerical order, if available, or by relative order, if not
      - merges may mix leaf and non-leaf divs
      - merges on the leaf div level should not lack any version, including versions that span or bridge other leaf divs
      - if a merge results in multiple copies, or parts, of a div, the div should be tagged with appropriate metadata 
      indicating that copies of it reside elsewhere
      - divs should retain their depth in the hierarchy, but <div>s that are versions of the same leaf node should be
      pushed down one level, encompassed by a <div> that groups it and its fellow version <div>s.
      
      The result is a series of simplified <div>s that contain key <n>, <ref>, <src>, and class-2 adjustment anchors, 
      with leaf divs in the innermost position of the appropriate grouping <div>
      
      The above list will be better understood in light of specific challenges in class 1 merges, discussed below. -->
      <!-- Some challenges in merging TAN-T files, discussed point by point: --> 
      <!-- Challenge: A div with a particular ref/n might be split, with other divs in-between
      Resolution: all split divs will be grouped together, because the whole point of a merge is, well, to merge.
      Suppose you had to merge a leaf div from version A with a split leaf div from version B. If you did not fully merge 
      B you would need to move A into one B split or the other, or put one copy of A in one split and another in the other. 
      The situation would get even more complicated for a version C with non-leaf divs that would need to be 
      merged. On the other hand, the grouping does not mean consolidation. The two, three, or more parts of a 
      split div will be preserved as sibling elements within a merge. To assist in later processing, such split divs will
      be given @part and @part-count and appropriate integers (to be able to express something like "part 1 of 3").
      In addition, each split div element will have the same value for @q, to facilitate referencing. --> 
      
      <!-- Challenge: A particular version might have a div where numerical @ns do not follow their original sequence 
      (remember, a TAN-T file should honor the sequence of the text within the scriptum, ahead of any reference system)
      Resolution: A merge necessarily has to rearrange divs. As a general rule, the order of divs should be determined 
      by adhering to the numerical value of @ns.--> 
      
      <!-- Challenge: Many @ns are not numbers, and a non-numerical div may appear in rather different places in 
      different versions.
      Resolution: The position of a merged div with a non-numerical @n should be determined in accordance
      with principles outlined above regarding the order of divs. Suppose you have version one with div @ns
      of (epigraph), (1), (2); version two with (1), (2), (epigraph). The merge should result, for better or worse, with
      the divs ordered: (1), (epigraph), (2). Similarly, a version one with divs (title), (1), (2), ... (59), (60) and 
      a version two with divs (title), (1), should result in the order of version one, and not something like 
      (1), (2), ... (15), (title), (16), ... (59), (60). The position of non-numerical divs should be determined by 
      nearby numerical div context, specifically the closest previous numerical @n value, then the distance from
      it (i.e., calculate the number of intervening divs with non-numerical @n values that intervene). --> 
      
      <!-- Challenge: Some non-numerical @n's appear in different orders in different versions.
      Resolution: An example of the challenge would be the Old Testament / Tanakh. Modern editions have an
      order of books that diverges from what is in the Septuagint, and a merge of those two versions, according
      to the principles outlined above, would result in an idiosyncractic order of books. If the
      user wishes such divs to follow a particular order, it is up to a later process to re-sort the output. --> 
      
      <!-- Challenge: After adjustment actions, some sources may have empty divs (those without children divs and 
      without text / tokens).
      Resolution: Empty divs will be skipped. -->
      
      <!-- Challenge: Some @ns might have multiple values, with complex overlap patterns
      Resolution: In a merge, when the algorithm encounters multiple values of @n, all numerical values are
      retained, and any non-numerical values are thrown out. The numerals are treated as requiring distribution.
      That is, if @n points to multiple numerical references, copies of the div are to distributed to the 
      atomic numerical values of @n. If no numerical values of @n are found, each value is treated as an alias, and 
      invite merging, greedily.
         Numerical example: four divs with @n values of (The_Cow, 1), (The_Cow, 2), (1), (2). The non-numerical
      values are ignored for their numerical counterparts, resulting in two merge groups, one for 1, another for 2.
         Non-numerical example: three divs with @n values of (head), (head, title), (title). Greedy overlap of the 
      aliases results in a single group.
         Mixed example: three divs with @n values of (head), (head, title, 1), (title). Because the middle term has 
      a numerical value, the non-numerical values are ignored, resulting in three merge groups: head, 1, and title.
         Numerical example with ranges: four divs with @n values of (1), (2), (3), (1-3). The last @n value, a 
      complex/spanning range, requires distribution. Three merge groups are created. The three copies of the
      fourth div are each imprinted with @copy (value 1, 2, or 3) and @copy-count (value 3). Each copy retains 
      intact its @q id, and its content. If an application using a merge requires the content to be reallocated
      proportionately, it will need to perform that operation upon the merged output. (There are many methods of
      proportional reallocation, and some of them require inspection of other versions that are in the merge, so
      there is little point in implementing in this merge algorithm a complex process that many users will not
      find useful or representative of their texts.)
         The position of merged divs follow the principles detailed earlier. Those with numerical references retain 
      their position relative to their @n value. Those with only non-numerical references will attract a position 
      computed by their position relative to the closest preceding div with a numerical value for @n. -->
      <xsl:param name="elements-to-merge" as="element()*"/>
      
      <xsl:variable name="mergable-elements" select="$elements-to-merge[self::tan:TAN-T or self::tei:TEI]" as="element()*"/>
      <xsl:variable name="pre-merge-bodies-pass-1" as="element()*">
         <xsl:apply-templates select="tan:body, $mergable-elements/tan:body"
            mode="tan:prep-class-1-files-for-merge"/>
      </xsl:variable>
      
      <TAN-T_merge>
         <xsl:apply-templates select="tan:head, $mergable-elements/tan:head" mode="#current"/>
         <xsl:apply-templates select="$pre-merge-bodies-pass-1[1]" mode="#current">
            <xsl:with-param name="elements-to-merge" select="$pre-merge-bodies-pass-1[position() gt 1]"/>
         </xsl:apply-templates>
      </TAN-T_merge>
   </xsl:template>
   
   <xsl:template match="/tan:TAN-T/tan:head | tei:TEI/tan:head" mode="tan:merge-tan-docs">
      <xsl:variable name="this-src-or-id-attr" select="root(.)/*/(@src, @id)[1]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <src>
            <xsl:value-of select="$this-src-or-id-attr"/>
         </src>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:body[tan:div] | tan:div" mode="tan:merge-tan-docs">
      <xsl:param name="elements-to-merge" as="element()*"/>
      <xsl:param name="primary-n-value" as="xs:string" tunnel="yes" select="''"/>
      <!-- We assume that the current context element is the primary/first element, whose children divs should be merged with the children divs of the elements to merge -->
      <!-- Any child element that is not a div will get copied first, and stamped with @src, to specify the source -->
      <!-- Any host attributes, which are source-specific, will be lost -->

      <xsl:variable name="this-is-body" select="local-name(.) eq 'body'" as="xs:boolean"/>

      <xsl:variable name="non-numbered-children-divs" select="tan:div[tan:non-numbered], $elements-to-merge/tan:div[tan:non-numbered]"/>
      <xsl:variable name="non-numbered-children-divs-grouped" select="tan:group-divs-by-ref($non-numbered-children-divs)"/>
      <xsl:variable name="numbered-children-divs" select="tan:div[not(tan:non-numbered)], $elements-to-merge/tan:div[not(tan:non-numbered)]"/>
      <xsl:variable name="non-leaf-adjustments" select="self::*[tan:div]/(tan:rename | tan:equate | tan:skip),
         $elements-to-merge[tan:div]/(tan:rename | tan:equate | tan:skip)" as="element()*"/>
      
      <xsl:variable name="primary-n-value-is-number" select="matches($primary-n-value, '^\d+(#\d+)?$')" as="xs:boolean"/>
      <xsl:variable name="unique-non-numbered-ns" select="
            tan:distinct-items((self::*[tan:non-numbered]/tan:n[not(. eq $primary-n-value)],
            $elements-to-merge[tan:non-numbered]/tan:n[not(. eq $primary-n-value)]))"
         as="element()*"/>
      
      <xsl:copy>
         
         <!-- leave a copy of distinct <n>s and <ref>s -->
         <xsl:choose>
            <!-- no need to copy <n> or <ref> in a body -->
            <xsl:when test="$this-is-body"/>
            <xsl:when test="$primary-n-value-is-number">
               <n><xsl:value-of select="$primary-n-value"/></n>
               <xsl:for-each-group select="tan:ref[tan:n], $elements-to-merge/tan:ref[tan:n]" group-by="(string-join((tan:n except tan:n[last()]), $tan:separator-hierarchy), '')[1]">
                  <ref>
                     <xsl:value-of select="normalize-space(string-join((current-grouping-key(), $primary-n-value), $tan:separator-hierarchy))"/>
                     <xsl:copy-of select="current-group()[1]/(tan:n except tan:n[last()])"/>
                     <n><xsl:value-of select="$primary-n-value"/></n>
                  </ref>
               </xsl:for-each-group>
            </xsl:when>
            <xsl:when test="matches($primary-n-value, 'group \d')">
               <xsl:copy-of select="$unique-non-numbered-ns"/>
               <xsl:for-each-group select="tan:ref[tan:n], $elements-to-merge/tan:ref[tan:n]" group-by="(string-join((tan:n except tan:n[last()]), $tan:separator-hierarchy), '')[1]">
                  <xsl:variable name="this-ref-base" select="current-grouping-key()" as="xs:string"/>
                  <xsl:variable name="this-ref-group" select="current-group()" as="element()+"/>
                  <xsl:for-each select="$unique-non-numbered-ns">
                     <ref>
                        <xsl:value-of select="normalize-space(string-join(($this-ref-base, .), $tan:separator-hierarchy))"/>
                        <xsl:copy-of select="$this-ref-group[1]/(tan:n except tan:n[last()])"/>
                        <n><xsl:value-of select="."/></n>
                     </ref>
                  </xsl:for-each>
               </xsl:for-each-group>
            </xsl:when>
            <xsl:when test="string-length($primary-n-value) gt 0">
               <n><xsl:value-of select="$primary-n-value"/></n>
               <xsl:copy-of select="$unique-non-numbered-ns"/>
               <xsl:for-each-group select="tan:ref[tan:n], $elements-to-merge/tan:ref[tan:n]" group-by="(string-join((tan:n except tan:n[last()]), $tan:separator-hierarchy), '')[1]">
                  <xsl:variable name="this-ref-base" select="current-grouping-key()" as="xs:string"/>
                  <xsl:variable name="this-ref-group" select="current-group()" as="element()+"/>
                  <xsl:for-each select="$primary-n-value, $unique-non-numbered-ns">
                     <ref>
                        <xsl:value-of select="normalize-space(string-join(($this-ref-base, .), $tan:separator-hierarchy))"/>
                        <xsl:copy-of select="$this-ref-group[1]/(tan:n except tan:n[last()])"/>
                        <n><xsl:value-of select="."/></n>
                     </ref>
                  </xsl:for-each>
               </xsl:for-each-group>
               
            </xsl:when>
         </xsl:choose>
         
         <!-- specify the sources that are part of the merged group -->
         <xsl:for-each select="distinct-values((@src, $elements-to-merge/@src))">
            <src>
               <xsl:value-of select="."/>
            </src>
         </xsl:for-each>
         
         <!-- Leaf-level adjustments will populate the individual leaves, but any adjustments applied earlier will not be
         recorded unless this provision is made. -->
         <xsl:if test="exists($non-leaf-adjustments)">
            <adjustments>
               <xsl:for-each select="$non-leaf-adjustments">
                  <xsl:variable name="this-src" select="ancestor-or-self::*[(@src | tan:src)][1]/(@src | tan:src)"/>
                  
                  <xsl:copy>
                     <xsl:copy-of select="@*"/>
                     <src><xsl:value-of select="$this-src"/></src>
                     <xsl:copy-of select="node()"/>
                  </xsl:copy>
               </xsl:for-each>
            </adjustments> 
            
         </xsl:if>
         
         <!-- This or elements to merge that are leaf divs should be processed before their children are grouped -->
         <xsl:apply-templates select="self::tan:div[not(tan:div)], $elements-to-merge[not(tan:div)]"
            mode="tan:merge-tan-doc-leaf-divs"/>

         <xsl:for-each-group select="$non-numbered-children-divs-grouped/tan:div, $numbered-children-divs"
            group-by="
               if (exists(parent::tan:group)) then
                  concat('group ', ../@n)
               else
                  tan:n[matches(., '^\d+(#\d+)?$')]">
            <xsl:sort
               select="
                  if (starts-with(current-grouping-key(), 'group')) then
                     avg(for $i in current-group()/tan:non-numbered/tan:n-pos[1]
                     return
                        xs:integer($i))
                  else
                     xs:integer(tokenize(current-grouping-key(), '#')[1])"
            />
            <xsl:sort
               select="
                  if (starts-with(current-grouping-key(), 'group')) then
                     avg(for $i in current-group()/tan:non-numbered/tan:n-pos[2]
                     return
                        xs:integer($i))
                  else
                     xs:integer(tokenize(current-grouping-key(), '#')[2])"
            />

            <xsl:apply-templates select="current-group()[1]" mode="#current">
               <xsl:with-param name="elements-to-merge" select="current-group()[position() gt 1]"/>
               <xsl:with-param name="primary-n-value" as="xs:string" tunnel="yes" select="current-grouping-key()"
               />
               </xsl:apply-templates>
         </xsl:for-each-group>
      </xsl:copy>
   </xsl:template>
   
   
   <xsl:mode name="tan:merge-tan-doc-leaf-divs" on-no-match="shallow-copy"/>
   
   <xsl:template match="tan:div" mode="tan:merge-tan-doc-leaf-divs">
      <xsl:param name="primary-n-value" as="xs:string" tunnel="yes" select="''"/>
      <xsl:variable name="this-div-has-been-distributed" as="xs:boolean" select="not(tan:non-numbered) and count(tan:n) gt 1"/>
      <xsl:copy>
         <xsl:copy-of select="@* except @type"/>
         <!-- Special feature to itemize leaf divs, to differentiate them in a merge from <div>s of other versions -->
         <xsl:attribute name="type" select="'#version'"/>
         <xsl:if test="$this-div-has-been-distributed">
            <xsl:attribute name="copy" select="index-of(tan:n, $primary-n-value)"/>
            <xsl:attribute name="copy-count" select="count(tan:n)"/>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:ref[tan:n]" mode="tan:merge-tan-docs tan:merge-tan-doc-leaf-divs">
      <!-- An expanded class-1 file might have two kinds of <ref>s. One is a reconstruction
      of the reference hierarchy, marked by a text node and one or more <n>s. The other is
      an empty element with a @q that serves as an anchor from the source class-2 file. This
      template deals with only the former. The latter should be passed on as-is. -->
      <xsl:variable name="this-src-code" select="concat('#', (@src, ../@src)[1])"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:value-of select="string-join((text(), $this-src-code), $tan:separator-hierarchy)"/>
         <xsl:apply-templates select="*" mode="#current"/>
         <v>
            <xsl:value-of select="$this-src-code"/>
         </v>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:_weight | tan:_rel-pos | tan:_n-pos | tan:_n-integer | tan:non-numbered"
      mode="tan:merge-tan-docs tan:merge-tan-doc-leaf-divs"/>
   
   
   <xsl:mode name="tan:prep-class-1-files-for-merge" on-no-match="shallow-copy"/>
   
   <!-- Omit any empty divs -->
   <xsl:template match="tan:div[not(tan:div)][not(text())][not(tan:tok)][not(tei:*)]"
      mode="tan:prep-class-1-files-for-merge"/>
   
   <xsl:template match="tan:div" mode="tan:prep-class-1-files-for-merge">
      <xsl:variable name="numbered-ns" select="tan:n[matches(., '^\d+(#\d+)?$')]"/>
      <xsl:variable name="this-src-or-id-attr" select="root(.)/*[1]/(@src, @id)[1]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="src" select="$this-src-or-id-attr"/>
         <xsl:if test="not(exists($numbered-ns))">

            <xsl:variable name="last-numbered-div"
               select="preceding-sibling::tan:div[tan:n[matches(., '^\d+(#\d+)?$')]][1]"/>
            <xsl:variable name="intervening-divs"
               select="preceding-sibling::tan:div except $last-numbered-div/(self::*, preceding-sibling::tan:div)"/>
            <xsl:variable name="first-n-pos"
               select="
                  max((0,
                  for $i in $last-numbered-div/tan:n[matches(., '^\d+(#\d+)?$')]
                  return
                     xs:integer(tokenize($i, '#')[1])))"
            />
            <!-- Any div that lacks a numbered value of @n should come after any preceding numbered divs, including letter+Arabic and Arabic+letter combos,
            which have two levels of sorting. We assume that the second tier of ranking won't go beyond a 999,998 (in the Arabic+letter combo,
            that would require 38,472 letter ls). -->
            <xsl:variable name="second-n-pos" select="count($intervening-divs) + 999999"/>
            <non-numbered>
               <n-pos>
                  <xsl:value-of select="$first-n-pos"/>
               </n-pos>
               <n-pos>
                  <xsl:value-of select="$second-n-pos"/>
               </n-pos>
            </non-numbered>

         </xsl:if>
         <!-- Because <n>s are the primary point of merging, we eliminate any duplicates that might have creeped in. -->
         <xsl:for-each-group select="tan:n" group-by=".">
            <n>
               <xsl:value-of select="current-grouping-key()"/>
            </n>
         </xsl:for-each-group> 
         <xsl:apply-templates select="node() except tan:n" mode="#current"/>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="tan:ref" mode="tan:prep-class-1-files-for-merge">
      <xsl:variable name="this-src-or-id-attr" select="root(.)/*[1]/(@src, @id)[1]"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="src" select="$this-src-or-id-attr"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   


   <xsl:function name="tan:merge-divs" as="item()*" visibility="public">
      <!-- one-parameter version of the fuller one below -->
      <xsl:param name="expanded-class-1-fragment" as="item()*"/>
      <xsl:copy-of select="tan:merge-divs($expanded-class-1-fragment, true(), (), ())"/>
   </xsl:function>
   
   <xsl:function name="tan:merge-divs" as="item()*" visibility="public">
      <!-- two-parameter version of the fuller one below -->
      <xsl:param name="expanded-class-1-fragment" as="item()*"/>
      <xsl:param name="itemize-leaf-divs" as="xs:boolean"/>
      <xsl:copy-of select="tan:merge-divs($expanded-class-1-fragment, $itemize-leaf-divs, (), ())"/>
   </xsl:function>
   
   <xsl:function name="tan:merge-divs" as="item()*" visibility="public">
      <!-- Input: expanded class 1 document fragment whose individual <div>s are assumed to be in the proper hierarchy (result of tan:normalize-text-hierarchy()); a boolean indicating whether leaf divs should be itemized; an optional string representing the name of an attribute to be checked for duplicates -->
      <!-- Output: the fragment with the <div>s grouped according to their <ref> values -->
      <!-- If the 2nd parameter is true, for each leaf <div> in a group there will be a separate <div type="#version">; otherwise leaf divs will be merely copied -->
      <!-- For merging multiple files normally the value should be true; if they are misfits from a single source, false -->
      <!--kw: merging, tree manipulation, grouping -->
      <xsl:param name="expanded-class-1-fragment" as="item()*"/>
      <xsl:param name="itemize-leaf-divs" as="xs:boolean"/>
      <xsl:param name="exclude-elements-with-duplicate-values-of-what-attribute" as="xs:string?"/>
      <xsl:param name="keep-last-duplicate" as="xs:boolean?"/>
      <xsl:apply-templates select="$expanded-class-1-fragment" mode="tan:merge-divs">
         <xsl:with-param name="itemize-leaf-divs" select="$itemize-leaf-divs" as="xs:boolean"
            tunnel="yes"/>
         <xsl:with-param name="duplicate-check"
            select="$exclude-elements-with-duplicate-values-of-what-attribute" tunnel="yes"/>
         <xsl:with-param name="keep-last-duplicate" select="$keep-last-duplicate" tunnel="yes"/>
      </xsl:apply-templates>
   </xsl:function>

   <xsl:function name="tan:group-divs" as="element()*" visibility="public">
      <!-- Input: expanded <div>s -->
      <!-- Output: those <div>s grouped in <group>s according to their <ref> values -->
      <!-- Attempt is made to preserve original div order -->
      <!--kw: merging, grouping, tree manipulation -->
      <xsl:param name="divs-to-group" as="element()*"/>
      <!-- Begin looking for overlaps between divs by creating <div>s with only <ref> and the plain text reference -->
      <xsl:variable name="ref-group-prep" as="element()*">
         <xsl:for-each select="$divs-to-group">
            <xsl:copy>
               <xsl:for-each select="tan:ref">
                  <xsl:copy>
                     <xsl:value-of select="text()"/>
                  </xsl:copy>
               </xsl:for-each>
            </xsl:copy>
         </xsl:for-each>
      </xsl:variable>
      <!-- Now create groups of those stripped <div>s -->
      <xsl:variable name="ref-groups"
         select="tan:group-elements-by-shared-node-values($ref-group-prep, 'ref')" as="element()*"/>
      <xsl:variable name="sort-key-prep" as="element()*">
         <xsl:for-each-group select="$divs-to-group" group-by="tan:src">
            <a src="{current-grouping-key()}">
               <xsl:for-each select="current-group()/tan:ref[1]">
                  <xsl:variable name="this-first-ref" select="text()"/>
                  <ref>
                     <xsl:value-of
                        select="$ref-groups[tan:div/tan:ref = $this-first-ref]/tan:div[1]/tan:ref[1]"
                     />
                  </ref>
               </xsl:for-each>
            </a>
         </xsl:for-each-group>
      </xsl:variable>
      <xsl:variable name="sort-key" select="tan:collate-sequences($sort-key-prep)" as="xs:string*"/>
      
      <xsl:variable name="diagnostics-on" select="exists($divs-to-group/parent::tan:body)" as="xs:boolean"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for tan:group-divs()'"/>
         <xsl:message select="'ref group prep: ', $ref-group-prep"/>
         <xsl:message select="'ref groups: ', $ref-groups"/>
         <xsl:message select="'sort key prep: ', $sort-key-prep"/>
         <xsl:message select="'sort key: ', $sort-key"/>
      </xsl:if>
      
      <xsl:for-each-group select="$divs-to-group"
         group-by="
            for $i in tan:ref[1]/text()
            return
               $ref-groups[tan:div/tan:ref = $i]/tan:div[1]/tan:ref[1]">
         <xsl:sort select="(index-of($sort-key, current-grouping-key()))[1]"/>
         <group>
            <xsl:copy-of select="current-group()"/>
         </group>
      </xsl:for-each-group>
   </xsl:function>


   <xsl:mode name="tan:merge-divs" on-no-match="shallow-copy"/>

   <xsl:template match="tan:body" mode="tan:merge-divs">
      <xsl:variable name="these-children-divs-regrouped" as="element()*"
         select="tan:group-divs(tan:div)"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="node() except tan:div"/>
         <xsl:apply-templates select="$these-children-divs-regrouped" mode="#current"/>
      </xsl:copy>
   </xsl:template>

   <xsl:template match="tan:group" mode="tan:merge-divs">
      <xsl:param name="itemize-leaf-divs" tunnel="yes" select="true()"/>
      <xsl:param name="duplicate-check" as="xs:string?" tunnel="yes"/>
      <xsl:param name="keep-last-duplicate" as="xs:boolean?" tunnel="yes"/>
      <xsl:variable name="this-group-revised" as="element()">
         <xsl:choose>
            <xsl:when test="string-length($duplicate-check) gt 0">
               <xsl:apply-templates select="." mode="tan:strip-duplicate-children-by-attribute-value">
                  <xsl:with-param name="attribute-to-check" select="$duplicate-check"/>
                  <xsl:with-param name="keep-last-duplicate" select="$keep-last-duplicate"/>
               </xsl:apply-templates>
            </xsl:when>
            <xsl:otherwise>
               <xsl:sequence select="."/>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="children-divs" select="$this-group-revised/tan:div"/>
      <xsl:variable name="distinct-refs" select="distinct-values($children-divs/tan:ref/text())"/>
      <div>
         <xsl:copy-of select="$children-divs/(@* except @xml:lang)"/>
         <xsl:copy-of
            select="$children-divs/(* except (tan:div, tan:tok, tan:non-tok, tan:ref, tei:*))"/>
         
         <xsl:for-each-group select="$children-divs/tan:ref" group-by="text()">
            <ref>
               <xsl:copy-of select="current-group()[1]/tan:n"/>
               <xsl:copy-of select="current-group()/tan:orig-ref"/>
               <xsl:value-of select="current-grouping-key()"/>
            </ref>
         </xsl:for-each-group>
         <xsl:for-each-group select="$children-divs" group-by="exists(tan:div)">
            <xsl:choose>
               <xsl:when test="current-grouping-key()">
                  <xsl:apply-templates select="tan:group-divs(current-group()/tan:div)"
                     mode="#current"/>
               </xsl:when>
               <xsl:when test="$itemize-leaf-divs">
                  <!-- process leaf divs of a TAN-T_merge here -->
                  <xsl:apply-templates select="current-group()" mode="#current"/>
               </xsl:when>
               <xsl:otherwise>
                  <!-- It is assumed that if leaf divs are not being itemized, they are not in a TAN-T_merge (i.e., a single source), and so you want to flag cases where leaf divs and non-leaf divs get mixed -->
                  <xsl:copy-of select="current-group()/(tan:tok, tan:non-tok)"/>
                  <xsl:value-of select="tan:text-join(current-group()/text())"/>
               </xsl:otherwise>
            </xsl:choose>
         </xsl:for-each-group>
      </div>
   </xsl:template>
   
   <xsl:template match="tan:div[not(tan:div)]" mode="tan:merge-divs">
      <!-- Special feature to itemize leaf divs, to differentiate them in a merge from <div>s of other versions -->
      <xsl:variable name="new-refs" as="element()+">
         <xsl:variable name="this-src" select="concat('#', tan:src)"/>
         <xsl:for-each select="tan:ref">
            <xsl:copy>
               <xsl:value-of select="string-join((text(), $this-src), $tan:separator-hierarchy)"/>
               <xsl:copy-of select="*"/>
               <v>
                  <xsl:value-of select="$this-src"/>
               </v>
            </xsl:copy>
         </xsl:for-each>
      </xsl:variable>
      <div type="#version">
         <xsl:copy-of select="@* except @type"/>
         <!-- if 'version' is already reserved as an idref for another div-type, the hash in the attribute can be used to disambiguate -->
         <type>version</type>
         <xsl:copy-of select="$new-refs"/>
         <xsl:copy-of select="node() except tan:ref"/>
      </div>
   </xsl:template>



   
</xsl:stylesheet>
