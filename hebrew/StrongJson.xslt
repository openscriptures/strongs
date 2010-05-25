<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
				xmlns:osis="http://www.bibletechnologies.net/2003/OSIS/namespace"
				xmlns="http://www.w3.org/1999/xhtml">
	<xsl:output method="text" encoding="UTF-8"/>
	
	<xsl:template match="/">
		<xsl:text>var strongsHebrewDictionary = {</xsl:text>
		<xsl:apply-templates select="osis:osis/osis:osisText/osis:div/osis:div"/>
		<xsl:text>}</xsl:text>
	</xsl:template>
	
	<xsl:template match="osis:div">
		<xsl:apply-templates select="osis:w[@ID]"/>
		<xsl:apply-templates select="osis:note[@type='exegesis']"/>
		<xsl:apply-templates select="osis:note[@type='explanation']"/>
		<xsl:apply-templates select="osis:note[@type='translation']"/>
		<xsl:apply-templates select="osis:foreign"/>
		<xsl:apply-templates select="osis:list"/>
		<xsl:text>}</xsl:text>
		<xsl:if test="position()!=last()">
			<xsl:text>,
</xsl:text>
		</xsl:if>
	</xsl:template>
	
	<xsl:template match="osis:w[@lemma]">
		<xsl:value-of select="@lemma"/>
	</xsl:template>
	
	<xsl:template match="osis:w[@ID]">
		<xsl:text>&quot;</xsl:text>
		<xsl:value-of select="@ID"/>
		<xsl:text>&quot;:{&quot;lemma&quot;:&quot;</xsl:text>
		<xsl:value-of select="@lemma"/>
		<xsl:text>&quot;,&quot;xlit&quot;:&quot;</xsl:text>
		<xsl:value-of select="@xlit"/>
		<xsl:text>&quot;,&quot;pron&quot;:&quot;</xsl:text>
		<xsl:value-of select="@POS"/>
		<xsl:text>&quot;</xsl:text>
	</xsl:template>
	
	<xsl:template match="osis:note[@type='exegesis']">
		<xsl:text>,&quot;derivation&quot;:&quot;</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>&quot;</xsl:text>
	</xsl:template>
	
	<xsl:template match="osis:w[@src]">
		<xsl:text>H</xsl:text>
		<xsl:value-of select="@src"/>
		<xsl:text> (</xsl:text>
		<xsl:value-of select="@lemma"/>
		<xsl:text>)</xsl:text>
	</xsl:template>

	<xsl:template match="osis:note[@type='explanation']">
		<xsl:text>,&quot;strongs_def&quot;:&quot;</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>&quot;</xsl:text>
	</xsl:template>
	
	<xsl:template match="osis:hi">
		<xsl:apply-templates/>
	</xsl:template>
	
	<xsl:template match="osis:note[@type='translation']">
		<xsl:text>,&quot;kjv_def&quot;:&quot;</xsl:text>
		<xsl:apply-templates/>
		<xsl:text>&quot;</xsl:text>	
	</xsl:template>
	
	<xsl:template match="osis:foreign">
	</xsl:template>
	
	<xsl:template match="osis:list">
	</xsl:template>
	
	<xsl:template match="osis:item">
	</xsl:template>
	
</xsl:stylesheet>
