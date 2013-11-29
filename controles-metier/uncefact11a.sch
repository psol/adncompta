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
      <title>Validation des scénarios</title>
      <rule context="ram:SpecifiedAAAWrapProcessedEntity">
         <!-- 002 -->
         <assert test="count(ram:ScenarioIdentificationID) = 1">
            L'identifiant du scénario manquant.
         </assert>
         <!-- 004 -->
         <assert test="count(ram:ScenarioStepNumberNumeric) = 1">
            Le numéro d'étape dans le scénario manquant.
         </assert>
         <let name="actors" value="substring(ram:ScenarioIdentificationID, 16, 20)"/>
         <!-- 005 -->
         <assert test="($actors = 'PreparerIntermediary' and (ram:ScenarioStepNumberNumeric = '1' or ram:ScenarioStepNumberNumeric = '2')) or
                       ($actors = 'IntermediaryArchiver' and (ram:ScenarioStepNumberNumeric = '2' or ram:ScenarioStepNumberNumeric = '3'))">
            Etape de scénario <value-of select="ram:ScenarioStepNumberNumeric"/> incohérente pour un scénario entre <value-of select="$actors"/>
         </assert>
      </rule>
      <rule context="ram:ScenarioIdentificationID">
         <!-- 003 -->
         <assert test="matches(., '^ADNCompta_2013_((PreparerIntermediary)|(IntermediaryArchiver))_Entry$')">
            Identifiant du scénario inconnu ou mal formé
         </assert>
      </rule>
      <rule context="ram:SpecifiedAAAWrapProcessedEntity">
         <!-- 013 -->
         <assert test="count(ram:SpecifiedAAAWrapDayBook) > 0">
            Journal d'écriture manquant
         </assert>
      </rule>
   </pattern>
   <pattern>
      <title>Validation de l'unité de tenue de compte</title>
      <!-- 006 -->
      <rule context="ram:SpecifiedAAAWrapProcessedEntity">
         <assert test="count(ram:LocalAccountingCurrencyCode) = 1">
            Unité de tenue de compte manquante
         </assert>
      </rule>
      <!-- 007 -->
      <rule context="ram:LocalAccountingCurrencyCode">
         <assert test="matches(., 'eur', 'i')">
            Unité de tenue de compte invalide
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
         <let name="useless-check" value="ram:SpecifiedAAAWrapDayBook/ram:SpecifiedAAAWrapAccountingPeriod/ram:SpecifiedAAAWrapAccountingCheck"/>
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
         <let name="values" value="document(concat($path, ram:SpecifiedAAAWrapDayBook/ram:ID))/rsment:AAAAccountingEntryMessage/rsment:AAAEntryDayBook/ram:IncludedOriginatorAccountingVoucher/ram:RelatedEvidenceDocument/ram:JustifiedPostedAccountingEntry/ram:DetailedPostedAccountingEntryLine/ram:RelatedPostedAccountingLineMonetaryValue"/>
         <!-- 034 -->
         <assert test="if($useless-check)
                       then abs(number($useless-check/ram:TotalDebitAmount) - sum(for $v in $values[ram:DebitCreditCode = 29]/ram:LocalAccountingCurrencyAmount return number($v))) lt 0.1
                       else true()">
            Total calculés des débits (<value-of select="sum($values[ram:DebitCreditCode = 29]/ram:LocalAccountingCurrencyAmount)"/>) différent du total annoncé (<value-of select="$useless-check/ram:TotalDebitAmount"/>)
         </assert>
         <!-- 036 -->
         <assert test="if($useless-check)
                       then abs(number($useless-check/ram:TotalDebitAmount) - sum(for $v in $values[ram:DebitCreditCode = 30]/ram:LocalAccountingCurrencyAmount return number($v))) lt 0.1
                       else true()">
            Total calculés des crédits (<value-of select="sum($values[ram:DebitCreditCode = 30]/ram:LocalAccountingCurrencyAmount)"/>) différent du total annoncé (<value-of select="$useless-check/ram:TotalCreditAmount"/>)
         </assert>
      </rule>
   </pattern>
   <pattern>
      <title>Autres attributs rendus obligatoires hors schéma</title>
      <rule context="rsmmsg:AAAWrapAccountingBook">
         <!-- 001 -->
         <assert test="count(ram:SpecifiedAAAWrapProcessedEntity) = 1">
            Il n'y a pas une (et une seule) entitée par message
         </assert>
      </rule>
      <rule context="ram:SpecifiedAAAWrapProcessedEntity">
         <!-- 008 -->
         <assert test="count(ram:AccountingBookCreationDateTime) = 1">
            Date de création du message manquant
         </assert>
         <!-- 009 -->
         <assert test="count(ram:OriginatorAAAWrapOrganization) = 1">
            Cardinalité d'originateur incorrecte (1-1 attendu)
         </assert>
         <!-- 010 -->
         <assert test="count(ram:SenderAAAWrapOrganization) = 1">
            Cardinalité d'émetteur incorrect (1-1 attendu)
         </assert>
         <!-- 011 -->
         <assert test="count(ram:RecipientAAAWrapOrganization) > 0">
            Cardinalité de destinataire incorrect (1-n attendu)
         </assert>
         <!-- 012 -->
         <assert test="count(ram:SenderAAAWrapSoftware | ram:RecipientAAAWrapSoftware | ram:IntermediateAAAWrapSoftware) > 0">
            Identifiant du logiciel manquant
         </assert>
      </rule>
      <rule context="ram:SenderAAAWrapSoftware | ram:RecipientAAAWrapSoftware | ram:IntermediateAAAWrapSoftware">
         <!-- 022 -->
         <assert test="count(ram:Name) = 1">
            Nom du logiciel manquant pour <value-of select="local-name()"/>
         </assert>
         <!-- 023 -->
         <assert test="count(ram:VersionID) = 1">
            Numéro de version du logiciel manquant pour <value-of select="local-name()"/>
         </assert>
         <!-- 024 -->
         <assert test="count(ram:ProvidedAAAWrapCertificate) = 1">
            Attestation du logiciel manquante pour <value-of select="local-name()"/>
         </assert>
      </rule>
      <rule context="ram:SpecifiedAAAWrapDayBook">
         <!-- 025 -->
         <assert test="count(ram:Comment) = 1">
            Commentaire manquant pour le livre <value-of select="ram:ID"/>
         </assert>
         <!-- 026 -->
         <assert test="count(ram:SpecifiedAAAWrapAccountingPeriod/ram:SpecifiedAAAPeriod[ram:FunctionCode = 322]) = 1">
            Période comptable manquante pour <value-of select="ram:ID"/>
         </assert>
         <!-- 027 -->
         <assert test="if(ram:SpecifiedAAAWrapAccountingPeriod/ram:SpecifiedAAAPeriod[ram:FunctionCode = 746]) then count(ram:SpecifiedAAAWrapAccountingPeriod/ram:SpecifiedAAAPeriod) = 2 else true()">
            Nombre de périodes incorrect pour <value-of select="ram:ID"/>
         </assert>
         <!-- 032 -->
         <assert test="if(count(ram:SpecifiedAAAWrapAccountingPeriod) = 2) then ram:SpecifiedAAAWrapAccountingPeriod/ram:SpecifiedAAAWrapAccountingCheck else true()">
            Les totaux de contrôles ne sont pas présents, certes ils sont inutiles mais leur absence ne passera pas inapercue
         </assert>
      </rule>
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
      <title>Cohérence des totaux de contrôles</title>
      <rule context="ram:SpecifiedAAAWrapAccountingCheck">
         <!-- 033 -->
         <assert test="count(ram:TotalDebitAmount) = 1">
            Total des débits absent (ils ne servent à rien mais leur absence est remarquée)
         </assert>
         <!-- 035 -->
         <assert test="count(ram:TotalCreditAmount) = 1">
            Total des crédits absent (ils ne servent à rien mais leur absence est remarquée)
         </assert>
         <assert test="$useless-check/ram:TotalDebitAmount = $useless-check/ram:TotalCreditAmount">
            Débit n'est pas égal à crédit dans les totaux de contrôles
         </assert>
      </rule>
   </pattern>
   <pattern>
      <title>Identifiant des partenaires de l'échange</title>
      <rule context="ram:AuditAAAWrapOrganization | ram:RepresentativeAAAWrapOrganization | ram:BilledAAAWrapOrganization | ram:PreparerAAAWrapOrganization | ram:OriginatorAAAWrapOrganization | ram:RecipientAAAWrapOrganization | ram:SenderAAAWrapOrganization | ram:OwnerAAAWrapOrganization">
         <!-- 014 -->
         <assert test="count(ram:Name) = 1">
            Nom de l'organisation <value-of select="local-name()"/> manquant
         </assert>
         <!-- 015 -->
         <assert test="count(ram:ID) = 1">
            SIRET/SIREN manquant pour <value-of select="local-name()"/>
         </assert>
         <let name="siretn" value="translate(normalize-space(ram:ID), ' ', '')"/>
         <let name="siretn-len" value="string-length($siretn)"/>
         <!-- 016 -->
         <assert test="$siretn-len = 9 or $siretn-len = 14">
            Longueur du SIRET/SIREN <value-of select="$siretn"/> invalide
         </assert>
         <!-- 017 -->
         <assert test="sum(for $c in (for $i in (1 to $siretn-len) return xs:integer(substring($siretn, $i, 1)) * (if (($siretn-len - $i + 1) mod 2 != 0) then 1 else 2)) return if ($c >= 10) then $c - 9 else $c) mod 10 = 0">
            Code SIRET/SIREN <value-of select="$siretn"/> invalide
         </assert>
         <!-- 018 -->
         <assert test="count(ram:PostalAAAAddress) = 1">
            Adresse postale manquante pour <value-of select="local-name()"/>
         </assert>
         <!-- 019 -->
         <assert test="count(ram:PostalAAAAddress/ram:PostcodeCode) = 1">
            Adresse postale manquante pour <value-of select="local-name()"/>
         </assert>
         <!-- 020 -->
         <assert test="count(ram:PostalAAAAddress/ram:LineOne) = 1">
            Adresse postale manquante pour <value-of select="local-name()"/>
         </assert>
         <!-- 021 -->
         <assert test="count(ram:PostalAAAAddress/ram:CityName) = 1">
            Adresse postale manquante pour <value-of select="local-name()"/>
         </assert>
      </rule>
   </pattern>
   <pattern>
      <title>Cohérence des périodes</title>
      <rule context="ram:SpecifiedAAAPeriod">
         <!-- 028 -->
         <assert test="count(ram:StartDateTime) = 1">
            Date de début de période manquante pour la période se terminant en <value-of select="ram:EndDateTime"/>
         </assert>
         <!-- 029 -->
         <assert test="count(ram:EndDateTime) = 1">
            Date de fin de période manquante pour la période débutant en <value-of select="ram:StartDateTime"/>
         </assert>
         <!-- 030 -->
         <assert test="count(ram:InclusiveIndicator) = 1">
            Indicateur d'inclusivité manquant pour la période <value-of select="ram:StartDateTime"/>-<value-of select="ram:EndDateTime"/>
         </assert>
         <!-- 031 -->
         <assert test="count(ram:FunctionCode) = 1">
            Code de fonction manquant pour la période <value-of select="ram:StartDateTime"/>-<value-of select="ram:EndDateTime"/>
         </assert>
         <assert test="xs:dateTime(ram:EndDateTime) >= xs:dateTime(ram:StartDateTime)">
            Période commence le <value-of select="ram:StartDateTime"/> soit après la fin <value-of select="ram:StartDateTime"/> ! 
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