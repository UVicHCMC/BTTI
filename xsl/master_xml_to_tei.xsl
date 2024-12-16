<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    exclude-result-prefixes="#all"
    xmlns="http://www.tei-c.org/ns/1.0"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xpath-default-namespace="http://hcmc.uvic.ca/ns"
    xmlns:hcmc="http://hcmc.uvic.ca/ns"
    expand-text="yes"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Nov 30, 2024</xd:p>
            <xd:p><xd:b>Author:</xd:b> mholmes</xd:p>
            <xd:p>This converts the ad-hoc XML structures built from the 
            original TSV files into proper TEI XML files. It runs on itself
            and loads what it needs from disk. The default namespace is the
            hcmc namespace in which the temporary XML versions of the tables
            are expressed.</xd:p>
        </xd:desc>
        <xd:param name="basedir">The project base directory.</xd:param>
    </xd:doc>
    
    <xd:doc>
        <xd:desc>We need some functions.</xd:desc>
    </xd:doc>
    <xsl:include href="module_functions.xsl"/>
    
    <xd:doc>
        <xd:desc>XML in, XML out.</xd:desc>
    </xd:doc>
    <xsl:output method="xml" indent="yes" encoding="UTF-8" 
        normalization-form="NFC" exclude-result-prefixes="#all"/>
    
    <xd:doc>
        <xd:desc>For any tei: elements, we want to behave as though
        this is an identity transform; for any hcmc: elements, we want
        them to survive to the output so that we know that we have failed
        to deal with them correctly.</xd:desc>
    </xd:doc>
    <xsl:mode name="metadata" on-no-match="shallow-copy"/>
    <xsl:mode name="prosopography" on-no-match="shallow-copy"/>
    <xsl:mode name="remediate" on-no-match="shallow-copy"/>
    
    <xd:doc>
        <xd:desc>For clarity, we use a basedir from the Ant build file.</xd:desc>
    </xd:doc>
    <xsl:param name="basedir" as="xs:string" select="'../'"/>
    
    <xd:doc>
        <xd:desc>The collection of ad-hoc XML tables we have created from the TSV.</xd:desc>
    </xd:doc>
    <xsl:variable name="inputFiles" as="document-node()*" select="collection($basedir || '/tempXml/?select=*.xml')"/>
    
    <xd:doc>
        <xd:desc>The template file is used as the basis for the output files.</xd:desc>
    </xd:doc>
    <xsl:variable name="teiTemplate" as="element(tei:TEI)" select="doc($basedir || '/templates/template.xml')//tei:TEI"/>
    
    <xd:doc>
        <xd:desc>The main template runs the whole process.</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:message>Processing {count($inputFiles)} input files into TEI...</xsl:message>
        <xsl:message>Working in base directory {$basedir}</xsl:message>
        
        <!-- First, we'll generate a metadata file with most of the linked items in it. -->
        <xsl:result-document href="{$basedir}/tei/metadata.xml">
            <xsl:apply-templates mode="metadata" select="$teiTemplate"/>
        </xsl:result-document>
        
        <!-- Now we'll generate a collection of files for the personography itself. -->
        <xsl:for-each-group select="$inputFiles//table[@name='tbltradersmain']/body/row"
            group-by="substring(replace(child::cell[2], '^[^A-Z]+', ''), 1, 1)">
            <xsl:sort select="current-grouping-key()"/>
            <xsl:result-document href="{$basedir}/tei/prosopography/prosopography_{lower-case(current-grouping-key())}.xml">
                <xsl:apply-templates mode="prosopography" select="$teiTemplate">
                    <xsl:with-param name="prosRecords" as="element(row)+" select="current-group()" tunnel="yes"/>
                    <xsl:with-param name="currLetter" as="xs:string" select="current-grouping-key()" tunnel="yes"/>
                </xsl:apply-templates>
            </xsl:result-document>
        </xsl:for-each-group>
    </xsl:template>
    
    <!-- ********************** TEMPLATES IN metadata MODE. ********************** -->
    
    <xd:doc>
        <xd:desc>This template matches the placeholder taxonomy elements and 
        generates a range of taxonomy/category structures from the source data.</xd:desc>
    </xd:doc>
    <xsl:template match="tei:taxonomy" mode="metadata">
        <taxonomy xml:id="trades">
            <taxonomy xml:id="tradesPrimary">
                <xsl:apply-templates select="$inputFiles//table[@name='tblprimarytrades']" mode="#current"/>
            </taxonomy>
            <taxonomy xml:id="tradesSecondary">
                <xsl:apply-templates select="$inputFiles//table[@name='tblsecondarytrades']" mode="#current"/>
            </taxonomy>
            <taxonomy xml:id="tradesNonBook">
                <xsl:apply-templates select="$inputFiles//table[@name='tblnonbooktrades']" mode="#current"/>
            </taxonomy>
        </taxonomy>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>This template matches the body element in the metadata mode and
        triggers the output of each of the metadata collections.</xd:desc>
    </xd:doc>
    <xsl:template match="tei:body" mode="metadata">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:apply-templates select="$inputFiles//table[@name='abbreviations']" mode="#current"/>
            <xsl:apply-templates select="$inputFiles//table[@name='tbldatesuffixes']" mode="#current"/>
            <xsl:apply-templates select="$inputFiles//table[@name='feather']" mode="#current"/>
            <xsl:apply-templates select="$inputFiles//table[@name='sourceshtml']" mode="#current"/>
            <xsl:apply-templates select="$inputFiles//table[@name='tblcountries']" mode="#current"/>
            <xsl:apply-templates select="$inputFiles//table[@name='tblcounty']" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>We add a subtitle to the template for the metadata file.</xd:desc>
    </xd:doc>
    <xsl:template match="tei:title[@type='sub']" mode="metadata">
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:sequence select="'Related metadata'"/>
        </xsl:copy>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>The primary trades listing becomes a set of categories. We can ignore the cell[3]
        column ("OK") because it only contains "1".</xd:desc>
    </xd:doc>
    <xsl:template match="table[@name='tblprimarytrades']" mode="metadata">
        <xsl:for-each select="body/row">
            <category xml:id="trdPri{'_' || normalize-space(cell[1])}">
                <desc><xsl:sequence select="normalize-space(cell[2])"/></desc>
                <gloss type="class"><xsl:value-of select="cell[4]"/></gloss>
            </category>
        </xsl:for-each>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>The secondary and non-book trades listings become sets of categories.</xd:desc>
    </xd:doc>
    <xsl:template match="table[@name=('tblsecondarytrades', 'tblnonbooktrades')]" mode="metadata">
        <xsl:variable name="idPrefix" as="xs:string" select="if (@name eq 'tblsecondarytrades') then 'trdSec' else 'trdNonBk'"/>
        <xsl:for-each select="body/row">
            <category xml:id="{$idPrefix || '_' || normalize-space(cell[1])}">
                <desc><xsl:sequence select="normalize-space(cell[2])"/></desc>
            </category>
        </xsl:for-each>
    </xsl:template>
    
    
    <xd:doc>
        <xd:desc>We convert the abbreviations into a list.</xd:desc>
    </xd:doc>
    <xsl:template match="table[@name='abbreviations']" mode="metadata">
        <list type="abbreviations">
            <xsl:for-each select="body/row">
                <item>
                    <choice xml:id="abbr_{cell[1]/text()}">
                        <abbr><xsl:value-of select="cell[2]"/></abbr>
                        <expan><xsl:value-of select="replace(cell[3], '&lt;.+&gt;\s*$', '')"/></expan>
                    </choice>
                    <xsl:if test="matches(cell[3], '&lt;.+&gt;')">
                        <note type="internal">Original expansion was followed by <q><xsl:value-of select="replace(cell[3], '.+(&lt;.+&gt;\s*)$', '$1')"/></q>.</note>
                    </xsl:if>
                </item>
            </xsl:for-each>
        </list>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>We convert the date suffix abbreviations into a list.</xd:desc>
    </xd:doc>
    <xsl:template match="table[@name='tbldatesuffixes']" mode="metadata">
        <list type="dateSuffixes">
            <xsl:for-each select="body/row">
                <item>
                    <choice xml:id="dateSuff_{position()}">
                        <abbr><xsl:value-of select="cell[1]"/></abbr>
                        <expan><xsl:value-of select="cell[2]"/></expan>
                    </choice>
                </item>
            </xsl:for-each>
        </list>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>We convert the "Feather" bibliography into a listBibl.</xd:desc>
    </xd:doc>
    <xsl:template match="table[@name='feather']" mode="metadata">
        <listBibl xml:id="feather" source="src:feather"><!-- Add a proper pointer to a usable source. -->
            <xsl:for-each select="body/row">
                <bibl xml:id="feather_{cell[1]}">
                    <author>
                        <xsl:choose>
                            <xsl:when test="cell[2] eq 'NULL'"/>
                            <xsl:when test="matches(cell[2], '^\s*-\s*$')">
                                <xsl:value-of select="parent::row/preceding-sibling::row[cell[2][not(matches(., '^\s*-\s*$'))]]/cell[2]/normalize-space(.)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="normalize-space(cell[2])"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </author>
                    <title><xsl:value-of select="normalize-space(cell[3])"/></title>
                    <bibl type="publication"><xsl:value-of select="normalize-space(cell[4])"/></bibl>
                    <xsl:if test="not(cell[6] eq 'NULL')">
                        <orgName><xsl:value-of select="normalize-space(cell[6])"/></orgName>
                    </xsl:if>
                    <xsl:if test="not(cell[7] eq 'NULL')">
                        <pubPlace><placeName><xsl:value-of select="normalize-space(cell[7])"/></placeName></pubPlace>
                    </xsl:if>
                    <idno type="Feather"><xsl:value-of select="cell[8]"/></idno>
                    <xsl:if test="not(cell[5] eq 'NULL')">
                        <note><xsl:value-of select="normalize-space(cell[5])"/></note>
                    </xsl:if>
                </bibl>
            </xsl:for-each>
        </listBibl>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>We convert the HTML sources table into a listBibl.</xd:desc>
    </xd:doc>
    <xsl:template match="table[@name='sourceshtml']" mode="metadata">
        <listBibl xml:id="sourceshtml" source="src:sourceshtml"><!-- Add a proper pointer to a usable source. -->
            <xsl:for-each select="body/row">
                <bibl xml:id="srch_{replace(cell[1], '[\s/\+&amp;\(\)\*]+', '_')}" n="{cell[1]}">
                    <xsl:apply-templates select="hcmc:embeddedMarkupToTei(normalize-space(hcmc:fixEncoding(cell[2])))" mode="remediate">
                        <xsl:with-param name="ancestorTableName" as="xs:string" select="'sourceshtml'" tunnel="yes"/>
                    </xsl:apply-templates>
                    <xsl:if test="not(cell[3] eq 'NULL')">
                        <note type="unknownField"><xsl:value-of select="normalize-space(cell[3])"/></note>
                    </xsl:if>
                    <xsl:if test="not(cell[4] eq 'NULL')">
                        <note type="unknownField"><xsl:value-of select="normalize-space(cell[4])"/></note>
                    </xsl:if>
                </bibl>
            </xsl:for-each>
        </listBibl>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>We convert countries into a listPlace.</xd:desc>
    </xd:doc>
    <xsl:template match="table[@name='tblcountries']" mode="metadata">
        <listPlace xml:id="countries">
            <xsl:for-each select="body/row">
                <place xml:id="country_{position()}">
                    <placeName><xsl:sequence select="normalize-space(cell[2])"/></placeName>
                    <idno type="BBTI"><xsl:sequence select="normalize-space(cell[1])"/></idno>
                    <idno type="ISO-3166"><xsl:sequence select="normalize-space(cell[3])"/></idno>
                </place>
            </xsl:for-each>
        </listPlace>
    </xsl:template>
    
    
    <xd:doc>
        <xd:desc>We convert counties into a listPlace.</xd:desc>
    </xd:doc>
    <xsl:template match="table[@name='tblcounty']" mode="metadata">
        <listPlace xml:id="counties">
            <xsl:for-each select="body/row">
                <place xml:id="county_{position()}">
                    <placeName><xsl:sequence select="normalize-space(cell[2])"/></placeName>
                    <country><idno type="ISO-3166"><xsl:sequence select="normalize-space(cell[3])"/></idno></country>
                    <idno type="BBTI"><xsl:sequence select="normalize-space(cell[1])"/></idno>
                    <xsl:variable name="ISO-3166" as="xs:string" select="normalize-space(cell[4])"/>
                    <xsl:variable name="ISO-3166_Deleted" as="xs:string" select="normalize-space(cell[6])"/>
                    <xsl:variable name="Chapman" as="xs:string" select="normalize-space(cell[5])"/>
                    <xsl:variable name="note" as="xs:string" select="normalize-space(cell[7])"/>
                    <xsl:if test="$ISO-3166 ne ''">
                        <idno type="ISO-3166"><xsl:sequence select="$ISO-3166"/></idno>
                    </xsl:if>
                    <xsl:if test="$ISO-3166_Deleted ne ''">
                        <idno type="ISO-3166_Deleted"><xsl:sequence select="$ISO-3166_Deleted"/></idno>
                    </xsl:if>
                    <xsl:if test="$Chapman ne ''">
                        <idno type="Chapman"><xsl:sequence select="$Chapman"/></idno>
                    </xsl:if>
                    <xsl:if test="$note ne ''">
                        <note><xsl:sequence select="$note"/></note>
                    </xsl:if>
                </place>
            </xsl:for-each>
        </listPlace>
    </xsl:template>
    
    
    <!-- ******************* TEMPLATES IN remediate MODE ******************** -->
    <!--  These templates take interim generated TEI and attempt to convert them into something better.  -->
    
    <xd:doc>
        <xd:desc>This matches various attribute values </xd:desc>
        <xd:param name="ancestorTableName" as="xs:string" tunnel="yes">This tells us what the context
        of the incoming item is, so that we can guess the most likely semantic reason for e.g. italicizing
        content, and supply the appropriate TEI tag.</xd:param>
    </xd:doc>
    <xsl:template match="tei:hi[@n]" mode="remediate">
        <xsl:param name="ancestorTableName" as="xs:string" tunnel="yes"/>
        <xsl:choose>
            <xsl:when test="@n='EM' and $ancestorTableName eq 'sourceshtml'">
                <title style="font-style: italic;"><xsl:apply-templates mode="#current"/></title>
            </xsl:when>
            <xsl:otherwise>
                <xsl:next-match/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    
    <!-- ********************** TEMPLATES IN prosopography MODE. ********************** -->
    
    <xd:doc>
        <xd:desc>Things to suppress in prosopography mode.</xd:desc>
    </xd:doc>
    <xsl:template match="tei:taxonomy | tei:classDecl[normalize-space(.) eq ''] | tei:encodingDesc[normalize-space(.) eq '']" mode="prosopography"/>
    
    <xd:doc>
        <xd:desc>We put the prosopography records in the body.</xd:desc>
        <xd:param name="prosRecords" as="element(row)+" tunnel="yes">The rows of data for the currentr letter.</xd:param>
        <xd:param name="currLetter" as="xs:string" tunnel="yes">The current name first-letter we're creating a file for.</xd:param>
    </xd:doc>
    <xsl:template match="tei:body" mode="prosopography">
        <xsl:param name="prosRecords" as="element(row)+" tunnel="yes"/>
        <xsl:param name="currLetter" as="xs:string" tunnel="yes"/>
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:message expand-text="yes">Processing {count($prosRecords)} records for letter {$currLetter}.</xsl:message>
            <listPerson>
                <head>Traders for letter <xsl:value-of select="$currLetter"/></head>
                <xsl:for-each select="$prosRecords">
                    <xsl:sort select="normalize-space(lower-case(replace(child::cell[2], '^[^A-Z]+', '')))"/>
                    <xsl:sort select="normalize-space(lower-case(replace(child::cell[3], '^[^A-Z]+', '')))"/>
                    <person xml:id="prs_{cell[1]}">
                        <xsl:comment>More to come here.</xsl:comment>
                    </person>
                </xsl:for-each>
            </listPerson>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>