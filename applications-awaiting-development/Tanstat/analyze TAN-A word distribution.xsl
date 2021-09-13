<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="tag:textalign.net,2015:ns"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:tan="tag:textalign.net,2015:ns" exclude-result-prefixes="#all" version="2.0">
    
    <!-- Initial input: any TAN-A file -->
    <!-- Calculated input: the sources, grouped by work, tokenized and merged -->
    <!-- Template: depends on whether requested output is html or docx -->
    <!-- Output: statistics analyzing word count distribution; if a work group has more than one source, the second and subsequent sources will include a comparison with the first source -->

    <xsl:import href="../get%20inclusions/statistic-core.xsl"/>
    
    <xsl:param name="html-preamble" as="element()*">
        <h1 xmlns="http://www.w3.org/1999/xhtml">Analysis of word distribution</h1>
        <div xmlns="http://www.w3.org/1999/xhtml">The tables below show the relative word length of
            each div in multiple versions of the same work. The token (word) counts in the leftmost
            source are the benchmark against which all other sources are compared. The data may be
            used to explore anomalies in alignment, to compare versions of the same work, or to
            analyze explicitation and implicitation across different translations of the same work.
            Note, it is never advisable to draw conclusions from data without understanding
            thoroughly its basis. You are advised to consult the sources, which may have errors or
            anomalies. </div>
        <div xmlns="http://www.w3.org/1999/xhtml">This report has been generated automatically on
            the basis of TAN XML sources, via a TAN-A file supplied as input to an XSLT algorithm
            written by Joel Kalvesmaki.</div>
        <div xmlns="http://www.w3.org/1999/xhtml">For more on the TAN XML format, see <a
                href="http://textalign.net">textalign.net</a></div>
    </xsl:param>
    
</xsl:stylesheet>
