package org.testeditor.web.xtext.index.changes

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
import org.testeditor.web.xtext.index.ChangedResources
import org.testeditor.web.xtext.index.persistence.GitService

import static org.assertj.core.api.Assertions.assertThat
import static org.eclipse.jgit.diff.DiffEntry.ChangeType.*

import static extension org.eclipse.emf.common.util.URI.createFileURI
import static extension org.mockito.Mockito.*

class GitBasedChangeDetectorTest {

	@Rule public MockitoRule mockitoRule = MockitoJUnit.rule

	@Mock(answer=Answers.RETURNS_SMART_NULLS) GitService mockGit
	@Mock ResourceSet mockResourceSet
	@InjectMocks GitBasedChangeDetector unitUnderTest

	val root = new File('rootDir')
	val headOnInitialUpdate = ObjectId.fromString('cafec0fefec0fefec0fefec0fefec0fefec0fefe')
	val headOnSubsequentUpdate = ObjectId.fromString('deadbeefdeadbeefdeadbeefdeadbeefdeadbeef')

	@Before
	def void setupMocks() {
		when(mockGit.headTree).thenReturn(headOnInitialUpdate)
		when(mockGit.projectFolder).thenReturn(root)
	}
	
	@Test
	def void getFullListWithAbsoluteFileUriIfRequested() {
		// given
		val fileList = #['some.txt', 'src/other.md']
		when(mockGit.listAllCommittedFiles).thenReturn(fileList)
		
		// when
		val actualChanges = unitUnderTest.collectFull(mockResourceSet, #[root.absolutePath], new ChangedResources)
		
		// then
		assertThat(actualChanges.modifiedResources).containsOnly(
			toAbsoluteFileUri(root, 'some.txt'),
			toAbsoluteFileUri(root, 'src/other.md')
		)
	}

	@Test
	def void handlesDiffCorrectlyOnFirstChangeDetection() {
		// given
		val diffs = #[
			mockDiffEntry(ADD, 'added.txt', null),
			mockDiffEntry(COPY, 'theNewCopy.txt', 'theOldCopy.txt'),
			mockDiffEntry(DELETE, null, 'theDeleted.txt'),
			mockDiffEntry(MODIFY, 'theModified.txt', 'theModified.txt'),
			mockDiffEntry(RENAME, 'theRenamed.txt', 'theOldRenamed.txt')
		]

		when(mockGit.allFilesAsDiff(headOnInitialUpdate.name())).thenReturn(diffs)

		// when
		val actualChanges = unitUnderTest.detectChanges(mockResourceSet, #[root.absolutePath], new ChangedResources)

		// then
		assertThat(actualChanges.modifiedResources).containsOnly(
			toAbsoluteFileUri(root, 'added.txt'),
			toAbsoluteFileUri(root, 'theNewCopy.txt'),
			toAbsoluteFileUri(root, 'theModified.txt'),
			toAbsoluteFileUri(root, 'theRenamed.txt')
		)
		assertThat(actualChanges.deletedResources).containsOnly(
			toAbsoluteFileUri(root, 'theOldRenamed.txt'),
			toAbsoluteFileUri(root, 'theDeleted.txt')
		)
	}

	@Test
	def void handlesDiffCorrectlyAfterFirstChangeDetection() {
		// given
		val diffs = #[
			mockDiffEntry(ADD, 'added.txt', null),
			mockDiffEntry(COPY, 'theNewCopy.txt', 'theOldCopy.txt'),
			mockDiffEntry(DELETE, null, 'theDeleted.txt'),
			mockDiffEntry(MODIFY, 'theModified.txt', 'theModified.txt'),
			mockDiffEntry(RENAME, 'theRenamed.txt', 'theOldRenamed.txt')
		]

		when(mockGit.allFilesAsDiff(headOnInitialUpdate.name())).thenReturn(diffs)

		unitUnderTest.detectChanges(mockResourceSet, #[root.absolutePath], new ChangedResources)

		when(mockGit.calculateDiff(headOnInitialUpdate.name(), headOnSubsequentUpdate.name())).thenReturn(diffs)

		doAnswer[
			when(mockGit.headTree).thenReturn(headOnSubsequentUpdate)
		].when(mockGit).pull

		// when
		val actualChanges = unitUnderTest.detectChanges(mockResourceSet, #[root.absolutePath], new ChangedResources)

		// then
		assertThat(actualChanges.modifiedResources).containsOnly(
			toAbsoluteFileUri(root, 'added.txt'),
			toAbsoluteFileUri(root, 'theNewCopy.txt'),
			toAbsoluteFileUri(root, 'theModified.txt'),
			toAbsoluteFileUri(root, 'theRenamed.txt')
		)
		assertThat(actualChanges.deletedResources).containsOnly(
			toAbsoluteFileUri(root, 'theOldRenamed.txt'),
			toAbsoluteFileUri(root, 'theDeleted.txt')
		)
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
