<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:textalign.net,2015:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:tei="http://www.tei-c.org/ns/1.0" xmlns:tan="tag:textalign.net,2015:ns"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="#all" version="2.0">
   <!-- This stylesheet helps other stylesheets interrogate the contents of an XSLT stylesheet -->

   <xsl:variable name="component-syntax" select="doc('component%20syntax.xml')"/>

   <xsl:function name="tan:string-representation-of-component" as="xs:string*" visibility="private">
      <!-- 2-param version of the full function, below -->
      <xsl:param name="component-name" as="xs:string*"/>
      <xsl:param name="component-type" as="xs:string?"/>
      <xsl:value-of
         select="tan:string-representation-of-component($component-name, $component-type, false())"
      />
   </xsl:function>

   <xsl:function name="tan:string-representation-of-component" as="xs:string*" visibility="private">
      <!-- Input: the string name of an XSL component, perhaps the string name of an xsl:template mode, the string name of the component type -->
      <!-- Output: a string that renders the name of the component in the appropriate syntax -->
      <!-- Example: ('arg','variable', false) - > '$arg' -->
      <!-- If the component is a template with a set of modes, then  -->
      <xsl:param name="component-name" as="xs:string*"/>
      <xsl:param name="component-type" as="xs:string?"/>
      <xsl:param name="component-name-is-mode" as="xs:boolean"/>
      <xsl:variable name="this-component-type-syntax"
         select="
            $component-syntax/*/*[tokenize(@type, ' ') = $component-type
            and exists(@mode) = $component-name-is-mode]/@syntax"/>
      <xsl:for-each select="$component-name">
         <xsl:value-of select="replace($this-component-type-syntax, 'name', .)"/>
      </xsl:for-each>
   </xsl:function>

   <xsl:function name="tan:regex-for-component" as="xs:string?" visibility="private">
      <!-- Input: strings representing a component name and type; a boolean indicating whether the regular expression sought is for ordinary text (default) or an xpath expression -->
      <!-- Output: the string to be used for a regular expression on that component and name -->
      <!-- If none is found, nothing is returned; by default, the name will be put inside parentheses, to serve as a capturing group -->
      <xsl:param name="component-name" as="xs:string*"/>
      <xsl:param name="component-type" as="xs:string?"/>
      <xsl:param name="regex-is-for-string-and-not-xpath" as="xs:boolean?"/>
      <xsl:variable name="syntax-key"
         select="$component-syntax/*/*[tokenize(@type, ' ') = $component-type]"/>
      <xsl:variable name="syntax-regex"
         select="
            if ($regex-is-for-string-and-not-xpath = false()) then
               $syntax-key/@xpath-matching-pattern
            else
               $syntax-key/@string-matching-pattern"/>
      <xsl:if test="exists($syntax-regex)">
         <xsl:value-of select="replace($syntax-regex, 'name', concat('(', $component-name, ')'))"/>
      </xsl:if>
   </xsl:function>

   <xsl:function name="tan:xslt-dependencies" as="element()*" visibility="private">
      <!-- Input: two strings, representing a name and a type (e.g., function, key, variable, template), a boolean indicating whether the name describes a template mode, and a series of XSLT files to interrogate -->
      <!-- Output: from the XSLT files, those top-level components that depend upon that function, key, variable, or template -->
      <!-- If the type is unknown, nothing will be returned -->
      <xsl:param name="name" as="xs:string?"/>
      <xsl:param name="type" as="xs:string"/>
      <xsl:param name="name-is-mode" as="xs:boolean"/>
      <xsl:param name="xslt-docs" as="document-node()*"/>
      <xsl:variable name="xpath-pattern-to-match"
         select="replace($component-syntax/*/*[tokenize(@type, ' ') = $type]/@xpath-matching-pattern, 'name', $name)"/>
      <xsl:variable name="these-modes" select="tokenize($name, '\s+')"/>
      <xsl:choose>
         <xsl:when test="$type = ('template', 'xsl:template')">
            <xsl:sequence
               select="
                  $xslt-docs/xsl:stylesheet/*[.//(xsl:apply-templates, xsl:call-template)[@name = $name or tokenize(@mode, '\s+') = $these-modes]]"
            />
         </xsl:when>
         <xsl:when test="exists($xpath-pattern-to-match)">
            <xsl:sequence
               select="
                  $xslt-docs/xsl:stylesheet/*[some $i in .//@*
                     satisfies matches($i, $xpath-pattern-to-match)]"
            />
         </xsl:when>

      </xsl:choose>
   </xsl:function>

</xsl:stylesheet>
