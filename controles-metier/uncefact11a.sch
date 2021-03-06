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
   <title>Validation de l'écriture comptable, niveau 1, 2014f</title>
   <ns uri="urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:10" prefix="ram"/>
   <ns uri="urn:un:unece:uncefact:data:standard:AAAReportingMessage:2" prefix="rsmres"/>
   <ns uri="urn:un:unece:uncefact:data:standard:AAAChartOfAccountsMessage:2" prefix="rsmcha"/>
   <ns uri="urn:un:unece:uncefact:data:standard:AAAAccountingMessage:2" prefix="rsmmsg"/>
   <ns uri="urn:un:unece:uncefact:data:standard:AAAAccountingEntryMessage:2" prefix="rsment"/>
   <ns uri="urn:un:unece:uncefact:data:standard:AAALedgerMessage:2" prefix="rsmldg"/>
   <!-- TODO refactor: use regex instead -->
   <let name="debitCodes" value="'29', '31', '32'"/>
   <let name="creditCodes" value="'30', '33', '34'"/>
   <pattern>
      <title>Numéros de compte</title>
      <let name="first-account-length" value="if (count(//ram:BookingBookedAccountingAccount) > 0) then string-length((//ram:BookingBookedAccountingAccount/ram:ID)[1]) else if (count(//ram:IncludedAAALedgerAccountingAccount)) then string-length((//ram:IncludedAAALedgerAccountingAccount/ram:ID)[1]) else string-length((//ram:RelatedAAAChartOfAccountsAccountingAccount/ram:ID)[1])"/>
      <rule context="ram:BookingBookedAccountingAccount | ram:RelatedAAAChartOfAccountsAccountingAccount | ram:IncludedAAALedgerAccountingAccount">
         <!-- 058 -->
         <assert test="string-length(ram:ID) > 2 and string-length(ram:ID) &lt; 13">
            Err 058 : Compte <value-of select="ram:ID"/> : longueur incorrecte
         </assert>
         <!-- 057 -->
         <assert test="matches(ram:ID,'^[1-8][0-9]+$')">
            Err 057 : Compte <value-of select="ram:ID"/> : mauvais masque
         </assert>
         <!-- 056 -->
         <assert test="string-length(ram:ID) = $first-account-length">
            Err 056 : Compte <value-of select="ram:ID"/> : pas la même longueur que ses petits camarades
         </assert>
      </rule>
      <rule context="ram:DetailedPostedAccountingEntryLine[ram:RelatedFiscalTax]">
         <let name="account-id" value="ram:RelatedPostedAccountingLineMonetaryValue/ram:BookingBookedAccountingAccount/ram:ID"/>
         <!--
         <assert test="starts-with($account-id,'6') or starts-with($account-id,'7')">
            La ligne <value-of select="position()"/> contient de la TVA mais n'est pas un compte de TVA
         </assert>
         -->
      </rule>
      <rule context="ram:RelatedPostedAccountingLineMonetaryValue[ram:MatchingID]">
         <let name="account-id" value="ram:BookingBookedAccountingAccount/ram:ID"/>
         <!--
         <assert test="starts-with($account-id,'4') or starts-with($account-id,'5')">
            La ligne <value-of select="ram:Comment"/> a un lettrage mais n'est pas un compte TVA ou bancaire
         </assert>
         -->
      </rule>
      <rule context="ram:RelatedAAAChartOfAccountsAccountingAccount">
         <assert test="ram:Name or ram:AbbreviatedName">
            Un des noms est requis pour <value-of select="ram:ID"/>
         </assert>
      </rule>
   </pattern>
   <pattern>
      <title>Numéro de comptes pour les comptes auxiliaires (méthode alternative)</title>
      <rule context="ram:BookingBookedAccountingAccount | ram:RelatedAAAChartOfAccountsAccountingAccount | ram:IncludedAAALedgerAccountingAccount">
         <!-- 061 -->
         <assert test="if(count(ram:SubAccountID) > 0) then string-length(ram:SubAccountID) > 0 and string-length(ram:SubAccountID) &lt; 18 else true()">
            Err 061 : Compte auxiliaire <value-of select="ram:SubAccountID"/> : longueur incorrecte
         </assert>
         <!-- 060 -->
         <assert test="if(count(ram:SubAccountID) > 0) then normalize-space(ram:SubAccountID) != '' else true()">
            Err 060 : Compte <value-of select="ram:ID"/> : compte auxiliaire composé d'un espace !
         </assert>
         <!-- 062 -->
         <assert test="count(ram:Name) = 1 or count(ram:AbbreviatedName) = 1">
            Err 062 : Nom de compte manquant pour <value-of select="ram:ID"/>
         </assert>
         <!-- 063 -->
         <assert test="count(ram:TypeCode) = 1">
            Err 063 : Type de compte manquant pour <value-of select="ram:ID"/>
         </assert>
      </rule>
   </pattern>
   <pattern>
      <title>Validation des scénarios</title>
      <rule context="ram:SpecifiedAAAWrapProcessedEntity">
         <!-- 002 -->
         <assert test="count(ram:ScenarioIdentificationID) = 1">
            Err 002 : L'identifiant du scénario manquant.
         </assert>
         <!-- 004 -->
         <assert test="count(ram:ScenarioStepNumberNumeric) = 1">
            Err 004 : Le numéro d'étape dans le scénario manquant.
         </assert>
         <let name="actors" value="substring-before(substring(ram:ScenarioIdentificationID, 22, 20), '_')"/>
         <!-- 005 -->
         <assert test="($actors = 'PreparerIntermediary' and (ram:ScenarioStepNumberNumeric = '1' or ram:ScenarioStepNumberNumeric = '2')) or
                       ($actors = 'IntermediaryArchiver' and (ram:ScenarioStepNumberNumeric = '2' or ram:ScenarioStepNumberNumeric = '3')) or
                       ($actors = 'PreparerArchiver'     and  ram:ScenarioStepNumberNumeric = '1')">
            Err 005 : Etape de scénario <value-of select="ram:ScenarioStepNumberNumeric"/> incohérente pour un scénario entre <value-of select="$actors"/>
         </assert>
      </rule>
      <rule context="ram:ScenarioIdentificationID">
         <!-- 003 -->
         <assert test="matches(., '^ADNCompta_((Legal)|(Plain))_2014_((PreparerIntermediary)|(IntermediaryArchiver)|(PreparerArchiver))_Entry$')">
            Err 003 : Identifiant du scénario inconnu ou mal formé
         </assert>
      </rule>
      <rule context="ram:SpecifiedAAAWrapProcessedEntity">
         <!-- 013 -->
         <assert test="count(ram:SpecifiedAAAWrapDayBook) > 0">
            Err 013 : Journal d'écriture manquant
         </assert>
      </rule>
   </pattern>
   <pattern>
      <title>Validation de l'unité de tenue de compte</title>
      <!-- 006 -->
      <rule context="ram:SpecifiedAAAWrapProcessedEntity">
         <assert test="count(ram:LocalAccountingCurrencyCode) = 1">
            Err 006 : Unité de tenue de compte manquante
         </assert>
      </rule>
      <!-- 007 -->
      <rule context="ram:LocalAccountingCurrencyCode">
         <assert test="matches(., 'eur', 'i')">
            Err 007 : Unité de tenue de compte invalide. Valeur attendue Euro
         </assert>
      </rule>
   </pattern>
   <!-- TODO séparer la présence des fichiers (hors abstraits) et les contrôles de périodes/totaux (abstraits) -->
   <pattern abstract="true" id="interfiles">
      <title>Liens entre le message/envelope et les pièces, ainsi que les périodes</title>
      <rule context="rsmmsg:AAAWrapAccountingBook/ram:SpecifiedAAAWrapProcessedEntity">
         <!-- 071 - 072 - 073 - 074 -->
         <let name="tpath1" value="tokenize(document-uri(/), '/')"/>
         <let name="tpath2" value="remove($tpath1, count($tpath1))"/>
         <let name="path" value="concat(string-join($tpath2, '/'), '/')"/>
         <let name="period" value="$entitytag/ram:SpecifiedAAAWrapAccountingPeriod/ram:SpecifiedAAAPeriod"/>
         <let name="period-start" value="xs:dateTime($period/ram:StartDateTime)"/>
         <let name="period-end" value="xs:dateTime($period/ram:EndDateTime)"/>
         <let name="useless-check" value="$entitytag/ram:SpecifiedAAAWrapAccountingPeriod/ram:SpecifiedAAAWrapAccountingCheck"/>
         <assert test="if(ram:SpecifiedAAAWrapJournalList) then doc-available(concat($path,ram:SpecifiedAAAWrapJournalList/ram:ID)) else true()">
            Err 071: Document 'JournalList' <value-of select="ram:SpecifiedAAAWrapJournalList/ram:ID"/> manquant
         </assert>
         <assert test="doc-available(concat($path,ram:SpecifiedAAAWrapDayBook/ram:ID))">
            Err 072 : Document 'Entry' <value-of select="ram:SpecifiedAAAWrapDayBook/ram:ID"/> manquant
         </assert>
         <assert test="if(ram:SpecifiedAAAWrapAccountingAccountClassification) then doc-available(concat($path,ram:SpecifiedAAAWrapAccountingAccountClassification/ram:ID)) else true()">
            Err 073 : Document 'AccountClassification' <value-of select="ram:SpecifiedAAAWrapAccountingAccountClassification/ram:ID"/> manquant
         </assert>
         <assert test="doc-available(concat($path,ram:SpecifiedAAAWrapLedger/ram:ID))">
            Err 074 : Document 'Ledger' <value-of select="ram:SpecifiedAAAWrapLedger/ram:ID"/> manquant
         </assert>
         <!-- 076 - 077 -->
         <let name="value-dates" value="document(concat($path, $entitytag/ram:ID))/$valuedatepath"/>
         <assert test="every $v in $value-dates satisfies xs:dateTime($v) >= $period-start">
            Err 076 : Date de valeur d'au moins une écriture de <value-of select="$entitytag/ram:ID"/> antérieure au début de la période comptable (<value-of select="$period-start"/>)
         </assert>
         <assert test="every $v in $value-dates satisfies xs:dateTime($v) &lt;= $period-end">
            Err 077 : Date de valeur d'au moins une écriture de <value-of select="$entitytag/ram:ID"/> postérieure au début de la période comptable (<value-of select="$period-end"/>)
         </assert>
         <let name="values" value="document(concat($path, $entitytag/ram:ID))/$monetaryvaluepath"/>
         <!-- 034 -->
         <assert test="if($useless-check)
            then abs(number($useless-check/ram:TotalDebitAmount) - sum(for $v in $values[not(empty(index-of($debitCodes, ram:DebitCreditCode)))]/ram:LocalAccountingCurrencyAmount return number($v))) lt 0.1
            else true()">
            Err 034 : Total calculés des débits de <value-of select="$entitytag/ram:ID"/> (<value-of select="sum($values[not(empty(index-of($debitCodes, ram:DebitCreditCode)))]/ram:LocalAccountingCurrencyAmount)"/>) différent du total annoncé (<value-of select="$useless-check/ram:TotalDebitAmount"/>)
         </assert>
         <!-- 036 et 059 -->
         <assert test="if($useless-check)
            then abs(number($useless-check/ram:TotalDebitAmount) - sum(for $v in $values[not(empty(index-of($creditCodes, ram:DebitCreditCode)))]/ram:LocalAccountingCurrencyAmount return number($v))) lt 0.1
            else true()">
            Err 036 : Total calculés des crédits de <value-of select="$entitytag/ram:ID"/> (<value-of select="sum($values[not(empty(index-of($creditCodes, ram:DebitCreditCode)))]/ram:LocalAccountingCurrencyAmount)"/>) différent du total annoncé (<value-of select="$useless-check/ram:TotalCreditAmount"/>)
         </assert>
         <assert test="$useless-check/ram:TotalDebitAmount = $useless-check/ram:TotalCreditAmount">
            Err 059 : Débit n'est pas égal à crédit dans les totaux de contrôles
         </assert>
      </rule>
   </pattern>
   <pattern is-a="interfiles" id="entry-interfiles">
      <param name="entitytag" value="ram:SpecifiedAAAWrapDayBook"/>
      <param name="valuedatepath" value="rsment:AAAAccountingEntryMessage/rsment:AAAEntryDayBook/ram:IncludedOriginatorAccountingVoucher/ram:RelatedEvidenceDocument/ram:JustifiedPostedAccountingEntry/ram:ValueDateDateTime"/>
      <param name="monetaryvaluepath" value="rsment:AAAAccountingEntryMessage/rsment:AAAEntryDayBook/ram:IncludedOriginatorAccountingVoucher/ram:RelatedEvidenceDocument/ram:JustifiedPostedAccountingEntry/ram:DetailedPostedAccountingEntryLine/ram:RelatedPostedAccountingLineMonetaryValue"/>
   </pattern>
   <pattern is-a="interfiles" id="ledger-interfiles">
      <param name="entitytag" value="ram:SpecifiedAAAWrapLedger"/>
      <param name="valuedatepath" value="rsmldg:AAALedgerMessage/rsmldg:AAALedgerLedger/ram:IncludedAAALedgerAccountingAccount/ram:IncludedAAALedgerAccountingEntryLine/ram:ConnectedAAALedgerAccountingEntry/ram:ValueDateDateTime"/>
      <param name="monetaryvaluepath" value="rsmldg:AAALedgerMessage/rsmldg:AAALedgerLedger/ram:IncludedAAALedgerAccountingAccount/ram:IncludedAAALedgerAccountingEntryLine/ram:RelatedAAALedgerAccountingLineMonetaryValue"/>
   </pattern>
   <pattern>
      <title>Coherence entre écritures et grand livre</title>
      <rule context="ram:SpecifiedAAAWrapDayBook">
         <!-- 100 -->
         <assert test="(ram:SpecifiedAAAWrapAccountingPeriod/ram:SpecifiedAAAPeriod/ram:StartDateTime = ../ram:SpecifiedAAAWrapLedger/ram:SpecifiedAAAWrapAccountingPeriod/ram:SpecifiedAAAPeriod/ram:StartDateTime) and (ram:SpecifiedAAAWrapAccountingPeriod/ram:SpecifiedAAAPeriod/ram:EndDateTime = ../ram:SpecifiedAAAWrapLedger/ram:SpecifiedAAAWrapAccountingPeriod/ram:SpecifiedAAAPeriod/ram:EndDateTime)">
            Err 100 : Incohérence entre le périodes comptables des écritures et du grand livre
         </assert>
         <assert test="ram:SpecifiedAAAWrapAccountingPeriod/ram:SpecifiedAAAWrapAccountingCheck/ram:TotalDebitAmount = ../ram:SpecifiedAAAWrapLedger/ram:SpecifiedAAAWrapAccountingPeriod/ram:SpecifiedAAAWrapAccountingCheck/ram:TotalDebitAmount">
            Err 101 : Incohérence entre les totaux de débits des écritures et du grand livre
         </assert>
         <assert test="ram:SpecifiedAAAWrapAccountingPeriod/ram:SpecifiedAAAWrapAccountingCheck/ram:TotalCreditAmount = ../ram:SpecifiedAAAWrapLedger/ram:SpecifiedAAAWrapAccountingPeriod/ram:SpecifiedAAAWrapAccountingCheck/ram:TotalCreditAmount">
            Err 102 : Incohérence entre les totaux de débits des écritures et du grand livre
         </assert>
      </rule>
   </pattern>
   <pattern>
      <title>Autres attributs rendus obligatoires hors schéma</title>
      <rule context="rsmmsg:AAAWrapAccountingBook">
         <!-- 001 -->
         <assert test="count(ram:SpecifiedAAAWrapProcessedEntity) = 1">
            Err 001 : Il n'y a pas une (et une seule) entitée par message
         </assert>
      </rule>
      <rule context="ram:SpecifiedAAAWrapProcessedEntity">
         <!-- 008 -->
         <assert test="count(ram:AccountingBookCreationDateTime) = 1">
            Err 008 : Date de création du message manquante
         </assert>
         <!-- 009 -->
         <assert test="count(ram:OriginatorAAAWrapOrganization) = 1">
            Err 009 : Cardinalité d'originateur incorrecte (1-1 attendu)
         </assert>
         <!-- 010 -->
         <assert test="count(ram:SenderAAAWrapOrganization) = 1">
            Err 010 : Cardinalité d'émetteur incorrect (1-1 attendu)
         </assert>
         <!-- 011 -->
         <assert test="if(matches(ram:ScenarioIdentificationID, '^ADNCompta_.{11}_((PreparerIntermediary)|(IntermediaryArchiver))')) then count(ram:RecipientAAAWrapOrganization) > 0 else true()">
            Err 011 : Cardinalité de destinataire incorrect (1-n attendu)
         </assert>
         <!-- 070 -->
         <assert test="if(number(../ram:ScenarioStepNumberNumeric) = 3) then count(ram:PreparerAAAWrapOrganization) > 0 else true()">
            Err 070 : Cardinalité de préparateur incorrect (1-n attendu pour les scénarios avec intermédiaire)
         </assert>
         <!-- 012 -->
         <assert test="count(ram:SenderAAAWrapSoftware | ram:RecipientAAAWrapSoftware | ram:IntermediateAAAWrapSoftware) > 0">
            Err 012 : Identifiant du logiciel manquant
         </assert>
      </rule>
      <rule context="ram:SenderAAAWrapSoftware | ram:RecipientAAAWrapSoftware | ram:IntermediateAAAWrapSoftware">
         <!-- 022 -->
         <assert test="count(ram:Name) = 1">
            Err 022 : Nom du logiciel manquant pour <value-of select="local-name()"/>
         </assert>
         <!-- 023 -->
         <assert test="count(ram:VersionID) = 1">
            Err 023 : Numéro de version du logiciel manquant pour <value-of select="local-name()"/>
         </assert>
         <!-- 024 -->
         <assert test="count(ram:ProvidedAAAWrapCertificate) = 1">
            Err 024 : Attestation du logiciel manquante pour <value-of select="local-name()"/>
         </assert>
      </rule>
      <rule context="ram:SpecifiedAAAWrapDayBook | ram:SpecifiedAAAWrapLedger">
         <!-- 025 -->
         <assert test="count(ram:Comment) = 1">
            Err 025 : Commentaire manquant pour le livre <value-of select="ram:ID"/>
         </assert>
         <!-- 026 -->
         <assert test="count(ram:SpecifiedAAAWrapAccountingPeriod/ram:SpecifiedAAAPeriod[ram:FunctionCode = 322]) = 1">
            Err 026 : Période comptable manquante pour <value-of select="ram:ID"/>
         </assert>
         <!-- 027 -->
         <assert test="if(ram:SpecifiedAAAWrapAccountingPeriod/ram:SpecifiedAAAPeriod[ram:FunctionCode = 567]) then count(ram:SpecifiedAAAWrapAccountingPeriod/ram:SpecifiedAAAPeriod) = 2 else true()">
            Err 027 : Nombre de périodes incorrect pour <value-of select="ram:ID"/>
         </assert>
         <!-- 032 -->
         <assert test="if(count(ram:SpecifiedAAAWrapAccountingPeriod) = 2) then ram:SpecifiedAAAWrapAccountingPeriod/ram:SpecifiedAAAWrapAccountingCheck else true()">
            Er 032 : Les totaux de contrôles ne sont pas présents, certes ils sont inutiles mais leur absence ne passera pas inapercue
         </assert>
      </rule>
      <rule context="rsment:AAAEntryDayBook">
         <!-- 037 -->
         <assert test="count(ram:ID) = 1">
            Err 037 : Identifiant du livre comptable <value-of select="ram:Comment"/> manquant
         </assert>
         <!-- 038 -->
         <assert test="count(ram:Comment) = 1">
            Err 038 : Commentaire du livre comptable <value-of select="ram:ID"/> manquant
         </assert>
         <!-- 039 -->
         <assert test="count(ram:IncludedOriginatorAccountingVoucher) > 0">
            Err 039 : Voucher manquant pour le livre comptable <value-of select="ram:ID"/>
         </assert>
      </rule>
      <rule context="rsmldg:AAALedgerLedger">
         <!-- 085 -->
         <assert test="count(ram:ID) = 1">
            Err 085 : Identifiant du livre comptable <value-of select="ram:Comment"/> manquant
         </assert>
         <!-- 086 -->
         <assert test="count(ram:Comment) = 1">
            Err 086 : Commentaire du livre comptable <value-of select="ram:ID"/> manquant
         </assert>
         <!-- 087 -->
         <assert test="count(ram:IncludedAAALedgerAccountingAccount) > 0">
            Err 087 : compte manquant pour le grand livre <value-of select="ram:ID"/>
         </assert>
         <!-- 090 -->
         <let name="entry-ids" value="distinct-values(ram:IncludedAAALedgerAccountingAccount/ram:IncludedAAALedgerAccountingEntryLine/ram:ConnectedAAALedgerAccountingEntry/ram:ID)"/>
         <let name="comment-count" value="for $e in $entry-ids return count(ram:IncludedAAALedgerAccountingAccount/ram:IncludedAAALedgerAccountingEntryLine[ram:ConnectedAAALedgerAccountingEntry/ram:ID = $e]/ram:Comment) > 0"/>
         <assert test="every $c in $comment-count satisfies $c">
            Err 090 : les écritures <value-of select="for $e in $entry-ids return if (count(ram:IncludedAAALedgerAccountingAccount/ram:IncludedAAALedgerAccountingEntryLine[ram:ConnectedAAALedgerAccountingEntry/ram:ID = $e]/ram:Comment) > 0) then () else $e"/> n'ont pas au moins un commentaire sur une des lignes d'écriture
         </assert>
      </rule>
      <rule context="ram:IncludedAAALedgerAccountingEntryLine">
         <!-- 054 -->
         <assert test="count(ram:CategoryCode) = 1">
            Err 054 : Catégorie d'écriture manquant pour l'écriture <value-of select="../ram:ID"/>
         </assert>
      </rule>
      <rule context="ram:IncludedOriginatorAccountingVoucher">
         <!-- 040 -->
         <assert test="count(ram:RelatedEvidenceDocument) > 0">
            Err 040 : Document (pièce probante) manquant pour le livre comptable <value-of select="../ram:ID"/>
         </assert>
      </rule>
      <rule context="ram:IncludedAAALedgerAccountingAccount">
         <!-- 088 -->
         <assert test="count(ram:ID) > 0">
            Err 088 : Identifiant manquant pour le compte <value-of select="position()"/>
         </assert>
         <!-- 089 -->
         <assert test="count(ram:IncludedAAALedgerAccountingEntryLine) > 0">
            Err 089 : Ligne d'écriture manquante pour le compte <value-of select="ram:ID"/>
         </assert> 
      </rule>
      <rule context="ram:RelatedEvidenceDocument">
         <!-- 041 -->
         <assert test="count(ram:CreationDateTime) = 1">
            Err 041 : Date de la pièce comptable <value-of select="ram:ID"/> manquante
         </assert>
         <!-- 046 -->
         <assert test="count(ram:JustifiedPostedAccountingEntry) > 0">
            Ecriture manquante pour la pièce comptable <value-of select="ram:ID"/>
         </assert>
      </rule>
      <rule context="ram:JustifiedPostedAccountingEntry">
         <!-- 052 -->
         <assert test="count(ram:ID) = 1">
            Err 052 : Identifiant manquant pour une écriture de la pièce <value-of select="../ram:ID"/>
         </assert>
         <!-- 045 -->
         <assert test="count(ram:ValidationDateTime) = 1">
            Err 045 : Date de validation manquante pour <value-of select="ram:ID"/>
         </assert>
         <!-- 048 -->
         <assert test="some $l in ram:DetailedPostedAccountingEntryLine satisfies $l/ram:Comment">
            Err 048 : Aucune des lignes de l'écriture <value-of select="../ram:ID"/> n'a pas de libellé
         </assert>
      </rule>
      <rule context="ram:DetailedPostedAccountingEntryLine">
         <!-- 049 -->
         <assert test="count(ram:CategoryCode) = 1">
            Err 049 : Catégorie d'écriture manquant pour l'écriture <value-of select="../ram:ID"/>
         </assert>
         <!-- 050 -->
         <assert test="count(ram:SpecifiedReferenceAccountingLineIndex) > 0">
            Err 050 : Numéro de ligne dans le document de base pour l'écriture <value-of select="../ram:ID"/> manquant
         </assert>
      </rule>
      <rule context="ram:ConnectedAAALedgerAccountingEntry">
         <!-- 092 -->
         <assert test="count(ram:ID) = 1">
            Err 092 : identifiant manquant pour l'écriture passée le <value-of select="ram:ValueDateDateTime"/>
         </assert>
         <!-- 093 -->
         <assert test="count(ram:ProcessingStatusCode) = 1">
            Err 093 : indicateur de validation de l'écriture <value-of select="ram:ID"/> absent 
         </assert>
         <!-- 094 -->
         <assert test="count(ram:JournalID) = 1">
            Err 094 : code journal absent pour l'écriture <value-of select="ram:ID"/>
         </assert>
         <!-- 095 -->
         <assert test="count(ram:ValueDateDateTime) = 1">
            Err 095 : date de valeur absente pour l'écriture <value-of select="ram:ID"/>
         </assert>
         <!-- 044 -->
         <assert test="count(ram:Purpose) = count(ram:JournalID)">
            Err 044 : libellé du journal obligatoire pour l'écriture <value-of select="ram:ID"/>
         </assert>
         <!-- 096 -->
         <assert test="(ram:ProcessingStatusCode = 1 and count(ram:ValidationDateTime) = 1) or (ram:ProcessingStatusCode != 1 and count(ram:ValidationDateTime) = 0)">
            Err 096 : date de validation incorrecte pour l'écriture <value-of select="ram:ID"/>
         </assert>
         <!-- 097 -->
         <assert test="count(ram:JustificationAAALedgerDocument) = 1">
            Err 097 : document de justification manquant pour l'écriture <value-of select="ram:ID"/>
         </assert>
      </rule>
      <rule context="ramJustificationAAALedgerDocument">
         <!-- 098 -->
         <assert test="count(ram:ID)">
            Err 098 : identifiant du document manquant pour l'écriture <value-of select="../ram:ID"/>
         </assert>
      </rule>
      <rule context="ram:RepeatedAAALedgerMonetaryInstalment">
         <!-- 099 -->
         <assert test="count(ram:PaymentAmount) = 1">
            Err 099 : montant manquant pour l'échéancier
         </assert>
      </rule>
      <rule context="ram:SpecifiedReferenceAccountingLineIndex">
         <!-- 051 -->
         <assert test="count(ram:LineNumeric) = 1">
            Err 051 : Numéro de ligne manquant
         </assert>
      </rule>      
      <rule context="ram:BookingBookedAccountingAccount">
         <!-- 055 -->
         <assert test="count(ram:ID) = 1">
            Err 055 : Numero de compte manquant
         </assert>
      </rule>
      <rule context="ram:RelatedFiscalTax | ram:RelatedAAALedgerTax">
         <!-- 066 -->
         <assert test="count(ram:TypeCode) = 1">
            Err 066 : Type de taxe <value-of select="ram:CalculatedRate"/> manquant
         </assert>
         <!-- 067 -->
         <assert test="count(ram:CalculatedRate) = 1">
            Err 067 : Taux de taxe <value-of select="ram:TypeCode"/> manquant
         </assert>
         <!-- 068 -->
         <assert test="count(ram:CategoryCode) = 1">
            Err 068 : Taux de taxe <value-of select="ram:TypeCode"/> manquant
         </assert>
      </rule>
      <rule context="ram:DerivedLinkedReport | ram:DerivedAAALedgerReport">
         <!-- 069 -->
         <assert test="count(ram:Name) = count(ram:ItemID)">
            Err 069 : Nom ou numéro d'item manquant
         </assert>
      </rule>
   </pattern>
   <pattern>
      <title>Cohérence des totaux de contrôles</title>
      <rule context="ram:SpecifiedAAAWrapAccountingCheck">
         <!-- 033 -->
         <assert test="count(ram:TotalDebitAmount) = 1">
           Err 033 : Total des débits absent (ils ne servent à rien mais leur absence est remarquée)
         </assert>
         <!-- 035 -->
         <assert test="count(ram:TotalCreditAmount) = 1">
           Err 035 : Total des crédits absent (ils ne servent à rien mais leur absence est remarquée)
         </assert>
      </rule>
   </pattern>
   <pattern>
      <title>Identifiant des partenaires de l'échange</title>
      <rule context="ram:AuditAAAWrapOrganization | ram:RepresentativeAAAWrapOrganization | ram:BilledAAAWrapOrganization | ram:PreparerAAAWrapOrganization | ram:OriginatorAAAWrapOrganization | ram:RecipientAAAWrapOrganization | ram:SenderAAAWrapOrganization | ram:OwnerAAAWrapOrganization">
         <!-- 014 -->
         <assert test="count(ram:Name) = 1">
            Err 014 : Nom de l'organisation <value-of select="local-name()"/> manquant
         </assert>
         <!-- 015 -->
         <assert test="count(ram:ID) = 1">
            Err 015 : SIRET/SIREN manquant pour <value-of select="local-name()"/>
         </assert>
         <let name="siretn" value="translate(normalize-space(ram:ID), ' ', '')"/>
         <let name="siretn-len" value="string-length($siretn)"/>
         <!-- 016 -->
         <assert test="$siretn-len = 9 or $siretn-len = 14">
            Err 016 : Longueur du SIRET/SIREN <value-of select="$siretn"/> invalide
         </assert>
         <!-- 017 -->
         <assert test="sum(for $c in (for $i in (1 to $siretn-len) return xs:integer(substring($siretn, $i, 1)) * (if (($siretn-len - $i + 1) mod 2 != 0) then 1 else 2)) return if ($c >= 10) then $c - 9 else $c) mod 10 = 0">
            Err 017 : Code SIRET/SIREN <value-of select="$siretn"/> invalide
         </assert>
         <!-- 018 -->
         <assert test="count(ram:PostalAAAAddress) > 0">
            Err 018 : Adresse postale manquante pour <value-of select="local-name()"/>
         </assert>
         <!-- 019 -->
         <assert test="count(ram:PostalAAAAddress/ram:PostcodeCode) = 1">
            Err 019 : Adresse postale manquante pour <value-of select="local-name()"/>
         </assert>
         <!-- 020 -->
         <assert test="count(ram:PostalAAAAddress/ram:LineOne) = 1">
            Err 020 : Adresse postale manquante pour <value-of select="local-name()"/>
         </assert>
         <!-- 021 -->
         <assert test="count(ram:PostalAAAAddress/ram:CityName) = 1">
            Err 021 : Adresse postale manquante pour <value-of select="local-name()"/>
         </assert>
      </rule>
   </pattern>
   <pattern>
      <title>Cohérence des périodes</title>
      <rule context="ram:SpecifiedAAAPeriod">
         <!-- 028 -->
         <assert test="count(ram:StartDateTime) = 1">
            Err 028 : Date de début de période manquante pour la période se terminant en <value-of select="ram:EndDateTime"/>
         </assert>
         <!-- 029 -->
         <assert test="count(ram:EndDateTime) = 1">
            Err 029 : Date de fin de période manquante pour la période débutant en <value-of select="ram:StartDateTime"/>
         </assert>
         <!-- 031 -->
         <assert test="count(ram:FunctionCode) = 1">
            Err 031 : Code de fonction manquant pour la période <value-of select="ram:StartDateTime"/>-<value-of select="ram:EndDateTime"/>
         </assert>
          <!-- 075 -->
         <assert test="xs:dateTime(ram:EndDateTime) >= xs:dateTime(ram:StartDateTime)">
            Err 075 : Période commence le <value-of select="ram:StartDateTime"/> soit après la fin <value-of select="ram:StartDateTime"/> ! 
         </assert>
      </rule>
   </pattern>
   <pattern>
      <title>Equilibre de l'écriture</title>
      <!-- 047 -->
      <rule context="ram:JustifiedPostedAccountingEntry">
         <let name="debit"  value="ram:DetailedPostedAccountingEntryLine/ram:RelatedPostedAccountingLineMonetaryValue[not(empty(index-of($debitCodes, ram:DebitCreditCode)))]/ram:LocalAccountingCurrencyAmount"/>
         <let name="credit" value="ram:DetailedPostedAccountingEntryLine/ram:RelatedPostedAccountingLineMonetaryValue[not(empty(index-of($creditCodes, ram:DebitCreditCode)))]/ram:LocalAccountingCurrencyAmount"/>
         <assert test="round-half-to-even(sum($debit), 2) = round-half-to-even(sum($credit), 2)">
            Err 047 : Débit (<value-of select="round-half-to-even(sum($debit), 2)"/>) n'est pas égal au crédit (<value-of select="round-half-to-even(sum($credit), 2)"/>) pour l'écriture (<value-of select="ram:ID"/>).
         </assert>
      </rule>
      <!-- 091 -->
      <rule context="ram:IncludedAAALedgerAccountingEntryLine[not(empty(index-of($debitCodes, ram:RelatedAAALedgerAccountingLineMonetaryValue/ram:DebitCreditCode)))]">
         <!-- assez inefficace : on recalcule l'équilibre pour chaque ligne… au lieu de chaque écriture -->
         <!-- mais c'est beaucoup plus lisible/maintenable que de regrouper les écritures distinctes    -->
         <!-- pour atténuez l'inefficacité, on ne fait le contrôles que sur les line de débit           -->
         <!-- bien entendu, le crédit correspondant est vérifié puisqu'on vérifie que débit = crédit    -->
         <let name="entry"  value="ram:ConnectedAAALedgerAccountingEntry/ram:ID"/>
         <let name="debit"  value="../../ram:IncludedAAALedgerAccountingAccount/ram:IncludedAAALedgerAccountingEntryLine[ram:ConnectedAAALedgerAccountingEntry/ram:ID = $entry]/ram:RelatedAAALedgerAccountingLineMonetaryValue[not(empty(index-of($debitCodes, ram:DebitCreditCode)))]/ram:LocalAccountingCurrencyAmount"/>
         <let name="credit" value="../../ram:IncludedAAALedgerAccountingAccount/ram:IncludedAAALedgerAccountingEntryLine[ram:ConnectedAAALedgerAccountingEntry/ram:ID = $entry]/ram:RelatedAAALedgerAccountingLineMonetaryValue[not(empty(index-of($creditCodes, ram:DebitCreditCode)))]/ram:LocalAccountingCurrencyAmount"/>
         <assert test="round-half-to-even(sum($debit), 2) = round-half-to-even(sum($credit), 2)">
            Err 091 : Débit (<value-of select="round-half-to-even(sum($debit), 2)"/>) n'est pas égal au crédit (<value-of select="round-half-to-even(sum($credit), 2)"/>) pour l'écriture (<value-of select="ram:ConnectedAAALedgerAccountingEntry/ram:ID"/>).
         </assert>
      </rule>
   </pattern>
   <pattern>
      <title>Vérification des journaux</title>
      <rule context="ram:JustifiedPostedAccountingEntry | ram:ConnectedAAALedgerAccountingEntry">
         <!-- 043 -->
         <assert test="string-length(ram:JournalID) lt 7">
            Err 043 : Longueur incorrecte pour le numéro de journal
         </assert>
      </rule>
   </pattern>
   <pattern>
      <title>Liste de codes</title>
      <!-- 064 -->
      <let name="account-types" value="'1'"/>
      <rule context="ram:BookingBookedAccountingAccount | ram:IncludedAAALedgerAccountingAccount">
         <assert test="ram:TypeCode = 1">
            Err 064 : Le type de comptabilité est <value-of select="ram:TypeCode"/> mais seul 1 (comptabilité générale) est permis pour le moment
         </assert>
      </rule>
      <rule context="ram:JustifiedPostedAccountingEntry | ram:ConnectedAAALedgerAccountingEntry">
         <!-- 042 -->
         <assert test="ram:ProcessingStatusCode = '1'">
            Err 042 : Ecriture non validée
         </assert>
      </rule>
   </pattern>
   <pattern>
      <title>Code débit/crédit</title>
      <!-- 053 -->
      <rule context="ram:RelatedPostedAccountingLineMonetaryValue | ram:RelatedAAALedgerAccountingLineMonetaryValue">
         <assert test="matches(ram:DebitCreditCode, '29|30|31|32|33|34')">
            Err 053 : Code debit/credit inacceptable <value-of select="ram:DebitCreditCode"/>
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
   <pattern>
      <title>Cohérence des lignes de décomposition</title>
      <!-- 065 -->
      <rule context="ram:DetailedPostedAccountingEntryLine[ram:RepeatedPortionedMonetaryInstalment]">
         <assert test="round-half-to-even(sum(ram:RepeatedPortionedMonetaryInstalment/ram:PaymentAmount), 2) = round-half-to-even(ram:RelatedPostedAccountingLineMonetaryValue/ram:LocalAccountingCurrencyAmount, 2)">
            Err 065 : La somme des lignes de décomposition <value-of select="sum(ram:RepeatedPortionedMonetaryInstalment/ram:PaymentAmount)"/> n'est pas cohérente avec le montant de la ligne <value-of select="ram:RelatedPostedAccountingLineMonetaryValue/ram:LocalAccountingCurrencyAmount"/> pour <value-of select="../ram:ID"/>
         </assert>
      </rule>
      <rule context="ram:IncludedAAALedgerAccountingEntryLine[ram:RepeatedAAALedgerMonetaryInstalment]">
            <assert test="round-half-to-even(sum(ram:RepeatedAAALedgerMonetaryInstalment/ram:PaymentAmount), 2) = round-half-to-even(ram:RelatedAAALedgerAccountingLineMonetaryValue/ram:LocalAccountingCurrencyAmount, 2)">
            Err 065 : La somme des lignes de décomposition <value-of select="sum(ram:RepeatedAAALedgerMonetaryInstalment/ram:PaymentAmount)"/> n'est pas cohérente avec le montant de la ligne <value-of select="ram:RelatedAAALedgerAccountingLineMonetaryValue/ram:LocalAccountingCurrencyAmount"/> pour <value-of select="../ram:ID"/>
         </assert>
      </rule>
   </pattern>
</schema>