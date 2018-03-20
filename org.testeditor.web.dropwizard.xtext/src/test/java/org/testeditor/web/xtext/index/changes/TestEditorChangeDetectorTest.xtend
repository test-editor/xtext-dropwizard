package org.testeditor.web.xtext.index.changes

import com.google.inject.Module
import java.io.File
import java.util.List
import javax.inject.Inject
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.jgit.diff.DiffEntry
import org.eclipse.jgit.diff.DiffEntry.ChangeType
import org.eclipse.jgit.lib.ObjectId
import org.junit.Before
import org.junit.Test
import org.mockito.Mock
import org.testeditor.web.dropwizard.xtext.XtextConfiguration
import org.testeditor.web.xtext.index.AbstractTestWithExampleLanguage
import org.testeditor.web.xtext.index.ChangedResources
import org.testeditor.web.xtext.index.LanguageAccessRegistry
import org.testeditor.web.xtext.index.persistence.GitService

import static org.assertj.core.api.Assertions.assertThat
import static org.eclipse.jgit.diff.DiffEntry.ChangeType.*

import static extension org.eclipse.emf.common.util.URI.createFileURI
import static extension org.mockito.Mockito.*

class TestEditorChangeDetectorTest extends AbstractTestWithExampleLanguage {

	@Inject TestEditorChangeDetector changeDetectorUnderTest

	val root = new File('rootDir')
	val headOnInitialUpdate = ObjectId.fromString('cafec0fefec0fefec0fefec0fefec0fefec0fefe')
	val headOnSubsequentUpdate = ObjectId.fromString('deadbeefdeadbeefdeadbeefdeadbeefdeadbeef')

	@Mock GitService mockGit
	@Mock XtextConfiguration config
	@Mock ResourceSet mockResourceSet
	@Mock LanguageAccessRegistry mockLanguages

	override protected collectModules(List<Module> modules) {
		super.collectModules(modules)
		modules += [ binder |
			binder.install(new IndexFilterModule)
			binder.bind(GitService).toInstance(mockGit)
			binder.bind(XtextConfiguration).toInstance(config)
			binder.bind(LanguageAccessRegistry).toInstance(mockLanguages)
		]
	}

	@Before
	def void setupMocks() {
		when(mockGit.headTree).thenReturn(headOnInitialUpdate)
		when(mockGit.projectFolder).thenReturn(root)
		when(config.localRepoFileRoot).thenReturn(root.absolutePath)
		when(config.indexSearchPaths).thenReturn(#[''])
		when(mockLanguages.extensions).thenReturn(#['mydsl'])
	}

	@Test
	def void handlesDiffCorrectlyOnFirstChangeDetection() {
		// given
		val diffs = #[
			mockDiffEntry(ADD, 'added.mydsl', null),
			mockDiffEntry(COPY, 'theNewCopy.mydsl', 'theOldCopy.mydsl'),
			mockDiffEntry(DELETE, null, 'theDeleted.mydsl'),
			mockDiffEntry(MODIFY, 'theModified.mydsl', 'theModified.mydsl'),
			mockDiffEntry(RENAME, 'theRenamed.mydsl', 'theOldRenamed.mydsl'),
			mockDiffEntry(ADD, 'theIrrelevant', null)
		]

		when(mockGit.allFilesAsDiff(headOnInitialUpdate.name())).thenReturn(diffs)

		// when
		val actualChanges = changeDetectorUnderTest.detectChanges(mockResourceSet, #[root.absolutePath], new ChangedResources)

		// then
		assertThat(actualChanges.modifiedResources).containsOnly(
			toAbsoluteFileUri(root, 'added.mydsl'),
			toAbsoluteFileUri(root, 'theNewCopy.mydsl'),
			toAbsoluteFileUri(root, 'theModified.mydsl'),
			toAbsoluteFileUri(root, 'theRenamed.mydsl')
		)
		assertThat(actualChanges.deletedResources).containsOnly(
			toAbsoluteFileUri(root, 'theOldRenamed.mydsl'),
			toAbsoluteFileUri(root, 'theDeleted.mydsl')
		)
	}

	@Test
	def void handlesDiffCorrectlyAfterFirstChangeDetection() {
		// given
		val diffs = #[
			mockDiffEntry(ADD, 'added.mydsl', null),
			mockDiffEntry(COPY, 'theNewCopy.mydsl', 'theOldCopy.mydsl'),
			mockDiffEntry(DELETE, null, 'theDeleted.mydsl'),
			mockDiffEntry(MODIFY, 'theModified.mydsl', 'theModified.mydsl'),
			mockDiffEntry(RENAME, 'theRenamed.mydsl', 'theOldRenamed.mydsl'),
			mockDiffEntry(ADD, 'theIrrelevant', null)
		]

		when(mockGit.allFilesAsDiff(headOnInitialUpdate.name())).thenReturn(diffs)

		changeDetectorUnderTest.detectChanges(mockResourceSet, #[root.absolutePath], new ChangedResources)

		doAnswer[
			when(mockGit.headTree).thenReturn(headOnSubsequentUpdate)
		].when(mockGit).pull
		when(mockGit.calculateDiff(headOnInitialUpdate.name(), headOnSubsequentUpdate.name())).thenReturn(diffs)

		// when
		val actualChanges = changeDetectorUnderTest.detectChanges(mockResourceSet, #[root.absolutePath], new ChangedResources)

		// then
		assertThat(actualChanges.modifiedResources).containsOnly(
			toAbsoluteFileUri(root, 'added.mydsl'),
			toAbsoluteFileUri(root, 'theNewCopy.mydsl'),
			toAbsoluteFileUri(root, 'theModified.mydsl'),
			toAbsoluteFileUri(root, 'theRenamed.mydsl')
		)
		assertThat(actualChanges.deletedResources).containsOnly(
			toAbsoluteFileUri(root, 'theOldRenamed.mydsl'),
			toAbsoluteFileUri(root, 'theDeleted.mydsl')
		)
	}

	@Test
	def void ignoresCopyUpdateIfNewPathIsNotRelevant() {
		// given
		when(mockGit.allFilesAsDiff(headOnInitialUpdate.name())).thenReturn(#[
			mockDiffEntry(COPY, 'irrelevant.txt', 'theNewCopy.mydsl')
		])

		// when
		val actualChanges = changeDetectorUnderTest.detectChanges(mockResourceSet, #[root.absolutePath], new ChangedResources)

		// then
		assertThat(actualChanges.modifiedResources).isEmpty
	}

	@Test
	def void handlesRenamingCorrectlyIfOnlyOnePathIsRelevant() {
		// given
		when(mockGit.allFilesAsDiff(headOnInitialUpdate.name())).thenReturn(#[
			mockDiffEntry(RENAME, 'nowRelevant.mydsl', 'example.txt'),
			mockDiffEntry(RENAME, 'nowIrrelevant.txt', 'formerlyRelevant.mydsl')
		])

		// when
		val actualChanges = changeDetectorUnderTest.detectChanges(mockResourceSet, #[root.absolutePath], new ChangedResources)

		// then
		assertThat(actualChanges.modifiedResources).containsOnly(toAbsoluteFileUri(root, 'nowRelevant.mydsl'))
		assertThat(actualChanges.deletedResources).containsOnly(toAbsoluteFileUri(root, 'formerlyRelevant.mydsl'))
	}

	private def DiffEntry mockDiffEntry(ChangeType type, String newPath, String oldPath) {
		val entry = DiffEntry.mock
		when(entry.changeType).thenReturn(type)
		when(entry.newPath).thenReturn(newPath)
		when(entry.oldPath).thenReturn(oldPath)
		return entry
	}

	private def URI toAbsoluteFileUri(File root, String relative) {
		return (new File(root, relative)).absolutePath.createFileURI
	}

}
