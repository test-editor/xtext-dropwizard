package org.testeditor.web.xtext.index.changes

import com.google.inject.Guice
import com.google.inject.name.Names
import java.io.File
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.jgit.diff.DiffEntry
import org.eclipse.jgit.diff.DiffEntry.ChangeType
import org.eclipse.jgit.lib.ObjectId
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.mockito.Answers
import org.mockito.InjectMocks
import org.mockito.Mock
import org.mockito.junit.MockitoJUnit
import org.mockito.junit.MockitoRule
import org.testeditor.web.xtext.index.persistence.GitService

import static org.assertj.core.api.Assertions.assertThat
import static org.eclipse.jgit.diff.DiffEntry.ChangeType.*
import static org.mockito.ArgumentMatchers.*

import static extension org.eclipse.emf.common.util.URI.createFileURI
import static extension org.mockito.AdditionalMatchers.*
import static extension org.mockito.Mockito.*

class GitBasedChangeDetectorTest {

	@Rule public MockitoRule mockitoRule = MockitoJUnit.rule

	@Mock(answer=Answers.RETURNS_SMART_NULLS) GitService mockGit
	@Mock IndexFilter mockFilter
	@Mock ResourceSet mockResourceSet
	@InjectMocks GitBasedChangeDetector unitUnderTest

	val root = new File('rootDir')
	val headOnInitialUpdate = ObjectId.fromString('cafec0fefec0fefec0fefec0fefec0fefec0fefe')
	val headOnSubsequentUpdate = ObjectId.fromString('deadbeefdeadbeefdeadbeefdeadbeefdeadbeef')

	@Before
	def void setupMocks() {
		when(mockGit.headTree).thenReturn(headOnInitialUpdate)
		when(mockGit.projectFolder).thenReturn(root)
		when(mockFilter.isRelevantForIndex(isNull.or(not(endsWith('.mydsl'))))).thenReturn(false)
		when(mockFilter.isRelevantForIndex(isNotNull.and(endsWith('.mydsl')))).thenReturn(true)
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
		val actualChanges = unitUnderTest.detectChanges(mockResourceSet, #[root.absolutePath])

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
		when(mockGit.calculateDiff(headOnInitialUpdate.name(), headOnSubsequentUpdate.name())).thenReturn(diffs)

		unitUnderTest.detectChanges(mockResourceSet, #[root.absolutePath])

		doAnswer[
			when(mockGit.headTree).thenReturn(headOnSubsequentUpdate)
		].when(mockGit).pull

		// when
		val actualChanges = unitUnderTest.detectChanges(mockResourceSet, #[root.absolutePath])

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
		val actualChanges = unitUnderTest.detectChanges(mockResourceSet, #[root.absolutePath])

		// then
		assertThat(actualChanges.modifiedResources).isEmpty
	}

//
	@Test
	def void handlesRenamingCorrectlyIfOnlyOnePathIsRelevant() {
		// given
		when(mockGit.allFilesAsDiff(headOnInitialUpdate.name())).thenReturn(#[
			mockDiffEntry(RENAME, 'nowRelevant.mydsl', 'example.txt'),
			mockDiffEntry(RENAME, 'nowIrrelevant.txt', 'formerlyRelevant.mydsl')
		])

		// when
		val actualChanges = unitUnderTest.detectChanges(mockResourceSet, #[root.absolutePath])

		// then
		assertThat(actualChanges.modifiedResources).containsOnly(toAbsoluteFileUri(root, 'nowRelevant.mydsl'))
		assertThat(actualChanges.deletedResources).containsOnly(toAbsoluteFileUri(root, 'formerlyRelevant.mydsl'))
	}

	@Test
	def void returnsSuccessorIfProvided() {
		// given
		val expectedSuccessor = mock(ChainableChangeDetector)
		val injector = Guice.createInjector [
			bind(GitService).toInstance(mock(GitService))
			bind(IndexFilter).toInstance(mock(IndexFilter))
			bind(ResourceSet).toInstance(mock(ResourceSet))
			bind(ChainableChangeDetector).annotatedWith(Names.named(GitBasedChangeDetector.SUCCESSOR_NAME)).toInstance(expectedSuccessor)
		]

		// when
		val unitUnderTest = injector.getInstance(GitBasedChangeDetector)
		val actualSuccessor = unitUnderTest.successor

		// then
		assertThat(actualSuccessor).isSameAs(expectedSuccessor)
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
