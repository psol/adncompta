<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:fn="http://adncompta.com/2013/functions"
   exclude-result-prefixes="xs"
   version="2.0">

   <xsl:function name="fn:is-siren-valid" as="xs:boolean">
      <xsl:param name="siren" as="xs:string"/>
      <xsl:value-of select="sum(for $c in (for $i in (1 to 9) return xs:integer(substring(translate(normalize-space($siren),' ',''),$i,1)) * (if ($i mod 2 != 0) then 1 else 2)) return if ($c >= 10) then $c - 9 else $c) mod 10 = 0"/>
   </xsl:function>
   
   <xsl:function name="fn:parent-directory" as="xs:string">
      <xsl:param name="uri" as="xs:string"/>
      <xsl:variable name="tpath1" select="tokenize($uri, '/')"/>
      <xsl:variable name="tpath2" select="remove($tpath1, count($tpath1))"/>
      <xsl:value-of select="concat(string-join($tpath2, '/'), '/')"/>
   </xsl:function>

</xsl:stylesheet>