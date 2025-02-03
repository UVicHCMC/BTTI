<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    exclude-result-prefixes="#all"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xh="http://www.w3.org/1999/xhtml"
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    xmlns:hcmc="http://hcmc.uvic.ca/ns"
    expand-text="yes"
    version="3.0">
    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Dec 17, 2024</xd:p>
            <xd:p><xd:b>Author:</xd:b> mholmes</xd:p>
            <xd:p>This runs a range of diagnostic checks against the TEI 
            XML to find broken pointers, bad links, and other oddities.</xd:p>
        </xd:desc>
    </xd:doc>
    
    <xd:doc>
        <xd:desc>We're producing XHTML5.</xd:desc>
    </xd:doc>
    <xsl:output method="xhtml" html-version="5" encoding="UTF-8" omit-xml-declaration="yes"
        normalization-form="NFC" indent="yes" exclude-result-prefixes="#all" include-content-type="no"/>
    
    <xd:doc>
        <xd:desc>For clarity, we use a basedir from the Ant build file.</xd:desc>
    </xd:doc>
    <xsl:param name="baseDir" as="xs:string" select="'..'"/>
    
    <xd:doc>
        <xd:desc>Set this param to limit the run to a single diagnostic.</xd:desc>
    </xd:doc>
    <xsl:param name="runOnly" as="xs:string" select="''"/>
    
    <xd:doc scope="component">
        <xd:desc><xd:ref name="docRoot">docRoot</xd:ref> is needed in various contexts where the input
            document is out of scope.</xd:desc>
    </xd:doc>
    <xsl:variable name="docRoot" select="/"/>
    
    <xd:doc>
        <xd:desc>This is the TEI source XML.</xd:desc>
    </xd:doc>
    <xsl:variable name="teiSource" as="document-node()+" select="collection($baseDir || '/tei/?select=*.xml;recurse=yes')"/>
    
    <xd:doc>
        <xd:desc>We need the maps file.</xd:desc>
    </xd:doc>
    <xsl:include href="module_tei_maps.xsl"/>
    <xsl:include href="module_html_functions.xsl"/>
    
    <xd:doc>
        <xd:desc>Captions used.</xd:desc>
    </xd:doc>
    <xsl:variable name="capNoneFound" as="xs:string" select="'None found.'"/>
    
    <xd:doc>
        <xd:desc>The root template calls each of the individual diagnostic processes.</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:message>Running diagnostics...</xsl:message>
        
        <xsl:result-document href="{$baseDir}/site/diagnostics.html">
            <html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en" id="diagnostics">
                <head>
                    <title>BBTI Project Diagnostics</title>
                    <link rel="stylesheet" href="css/diagnostics.css"/>
                </head>
                <body>
                    <header>
                        <h1>BBTI Project Diagnostics</h1>
                    </header>
                    
                    <main>
                        <!-- Run everything, or just selected items? -->
                        <xsl:choose>
                            <xsl:when test="$runOnly = ''">
                                <xsl:call-template name="statistics"/>
                                <xsl:call-template name="checkPointersToSources"/>
                                <xsl:call-template name="checkPointersToCounties"/>
                                <xsl:call-template name="checkPointersToCountries"/>
                                <xsl:call-template name="citiesInMultipleCounties"/>
                                <xsl:call-template name="citiesInNoCounty"/>
                                <xsl:call-template name="checkDateSuffixes"/>
                                <xsl:call-template name="checkForOldHtml"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <!-- Run only the one(s) that are being called. -->
                                <xsl:for-each select="tokenize($runOnly, '\s*,\s*')">
                                    <xsl:variable name="templateName" as="xs:string" select="."/>
                                    <xsl:apply-templates select="$docRoot//xsl:template[@name = $templateName]"/>
                                </xsl:for-each>
                            </xsl:otherwise>
                        </xsl:choose>
                    </main>
                </body>
            </html>
        </xsl:result-document>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>This template checks the list of pointers from org records to sources,
        to ensure that the source pointed at actually exists.</xd:desc>
    </xd:doc>
    <xsl:template name="checkPointersToSources" match="xsl:template[@name='checkPointersToSources']">
        <xsl:variable name="idsFromPointers" as="xs:string+" select="distinct-values(($teiSource//org/bibl[@type='source']/substring-after(@corresp, 'src:')))"/>
        <xsl:message>Checking {count($idsFromPointers)} pointers against source xml:ids.</xsl:message>
        
        <xsl:variable name="issues" as="element(xh:li)*">
            <xsl:for-each select="$idsFromPointers[not (. = $mainSourceIds)]">
                <li>There is at least one pointer to {.}, but no source reference with that id exists.</li>
            </xsl:for-each>
        </xsl:variable>
        <xsl:call-template name="createDetails">
            <xsl:with-param name="id" select="'checkPointersToSources'"/>
            <xsl:with-param name="count" select="count($issues)"/>
            <xsl:with-param name="title" select="'Broken pointers to bibliographical sources'"/>
            <xsl:with-param name="explanation" as="item()*">
                The @corresp attribute in a bibl[@type='source'] in a trader org should point to 
                the id of a source reference in the metadata file.
            </xsl:with-param>
            <xsl:with-param name="content">
                <xsl:choose>
                    <xsl:when test="count($issues) gt 0">
                        <ul>
                            <xsl:sequence select="$issues"/>
                        </ul>
                    </xsl:when>
                    <xsl:otherwise>
                        <p><xsl:sequence select="$capNoneFound"/></p>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>This template checks for any remaining old-style HTML tags that have persisted 
            in the data, because they were ill-formed and therefore not converted to title 
            elements in TEI.</xd:desc>
    </xd:doc>
    <xsl:template name="checkForOldHtml" match="xsl:template[@name='checkForOldHtml']">
        <xsl:variable name="oldHtmlTags" as="node()*" select="$teiSource//text()[matches(., '&lt;/?[a-zA-Z\s]+/?&gt;')]"/>
        <xsl:message>Checking for old HTML tags persisting into the TEI XML.</xsl:message>
        
        <xsl:variable name="issues" as="element(xh:li)*">
            <xsl:for-each-group select="$oldHtmlTags" group-by="ancestor::*[@xml:id][1]/@xml:id">
                <li>The item with id <a href="orgs/{current-grouping-key()}.html"><xsl:value-of select="current-grouping-key()"/></a> contains unconverted HTML tags.</li>
            </xsl:for-each-group>
        </xsl:variable>
        <xsl:call-template name="createDetails">
            <xsl:with-param name="id" select="'checkForOldHtml'"/>
            <xsl:with-param name="count" select="count($issues)"/>
            <xsl:with-param name="title" select="'Old HTML tags not converted to TEI'"/>
            <xsl:with-param name="explanation" as="item()*">
                Normally old HTML tags in the source spreadsheets are converted automatically to 
                TEI tags, but if they are ill-formed, they may not be.
            </xsl:with-param>
            <xsl:with-param name="content">
                <xsl:choose>
                    <xsl:when test="count($issues) gt 0">
                        <ul>
                            <xsl:sequence select="$issues"/>
                        </ul>
                    </xsl:when>
                    <xsl:otherwise>
                        <p><xsl:sequence select="$capNoneFound"/></p>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>This template checks the list of pointers from org records to counties,
            to ensure that the place pointed at actually exists.</xd:desc>
    </xd:doc>
    <xsl:template name="checkPointersToCounties" match="xsl:template[@name='checkPointersToCounties']">
        <xsl:variable name="idsFromPointers" as="xs:string+" select="distinct-values(($teiSource//org/location/address/region))"/>
        <xsl:message>Checking {count($idsFromPointers)} pointers against county keys.</xsl:message>
        
        <xsl:variable name="issues" as="element(xh:li)*">
            <xsl:for-each select="$idsFromPointers[not (. = $countyIds)]">
                <li>There is at least one pointer to {.}, but no county with that id exists.</li>
            </xsl:for-each>
        </xsl:variable>
        <xsl:call-template name="createDetails">
            <xsl:with-param name="id" select="'checkPointersToCounties'"/>
            <xsl:with-param name="count" select="count($issues)"/>
            <xsl:with-param name="title" select="'Broken pointers to counties'"/>
            <xsl:with-param name="explanation" as="item()*">
                The region element in an org/location should contain the text key which 
                is the BBTI abbreviation/key for a historical county in the metadata file.
            </xsl:with-param>
            <xsl:with-param name="content">
                <xsl:choose>
                    <xsl:when test="count($issues) gt 0">
                        <ul>
                            <xsl:sequence select="$issues"/>
                        </ul>
                    </xsl:when>
                    <xsl:otherwise>
                        <p><xsl:sequence select="$capNoneFound"/></p>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>This template checks the list of pointers from org records to countries,
            to ensure that the place pointed at actually exists.</xd:desc>
    </xd:doc>
    <xsl:template name="checkPointersToCountries" match="xsl:template[@name='checkPointersToCountries']">
        <xsl:variable name="idsFromPointers" as="xs:string+" select="distinct-values(($teiSource//org/location/address/country))"/>
        <xsl:message>Checking {count($idsFromPointers)} pointers against country xml:ids.</xsl:message>
        
        <xsl:variable name="issues" as="element(xh:li)*">
            <xsl:for-each select="$idsFromPointers[not (. = $countryIds)]">
                <li>There is at least one pointer to {.}, but no county with that id exists.</li>
            </xsl:for-each>
        </xsl:variable>
        <xsl:call-template name="createDetails">
            <xsl:with-param name="id" select="'checkPointersToCountries'"/>
            <xsl:with-param name="count" select="count($issues)"/>
            <xsl:with-param name="title" select="'Broken pointers to countries'"/>
            <xsl:with-param name="explanation" as="item()*">
                The country element in an org/location should contain the text key which 
                is the BBTI abbreviation/key for a country in the metadata file.
            </xsl:with-param>
            <xsl:with-param name="content">
                <xsl:choose>
                    <xsl:when test="count($issues) gt 0">
                        <ul>
                            <xsl:sequence select="$issues"/>
                        </ul>
                    </xsl:when>
                    <xsl:otherwise>
                        <p><xsl:sequence select="$capNoneFound"/></p>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>This template checks the list of date suffixes appearing in 
            state/@subtypes against the abbreviation list from which they're 
            supposed to be derived.</xd:desc>
    </xd:doc>
    <xsl:template name="checkDateSuffixes" match="xsl:template[@name='checkDateSuffixes']">
        <xsl:variable name="idsFromPointers" as="xs:string+" select="distinct-values(($teiSource//org//state[@type = ('bioStart', 'bioEnd', 'tradeStart', 'tradeEnd')]/@n))"/>
        <xsl:message>Checking {count($idsFromPointers)} pointers against the list of date suffix abbreviations.</xsl:message>
        
        <xsl:variable name="issues" as="element(xh:li)*">
            <xsl:for-each select="$idsFromPointers[not (. = $dateSuffixes)]">
                <li>There is at least one pointer to date suffix {.}, but no such suffix exists.</li>
            </xsl:for-each>
        </xsl:variable>
        <xsl:call-template name="createDetails">
            <xsl:with-param name="id" select="'checkDateSuffixes'"/>
            <xsl:with-param name="count" select="count($issues)"/>
            <xsl:with-param name="title" select="'Broken date suffixes'"/>
            <xsl:with-param name="explanation" as="item()*">
                The state element in org may carry the @subtype attribute, which captures
                the date suffix originally applied, where that suffix related to the 
                evidence or source or event type to which the date is relevant. The value
                in this attribute should be one of the abbreviations defined in the date
                suffix list.
            </xsl:with-param>
            <xsl:with-param name="content">
                <xsl:choose>
                    <xsl:when test="count($issues) gt 0">
                        <ul>
                            <xsl:sequence select="$issues"/>
                        </ul>
                    </xsl:when>
                    <xsl:otherwise>
                        <p><xsl:sequence select="$capNoneFound"/></p>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>This template checks the list of settlements to report any that have been located in 
        more than one county.</xd:desc>
    </xd:doc>
    <xsl:template name="citiesInMultipleCounties" match="xsl:template[@name='citiesInMultipleCounties']">
        <xsl:message>Checking for settlements located in more than one county.</xsl:message>
        
        <xsl:variable name="issues" as="element(xh:li)*">
            <xsl:for-each select="map:keys($mapCityNamesToCountyKeys)">
                <xsl:variable name="cityName" select="."/>
                <xsl:variable name="countyKeys" as="xs:string*" select="map:get($mapCityNamesToCountyKeys, $cityName)"/>
                <xsl:if test="count($countyKeys) gt 1">
                    <li>The town or city <strong>{$cityName}</strong> is listed as in the following counties:
                        <ul>
                            <xsl:for-each select="$countyKeys">
                                <li><xsl:sequence select="map:get($mapCountyKeysToStrings, .)"/></li>
                            </xsl:for-each>
                        </ul>
                    </li>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="sortedIssues" as="element(xh:li)*">
            <xsl:for-each select="$issues">
                <xsl:sort select="normalize-space(lower-case(.))"/>
                <xsl:sequence select="."/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:call-template name="createDetails">
            <xsl:with-param name="id" select="'citiesInMultipleCounties'"/>
            <xsl:with-param name="count" select="count($sortedIssues)"/>
            <xsl:with-param name="title" select="'Towns/cities listed in multiple counties'"/>
            <xsl:with-param name="explanation" as="item()*">
                A town, city, or or other settlement would normally appear in only one county; these
                are exceptions. They may not be errors, since there are duplicate placenames and 
                county boundaries do change.
            </xsl:with-param>
            <xsl:with-param name="content">
                <xsl:choose>
                    <xsl:when test="count($sortedIssues) gt 0">
                        <ul>
                            <xsl:sequence select="$sortedIssues"/>
                        </ul>
                    </xsl:when>
                    <xsl:otherwise>
                        <p><xsl:sequence select="$capNoneFound"/></p>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>This template checks the list of settlements to report any that are not located in any county.</xd:desc>
    </xd:doc>
    <xsl:template name="citiesInNoCounty" match="xsl:template[@name='citiesInNoCounty']">
        <xsl:message>Checking for settlements not located in any county.</xsl:message>
        
        <xsl:variable name="issues" as="element(xh:li)*">
            <xsl:for-each select="map:keys($mapCityNamesToCountyKeys)">
                <xsl:variable name="cityName" select="."/>
                <xsl:variable name="countyKeys" as="xs:string*" select="map:get($mapCityNamesToCountyKeys, $cityName)"/>
                <xsl:if test="count($countyKeys) lt 1 or (count($countyKeys) lt 2 and $countyKeys[1] eq '?')">
                    <li>The town or city <strong>{$cityName}</strong> is not associated with any counties at all.</li>
                </xsl:if>
            </xsl:for-each>
        </xsl:variable>
        <xsl:variable name="sortedIssues" as="element(xh:li)*">
            <xsl:for-each select="$issues">
                <xsl:sort select="normalize-space(lower-case(.))"/>
                <xsl:sequence select="."/>
            </xsl:for-each>
        </xsl:variable>
        <xsl:call-template name="createDetails">
            <xsl:with-param name="id" select="'citiesInNoCounty'"/>
            <xsl:with-param name="count" select="count($sortedIssues)"/>
            <xsl:with-param name="title" select="'Towns/cities which are not associated with any county'"/>
            <xsl:with-param name="explanation" as="item()*">
                A town, city, or or other settlement would normally appear in one or perhaps more counties; however, some towns or cities have been assigned as the location of traders, but without an associated county.
            </xsl:with-param>
            <xsl:with-param name="content">
                <xsl:choose>
                    <xsl:when test="count($sortedIssues) gt 0">
                        <ul>
                            <xsl:sequence select="$sortedIssues"/>
                        </ul>
                    </xsl:when>
                    <xsl:otherwise>
                        <p><xsl:sequence select="$capNoneFound"/></p>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>This template creates the output for a single diagnostic in a standardized way.</xd:desc>
        <xd:param name="id" as="xs:string">The id of the div to be created; also the id of the diagnostic template itself.</xd:param>
        <xd:param name="count" as="xs:integer">The number of problems found.</xd:param>
        <xd:param name="title" as="xs:string">The title/caption for the diagnostic.</xd:param>
        <xd:param name="explanation" as="item()*">An explanation of the diagnostic.</xd:param>
        <xd:param name="content" as="item()*">Any items found, or perhaps a paragraph with "None found".</xd:param>
    </xd:doc>
    <xsl:template name="createDetails" as="element(xh:div)">
        <xsl:param name="id" as="xs:string"/>
        <xsl:param name="count" as="xs:integer"/>
        <xsl:param name="title" as="xs:string"/>
        <xsl:param name="explanation" as="item()*"/>
        <xsl:param name="content" as="item()*"/>
        <div id="{$id}">
            <details>
                <summary class="{if ($count gt 0) then 'todo' else 'complete'}">
                    <xsl:sequence select="$title || ' (' || $count || ')'"/>
                </summary>
                <div class="explanation">
                    <h4>Explanation</h4>
                    <xsl:sequence select="$explanation"/>
                    <p>To run this diagnostic on its own, use:<br/>
                        <code>ant diagnostics -DrunOnly=<xsl:sequence select="$id"/></code></p>
                </div>
                <xsl:sequence select="$content"/>
            </details>
        </div>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>This template generates statistics for the XML collection as a whole.</xd:desc>
    </xd:doc>
    <xsl:template name="statistics" as="element(xh:div)">
        <xsl:message>Calculating statistics...</xsl:message>
        <div id="statistics">
            <details>
                <summary>Statistics <xsl:value-of select="format-date(current-date(), '[D1o] [MNn] [Y0001]')"/></summary>
                <table class="statistics">
                    <tbody>
                        
                        <tr>
                            <td>Trader records</td>
                            <td><xsl:sequence select="count($teiSource//org)"/></td>
                        </tr>
                        
                        <tr>
                            <td>Items in source listing</td>
                            <td><xsl:sequence select="count($teiSource//listBibl[@xml:id='sourceshtml']/bibl)"/></td>
                        </tr>
                        
                        <tr>
                            <td>Items in Feather bibliography</td>
                            <td><xsl:sequence select="count($teiSource//listBibl[@xml:id='feather']/bibl)"/></td>
                        </tr>
                        
                        <tr>
                            <td>Items in abbreviation listing</td>
                            <td><xsl:sequence select="count($teiSource//list[@type='abbreviations']/item)"/></td>
                        </tr>
                        
                        <tr>
                            <td>Counties identified</td>
                            <td><xsl:sequence select="count($teiSource//listPlace[@xml:id='counties']/place) - 1"/></td>
                        </tr>
                        
                        <tr>
                            <td>Distinct cities/towns</td>
                            <td><xsl:sequence select="count(distinct-values(($teiSource//settlement)))"/></td>
                        </tr>
                        
                        <tr>
                            <td>Trader records linked to <code>GEN</code> 
                                <q>(Unknown)</q> source</td>
                            <td><xsl:sequence select="count($teiSource//org[descendant::bibl[@type='source' and @corresp='src:srch_GEN']])"/></td>
                        </tr>
                        
                    </tbody>
                </table>
                
                <details>
                    <summary>Mapping of counties to settlements</summary>
                    This is a list of all the counties which appear, along with the cities/towns/settlements
                    inside them, as claimed by the dataset. This should be useful to detect erroneous location 
                    assignments.
                    <xsl:variable name="counties" as="element(xh:li)+">
                        <xsl:for-each select="map:keys($mapCountyKeysToCityNames)">
                            <xsl:sort select="lower-case(.)"/>
                            <li><xsl:sequence select="map:get($mapCountyKeysToStrings, .)"/>
                                <xsl:where-populated>
                                    <ul>
                                        <xsl:for-each select="map:get($mapCountyKeysToCityNames, .)">
                                            <xsl:sort select="lower-case(.)"/>
                                            <li><xsl:sequence select="."/></li>
                                        </xsl:for-each>
                                    </ul>
                                </xsl:where-populated>
                            </li>
                        </xsl:for-each>
                    </xsl:variable>
                    
                    <ul>
                        <xsl:sequence select="$counties"/>
                    </ul>
                    
                </details>
                
            </details>
        </div>
    </xsl:template>
    
</xsl:stylesheet>