<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:tan="tag:textalign.net,2015:ns"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" version="3.0">
    <!-- Input: a TAN-T fragment with a div with a @_shift-text -->
    <!-- Output: the given div and its appropriate siblings adjusted with new text. -->
    <!-- @_shift text has space-delimited values:
    1. push or pull 
    2. if push: first or last; if pull: next or prev 
    3. char, word, clause, or sentence 
    4. 1 or all -->
    <!-- This process assumes a TAN-T file, and that the rules of non-mixed content in divs holds true -->
    <xsl:include href="../../functions/TAN-function-library.xsl"/>
    
    <xsl:template match="*[*:div[not(*:div)][@_shift-text]]">
        <xsl:variable name="first-child-with-attr-_shift-text" select="*[@_shift-text][1]"/>
        <xsl:variable name="commands" select="tokenize($first-child-with-attr-_shift-text/@_shift-text, ' ')"/>
        <xsl:variable name="this-chop-regex" as="xs:string">
            <xsl:choose>
                <xsl:when test="$commands[3] = 'word'">
                    <xsl:sequence select="$tan:word-end-regex"/>
                </xsl:when>
                <xsl:when test="$commands[3] = 'clause'">
                    <xsl:sequence select="$tan:clause-end-regex"/>
                </xsl:when>
                <xsl:when test="$commands[3] = 'sentence'">
                    <xsl:sequence select="$tan:sentence-end-regex"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="'.'"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="break-when" as="xs:integer"
            select="
                if ($commands[4] castable as xs:integer) then
                    xs:integer($commands[4])
                else if ($commands[2] = ('first', 'prev')) then
                    count($first-child-with-attr-_shift-text/preceding-sibling::*:div)
                    else count($first-child-with-attr-_shift-text/following-sibling::*:div)"
        />
        
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:choose>
                <xsl:when test="$commands[1] eq 'push' and $commands[2] eq 'last'">
                    <xsl:copy-of select="$first-child-with-attr-_shift-text/preceding-sibling::node()"/>
                    <xsl:iterate select="$first-child-with-attr-_shift-text/(self::* | following-sibling::node())">
                        <xsl:param name="iteration" as="xs:integer" select="0"/>
                        <xsl:param name="text-to-prepend" as="xs:string?"/>
                        <xsl:variable name="this-is-leaf-div" select="self::*:div[not(*:div)]"/>
                        <xsl:variable name="this-text-chopped" select="tan:chop-string(., $this-chop-regex)"/>
                        
                        <xsl:choose>
                            <xsl:when test="$this-is-leaf-div and not($iteration gt $break-when)">
                                <xsl:copy>
                                    <xsl:copy-of select="@* except @_shift-text"/>
                                    <!-- Just in case something's been left behind -->
                                    <xsl:copy-of select="comment() | processing-instruction() | *"/>
                                    <xsl:value-of select="$text-to-prepend"/>
                                    <xsl:if test="not($this-chop-regex = '.') and not(matches($text-to-prepend, ' $'))">
                                        <!-- make sure div-end space normalization rules are in place -->
                                        <xsl:value-of select="' '"/>
                                    </xsl:if>
                                    <xsl:value-of select="$this-text-chopped[not(position() eq last())]"/>
                                    <xsl:if test="$iteration eq $break-when">
                                        <xsl:value-of select="$this-text-chopped[last()]"/>
                                    </xsl:if>
                                </xsl:copy>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:copy-of select="."/>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:variable name="next-text-to-prepend"
                            select="
                                if ($this-is-leaf-div) then
                                    $this-text-chopped[last()]
                                else
                                    $text-to-prepend"
                        />
                        <xsl:next-iteration>
                            <xsl:with-param name="iteration"
                                select="
                                    if ($this-is-leaf-div) then
                                        $iteration + 1
                                    else
                                        $iteration"
                            />
                            <xsl:with-param name="text-to-prepend" select="$next-text-to-prepend"/>
                        </xsl:next-iteration>
                    </xsl:iterate>
                </xsl:when>
                <xsl:when test="($commands[1] eq 'pull' and $commands[2] eq 'next')">
                    <xsl:copy-of select="$first-child-with-attr-_shift-text/preceding-sibling::node()"/>
                    <xsl:variable name="items-to-iterate-over" 
                        select="$first-child-with-attr-_shift-text/(self::* | following-sibling::node())"/>
                    <xsl:variable name="reversed-iteration" as="item()*">
                        <xsl:iterate select="reverse($items-to-iterate-over)">
                            <xsl:param name="iteration" as="xs:integer" select="count($items-to-iterate-over/self::*:div) - 1"/>
                            <xsl:param name="text-to-append" as="xs:string?"/>
                            <xsl:variable name="this-is-leaf-div" select="self::*:div[not(*:div)]"/>
                            <xsl:variable name="this-text-chopped" select="tan:chop-string(., $this-chop-regex)"/>
                            
                            <xsl:choose>
                                <xsl:when test="$this-is-leaf-div and ($iteration le $break-when)">
                                    <xsl:copy>
                                        <xsl:copy-of select="@* except @_shift-text"/>
                                        <xsl:copy-of select="comment() | processing-instruction() | *"/>
                                        <xsl:if test="$iteration eq 0">
                                            <xsl:value-of select="$this-text-chopped[1]"/>
                                        </xsl:if>
                                        <xsl:value-of select="$this-text-chopped[position() gt 1]"/>
                                        <xsl:if test="not($this-chop-regex = '.') and not(matches(., ' $'))">
                                            <!-- make sure div-end space normalization rules are in place -->
                                            <xsl:value-of select="' '"/>
                                        </xsl:if>
                                        <xsl:value-of select="$text-to-append"/>
                                    </xsl:copy>
                                </xsl:when>
                                <xsl:otherwise>
                                    <xsl:copy-of select="."/>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:variable name="next-text-to-append"
                                select="
                                    if ($this-is-leaf-div) then
                                        $this-text-chopped[1]
                                    else
                                        $text-to-append"
                            />
                            <xsl:next-iteration>
                                <xsl:with-param name="iteration"
                                    select="
                                        if ($this-is-leaf-div) then
                                            $iteration - 1
                                        else
                                            $iteration"
                                />
                                <xsl:with-param name="text-to-append" select="$next-text-to-append"/>
                            </xsl:next-iteration>
                        </xsl:iterate>
                        
                    </xsl:variable>
                    <xsl:copy-of select="reverse($reversed-iteration)"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:message select="string-join($commands, ' ') || ' is not a recognized construction. Correct construction: `push first/last char/word/clause/sentence 1/all` or `pull prev/next char/word/clause/sentence 1/all`'"></xsl:message>
                    <xsl:copy-of select="node()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>
