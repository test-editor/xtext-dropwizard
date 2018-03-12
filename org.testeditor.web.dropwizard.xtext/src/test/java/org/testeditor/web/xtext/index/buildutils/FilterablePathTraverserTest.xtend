package org.testeditor.web.xtext.index.buildutils

import java.io.FileFilter
import java.io.FileOutputStream
import java.util.jar.JarEntry
import java.util.jar.JarOutputStream
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

import static org.assertj.core.api.Assertions.assertThat
import static org.eclipse.emf.common.util.URI.*

class FilterablePathTraverserTest {

	@Rule public TemporaryFolder tmpDir = new TemporaryFolder

	@Test
	def void skipsFilesAndFoldersAccordingToFilterRule() {
		// given
		tmpDir.newFile('do.not.skipME')
		tmpDir.newFile('you-should-skip-me')
		tmpDir.newFolder('include')
		tmpDir.newFile('include/me')
		tmpDir.newFolder('you', 'must', 'skip-me')
		tmpDir.newFile('you/must/skip-me/and-not-even-consider-me')

		val FileFilter filter = [!absolutePath.contains('skip-me')]
		val unitUnderTest = new FilterablePathTraverser(filter)

		// when
		val actual = unitUnderTest.resolvePathes(#[tmpDir.root.absolutePath], [true])

		// then
		tmpDir.root => [
			assertThat(actual.values).containsOnly(
				createFileURI(absolutePath + '/do.not.skipME'),
				createFileURI(absolutePath + '/include/me')
			)
		]
	}

	@Test
	def void filteringDoesNotAffectArchives() {
		// given
		val folderPath = tmpDir.newFolder('folder').absolutePath
		val archivePath = tmpDir.root.absolutePath + '/archive.jar'
		
		tmpDir.newFile('folder/do.not.skipME')
		tmpDir.newFile('folder/you-should-skip-me')
		
		new JarOutputStream(new FileOutputStream(archivePath)) => [
			putNextEntry(new JarEntry('you-must-not-skip-me'))
			putNextEntry(new JarEntry('youMustInclude.me'))
			close
		]

		val FileFilter filter = [!absolutePath.contains('skip-me')]
		val unitUnderTest = new FilterablePathTraverser(filter)

		// when
		val actual = unitUnderTest.resolvePathes(#[folderPath, archivePath], [true])
		
		// then
		tmpDir.root => [
			assertThat(actual.values).containsOnly(
				createFileURI(folderPath + '/do.not.skipME'),
				createURI('archive:' + createFileURI(archivePath) + '!/you-must-not-skip-me'),
				createURI('archive:' + createFileURI(archivePath) + '!/youMustInclude.me')
			)
		]
	}

}
