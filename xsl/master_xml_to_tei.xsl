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
    <xsl:mode name="orgography" on-no-match="shallow-copy"/>
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
        <xd:desc>We need a map for faster lookup of trades.</xd:desc>
    </xd:doc>
    <xsl:variable name="mapTraderIdToPrimaryTrades" as="map(xs:string, element(tei:state)+)">
        <xsl:map>
            <xsl:for-each-group select="$inputFiles//table[@name='tbltraderid_booktrade']/body/row" group-by="xs:string(cell[5])">
                <xsl:map-entry key="current-grouping-key()">
                    <xsl:for-each select="current-group()">
                        <state type="primaryTrade" corresp="trd:trdPri_{cell[4]}">
                            <xsl:if test="cell[3] ne 'NULL'"><xsl:attribute name="subtype" select="normalize-space(cell[3])"/></xsl:if>
                            <xsl:if test="cell[2] eq '1'"><xsl:attribute name="cert" select="'low'"/></xsl:if>
                        </state>
                    </xsl:for-each>
                </xsl:map-entry>
            </xsl:for-each-group>
        </xsl:map>
    </xsl:variable>
    
    <xd:doc>
        <xd:desc>We also need a map to secondary trades, and it looks like those exist
        in two distinct locations, the original booktrades file and the secondary file.
        This makes things a bit awkward.</xd:desc>
    </xd:doc>
    <xsl:variable name="mapTraderIdToSecondaryTrades" as="map(xs:string, element(tei:state)+)">
        <xsl:map>
            <xsl:for-each-group select="$inputFiles//table[@name='tblbooktradetraderid_secondarytradeid']/body/row" group-by="xs:string(cell[2])">
                <xsl:map-entry key="current-grouping-key()">
                    <xsl:for-each select="current-group()">
                        <state type="secondaryTrade" corresp="trd:trdSec_{cell[3]}"/>
                    </xsl:for-each>
                </xsl:map-entry>
            </xsl:for-each-group>
            
            <!-- To avoid duplicate keys, we prefix all the entries created from the primary linking
                table, which also includes some secondary links, with 'fromPri_'. -->
            <xsl:for-each-group select="$inputFiles//table[@name='tbltraderid_booktrade']/body/row[not(cell[6] = 'NULL')]" group-by="xs:string(cell[5])">
                <xsl:map-entry key="'fromPri_' || current-grouping-key()">
                    <xsl:for-each select="current-group()">
                        <state type="secondaryTrade" corresp="trd:trdSec_{cell[6]}"/>
                    </xsl:for-each>
                </xsl:map-entry>
            </xsl:for-each-group>
            
        </xsl:map>
    </xsl:variable>
    
    <xd:doc>
        <xd:desc>We need a map for faster lookup of non-book-trades.</xd:desc>
    </xd:doc>
    <xsl:variable name="mapTraderIdToNonBookTrades" as="map(xs:string, element(tei:state)+)">
        <xsl:map>
            <xsl:for-each-group select="$inputFiles//table[@name='tbltraderid_nonbooktrade']/body/row" group-by="xs:string(cell[4])">
                <xsl:map-entry key="current-grouping-key()">
                    <xsl:for-each select="current-group()">
                        <state type="nonBookTrade" corresp="trd:trdNonBk_{cell[3]}"><label><xsl:sequence select="normalize-space(cell[2]/text())"/></label></state>
                    </xsl:for-each>
                </xsl:map-entry>
            </xsl:for-each-group>
        </xsl:map>
    </xsl:variable>
    
    <xd:doc>
        <xd:desc>We need a map for the sources for trader info.</xd:desc>
    </xd:doc>
    <xsl:variable name="mapTraderIdToSourceBibls" as="map(xs:string, element(tei:bibl)+)">
        <xsl:map>
            <xsl:for-each-group select="$inputFiles//table[@name='tbltraderid_sourcecode']/body/row[not(cell[3] eq 'NULL')]" group-by="xs:string(cell[2])">
                <xsl:map-entry key="current-grouping-key()">
                    <xsl:for-each select="current-group()">
                        <bibl type="source" corresp="src:srch_{hcmc:bbtiKeyToId(cell[3])}"><idno type="BBTI"><xsl:sequence select="normalize-space(cell[3]/text())"/></idno>.
                            <xsl:if test="cell[4]/text() and cell[4]/text() ne 'NULL'"><biblScope><xsl:sequence select="normalize-space(cell[4]/text())"/></biblScope></xsl:if>
                            <xsl:if test="cell[5]/text() and cell[5]/text() ne 'NULL'"><note><xsl:sequence select="normalize-space(cell[5]/text())"/></note></xsl:if>
                        </bibl>
                    </xsl:for-each>
                </xsl:map-entry>
            </xsl:for-each-group>
        </xsl:map>
    </xsl:variable>
    
    <xd:doc>
        <xd:desc>Because of the weird way that feather authors are handled, we need to use an accumulator
        to keep track of which author we have.</xd:desc>
    </xd:doc>
    <xsl:accumulator name="featherAuthor" as="xs:string" initial-value="''">
        <xsl:accumulator-rule match="table[@name='feather']/body/row/cell[2]" select="if (not(matches(normalize-space(.), '^(NULL|-)$'))) then normalize-space(.) else $value"/>
    </xsl:accumulator>
    
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
            <xsl:result-document href="{$basedir}/tei/orgography/orgography_{lower-case(current-grouping-key())}.xml">
                <xsl:apply-templates mode="orgography" select="$teiTemplate">
                    <xsl:with-param name="orgRecords" as="element(row)+" select="current-group()" tunnel="yes"/>
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
                    <author><xsl:sequence select="accumulator-after('featherAuthor')"/></author>
                    <!--<author>
                        <xsl:choose>
                            <xsl:when test="cell[2] eq 'NULL'"/>
                            <xsl:when test="matches(cell[2], '^\s*-\s*$')">
                                <xsl:value-of select="parent::row/preceding-sibling::row[cell[2][not(matches(., '^\s*-\s*$'))]]/cell[2]/normalize-space(.)"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="normalize-space(cell[2])"/>
                            </xsl:otherwise>
                        </xsl:choose>
                    </author>-->
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
                <bibl xml:id="srch_{hcmc:bbtiKeyToId(cell[1])}" n="{cell[1]}">
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
    
    
    <!-- ********************** TEMPLATES IN orgography MODE. ********************** -->
    
    <xd:doc>
        <xd:desc>Things to suppress in orgography mode.</xd:desc>
    </xd:doc>
    <xsl:template match="tei:taxonomy | tei:classDecl[normalize-space(.) eq ''] | tei:encodingDesc[normalize-space(.) eq '']" mode="orgography"/>
    
    <xd:doc>
        <xd:desc>We put the orgography records in the body.</xd:desc>
        <xd:param name="orgRecords" as="element(row)+" tunnel="yes">The rows of data for the current letter.</xd:param>
        <xd:param name="currLetter" as="xs:string" tunnel="yes">The current name first-letter we're creating a file for.</xd:param>
    </xd:doc>
    <xsl:template match="tei:body" mode="orgography">
        <xsl:param name="orgRecords" as="element(row)+" tunnel="yes"/>
        <xsl:param name="currLetter" as="xs:string" tunnel="yes"/>
        <xsl:copy>
            <xsl:apply-templates select="@*" mode="#current"/>
            <xsl:message expand-text="yes">Processing {count($orgRecords)} records for letter {$currLetter}.</xsl:message>
            <listOrg>
                <head>Traders for letter <xsl:value-of select="$currLetter"/></head>
                <xsl:for-each select="$orgRecords">
                    <xsl:sort select="normalize-space(lower-case(replace(child::cell[2], '^[^A-Z]+', '')))"/>
                    <xsl:sort select="normalize-space(lower-case(replace(child::cell[3], '^[^A-Z]+', '')))"/>
                    <xsl:variable name="currId" as="xs:string" select="xs:string(cell[1])"/>
                    <org xml:id="org_{cell[1]}">
                        
                        <!-- Names are horrible because surname and forename fields have been abused in
                             inconsistent ways to encode company names. We have to do the best we can. -->
                        
                        <orgName>
                            <xsl:choose>
                                <xsl:when test="xs:string(cell[3]) eq 'NULL'">
                                    <!-- Probably a pure org name. -->
                                    <xsl:sequence select="normalize-space(hcmc:fixEncoding(cell[2]))"/>
                                </xsl:when>
                                <xsl:when test="matches(cell[2], '&amp;\s*$')">
                                    <!-- Again, probably a pure org name split across the two fields. -->
                                    <xsl:sequence select="normalize-space(hcmc:fixEncoding(string-join((cell[2], cell[3]), ' ')))"/>
                                </xsl:when>
                                <xsl:otherwise>
                                    <persName>
                                        <surname><xsl:sequence select="normalize-space(hcmc:fixEncoding(cell[2]))"/></surname>
                                        <forename><xsl:sequence select="normalize-space(hcmc:fixEncoding(cell[3]))"/></forename>
                                        
                                    </persName>
                                </xsl:otherwise>
                            </xsl:choose>
                        </orgName>
                        
                        <!-- Next is the weird collection of date info -->
                        <xsl:variable name="dateStates" as="element(tei:state)*">
                            <xsl:sequence select="hcmc:renderDateAsState(xs:string(cell[4]), 
                                xs:string(cell[5]),
                                'bioStart')"/>
                            
                            <xsl:sequence select="hcmc:renderDateAsState(xs:string(cell[6]), 
                                xs:string(cell[7]), 
                                'bioEnd')"/>
                            
                            <xsl:sequence select="hcmc:renderDateAsState(xs:string(cell[10]), 
                                xs:string(cell[11]), 
                                'tradeStart')"/>
                            
                            <xsl:sequence select="hcmc:renderDateAsState(xs:string(cell[12]), 
                                xs:string(cell[13]), 
                                'tradeEnd')"/>
                        </xsl:variable>
                        <xsl:if test="count($dateStates) gt 0">
                            <state type="dateStates">
                                <xsl:for-each select="$dateStates">
                                    <xsl:sequence select="."/>
                                </xsl:for-each>
                            </state>
                        </xsl:if>
                        
                        <location>
                            <address>
                                <xsl:if test="cell[9] ne 'NULL'">
                                    <addrLine><xsl:sequence select="normalize-space(hcmc:fixEncoding(cell[9]))"/></addrLine>
                                </xsl:if>
                                <xsl:if test="cell[8] ne 'NULL'">
                                    <settlement><xsl:sequence select="normalize-space(hcmc:fixEncoding(cell[8]))"/></settlement>
                                </xsl:if>
                                <xsl:if test="cell[17] ne 'NULL'">
                                    <region><xsl:sequence select="normalize-space(hcmc:fixEncoding(cell[17]))"/></region>
                                </xsl:if>
                                <xsl:if test="cell[16] ne 'NULL'">
                                    <country><xsl:sequence select="normalize-space(hcmc:fixEncoding(cell[16]))"/></country>
                                </xsl:if>
                            </address>
                        </location>
                        
                        <xsl:sequence select="map:get($mapTraderIdToPrimaryTrades, $currId)"/>
                        <!-- The secondary case is awkward because this info is stored in two distinct 
                             tables. -->
                        <xsl:variable name="secStates" as="element(tei:state)*" 
                            select="(map:get($mapTraderIdToSecondaryTrades, $currId), map:get($mapTraderIdToSecondaryTrades, 'fromPri_' || $currId))"/>
                        <xsl:for-each-group select="$secStates" group-by="concat(@type, @corresp, if (@subtype) then @subtype else '')">
                            <xsl:sequence select="current-group()[1]"/>
                        </xsl:for-each-group>
                        <xsl:sequence select="map:get($mapTraderIdToNonBookTrades, $currId)"/>
                        
                        <!-- Not using this; it's always null or empty. -->
                        <!--<xsl:if test="cell[15] ne 'NULL'">
                            <bibl><xsl:sequence select="normalize-space(hcmc:fixEncoding(cell[15]))"/></bibl>
                        </xsl:if>-->
                        
                        <xsl:sequence select="map:get($mapTraderIdToSourceBibls, $currId)"/>
                        
                        <xsl:if test="cell[14] ne 'NULL'">
                            <note><xsl:sequence select="normalize-space(hcmc:fixEncoding(cell[14]))"/></note>
                        </xsl:if>
                    </org>
                </xsl:for-each>
            </listOrg>
        </xsl:copy>
    </xsl:template>
</xsl:stylesheet>