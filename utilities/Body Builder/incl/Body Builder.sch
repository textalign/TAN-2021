<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:tan="tag:textalign.net,2015:ns">
   <sch:ns uri="tag:textalign.net,2015:ns" prefix="tan"/>
   <sch:ns uri="http://www.w3.org/1999/XSL/Transform" prefix="xsl"/>
   
   <xsl:param name="output-diagnostics-on" static="yes" select="false()"/>
   <xsl:param name="tan:validation-mode-on" as="xs:boolean" select="false()"/>
   <!--<xsl:import href="../convert%20to%20TAN.xsl"/>-->
   
   <sch:let name="main-text-to-markup-param-name" value="'main-text-to-markup'"/>
   <sch:let name="main-text-to-markup-child-name" value="'markup'"/>
   
   <sch:let name="comments-to-markup-param-name" value="'comments-to-markup'"/>
   <sch:let name="comments-to-markup-child-name" value="$main-text-to-markup-child-name"/>
   
   <sch:pattern>
      <sch:rule context="tan:marker">
         <sch:assert test="exists(tan:where) and exists(tan:div)">A marker must have at least one
            where and at least one div.</sch:assert>
      </sch:rule>
      <sch:rule context="
            xsl:param[@name eq $main-text-to-markup-param-name]">
         <sch:assert test="exists(xsl:*) or exists(*[name(.) eq $main-text-to-markup-child-name])">The parameter
         <sch:value-of select="name(.)"/> must have at least one element <sch:value-of select="$main-text-to-markup-child-name"/>
            or XSLT elements that constructs one or more <sch:value-of select="$main-text-to-markup-child-name"/>.
         </sch:assert>
      </sch:rule>
      <sch:rule context="
            xsl:param[@name eq $main-text-to-markup-param-name]/xsl:*
            | xsl:param[@name eq $comments-to-markup-param-name]/xsl:*">
         <!-- It is fine to use XSLT elements within this parameter, to point to a configuration file. -->
      </sch:rule>
      <sch:rule context="xsl:param[@name eq $main-text-to-markup-param-name]/*">
         <!-- Otherwise, it must be the mandated name. -->
         <sch:assert test="name(.) eq $main-text-to-markup-child-name">The parameter <sch:value-of
               select="$main-text-to-markup-param-name"/> must contain only elements named <sch:value-of
               select="$main-text-to-markup-child-name"/></sch:assert>
      </sch:rule>
      <sch:rule context="xsl:param[@name eq $comments-to-markup-param-name]/*">
         <sch:assert test="name(.) eq $comments-to-markup-child-name">The parameter <sch:value-of
               select="$comments-to-markup-param-name"/> must contain only elements named <sch:value-of
               select="$comments-to-markup-child-name"/></sch:assert>
         <sch:assert test="count(descendant::tan:maintext) eq 1">There must be exactly one element
            named maintext in each <sch:value-of select="name(.)"/> inside the parameter 
            <sch:value-of select="$comments-to-markup-param-name"/>
         </sch:assert>
      </sch:rule>
      
      
      <sch:rule context="tan:where">
         <sch:assert test="matches(@pattern, '\S') or matches(@format, '\S')">A where element must
            have a non-empty @pattern or a non-empty @format (or both).</sch:assert>
      </sch:rule>
      <sch:rule context="tan:div">
         <sch:assert test="exists(@type)">div must have @type, specifying the division type</sch:assert>
      </sch:rule>

   </sch:pattern>
   
</sch:schema>