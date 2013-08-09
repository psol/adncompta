<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:rsm="urn:un:unece:uncefact:data:standard:AAAAccountingEntryMessage:2" xmlns:ram="urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:10" exclude-result-prefixes="xs" version="2.0">
   <xsl:output method="xml" indent="yes"/>
   <xsl:template match="@*|node()" priority="-100"><xsl:copy><xsl:apply-templates select="@*|node()"/></xsl:copy></xsl:template>
   <xsl:template match="rsm:AAAEntryDayBook">
      <ram:ID>2012-05-DB</ram:ID>
      <ram:Comment>Vente de pommes</ram:Comment>
      <xsl:for-each-group select="ram:IncludedOriginatorAccountingVoucher/ram:RelatedEvidenceDocument/ram:JustifiedPostedAccountingEntry" group-by="ram:JournalID">
         <ram:Journal>
            <ram:JournalID><xsl:value-of select="current-grouping-key()"/></ram:JournalID>
            <xsl:for-each select="current-group()">
               <ram:JustifiedPostedAccountingEntry>
                  <ram:IncludedOriginatorAccountingVoucher>
                     <ram:ID><xsl:value-of select="../ram:ID"/></ram:ID>
                     <ram:RelatedEvidenceDocument>
                        <ram:ID><xsl:value-of select="../ram:RelatedEvidenceDocument/ram:ID"/></ram:ID>
                        <ram:TypeCode><xsl:value-of select="../ram:RelatedEvidenceDocument/ram:TypeCode"/></ram:TypeCode>
                     </ram:RelatedEvidenceDocument>
                  </ram:IncludedOriginatorAccountingVoucher>
                  <xsl:apply-templates select="@*|node()"/>
               </ram:JustifiedPostedAccountingEntry>
            </xsl:for-each>
         </ram:Journal>
      </xsl:for-each-group>
   </xsl:template>
</xsl:stylesheet>