package org.testeditor.web.xtext.index.changes

import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder
import org.mockito.InjectMocks
import org.mockito.Mock
import org.mockito.junit.MockitoJUnit
import org.mockito.junit.MockitoRule
import org.testeditor.web.dropwizard.xtext.XtextConfiguration
import org.testeditor.web.xtext.index.ChangedResources
import org.testeditor.web.xtext.index.LanguageAccessRegistry
import org.testeditor.web.xtext.index.buildutils.XtextBuilderUtils

import static java.nio.charset.StandardCharsets.UTF_8
import static org.apache.commons.io.FileUtils.write
import static org.assertj.core.api.Assertions.assertThat
import static org.mockito.ArgumentMatchers.*
import static org.mockito.Mockito.*

import static extension org.eclipse.emf.common.util.URI.createFileURI

class GradleBuildChangeDetectorTest {

	@Rule public MockitoRule mockitoRule = MockitoJUnit.rule
	@Rule public TemporaryFolder tmpDir = new TemporaryFolder

	@Mock XtextConfiguration config
	@Mock XtextBuilderUtils builderUtils
	@Mock LanguageAccessRegistry languages
	@InjectMocks GradleBuildChangeDetector gradleChangeDetectorUnderTest

	static val sampleJarPath1 = '/path/to/gradle/cache/some.jar'
	static val sampleJarPath2 = '/path/to/gradle/cache/some.other.jar'

	static val relevantFileInJar = URI.createURI('archive:' + URI.createFileURI(sampleJarPath1) + '!/relevant/file.in.jar.mydsl');
	static val irrelevantFileInJar = URI.createURI('archive:' + URI.createFileURI(sampleJarPath1) + '!/irrelevant/file.in.jar.txt');

	@Before
	def void setupMocks() {
		when(config.localRepoFileRoot).thenReturn(tmpDir.root.absolutePath)
		when(builderUtils.collectResources(anyIterable, any, any)).thenReturn(#{relevantFileInJar})
		when(languages.extensions).thenReturn(#['mydsl'])
	}

	@Test
	def void doesNothingIfBuildScriptIsUnmodified() {
		// given
		val unrelatedFileURI = URI.createFileURI('not.build.gradle') 
		val previouslyDetectedChanges = new ChangedResources => [
			modifiedResources += unrelatedFileURI
		]

		// when
		val actualChanges = gradleChangeDetectorUnderTest.detectChanges(mock(ResourceSet), #[''], previouslyDetectedChanges)

		// then
		assertThat(actualChanges.modifiedResources).containsOnly(unrelatedFileURI)
		assertThat(actualChanges.deletedResources).isEmpty
	}

	@Test
	def void runsGradleBuildIfScriptWasModified() {
		// given
		val buildScript = tmpDir.newFile('build.gradle')
		val gradleWrapper = tmpDir.newFile('gradlew') => [
			executable = true
		]
		write(gradleWrapper, '''
			#!/bin/sh
			echo "«sampleJarPath1»"
			echo "  «sampleJarPath2»	"
			echo "/this/is/not/aJarFile"
			echo "this/is/not/an/absolute/path.jar"
		''', UTF_8)

		val previouslyDetectedChanges = new ChangedResources => [
			modifiedResources += buildScript.absolutePath.createFileURI
		]

		// when
		val actualChanges = gradleChangeDetectorUnderTest.detectChanges(mock(ResourceSet), #[], previouslyDetectedChanges)

		// then
		assertThat(actualChanges.modifiedResources).containsOnly(
			relevantFileInJar,
			buildScript.absolutePath.createFileURI
		)
		assertThat(actualChanges.deletedResources).isEmpty
	}

}
