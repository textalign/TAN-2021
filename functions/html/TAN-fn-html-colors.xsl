<xsl:stylesheet exclude-result-prefixes="#all" 
   xmlns="tag:textalign.net,2015:ns" xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tan="tag:textalign.net,2015:ns" xmlns:tei="http://www.tei-c.org/ns/1.0"
   xmlns:math="http://www.w3.org/2005/xpath-functions/math"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0">

   <!-- TAN Function Library HTML color functions. -->

   <xsl:function name="tan:blend-color-channel-value" as="xs:double?" visibility="public">
      <!-- Input: two integers and a double between zero and 1 -->
      <!-- Output: a double representing a blend between the first two numbers, interpreted as RGB values -->
      <!--kw: html, colors -->
      <xsl:param name="color-a" as="xs:double"/>
      <xsl:param name="color-b" as="xs:double"/>
      <xsl:param name="blend-mid-point" as="xs:double"/>
      <xsl:variable name="color-a-norm" select="$color-a mod 256"/>
      <xsl:variable name="color-b-norm" select="$color-b mod 256"/>
      <xsl:variable name="blend-mid-point-norm"
         select="abs($blend-mid-point) - floor($blend-mid-point)"/>
      <xsl:variable name="pass-1" as="xs:double"
         select="((1 - $blend-mid-point-norm) * math:pow($color-a-norm, 2)) + ($blend-mid-point-norm * math:pow($color-b-norm, 2))"/>
      <xsl:variable name="diagnostics-on" select="false()"/>
      <xsl:if test="$diagnostics-on">
         <xsl:message select="'diagnostics on for tan:blend-color-channel-value()'"/>
         <xsl:message select="'color a norm: ', $color-a-norm"/>
         <xsl:message select="'color b norm: ', $color-b-norm"/>
         <xsl:message select="'blend-mid-point-norm: ', $blend-mid-point-norm"/>
         <xsl:message select="'pass 1: ', $pass-1"/>
      </xsl:if>
      <xsl:value-of select="math:sqrt($pass-1)"/>
   </xsl:function>

   <xsl:function name="tan:blend-alpha-value" as="xs:double?" visibility="public">
      <!-- Input: three doubles between zero and 1 -->
      <!-- Output: the blend of the first two doubles, interpreted as alpha values and the third interpreted as a midpoint -->
      <!--kw: html, colors -->
      <xsl:param name="alpha-a" as="xs:double"/>
      <xsl:param name="alpha-b" as="xs:double"/>
      <xsl:param name="blend-mid-point" as="xs:double"/>
      <xsl:variable name="alpha-a-norm" select="abs($alpha-a) - floor($alpha-a)"/>
      <xsl:variable name="alpha-b-norm" select="abs($alpha-b) - floor($alpha-b)"/>
      <xsl:variable name="blend-mid-point-norm"
         select="abs($blend-mid-point) - floor($blend-mid-point)"/>
      <xsl:value-of
         select="((1 - $blend-mid-point-norm) * $alpha-a-norm) + ($blend-mid-point-norm * $alpha-b-norm)"
      />
   </xsl:function>

   <xsl:function name="tan:blend-colors" as="xs:double*" visibility="public">
      <!-- Input: two sequences of doubles (the first three items being from 0 through 255 and the fourth and last between 0 and 1); a double between zero and 1 -->
      <!-- Output: a sequence of doubles representing a blend of the first two sequences, interpreted as RGB colors, and the last double as a desired midpoint -->
      <!--kw: html, colors -->
      <xsl:param name="rgb-color-1" as="item()+"/>
      <xsl:param name="rgb-color-2" as="item()+"/>
      <xsl:param name="blend-mid-point" as="xs:double"/>
      <xsl:variable name="blend-mid-point-norm"
         select="abs($blend-mid-point) - floor($blend-mid-point)"/>
      <xsl:choose>
         <xsl:when test="
               not(every $i in $rgb-color-1
                  satisfies $i castable as xs:double)">
            <xsl:message
               select="'Every item in $rgb-color-1 must be a double or castable as a double'"/>
         </xsl:when>
         <xsl:when test="
               not(every $i in $rgb-color-2
                  satisfies $i castable as xs:double)">
            <xsl:message
               select="'Every item in $rgb-color-2 must be a double or castable as a double'"/>
         </xsl:when>
         <xsl:when
            test="(count($rgb-color-1) lt 3) or (count($rgb-color-1) gt 4) or (count($rgb-color-2) lt 3) or (count($rgb-color-2) gt 4)">
            <xsl:message
               select="'tan:blend-colors() expects as the first two parameters a sequence of three or four doubles'"
            />
         </xsl:when>
         <xsl:otherwise>
            <xsl:variable name="diagnostics-on" select="false()"/>
            <xsl:if test="$diagnostics-on">
               <xsl:message select="'diagnostics on for tan:blend-colors()'"/>
            </xsl:if>
            <xsl:for-each select="1 to 3">
               <xsl:variable name="this-pos" select="."/>
               <xsl:variable name="channel-1" select="xs:double($rgb-color-1[$this-pos])"/>
               <xsl:variable name="channel-2" select="xs:double($rgb-color-2[$this-pos])"/>
               
               <xsl:if test="$diagnostics-on">
                  <xsl:message select="'this channel number: ', $this-pos"/>
                  <xsl:message select="'channel 1 item: ', $rgb-color-1[$this-pos]"/>
                  <xsl:message select="'channel 1 as double: ', $channel-1"/>
                  <xsl:message select="'channel 2 item: ', $rgb-color-2[$this-pos]"/>
                  <xsl:message select="'channel 2 as double: ', $channel-2"/>
               </xsl:if>
               
               <xsl:value-of
                  select="tan:blend-color-channel-value($channel-1, $channel-2, $blend-mid-point-norm)"
               />
            </xsl:for-each>
            <xsl:choose>
               <xsl:when test="not(exists($rgb-color-1[4])) and not(exists($rgb-color-2[4]))"/>
               <xsl:when test="not(exists($rgb-color-1[4]))">
                  <xsl:value-of select="xs:double($rgb-color-2[4])"/>
               </xsl:when>
               <xsl:when test="not(exists($rgb-color-2[4]))">
                  <xsl:value-of select="xs:double($rgb-color-1[4])"/>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:value-of
                     select="tan:blend-alpha-value(xs:double($rgb-color-1[4]), xs:double($rgb-color-2[4]), $blend-mid-point-norm)"
                  />
               </xsl:otherwise>
            </xsl:choose>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:function>
   
   
   
   <!-- Color values -->
   <xsl:variable name="tan:rgb-snow" select="(255, 250, 250)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-ghost-white" select="(248, 248, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-GhostWhite" select="(248, 248, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-white-smoke" select="(245, 245, 245)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-WhiteSmoke" select="(245, 245, 245)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gainsboro" select="(220, 220, 220)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-floral-white" select="(255, 250, 240)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-FloralWhite" select="(255, 250, 240)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-old-lace" select="(253, 245, 230)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-OldLace" select="(253, 245, 230)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-linen" select="(250, 240, 230)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-antique-white" select="(250, 235, 215)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-AntiqueWhite" select="(250, 235, 215)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-papaya-whip" select="(255, 239, 213)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-PapayaWhip" select="(255, 239, 213)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-blanched-almond" select="(255, 235, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-BlanchedAlmond" select="(255, 235, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-bisque" select="(255, 228, 196)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-peach-puff" select="(255, 218, 185)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-PeachPuff" select="(255, 218, 185)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-navajo-white" select="(255, 222, 173)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-NavajoWhite" select="(255, 222, 173)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-moccasin" select="(255, 228, 181)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-cornsilk" select="(255, 248, 220)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-ivory" select="(255, 255, 240)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-lemon-chiffon" select="(255, 250, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LemonChiffon" select="(255, 250, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-seashell" select="(255, 245, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-honeydew" select="(240, 255, 240)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-mint-cream" select="(245, 255, 250)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-MintCream" select="(245, 255, 250)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-azure" select="(240, 255, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-alice-blue" select="(240, 248, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-AliceBlue" select="(240, 248, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-lavender" select="(230, 230, 250)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-lavender-blush" select="(255, 240, 245)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LavenderBlush" select="(255, 240, 245)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-misty-rose" select="(255, 228, 225)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-MistyRose" select="(255, 228, 225)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-white" select="(255, 255, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-black" select="(0, 0, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-dark-slate-gray" select="(47, 79, 79)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkSlateGray" select="(47, 79, 79)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-dark-slate-grey" select="(47, 79, 79)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkSlateGrey" select="(47, 79, 79)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-dim-gray" select="(105, 105, 105)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DimGray" select="(105, 105, 105)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-dim-grey" select="(105, 105, 105)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DimGrey" select="(105, 105, 105)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-slate-gray" select="(112, 128, 144)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SlateGray" select="(112, 128, 144)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-slate-grey" select="(112, 128, 144)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SlateGrey" select="(112, 128, 144)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-light-slate-gray" select="(119, 136, 153)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightSlateGray" select="(119, 136, 153)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-light-slate-grey" select="(119, 136, 153)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightSlateGrey" select="(119, 136, 153)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray" select="(190, 190, 190)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey" select="(190, 190, 190)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-light-grey" select="(211, 211, 211)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightGrey" select="(211, 211, 211)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-light-gray" select="(211, 211, 211)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightGray" select="(211, 211, 211)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-midnight-blue" select="(25, 25, 112)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-MidnightBlue" select="(25, 25, 112)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-navy" select="(0, 0, 128)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-navy-blue" select="(0, 0, 128)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-NavyBlue" select="(0, 0, 128)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-cornflower-blue" select="(100, 149, 237)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-CornflowerBlue" select="(100, 149, 237)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-dark-slate-blue" select="(72, 61, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkSlateBlue" select="(72, 61, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-slate-blue" select="(106, 90, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SlateBlue" select="(106, 90, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-medium-slate-blue" select="(123, 104, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-MediumSlateBlue" select="(123, 104, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-light-slate-blue" select="(132, 112, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightSlateBlue" select="(132, 112, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-medium-blue" select="(0, 0, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-MediumBlue" select="(0, 0, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-royal-blue" select="(65, 105, 225)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-RoyalBlue" select="(65, 105, 225)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-blue" select="(0, 0, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-dodger-blue" select="(30, 144, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DodgerBlue" select="(30, 144, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-deep-sky-blue" select="(0, 191, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DeepSkyBlue" select="(0, 191, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-sky-blue" select="(135, 206, 235)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SkyBlue" select="(135, 206, 235)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-light-sky-blue" select="(135, 206, 250)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightSkyBlue" select="(135, 206, 250)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-steel-blue" select="(70, 130, 180)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SteelBlue" select="(70, 130, 180)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-light-steel-blue" select="(176, 196, 222)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightSteelBlue" select="(176, 196, 222)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-light-blue" select="(173, 216, 230)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightBlue" select="(173, 216, 230)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-powder-blue" select="(176, 224, 230)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-PowderBlue" select="(176, 224, 230)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-pale-turquoise" select="(175, 238, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-PaleTurquoise" select="(175, 238, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-dark-turquoise" select="(0, 206, 209)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkTurquoise" select="(0, 206, 209)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-medium-turquoise" select="(72, 209, 204)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-MediumTurquoise" select="(72, 209, 204)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-turquoise" select="(64, 224, 208)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-cyan" select="(0, 255, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-light-cyan" select="(224, 255, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightCyan" select="(224, 255, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-cadet-blue" select="(95, 158, 160)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-CadetBlue" select="(95, 158, 160)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-medium-aquamarine" select="(102, 205, 170)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-MediumAquamarine" select="(102, 205, 170)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-aquamarine" select="(127, 255, 212)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-dark-green" select="(0, 100, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkGreen" select="(0, 100, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-dark-olive-green" select="(85, 107, 47)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkOliveGreen" select="(85, 107, 47)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-dark-sea-green" select="(143, 188, 143)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkSeaGreen" select="(143, 188, 143)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-sea-green" select="(46, 139, 87)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SeaGreen" select="(46, 139, 87)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-medium-sea-green" select="(60, 179, 113)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-MediumSeaGreen" select="(60, 179, 113)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-light-sea-green" select="(32, 178, 170)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightSeaGreen" select="(32, 178, 170)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-pale-green" select="(152, 251, 152)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-PaleGreen" select="(152, 251, 152)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-spring-green" select="(0, 255, 127)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SpringGreen" select="(0, 255, 127)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-lawn-green" select="(124, 252, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LawnGreen" select="(124, 252, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-green" select="(0, 255, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-chartreuse" select="(127, 255, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-medium-spring-green" select="(0, 250, 154)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-MediumSpringGreen" select="(0, 250, 154)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-green-yellow" select="(173, 255, 47)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-GreenYellow" select="(173, 255, 47)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-lime-green" select="(50, 205, 50)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LimeGreen" select="(50, 205, 50)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-yellow-green" select="(154, 205, 50)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-YellowGreen" select="(154, 205, 50)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-forest-green" select="(34, 139, 34)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-ForestGreen" select="(34, 139, 34)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-olive-drab" select="(107, 142, 35)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-OliveDrab" select="(107, 142, 35)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-dark-khaki" select="(189, 183, 107)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkKhaki" select="(189, 183, 107)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-khaki" select="(240, 230, 140)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-pale-goldenrod" select="(238, 232, 170)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-PaleGoldenrod" select="(238, 232, 170)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-light-goldenrod-yellow" select="(250, 250, 210)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightGoldenrodYellow" select="(250, 250, 210)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-light-yellow" select="(255, 255, 224)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightYellow" select="(255, 255, 224)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-yellow" select="(255, 255, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gold" select="(255, 215, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-light-goldenrod" select="(238, 221, 130)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightGoldenrod" select="(238, 221, 130)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-goldenrod" select="(218, 165, 32)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-dark-goldenrod" select="(184, 134, 11)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkGoldenrod" select="(184, 134, 11)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-rosy-brown" select="(188, 143, 143)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-RosyBrown" select="(188, 143, 143)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-indian-red" select="(205, 92, 92)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-IndianRed" select="(205, 92, 92)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-saddle-brown" select="(139, 69, 19)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SaddleBrown" select="(139, 69, 19)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-sienna" select="(160, 82, 45)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-peru" select="(205, 133, 63)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-burlywood" select="(222, 184, 135)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-beige" select="(245, 245, 220)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-wheat" select="(245, 222, 179)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-sandy-brown" select="(244, 164, 96)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SandyBrown" select="(244, 164, 96)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-tan" select="(210, 180, 140)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-chocolate" select="(210, 105, 30)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-firebrick" select="(178, 34, 34)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-brown" select="(165, 42, 42)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-dark-salmon" select="(233, 150, 122)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkSalmon" select="(233, 150, 122)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-salmon" select="(250, 128, 114)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-light-salmon" select="(255, 160, 122)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightSalmon" select="(255, 160, 122)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-orange" select="(255, 165, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-dark-orange" select="(255, 140, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkOrange" select="(255, 140, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-coral" select="(255, 127, 80)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-light-coral" select="(240, 128, 128)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightCoral" select="(240, 128, 128)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-tomato" select="(255, 99, 71)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-orange-red" select="(255, 69, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-OrangeRed" select="(255, 69, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-red" select="(255, 0, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-hot-pink" select="(255, 105, 180)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-HotPink" select="(255, 105, 180)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-deep-pink" select="(255, 20, 147)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DeepPink" select="(255, 20, 147)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-pink" select="(255, 192, 203)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-light-pink" select="(255, 182, 193)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightPink" select="(255, 182, 193)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-pale-violet-red" select="(219, 112, 147)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-PaleVioletRed" select="(219, 112, 147)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-maroon" select="(176, 48, 96)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-medium-violet-red" select="(199, 21, 133)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-MediumVioletRed" select="(199, 21, 133)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-violet-red" select="(208, 32, 144)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-VioletRed" select="(208, 32, 144)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-magenta" select="(255, 0, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-violet" select="(238, 130, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-plum" select="(221, 160, 221)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-orchid" select="(218, 112, 214)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-medium-orchid" select="(186, 85, 211)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-MediumOrchid" select="(186, 85, 211)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-dark-orchid" select="(153, 50, 204)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkOrchid" select="(153, 50, 204)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-dark-violet" select="(148, 0, 211)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkViolet" select="(148, 0, 211)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-blue-violet" select="(138, 43, 226)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-BlueViolet" select="(138, 43, 226)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-purple" select="(160, 32, 240)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-medium-purple" select="(147, 112, 219)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-MediumPurple" select="(147, 112, 219)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-thistle" select="(216, 191, 216)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-snow1" select="(255, 250, 250)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-snow2" select="(238, 233, 233)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-snow3" select="(205, 201, 201)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-snow4" select="(139, 137, 137)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-seashell1" select="(255, 245, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-seashell2" select="(238, 229, 222)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-seashell3" select="(205, 197, 191)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-seashell4" select="(139, 134, 130)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-AntiqueWhite1" select="(255, 239, 219)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-AntiqueWhite2" select="(238, 223, 204)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-AntiqueWhite3" select="(205, 192, 176)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-AntiqueWhite4" select="(139, 131, 120)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-bisque1" select="(255, 228, 196)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-bisque2" select="(238, 213, 183)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-bisque3" select="(205, 183, 158)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-bisque4" select="(139, 125, 107)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-PeachPuff1" select="(255, 218, 185)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-PeachPuff2" select="(238, 203, 173)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-PeachPuff3" select="(205, 175, 149)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-PeachPuff4" select="(139, 119, 101)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-NavajoWhite1" select="(255, 222, 173)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-NavajoWhite2" select="(238, 207, 161)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-NavajoWhite3" select="(205, 179, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-NavajoWhite4" select="(139, 121, 94)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LemonChiffon1" select="(255, 250, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LemonChiffon2" select="(238, 233, 191)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LemonChiffon3" select="(205, 201, 165)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LemonChiffon4" select="(139, 137, 112)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-cornsilk1" select="(255, 248, 220)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-cornsilk2" select="(238, 232, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-cornsilk3" select="(205, 200, 177)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-cornsilk4" select="(139, 136, 120)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-ivory1" select="(255, 255, 240)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-ivory2" select="(238, 238, 224)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-ivory3" select="(205, 205, 193)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-ivory4" select="(139, 139, 131)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-honeydew1" select="(240, 255, 240)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-honeydew2" select="(224, 238, 224)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-honeydew3" select="(193, 205, 193)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-honeydew4" select="(131, 139, 131)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LavenderBlush1" select="(255, 240, 245)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LavenderBlush2" select="(238, 224, 229)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LavenderBlush3" select="(205, 193, 197)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LavenderBlush4" select="(139, 131, 134)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-MistyRose1" select="(255, 228, 225)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-MistyRose2" select="(238, 213, 210)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-MistyRose3" select="(205, 183, 181)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-MistyRose4" select="(139, 125, 123)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-azure1" select="(240, 255, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-azure2" select="(224, 238, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-azure3" select="(193, 205, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-azure4" select="(131, 139, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SlateBlue1" select="(131, 111, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SlateBlue2" select="(122, 103, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SlateBlue3" select="(105, 89, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SlateBlue4" select="(71, 60, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-RoyalBlue1" select="(72, 118, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-RoyalBlue2" select="(67, 110, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-RoyalBlue3" select="(58, 95, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-RoyalBlue4" select="(39, 64, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-blue1" select="(0, 0, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-blue2" select="(0, 0, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-blue3" select="(0, 0, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-blue4" select="(0, 0, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DodgerBlue1" select="(30, 144, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DodgerBlue2" select="(28, 134, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DodgerBlue3" select="(24, 116, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DodgerBlue4" select="(16, 78, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SteelBlue1" select="(99, 184, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SteelBlue2" select="(92, 172, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SteelBlue3" select="(79, 148, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SteelBlue4" select="(54, 100, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DeepSkyBlue1" select="(0, 191, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DeepSkyBlue2" select="(0, 178, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DeepSkyBlue3" select="(0, 154, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DeepSkyBlue4" select="(0, 104, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SkyBlue1" select="(135, 206, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SkyBlue2" select="(126, 192, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SkyBlue3" select="(108, 166, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SkyBlue4" select="(74, 112, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightSkyBlue1" select="(176, 226, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightSkyBlue2" select="(164, 211, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightSkyBlue3" select="(141, 182, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightSkyBlue4" select="(96, 123, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SlateGray1" select="(198, 226, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SlateGray2" select="(185, 211, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SlateGray3" select="(159, 182, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SlateGray4" select="(108, 123, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightSteelBlue1" select="(202, 225, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightSteelBlue2" select="(188, 210, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightSteelBlue3" select="(162, 181, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightSteelBlue4" select="(110, 123, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightBlue1" select="(191, 239, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightBlue2" select="(178, 223, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightBlue3" select="(154, 192, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightBlue4" select="(104, 131, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightCyan1" select="(224, 255, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightCyan2" select="(209, 238, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightCyan3" select="(180, 205, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightCyan4" select="(122, 139, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-PaleTurquoise1" select="(187, 255, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-PaleTurquoise2" select="(174, 238, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-PaleTurquoise3" select="(150, 205, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-PaleTurquoise4" select="(102, 139, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-CadetBlue1" select="(152, 245, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-CadetBlue2" select="(142, 229, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-CadetBlue3" select="(122, 197, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-CadetBlue4" select="(83, 134, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-turquoise1" select="(0, 245, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-turquoise2" select="(0, 229, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-turquoise3" select="(0, 197, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-turquoise4" select="(0, 134, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-cyan1" select="(0, 255, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-cyan2" select="(0, 238, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-cyan3" select="(0, 205, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-cyan4" select="(0, 139, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkSlateGray1" select="(151, 255, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkSlateGray2" select="(141, 238, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkSlateGray3" select="(121, 205, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkSlateGray4" select="(82, 139, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-aquamarine1" select="(127, 255, 212)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-aquamarine2" select="(118, 238, 198)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-aquamarine3" select="(102, 205, 170)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-aquamarine4" select="(69, 139, 116)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkSeaGreen1" select="(193, 255, 193)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkSeaGreen2" select="(180, 238, 180)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkSeaGreen3" select="(155, 205, 155)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkSeaGreen4" select="(105, 139, 105)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SeaGreen1" select="(84, 255, 159)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SeaGreen2" select="(78, 238, 148)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SeaGreen3" select="(67, 205, 128)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SeaGreen4" select="(46, 139, 87)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-PaleGreen1" select="(154, 255, 154)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-PaleGreen2" select="(144, 238, 144)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-PaleGreen3" select="(124, 205, 124)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-PaleGreen4" select="(84, 139, 84)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SpringGreen1" select="(0, 255, 127)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SpringGreen2" select="(0, 238, 118)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SpringGreen3" select="(0, 205, 102)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-SpringGreen4" select="(0, 139, 69)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-green1" select="(0, 255, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-green2" select="(0, 238, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-green3" select="(0, 205, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-green4" select="(0, 139, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-chartreuse1" select="(127, 255, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-chartreuse2" select="(118, 238, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-chartreuse3" select="(102, 205, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-chartreuse4" select="(69, 139, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-OliveDrab1" select="(192, 255, 62)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-OliveDrab2" select="(179, 238, 58)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-OliveDrab3" select="(154, 205, 50)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-OliveDrab4" select="(105, 139, 34)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkOliveGreen1" select="(202, 255, 112)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkOliveGreen2" select="(188, 238, 104)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkOliveGreen3" select="(162, 205, 90)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkOliveGreen4" select="(110, 139, 61)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-khaki1" select="(255, 246, 143)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-khaki2" select="(238, 230, 133)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-khaki3" select="(205, 198, 115)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-khaki4" select="(139, 134, 78)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightGoldenrod1" select="(255, 236, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightGoldenrod2" select="(238, 220, 130)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightGoldenrod3" select="(205, 190, 112)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightGoldenrod4" select="(139, 129, 76)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightYellow1" select="(255, 255, 224)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightYellow2" select="(238, 238, 209)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightYellow3" select="(205, 205, 180)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightYellow4" select="(139, 139, 122)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-yellow1" select="(255, 255, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-yellow2" select="(238, 238, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-yellow3" select="(205, 205, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-yellow4" select="(139, 139, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gold1" select="(255, 215, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gold2" select="(238, 201, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gold3" select="(205, 173, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gold4" select="(139, 117, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-goldenrod1" select="(255, 193, 37)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-goldenrod2" select="(238, 180, 34)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-goldenrod3" select="(205, 155, 29)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-goldenrod4" select="(139, 105, 20)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkGoldenrod1" select="(255, 185, 15)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkGoldenrod2" select="(238, 173, 14)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkGoldenrod3" select="(205, 149, 12)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkGoldenrod4" select="(139, 101, 8)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-RosyBrown1" select="(255, 193, 193)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-RosyBrown2" select="(238, 180, 180)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-RosyBrown3" select="(205, 155, 155)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-RosyBrown4" select="(139, 105, 105)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-IndianRed1" select="(255, 106, 106)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-IndianRed2" select="(238, 99, 99)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-IndianRed3" select="(205, 85, 85)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-IndianRed4" select="(139, 58, 58)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-sienna1" select="(255, 130, 71)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-sienna2" select="(238, 121, 66)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-sienna3" select="(205, 104, 57)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-sienna4" select="(139, 71, 38)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-burlywood1" select="(255, 211, 155)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-burlywood2" select="(238, 197, 145)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-burlywood3" select="(205, 170, 125)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-burlywood4" select="(139, 115, 85)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-wheat1" select="(255, 231, 186)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-wheat2" select="(238, 216, 174)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-wheat3" select="(205, 186, 150)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-wheat4" select="(139, 126, 102)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-tan1" select="(255, 165, 79)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-tan2" select="(238, 154, 73)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-tan3" select="(205, 133, 63)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-tan4" select="(139, 90, 43)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-chocolate1" select="(255, 127, 36)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-chocolate2" select="(238, 118, 33)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-chocolate3" select="(205, 102, 29)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-chocolate4" select="(139, 69, 19)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-firebrick1" select="(255, 48, 48)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-firebrick2" select="(238, 44, 44)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-firebrick3" select="(205, 38, 38)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-firebrick4" select="(139, 26, 26)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-brown1" select="(255, 64, 64)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-brown2" select="(238, 59, 59)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-brown3" select="(205, 51, 51)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-brown4" select="(139, 35, 35)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-salmon1" select="(255, 140, 105)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-salmon2" select="(238, 130, 98)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-salmon3" select="(205, 112, 84)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-salmon4" select="(139, 76, 57)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightSalmon1" select="(255, 160, 122)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightSalmon2" select="(238, 149, 114)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightSalmon3" select="(205, 129, 98)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightSalmon4" select="(139, 87, 66)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-orange1" select="(255, 165, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-orange2" select="(238, 154, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-orange3" select="(205, 133, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-orange4" select="(139, 90, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkOrange1" select="(255, 127, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkOrange2" select="(238, 118, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkOrange3" select="(205, 102, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkOrange4" select="(139, 69, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-coral1" select="(255, 114, 86)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-coral2" select="(238, 106, 80)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-coral3" select="(205, 91, 69)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-coral4" select="(139, 62, 47)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-tomato1" select="(255, 99, 71)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-tomato2" select="(238, 92, 66)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-tomato3" select="(205, 79, 57)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-tomato4" select="(139, 54, 38)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-OrangeRed1" select="(255, 69, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-OrangeRed2" select="(238, 64, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-OrangeRed3" select="(205, 55, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-OrangeRed4" select="(139, 37, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-red1" select="(255, 0, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-red2" select="(238, 0, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-red3" select="(205, 0, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-red4" select="(139, 0, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DeepPink1" select="(255, 20, 147)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DeepPink2" select="(238, 18, 137)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DeepPink3" select="(205, 16, 118)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DeepPink4" select="(139, 10, 80)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-HotPink1" select="(255, 110, 180)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-HotPink2" select="(238, 106, 167)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-HotPink3" select="(205, 96, 144)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-HotPink4" select="(139, 58, 98)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-pink1" select="(255, 181, 197)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-pink2" select="(238, 169, 184)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-pink3" select="(205, 145, 158)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-pink4" select="(139, 99, 108)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightPink1" select="(255, 174, 185)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightPink2" select="(238, 162, 173)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightPink3" select="(205, 140, 149)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightPink4" select="(139, 95, 101)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-PaleVioletRed1" select="(255, 130, 171)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-PaleVioletRed2" select="(238, 121, 159)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-PaleVioletRed3" select="(205, 104, 137)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-PaleVioletRed4" select="(139, 71, 93)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-maroon1" select="(255, 52, 179)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-maroon2" select="(238, 48, 167)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-maroon3" select="(205, 41, 144)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-maroon4" select="(139, 28, 98)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-VioletRed1" select="(255, 62, 150)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-VioletRed2" select="(238, 58, 140)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-VioletRed3" select="(205, 50, 120)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-VioletRed4" select="(139, 34, 82)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-magenta1" select="(255, 0, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-magenta2" select="(238, 0, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-magenta3" select="(205, 0, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-magenta4" select="(139, 0, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-orchid1" select="(255, 131, 250)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-orchid2" select="(238, 122, 233)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-orchid3" select="(205, 105, 201)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-orchid4" select="(139, 71, 137)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-plum1" select="(255, 187, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-plum2" select="(238, 174, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-plum3" select="(205, 150, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-plum4" select="(139, 102, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-MediumOrchid1" select="(224, 102, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-MediumOrchid2" select="(209, 95, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-MediumOrchid3" select="(180, 82, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-MediumOrchid4" select="(122, 55, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkOrchid1" select="(191, 62, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkOrchid2" select="(178, 58, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkOrchid3" select="(154, 50, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkOrchid4" select="(104, 34, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-purple1" select="(155, 48, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-purple2" select="(145, 44, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-purple3" select="(125, 38, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-purple4" select="(85, 26, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-MediumPurple1" select="(171, 130, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-MediumPurple2" select="(159, 121, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-MediumPurple3" select="(137, 104, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-MediumPurple4" select="(93, 71, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-thistle1" select="(255, 225, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-thistle2" select="(238, 210, 238)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-thistle3" select="(205, 181, 205)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-thistle4" select="(139, 123, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray0" select="(0, 0, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey0" select="(0, 0, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray1" select="(3, 3, 3)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey1" select="(3, 3, 3)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray2" select="(5, 5, 5)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey2" select="(5, 5, 5)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray3" select="(8, 8, 8)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey3" select="(8, 8, 8)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray4" select="(10, 10, 10)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey4" select="(10, 10, 10)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray5" select="(13, 13, 13)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey5" select="(13, 13, 13)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray6" select="(15, 15, 15)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey6" select="(15, 15, 15)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray7" select="(18, 18, 18)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey7" select="(18, 18, 18)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray8" select="(20, 20, 20)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey8" select="(20, 20, 20)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray9" select="(23, 23, 23)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey9" select="(23, 23, 23)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray10" select="(26, 26, 26)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey10" select="(26, 26, 26)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray11" select="(28, 28, 28)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey11" select="(28, 28, 28)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray12" select="(31, 31, 31)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey12" select="(31, 31, 31)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray13" select="(33, 33, 33)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey13" select="(33, 33, 33)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray14" select="(36, 36, 36)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey14" select="(36, 36, 36)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray15" select="(38, 38, 38)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey15" select="(38, 38, 38)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray16" select="(41, 41, 41)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey16" select="(41, 41, 41)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray17" select="(43, 43, 43)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey17" select="(43, 43, 43)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray18" select="(46, 46, 46)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey18" select="(46, 46, 46)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray19" select="(48, 48, 48)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey19" select="(48, 48, 48)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray20" select="(51, 51, 51)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey20" select="(51, 51, 51)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray21" select="(54, 54, 54)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey21" select="(54, 54, 54)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray22" select="(56, 56, 56)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey22" select="(56, 56, 56)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray23" select="(59, 59, 59)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey23" select="(59, 59, 59)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray24" select="(61, 61, 61)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey24" select="(61, 61, 61)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray25" select="(64, 64, 64)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey25" select="(64, 64, 64)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray26" select="(66, 66, 66)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey26" select="(66, 66, 66)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray27" select="(69, 69, 69)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey27" select="(69, 69, 69)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray28" select="(71, 71, 71)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey28" select="(71, 71, 71)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray29" select="(74, 74, 74)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey29" select="(74, 74, 74)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray30" select="(77, 77, 77)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey30" select="(77, 77, 77)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray31" select="(79, 79, 79)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey31" select="(79, 79, 79)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray32" select="(82, 82, 82)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey32" select="(82, 82, 82)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray33" select="(84, 84, 84)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey33" select="(84, 84, 84)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray34" select="(87, 87, 87)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey34" select="(87, 87, 87)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray35" select="(89, 89, 89)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey35" select="(89, 89, 89)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray36" select="(92, 92, 92)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey36" select="(92, 92, 92)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray37" select="(94, 94, 94)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey37" select="(94, 94, 94)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray38" select="(97, 97, 97)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey38" select="(97, 97, 97)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray39" select="(99, 99, 99)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey39" select="(99, 99, 99)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray40" select="(102, 102, 102)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey40" select="(102, 102, 102)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray41" select="(105, 105, 105)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey41" select="(105, 105, 105)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray42" select="(107, 107, 107)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey42" select="(107, 107, 107)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray43" select="(110, 110, 110)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey43" select="(110, 110, 110)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray44" select="(112, 112, 112)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey44" select="(112, 112, 112)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray45" select="(115, 115, 115)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey45" select="(115, 115, 115)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray46" select="(117, 117, 117)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey46" select="(117, 117, 117)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray47" select="(120, 120, 120)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey47" select="(120, 120, 120)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray48" select="(122, 122, 122)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey48" select="(122, 122, 122)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray49" select="(125, 125, 125)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey49" select="(125, 125, 125)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray50" select="(127, 127, 127)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey50" select="(127, 127, 127)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray51" select="(130, 130, 130)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey51" select="(130, 130, 130)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray52" select="(133, 133, 133)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey52" select="(133, 133, 133)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray53" select="(135, 135, 135)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey53" select="(135, 135, 135)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray54" select="(138, 138, 138)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey54" select="(138, 138, 138)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray55" select="(140, 140, 140)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey55" select="(140, 140, 140)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray56" select="(143, 143, 143)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey56" select="(143, 143, 143)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray57" select="(145, 145, 145)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey57" select="(145, 145, 145)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray58" select="(148, 148, 148)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey58" select="(148, 148, 148)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray59" select="(150, 150, 150)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey59" select="(150, 150, 150)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray60" select="(153, 153, 153)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey60" select="(153, 153, 153)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray61" select="(156, 156, 156)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey61" select="(156, 156, 156)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray62" select="(158, 158, 158)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey62" select="(158, 158, 158)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray63" select="(161, 161, 161)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey63" select="(161, 161, 161)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray64" select="(163, 163, 163)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey64" select="(163, 163, 163)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray65" select="(166, 166, 166)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey65" select="(166, 166, 166)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray66" select="(168, 168, 168)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey66" select="(168, 168, 168)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray67" select="(171, 171, 171)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey67" select="(171, 171, 171)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray68" select="(173, 173, 173)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey68" select="(173, 173, 173)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray69" select="(176, 176, 176)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey69" select="(176, 176, 176)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray70" select="(179, 179, 179)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey70" select="(179, 179, 179)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray71" select="(181, 181, 181)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey71" select="(181, 181, 181)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray72" select="(184, 184, 184)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey72" select="(184, 184, 184)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray73" select="(186, 186, 186)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey73" select="(186, 186, 186)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray74" select="(189, 189, 189)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey74" select="(189, 189, 189)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray75" select="(191, 191, 191)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey75" select="(191, 191, 191)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray76" select="(194, 194, 194)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey76" select="(194, 194, 194)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray77" select="(196, 196, 196)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey77" select="(196, 196, 196)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray78" select="(199, 199, 199)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey78" select="(199, 199, 199)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray79" select="(201, 201, 201)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey79" select="(201, 201, 201)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray80" select="(204, 204, 204)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey80" select="(204, 204, 204)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray81" select="(207, 207, 207)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey81" select="(207, 207, 207)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray82" select="(209, 209, 209)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey82" select="(209, 209, 209)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray83" select="(212, 212, 212)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey83" select="(212, 212, 212)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray84" select="(214, 214, 214)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey84" select="(214, 214, 214)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray85" select="(217, 217, 217)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey85" select="(217, 217, 217)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray86" select="(219, 219, 219)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey86" select="(219, 219, 219)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray87" select="(222, 222, 222)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey87" select="(222, 222, 222)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray88" select="(224, 224, 224)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey88" select="(224, 224, 224)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray89" select="(227, 227, 227)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey89" select="(227, 227, 227)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray90" select="(229, 229, 229)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey90" select="(229, 229, 229)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray91" select="(232, 232, 232)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey91" select="(232, 232, 232)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray92" select="(235, 235, 235)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey92" select="(235, 235, 235)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray93" select="(237, 237, 237)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey93" select="(237, 237, 237)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray94" select="(240, 240, 240)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey94" select="(240, 240, 240)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray95" select="(242, 242, 242)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey95" select="(242, 242, 242)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray96" select="(245, 245, 245)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey96" select="(245, 245, 245)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray97" select="(247, 247, 247)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey97" select="(247, 247, 247)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray98" select="(250, 250, 250)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey98" select="(250, 250, 250)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray99" select="(252, 252, 252)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey99" select="(252, 252, 252)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-gray100" select="(255, 255, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-grey100" select="(255, 255, 255)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-dark-grey" select="(169, 169, 169)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkGrey" select="(169, 169, 169)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-dark-gray" select="(169, 169, 169)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkGray" select="(169, 169, 169)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-dark-blue" select="(0, 0, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkBlue" select="(0, 0, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-dark-cyan" select="(0, 139, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkCyan" select="(0, 139, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-dark-magenta" select="(139, 0, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkMagenta" select="(139, 0, 139)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-dark-red" select="(139, 0, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-DarkRed" select="(139, 0, 0)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-light-green" select="(144, 238, 144)" as="xs:integer+"/>
   <xsl:variable name="tan:rgb-LightGreen" select="(144, 238, 144)" as="xs:integer+"/>
   <!-- The twelve colors below are for the red-yellow-blue circle, whose primary, secondary, tertiary, and blends tend to produced more pleasing color combinations -->
   <xsl:variable name="tan:ryb-red" select="(254, 39, 18)" as="xs:integer+"/>
   <xsl:variable name="tan:ryb-yellow" select="(254, 254, 51)" as="xs:integer+"/>
   <xsl:variable name="tan:ryb-blue" select="(2, 71, 254)" as="xs:integer+"/>
   <xsl:variable name="tan:ryb-orange" select="(251, 153, 2)" as="xs:integer+"/>
   <xsl:variable name="tan:ryb-green" select="(102, 176, 50)" as="xs:integer+"/>
   <xsl:variable name="tan:ryb-purple" select="(134, 1, 175)" as="xs:integer+"/>
   <xsl:variable name="tan:ryb-red-orange" select="(252, 96, 10)" as="xs:integer+"/>
   <xsl:variable name="tan:ryb-yellow-orange" select="(252, 204, 26)" as="xs:integer+"/>
   <xsl:variable name="tan:ryb-yellow-green" select="(178, 215, 50)" as="xs:integer+"/>
   <xsl:variable name="tan:ryb-blue-green" select="(52, 124, 152)" as="xs:integer+"/>
   <xsl:variable name="tan:ryb-blue-purple" select="(68, 36, 214)" as="xs:integer+"/>
   <xsl:variable name="tan:ryb-red-purple" select="(194, 20, 96)" as="xs:integer+"/>
   <!-- These are masks, to lighten background colors -->
   <!-- almost pure white... -->
   <xsl:variable name="tan:white-mask-a90" select="(255, 255, 255, 0.90)" as="xs:double+"/>
   <xsl:variable name="tan:white-mask-a80" select="(255, 255, 255, 0.80)" as="xs:double+"/>
   <xsl:variable name="tan:white-mask-a70" select="(255, 255, 255, 0.70)" as="xs:double+"/>
   <xsl:variable name="tan:white-mask-a60" select="(255, 255, 255, 0.60)" as="xs:double+"/>
   <xsl:variable name="tan:white-mask-a50" select="(255, 255, 255, 0.50)" as="xs:double+"/>
   <xsl:variable name="tan:white-mask-a40" select="(255, 255, 255, 0.40)" as="xs:double+"/>
   <xsl:variable name="tan:white-mask-a30" select="(255, 255, 255, 0.30)" as="xs:double+"/>
   <xsl:variable name="tan:white-mask-a20" select="(255, 255, 255, 0.20)" as="xs:double+"/>
   <xsl:variable name="tan:white-mask-a10" select="(255, 255, 255, 0.10)" as="xs:double+"/>
   <!-- ...to almost pure background color -->





</xsl:stylesheet>
