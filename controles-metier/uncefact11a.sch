<?xml version="1.0" encoding="UTF-8"?>
<!--
   Copyright 2012, EDIFICAS. Tous droits réservés.
   Projet : ADN Compta
   http://www.edificas.fr

   ! Signalez-nous sans tarder les problèmes
   ! dans la mise en œuvre de ces règles. Merci.
   ! Benoît     : bmarchal@pineapplesoft.com
   ! Frédérique : fdanjon@cs.experts-comptables.org

   Pour valider un Schématron, utilisez une des implémentations sur
   http://www.schematron.com/implementation.html
   En particulier OxygenXML permet d'appliquer le schéma ET le schématron
   dans un seul scénario de validation:
   http://www.oyxgenxml.com
-->
<schema xmlns="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">
   <title>Validation de l'écriture comptable, niveau 1, 2013c</title>
   <ns uri="urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:10" prefix="ram"/>
   <ns uri="urn:un:unece:uncefact:data:standard:AAAReportingMessage:2" prefix="rsmres"/>
   <ns uri="urn:un:unece:uncefact:data:standard:AAAChartOfAccountsMessage:2" prefix="rsmcha"/>
   <ns uri="urn:un:unece:uncefact:data:standard:AAAAccountingMessage:2" prefix="rsmmsg"/>
   <ns uri="urn:un:unece:uncefact:data:standard:AAAAccountingEntryMessage:2" prefix="rsment"/>
   <pattern>
      <title>Numéros de compte</title>
      <let name="first-account-length" value="if (count(//ram:BookingBookedAccountingAccount) > 0) then string-length((//ram:BookingBookedAccountingAccount[ram:TypeCode = 1]/ram:ID)[1]) else if (count(//ram:IncludedAAALedgerAccountingAccount)) then string-length((//ram:IncludedAAALedgerAccountingAccount[ram:TypeCode = 1]/ram:ID)[1]) else string-length((//ram:RelatedAAAChartOfAccountsAccountingAccount[ram:TypeCode = 1]/ram:ID)[1])"/>
      <rule context="ram:BookingBookedAccountingAccount[ram:TypeCode = 1] | ram:RelatedAAAChartOfAccountsAccountingAccount[ram:TypeCode = 1] | ram:IncludedAAALedgerAccountingAccount[ram:TypeCode = 1]">
         <assert test="not(starts-with(ram:ID,'0')) and not(starts-with(ram:ID,'9'))">
            Compte <value-of select="ram:ID"/> : mauvais début
         </assert>
         <assert test="string-length(ram:ID) > 2 and string-length(ram:ID) &lt; 13">
            Compte <value-of select="ram:ID"/> : longueur incorrecte
         </assert>
         <assert test="matches(ram:ID,'^[0-9]+$')">
            Compte <value-of select="ram:ID"/> : mauvais masque
         </assert>
         <assert test="string-length(ram:ID) = $first-account-length">
            Compte <value-of select="ram:ID"/> : pas la même longueur que ses petits camarades
         </assert>
      </rule>
   </pattern>
   <!-- TODO vérifier les listes de code, etc. -->
   <!-- TODO vérifier les status dépendants    -->
   <pattern>
      <!-- faire également le contrôle que le compte auxilaire est bien accompagné d'un compte général -->
      <!-- TODO prevoir aussi le compte SubAccount au lieu de [TypeCode = 2] -->
      <title>Numéro de comptes pour les comptes auxiliaires</title>
      <rule context="ram:BookingBookedAccountingAccount[ram:TypeCode = 2] | ram:RelatedAAAChartOfAccountsAccountingAccount[ram:TypeCode = 2] | ram:IncludedAAALedgerAccountingAccount[ram:TypeCode = 2]">
         <assert test="string-length(ram:ID) &lt; 18">
            Compte <value-of select="ram:ID"/> : longueur incorrecte
         </assert>
         <assert test="normalize-space(ram:ID) != ''">
            Compte <value-of select="ram:ID"/> : compte composé d'un espace !
         </assert>
      </rule>
   </pattern>
   <pattern>
      <title>Liens entre le message/envelope et les pièces, ainsi que les périodes</title>
      <rule context="rsmmsg:AAAWrapAccountingBook/ram:SpecifiedAAAWrapProcessedEntity">
         <let name="tpath1" value="tokenize(document-uri(/), '/')"/>
         <let name="tpath2" value="remove($tpath1, count($tpath1))"/>
         <let name="path" value="concat(string-join($tpath2, '/'), '/')"/>
         <let name="period" value="ram:SpecifiedAAAWrapDayBook/ram:SpecifiedAAAWrapAccountingPeriod/ram:SpecifiedAAAPeriod"/>
         <let name="period-start" value="xs:dateTime($period/ram:StartDateTime)"/>
         <let name="period-end" value="xs:dateTime($period/ram:EndDateTime)"/>
         <assert test="if(ram:SpecifiedAAAWrapJournalList) then doc-available(concat($path,ram:SpecifiedAAAWrapJournalList/ram:ID)) else true()">
            Document 'JournalList' <value-of select="ram:SpecifiedAAAWrapJournalList/ram:ID"/> manquant
         </assert>
         <assert test="doc-available(concat($path,ram:SpecifiedAAAWrapDayBook/ram:ID))">
            Document 'Entry' <value-of select="ram:SpecifiedAAAWrapDayBook/ram:ID"/> manquant
         </assert>
         <assert test="if(ram:SpecifiedAAAWrapAccountingAccountClassification) then doc-available(concat($path,ram:SpecifiedAAAWrapAccountingAccountClassification/ram:ID)) else true()">
            Document 'AccountClassification' <value-of select="ram:SpecifiedAAAWrapAccountingAccountClassification/ram:ID"/> manquant
         </assert>
         <assert test="if(ram:SpecifiedAAAWrapLedger) then doc-available(concat($path,ram:SpecifiedAAAWrapLedger/ram:ID)) else true()">
            Document 'Ledger' <value-of select="ram:SpecifiedAAAWrapLedger/ram:ID"/> manquant
         </assert>
         <let name="value-dates" value="document(concat($path,ram:SpecifiedAAAWrapDayBook/ram:ID))/rsment:AAAAccountingEntryMessage/rsment:AAAEntryDayBook/ram:IncludedOriginatorAccountingVoucher/ram:RelatedEvidenceDocument/ram:JustifiedPostedAccountingEntry/ram:ValueDateDateTime"/>
         <assert test="every $v in $value-dates satisfies xs:dateTime($v) >= $period-start">
            Date de valeur d'au moins une écriture antérieure au début de la période comptable (<value-of select="$period-start"/>)
         </assert>
         <assert test="every $v in $value-dates satisfies xs:dateTime($v) &lt;= $period-end">
            Date de valeur d'au moins une écriture postérieure au début de la période comptable (<value-of select="$period-end"/>)
         </assert>
      </rule>
   </pattern>
   <pattern>
      <title>Attributs rendus obligatoires hors schéma</title>
      <rule context="ram:RelatedEvidenceDocument">
         <assert test="ram:TypeCode">
            Type de pièce manquante pour la pièce <value-of select="ram:ID"/>
         </assert>
      </rule>
      <rule context="ram:JustifiedPostedAccountingEntry">
         <assert test="every $l in ram:DetailedPostedAccountingEntryLine satisfies $l/ram:Comment">
            Au moins une des lignes de l'écriture <value-of select="../ram:ID"/> n'a pas de libellé
         </assert>
      </rule>
      <rule context="ram:DetailedPostedAccountingEntryLine[ram:RelatedFiscalTax]">
         <let name="account-id" value="ram:RelatedPostedAccountingLineMonetaryValue/ram:BookingBookedAccountingAccount/ram:ID"/>
         <assert test="starts-with($account-id,'6') or starts-with($account-id,'7')">
            La ligne <value-of select="position()"/> contient de la TVA mais n'est pas un compte de TVA
         </assert>
      </rule>
      <rule context="ram:RelatedPostedAccountingLineMonetaryValue[ram:MatchingID]">
         <let name="account-id" value="ram:BookingBookedAccountingAccount/ram:ID"/>
         <assert test="starts-with($account-id,'4') or starts-with($account-id,'5')">
            La ligne <value-of select="ram:Comment"/> a un lettrage mais n'est pas un compte TVA ou bancaire
         </assert>
      </rule>
      <rule context="ram:RelatedAAAChartOfAccountsAccountingAccount">
         <assert test="ram:Name or ram:AbbreviatedName">
            Un des noms est requis pour <value-of select="ram:ID"/>
         </assert>
      </rule>
   </pattern>
   <pattern>
      <title>SIREN dans le message/envelope</title>
      <rule context="ram:OriginatorAAAWrapOrganization">
         <assert test="string-length(translate(normalize-space(ram:OtherID),' ','')) = 9">
            Longueur du SIRET/SIREN de la balise <value-of select="ram:OtherID"/> invalide ou absent
         </assert>
         <assert test="sum(for $c in (for $i in (1 to 9) return xs:integer(substring(translate(normalize-space(ram:OtherID),' ',''),$i,1)) * (if ($i mod 2 != 0) then 1 else 2)) return if ($c >= 10) then $c - 9 else $c) mod 10 = 0">
            Code SIREN <value-of select="ram:OtherID"/> invalide
         </assert>
      </rule>
   </pattern>
   <pattern>
      <title>Cohérence des périodes</title>
      <rule context="ram:SpecifiedAAAPeriod">
         <assert test="ram:StartDateTime">
            Période se terminant <value-of select="ram:EndDateTime"/> n'a pas de date de début
         </assert>
         <assert test="ram:EndDateTime">
            Période se terminant <value-of select="ram:StartDateTime"/> n'a pas de date de début
         </assert>
         <assert test="xs:dateTime(ram:EndDateTime) >= xs:dateTime(ram:StartDateTime)">
            Période commence le <value-of select="ram:StartDateTime"/> soit après la fin du <value-of select="ram:StartDateTime"/> ! 
         </assert>
      </rule>
   </pattern>
   <pattern>
      <title>Equilibre de l'écriture</title>
      <rule context="ram:JustifiedPostedAccountingEntry">
         <let name="debit"  value="ram:DetailedPostedAccountingEntryLine/ram:RelatedPostedAccountingLineMonetaryValue[ram:DebitCreditCode = '29']/ram:LocalAccountingCurrencyAmount"/>
         <let name="credit" value="ram:DetailedPostedAccountingEntryLine/ram:RelatedPostedAccountingLineMonetaryValue[ram:DebitCreditCode = '30']/ram:LocalAccountingCurrencyAmount"/>
         <assert test="round-half-to-even(sum($debit), 2) = round-half-to-even(sum($credit), 2)">
            Débit (<value-of select="round-half-to-even(sum($debit), 2)"/>) n'est pas égal au crédit (<value-of select="round-half-to-even(sum($credit), 2)"/>) pour l'écriture (<value-of select="ram:ID"/>).
         </assert>
      </rule>
   </pattern>
   <pattern>
      <title>Liste de codes</title>
         <let name="account-types" value="('1', '2')"/>
         <rule context="ram:BookingBookedAccountingAccount">
         <assert test="exists(index-of($account-types, ram:TypeCode))">
            Le type de compte doit être un des suivants : (<value-of select="string-join($account-types, ', ')" />) 1 général, 2 auxiliaire.
         </assert>
         </rule>
   </pattern>
   <pattern>
      <title>Compte-rendu de traitement (préliminaire)</title>
      <rule context="rsmres:AAAReportingMessage">
         <assert test="rsmres:AAAReportFormality/ram:NomenclatureID = 'http://edificas.fr/2012/nomenclature'">
            La nomenclature n'est pas celle d'EDIFICAS !
         </assert>
         <assert test="rsmres:AAAReportFormality/ram:ConcernedAAAReportOrganization">
            Mais qui a émis ce compte-rendu de traitement ?
         </assert>
         <assert test="rsmres:AAAReportFormality/ram:SpecifiedAAAReportAccountingPeriod/ram:SpecifiedAAAPeriod">
            La période sur laquelle porte ce compte-rendu de traitement est inconnue.
         </assert>
         <assert test="rsmres:AAAReportFormality/ram:SpecifiedAAAReportExpectedInformation[ram:ResponseIndexID = '#organization' and ram:ReferenceID = 'recipient']">
            Pas de destinataire pour ce compte-rendu de traitement.
         </assert>
      </rule>
      <rule context="ram:SpecifiedAAAReportExpectedInformation[ram:ResponseIndexID = '#organization']">
         <assert test="ram:ReferenceID = 'intermediate' or ram:ReferenceID = 'recipient'">
            Type d'organisation inconnue.
         </assert>
         <assert test="../ram:SpecifiedAAAReportOrganization">
            Les données de l'organisation manquent.
         </assert>
      </rule>
      <!-- TODO vérifier le SIREN -->
      <rule context="ram:IncludedAAAReport[ram:SpecifiedAAAReportExpectedInformation/ram:ResponseIndexID = '#documentID']">
         <assert test="ram:SpecifiedAAAReportExpectedInformation[ram:ResponseIndexID = '#documentID'][ram:ReferenceID]">
            Compte-rendu n'identifie pas le document dont il parle.
         </assert>
         <assert test="ram:SpecifiedAAAReportExpectedInformation/ram:ResponseIndexID = '#token'">
            Manque le jeton d'horodatage.
         </assert>
      </rule>
      <rule context="ram:SpecifiedAAAReportExpectedInformation[ram:ResponseIndexID = '#token' and string(ram:ResponseIndicator) = 'true']">
         <assert test="ram:ReferenceID">
            Hash manquant dans le jeton d'horodatage.
         </assert>
         <assert test="ram:SpecifiedDate">
            Date manquante dans le jeton d'horodatage.
         </assert>
         <assert test="ram:SpecifiedTime">
            Heure manquante dans le jeton d'horodatage.
         </assert>
      </rule>
      <rule context="ram:SpecifiedAAAReportExpectedInformation[ram:ResponseIndexID = '#token' and string(ram:ResponseIndicator) = 'false']">
         <assert test="ram:Comment">
            Rapport d'erreur sans commentaire.
         </assert>
      </rule>
   </pattern>
</schema>