<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:tan="tag:textalign.net,2015:ns" xmlns="tag:textalign.net,2015:ns"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   exclude-result-prefixes="#all" version="3.0">

   <!-- Language catalogs -->
   
   <!-- Where are language catalogs for lexico-morphological data? Each map entry key is an ISO language name, and the contents are strings or URIs, pointing to absolute locations. -->
   <xsl:param name="tan:lang-catalog-map" as="map(xs:string,xs:anyURI+)">
      <xsl:map>
         <xsl:map-entry key="'grc'">
            <xsl:sequence
               select="resolve-uri('../../library-lm/grc/lm-perseus/catalog.tan.xml', static-base-uri())"/>
            <xsl:sequence
               select="resolve-uri('../../library-lm/grc/lm-bible/catalog.tan.xml', static-base-uri())"
            />
         </xsl:map-entry>
         <xsl:map-entry key="'lat'">
            <xsl:sequence
               select="resolve-uri('../../library-lm/lat/lm-perseus/catalog.tan.xml', static-base-uri())"
            />
         </xsl:map-entry>
      </xsl:map>
   </xsl:param>
   
   <!-- regular expressions to detect the end of sentences, clauses, and words -->
   
   <!-- What regular expression defines the end of a sentence? -->
   <xsl:param name="tan:sentence-end-regex" select="'[\.\?!]+\p{P}*[\s.]*'"/>
   <!-- What regular expression defines the end of a clause? The default regular expression seeks to avoid words terminated by a simple apostrophe, and anticipates ellipses. -->
   <xsl:param name="tan:clause-end-regex" as="xs:string">[\w\s][\p{P}-[&apos;’«\[\(-]]\p{P}*[\s.]*</xsl:param>
   <!-- What regular expression defines the end of a word? -->
   <xsl:param name="tan:word-end-regex" select="'\s+'"/>
   
   <!-- Should parenthetical clauses be chopped? If false, parethetical clauses will be kept intact in a string processed by tan:chop-string(). -->
   <xsl:param name="tan:do-not-chop-parenthetical-clauses" as="xs:boolean" select="false()"/>
   
   <!-- What words look like numbers? This is useful for applications that need to parse non-Arabic numerals out of text. -->
   <xsl:param name="words-that-look-like-numbers" as="xs:string*" select="('A', 'I', 'Ει')"/>
   
   
   <!-- When parsing a bibliographic citation, and looking for keywords, what words should be ignored? -->
   <xsl:param name="tan:bibliography-words-to-ignore" as="xs:string*"
      select="('university', 'press', 'publication')"/>
   
   
   <!-- Batch replacements, applicable across many languages. For language-specific
   batch replacements, see extra/TAN-language-functions.xsl. Batch replacements are
   sequences of elements with attributes corresponding to fn:replace(): @pattern,
   @replacement, @flags. There is also a @message option, to report back on 
   changes taking place. -->
   
   <!-- What batch replacements should be applied to punctuation? -->
   <xsl:param name="tan:batch-replace-punctuation" as="element()*">
      <replace pattern="\p{{P}}+" replacement="" message="Removing punctuation"/>
   </xsl:param>
   <!-- What batch replacements should be applied to combining marks? -->
   <xsl:param name="tan:batch-replace-combining-marks" as="element()*">
      <replace pattern="\p{{Mc}}+" replacement="" message="Removing combining marks"/>
   </xsl:param>
   
   
   <!-- Language-specific batch replacements, used to homogenize orthography to a particular normalization. -->
   
   <!-- Latin -->
   
   <xsl:param name="tan:latin-batch-replacements-1" as="element()*">
      <!-- These batch replacements try to aggressively reduce classical, medieval Latin texts to a minimal idiosyncratic but 
         common orthographic system. This converts items to lowercase. -->
      
      <!-- ligatures -->
      <replace pattern="v" replacement="u" flags="i" message="Converting every u to v"/>
      <replace pattern="j" replacement="i" flags="i" message="Converting every j to i"/>
      <replace pattern="oe" replacement="e" flags="i" message="Simplifying ligature oe as e"/>
      <replace pattern="ae" replacement="e" flags="i" message="Simplifying ligature ae as e"/>
      <!-- splitting words -->
      <replace pattern="(^|\P{{L}})qu(ae?|e|is?|os?|ibus)nam($|\P{{L}})" replacement="$1qu$2 nam$3" flags="i" message="Splitting qua/quis etc. and nam"/>
      <replace pattern="(^|\P{{L}})siqui(d|dem|s)?($|\P{{L}})" replacement="$1si qui$2$3" flags="i" message="Splitting si and quid/quis/quidem"/>
      <replace pattern="(^|\P{{L}})(ac|et)si($|\P{{L}})" replacement="$1$2 si$3" flags="i" message="Splitting ac/et and si"/>
      <replace pattern="(^|\P{{L}})etenim($|\P{{L}})" replacement="$1et enim$2" flags="i" message="Splitting et and enim"/>
      <replace pattern="(^|\P{{L}})quamobrem($|\P{{L}})" replacement="$1quam ob rem$2" flags="i" message="Splitting quam, ob, and rem"/>
      <replace pattern="(^|\P{{L}})quo(circa|modo)($|\P{{L}})" replacement="$1quo $2$3" flags="i" message="Splitting quo and circa/modo"/>
      <replace pattern="(^|\P{{L}})verumetium($|\P{{L}})" replacement="$1verum etium$2" flags="i" message="Splitting verum and etiam"/>
      <!-- c to d -->
      <replace pattern="quicquid" replacement="quidquid" flags="i" message="Converting quicquid to quidquid"/>
      <!-- c to t -->
      <replace pattern="terci" replacement="terti" flags="i" message="Converting terci to terti"/>
      <replace pattern="pocius" replacement="potius" flags="i" message="Converting pocius as potius"/>
      <replace pattern="ici([aeiou])" replacement="iti$1" flags="i" message="Converting c in icia/e/i/o/u to t"/>
      <replace pattern="aci([aeiou])" replacement="ati$1" flags="i" message="Converting c in acia/e/i/o/u to t"/>
      <!-- ch to c -->
      <replace pattern="archan" replacement="arcan" flags="i" message="Converting archan to arcan"/>
      <replace pattern="michi" replacement="mihi" flags="i" message="Converting michi to mihi"/>
      <replace pattern="(^|\P{{L}})char" replacement="car" flags="i" message="Converting char- to car-"/>
      <!-- adding d -->
      <replace pattern="(^|\P{{L}})astan" replacement="$1adstan" flags="i" message="Converting astan- to adstan-"/>
      <!-- d to n -->
      <replace pattern="(^|\P{{L}})adn" replacement="$1ann" flags="i" message="Converting adn- to ann-"/>
      <!-- h added -->
      <replace pattern="(^|\P{{L}})osann?a" replacement="$1hosanna" flags="i" message="Adding h to Hosanna"/>
      <!-- h dropped -->
      <replace pattern="abraham" replacement="abraam" flags="i" message="Dropping h from abraham"/>
      <replace pattern="coher" replacement="coer" flags="i" message="Dropping h from coher"/>
      <replace pattern="(^|\P{{L}})hebdo" replacement="$1ebdo" flags="i" message="Dropping h from hebdo (e.g., Hebdomades)"/>
      <replace pattern="iohann" replacement="ioann" flags="i" message="Dropping h from iohann (e.g., Iohannes)"/>
      <replace pattern="ihes" replacement="ies" flags="i" message="Dropping h from ihes (e.g., Ihesus)"/>
      <replace pattern="israhel" replacement="israel" flags="i" message="Dropping h from israhel"/>
      <!-- i to e -->
      <replace pattern="(^|\P{{L}})beni" replacement="$1bene" flags="i" message="Converting beni- to bene-"/>
      <replace pattern="alitud" replacement="aletud" flags="i" message="Converting alitud to aletud"/>
      <replace pattern="dilect" replacement="delect" flags="i" message="Converting dilect to delect"/>
      <replace pattern="itati($|\P{{L}})" replacement="itate$1" flags="i" message="converting -itati to -itate"/>
      <!-- i to u -->
      <replace pattern="emoliment" replacement="emolument" flags="i" message="Converting emoliment to emolument"/>
      <!-- m to mm -->
      <replace pattern="(^|\P{{L}})mamon(a|e)($|\P{{L}})" replacement="$1mammon$2$3" flags="i" message="Standardizing loanword mammon"/>
      <!-- n to m -->
      <replace pattern="circun" replacement="circum" flags="i" message="Converting circun to circum"/>
      <replace pattern="duntax" replacement="dumtax" flags="i" message="Converting duntax to dumtax"/>
      <replace pattern="nque" replacement="mque" flags="i" message="Converting nque to mque"/>
      <replace pattern="ntamen" replacement="mtamen" flags="i" message="Converting ntamen to mtamen"/>
      <replace pattern="conp" replacement="comp" flags="i" message="Converting conp to comp"/>
      <!-- ph to f -->
      <replace pattern="(pro|ne)phan" replacement="$1fan" flags="i" message="Converting ph in nephan/prophan to f"/>
      <!-- s to z -->
      <replace pattern="baptisa" replacement="baptiza" flags="i" message="Converting baptisa to baptiza"/>
      <!-- th to ct, e.g. authoritatis -->
      <replace pattern="author" replacement="auctor" flags="i" message="Converting author to auctor"/>
      <!-- y to i -->
      <replace pattern="hydr" replacement="hidr" flags="i" message="Converting hydr (e.g. hydras) to hidr"/>
      <replace pattern="mosyn" replacement="mosin" flags="i" message="Converting mosyn (e.g. elemosynis) to mosin"/>
      <replace pattern="myst" replacement="mist" flags="i" message="Converting myst (e.g. mysticam) to mist"/>
      <replace pattern="presbyt" replacement="presbit" flags="i" message="Converting presbyt (e.g. presbyteri) to presbit"/>
      <replace pattern="synag" replacement="sinag" flags="i" message="Converting synag (e.g. synagoga) to sinag"/>
      <!-- doubled letters -->
      <replace pattern="eleemo" replacement="elemo" flags="i" message="Converting ee in eleemo to e"/>
      <replace pattern="iic([ei])" replacement="ic$1" flags="i" message="Converting ii in iice/i to i"/>
      <replace pattern="necce" replacement="nece" flags="i" message="Converting necce to nece"/>
      <replace pattern="toll" replacement="tol" flags="i" message="Converting toll to tol"/>
      <replace pattern="commod" replacement="comod" flags="i" message="Converting commod to comod"/>
      <replace pattern="penittus" replacement="penitus" flags="i" message="Converting penittus to penitus"/>
      <replace pattern="litter" replacement="liter" flags="i" message="Converting litter to liter"/>
      <replace pattern="quott" replacement="quot" flags="i" message="Converting quott to quot"/>
      <replace pattern="(^|\P{{L}})paruum($|\P{{L}})" replacement="$1parum$3" flags="i" message="Converting paruum to parum"/>
      <!-- proper nouns -->
      <replace pattern="(^|\P{{L}})chana($|\P{{L}})" replacement="$1cana$2" flags="i" message="Standardizing proper noun Cana"/>
      <replace pattern="(^|\P{{L}})h?i?ezechkele?" replacement="$1ezechiel" flags="i" message="Standardizing proper noun Ezechiel"/>
      <replace pattern="(^|\P{{L}})[hi]+eremia" replacement="$1ieremia" flags="i" message="Standardizing proper noun Ieremias"/>
      <replace pattern="(^|\P{{L}})[ih]+er[ou]s[ao]l[ye]m" replacement="$1ierosolym" flags="i" message="Standardizing proper noun Ierosolyma"/>
      <replace pattern="(^|\P{{L}})[yh]?esaia" replacement="$1isaia" flags="i" message="Standardizing proper noun Isaias"/>
      <replace pattern="(^|\P{{L}})mo[iy]?s(i|em|en)($|\P{{L}})" replacement="$1moys$2$3" flags="i" message="Standardizing proper noun Moysis (Moses)"/>
      <replace pattern="(^|\P{{L}})syon($|\P{{L}})" replacement="$1sion$3" flags="i" message="Standardizing proper noun Sion"/>
      <replace pattern="(^|\P{{L}})th?[iy]moth" replacement="$1timoth" flags="i" message="Standardizing proper noun Timothe"/>
   </xsl:param>
   
   
   <!-- Syriac -->
   <xsl:variable name="syriac-batch-replacements-1" as="element()+">
      <!-- For best results, remove combining marks before applying these batch replacements -->
      <!-- marks -->
      <!--<replace pattern="([\p{{L}}\p{{M}}]+)(&#x307;)(\P{{L}}+)" replacement="$1$3$2" flags="i" message="Moving overdot mark (U+0307 COMBINING DOT ABOVE) to end of word"/>
      <replace pattern="(\p{{L}}+)(&#x308;)(\P{{L}}+)" replacement="$1$3$2" flags="i" message="Moving plural, seyame mark (U+0308 COMBINING DIAERESIS) to end of word"/>-->
      <!-- splitting words -->
      <replace pattern="(^[ܒܕܘܠ]?|\P{{L}}[ܒܕܘܠ]?)ܟܠܡܕܡ($|\P{{L}})" replacement="$1ܟܠ ܡܕܡ$2" flags="i" message="Splitting kl and mdm ('everything')"/>
      <!-- yodh removed -->
      <replace pattern="ܐܣܟܝܡ" replacement="ܐܣܟܡ" flags="i" message="Standardizing Syriac word root askm ('schema')"/>
      <!-- proper nouns -->
      <replace pattern="ܐܝܣܪܝܠ" replacement="ܐܝܣܪܐܝܠ" flags="i" message="Standardizing proper noun Israel"/>
      
   </xsl:variable>
   
   
   
   

</xsl:stylesheet>
