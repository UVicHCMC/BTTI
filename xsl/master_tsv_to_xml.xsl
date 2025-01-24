<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:map="http://www.w3.org/2005/xpath-functions/map"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    exclude-result-prefixes="#all"
    xpath-default-namespace=""
    xmlns="http://hcmc.uvic.ca/ns"
    xmlns:hcmc="http://hcmc.uvic.ca/ns"
    expand-text="yes"
    version="3.0">
    <xd:doc>
        <xd:desc>
            <xd:p>
                This process will:
                <xd:ul>
                    <xd:li>Load each TSV source file</xd:li>
                    <xd:li>Clean up known problems such as phony 
                    linebreaks (&#x0a; followed by \n)</xd:li>
                    <xd:li>Parse the text into lines</xd:li>
                    <xd:li>Parse each line into a record</xd:li>
                    <xd:li>Output a file containing XML serializations of those records.</xd:li>
                </xd:ul>
                Output XML is a convenient ad-hoc XML representation of the 
                original source records and labels, in the HCMC namespace. Since 
                there are character encoding issues in the source TSV, we also try
                to ameliorate those as part of the process.
            </xd:p>
            <xd:p>
                This file runs on itself and loads its requirements dynamically. The input 
                file is a parameter.
            </xd:p>
        </xd:desc>
        <xd:param name="tsvFile" as="xs:string">The file to process.</xd:param>
    </xd:doc>
    
    <xd:doc>
        <xd:desc>Include the functions.</xd:desc>
    </xd:doc>
    <xsl:include href="module_conversion_functions.xsl"/>
    
    <xsl:output method="xml" indent="yes" encoding="UTF-8" 
        normalization-form="NFC" exclude-result-prefixes="#all"/>
    
    <xsl:param name="tsvFile" as="xs:string"/>
    
    <xsl:variable name="strTsv" as="xs:string" select="unparsed-text($tsvFile, 'UTF-8')"/>
    
    <xd:doc>
        <xd:desc>The default template does all the work.</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <xsl:message>Processing {$tsvFile}...</xsl:message>
        <xsl:message>File length is {string-length($strTsv)}.</xsl:message>
        <!-- First, we get the header row labels for our cells. -->
        <xsl:variable name="rows" as="xs:string+" select="tokenize($strTsv, '&#x0a;')"/>
        <xsl:message>File has {count($rows)} rows in it.</xsl:message>
        <xsl:variable name="headings" as="xs:string+" select="tokenize($rows[1], '&#09;')"/>
        <xsl:message>File has {count($headings)} columns in it.</xsl:message>
        <xsl:variable name="outputFile" as="xs:string" select="replace(replace($tsvFile, '/sources/', '/tempXml/'), '\.tsv$', '.xml')"/>
        <xsl:message>Creating output file at {$outputFile}.</xsl:message>
        <xsl:result-document href="{$outputFile}">
            <table name="{substring-before(tokenize($tsvFile, '/')[last()], '.')}">
                <head>
                    <xsl:for-each select="$headings">
                        <label><xsl:sequence select="."/></label>
                    </xsl:for-each>
                </head>
                <body>
                    <xsl:for-each select="$rows[position() gt 1][string-length(normalize-space(.)) gt 0]">
                        <row>
                            <xsl:for-each select="tokenize(., '&#09;')">
                                <cell><xsl:sequence select="hcmc:fixEncoding(.)"/></cell>
                            </xsl:for-each>
                        </row>
                    </xsl:for-each>
                </body>
            </table>
        </xsl:result-document>
    </xsl:template>
    
</xsl:stylesheet>