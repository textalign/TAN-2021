<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:tan="tag:textalign.net,2015:ns" xmlns="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:tei="http://www.tei-c.org/ns/1.0"
   exclude-result-prefixes="#all" version="3.0">
   <!-- Global parameters pertaining to TAN applications making use of tan:diff() and tan:collate(). 
      This stylesheet is meant to be imported (not included) by other stylesheets, so that the
      parameter values can be changed. -->
   
   <!-- DIFF ALGORITHM SETTINGS -->
   
   <!-- Should tan:diff() output by default be rendered word-for-word (true) or character-for-character? 
      The former produces results that are imprecise but more legible; the latter, precise but sometimes 
      illegible. -->
   <xsl:param name="tan:snap-to-word" as="xs:boolean" select="true()"/>
   
   
   <!-- How many vertical stops should be used in tan:diff()? Large numbers do not penalize performance. Short numbers will
      exhaust loop tolerance on long texts and turn the operation over to the longest common substring program. When this
      parameter is set to 80, and the other parameters are given their default values, the final sample size in the vertical 
      stop will be 9.094947E-13. That's a samples size of one character from a string of length one trillion. -->
   <xsl:param name="tan:diff-vertical-stop-count" as="xs:integer" select="100"/>
   
   <!-- A sequence of doubles, descending from 1.0 to no lower than zero, specifing what portion of the length of the text should 
        be checked, i.e., the sequence of percentages to be checked at each outer loop pass. -->
   <xsl:param name="tan:diff-vertical-stops" select="
         for $i in (1 to $tan:diff-vertical-stop-count)
         return
            math:pow($tan:diff-sample-size-attenuation-base, ($tan:diff-sample-size-attenuation-rate * $i))"/>
   
   <!-- How steeply should sample sizes attenuate? Expected is a decimal between 1.0 and 0.0. The value defines the exponent 
      by which sample sizes diminish. Assuming an attenuation base (see next parameter) of 0.5, the values of this parameter 
      would result in the following sample sizes:
      0.7   62%, 38%, 23%, 14%, ...
      0.5   71%, 50%, 35%, 25%, ... 
      0.3   81%, 66%, 54%, 44%, ... 
      This parameter's value will have no effect if $tan:diff-vertical-stops has been overridden.
   -->
   <xsl:param name="tan:diff-sample-size-attenuation-rate" as="xs:decimal" select="0.5"/>
   
   <!-- Where is the basis or center of the sample size series? Expected is a decimal between 1.0 and 0.0. The value defines
      the base by which sample sizes diminish. As the number gets smaller, the largest sample size also diminishes. 
      Assuming an attenuation rate (see previous parameter) of 0.5, the values of this parameter 
      would result in the following sample sizes:
      0.7   84%, 70%, 59%, 49%, ...
      0.5   71%, 50%, 35%, 25%, ... 
      0.3   55%, 30%, 16%, 9%, ... 
      
      This parameter's value will have no effect if $tan:diff-vertical-stops 
      has been overridden.
   -->
   <xsl:param name="tan:diff-sample-size-attenuation-base" as="xs:decimal" select="0.5"/>
   
   
   <!-- What is the maximum number of horizontal passes to be applied in a given diff? -->
   <xsl:param name="tan:diff-maximum-number-of-horizontal-passes" as="xs:integer" select="50"/>
   
   <!-- At what point in the diminishment of the sample size should the maximum number of horizontal passes be suspended?
      If the sample size is less than or equal to this value, then the algorithm will draw the maximum number of samples 
      that can be taken from the short string. In some cases, setting this to say 3 might slightly improve the quality
      of results in texts that are quite unalike, but at the expense of some extra processing time; and a setting of 3
      will normally not affect the performance of tan:diff() on texts that are rather alike. The parameter should not
      be set much higher than 3, to avoid performance deterioriation, and not to defeat the stagger-sample approach 
      that has been adopted.
   -->
   <xsl:param name="tan:diff-suspend-horizontal-pass-maximum-when-sample-sizes-reach-what" as="xs:integer" select="3"/>
   
   
   <!-- The number of samples will increase from 1 to the maximum. How quickly should it rise? Expected is a positive
      number above 0, with 0.5 being the default, to reach the maximum relatively quickly. This number has 
      exponential power over the complement of the sample size. The higher the number the greater the number
      of samples at the beginning of the vertical stops. 
      Assuming an attenuation rate of 0.5 and attenuation base of 0.5 (see above), and 50 for maximum number of 
      horizontal passes (see above), the values of this parameter would result in the following number of samples
      for each vertical stop (sample size):
      0.7   9, 19, 27, 34, 38, ... 
      0.5   5, 13, 21, 29, 34, ... 
      0.3   1, 5, 12, 20, 27, ... 
      In general, the lower the value, the greater the efficiency, and the more work that is done on a granular
      level, which may be ideal for pairs of texts known to be unalike.
   -->
   <xsl:param name="tan:diff-horizontal-pass-frequency-rate" as="xs:decimal" select="0.5"/>
   
   <!-- Note, tan:diff() runs in logorithmic time, so the larger the strings, the faster the operation per character.
      One does not preprocess the strings to make the algorithm faster; rather, it is done to perhaps improve memory 
      management. -->
   
   <!-- At what point is the shortest string so long that it would be better to pre-process via tokenization? 
      This preprocessing is best when applied to large strings that are rather alike. -->
   <xsl:param name="tan:diff-preprocess-via-tokenization-trigger-point" as="xs:integer" select="30000000"/>
   
   <!-- What is the size of the smallest string permitted before preprocessing the input via segmentation? 
      If both strings are larger than this value, they will be pushed to tan:giant-diff() and cut into segments.
   -->
   <xsl:param name="tan:diff-preprocess-via-segmentation-trigger-point" as="xs:integer" select="20000000"/>
   
   <!-- When segmenting enormous strings to be fed through giant diff, what is the maximum size allowed for any
      input string segment? Be certain to keep this below the segmentation trigger point. -->
   <xsl:param name="tan:diff-max-size-of-giant-string-segments" as="xs:integer"
      select="xs:integer($tan:diff-preprocess-via-segmentation-trigger-point * 0.98)"/>
   
   <!-- What is the minimum number of segments into which a giant string should be chopped when processing a tan:giant-diff()? 
      The lower the number, the better the accuracy. A higher number might yield faster results. -->
   <xsl:param name="tan:diff-min-count-giant-string-segments" as="xs:integer" select="2"/>
   
   
   
</xsl:stylesheet>
