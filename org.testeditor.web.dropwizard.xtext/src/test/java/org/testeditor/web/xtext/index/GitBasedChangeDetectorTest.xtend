package org.testeditor.web.xtext.index

import org.eclipse.emf.ecore.resource.ResourceSet
import org.glassfish.hk2.api.IndexedFilter
import org.mockito.InjectMocks
import org.mockito.Mock
import org.testeditor.web.xtext.index.changes.GitBasedChangeDetector
import org.testeditor.web.xtext.index.persistence.GitService

class GitBasedChangeDetectorTest {
	@Mock GitService mockGit
	@Mock IndexedFilter mockFilter
	@Mock ResourceSet mockResourceSet
	@InjectMocks GitBasedChangeDetector unitUnderTest
//
//	@Test
//	def void shouldSkipGitDirectory() {
//		// given
//		val folder = new File('.git')
//
//		// when + then
//		indexUpdater.shouldSkipDirectory(folder).assertTrue
//	}
//
//	@Test
//	def void updatesIndexCorrectlyForSomeDiffs() {
//		// given
//		val diffs = #[
//			mockDiffEntry(ADD, 'added.mydsl', null),
//			mockDiffEntry(COPY, 'theNewCopy.mydsl', 'theOldCopy.mydsl'),
//			mockDiffEntry(DELETE, null, 'theDeleted.mydsl'),
//			mockDiffEntry(MODIFY, null, 'theModified.mydsl'),
//			mockDiffEntry(RENAME, 'theRenamed.mydsl', 'theOldRenamed.mydsl'),
//			mockDiffEntry(ADD, 'theIrrelevant', null)
//		]
//		val root = new File('some/root')
//
//		// when
//		indexUpdater.updateIndex(root, diffs)
//
//		// then
//		inOrder(index) => [
//			verify(index).add(toAbsoluteFileUri(root, 'added.mydsl'))
//			verify(index).add(toAbsoluteFileUri(root, 'theNewCopy.mydsl'))
//			verify(index).remove(toAbsoluteFileUri(root, 'theDeleted.mydsl'))
//			verify(index).update(toAbsoluteFileUri(root, 'theModified.mydsl'))
//			verify(index).remove(toAbsoluteFileUri(root, 'theOldRenamed.mydsl'))
//			verify(index).add(toAbsoluteFileUri(root, 'theRenamed.mydsl'))
//		]
//		verifyNoMoreInteractions(index)
//	}
//
//	@Test
//	def void ignoresCopyUpdateIfNewPathIsNotRelevant() {
//		// given
//		val diffs = #[
//			mockDiffEntry(COPY, 'irrelevant.txt', 'theNewCopy.mydsl')
//		]
//		val root = new File('some/root')
//
//		// when
//		indexUpdater.updateIndex(root, diffs)
//
//		// then
//		verifyZeroInteractions(index)
//	}
//
//	@Test
//	def void handlesRenamingCorrectlyIfOnlyOnePathIsRelevant() {
//		// given
//		val diffs = #[
//			mockDiffEntry(RENAME, 'nowRelevant.mydsl', 'example.txt'),
//			mockDiffEntry(RENAME, 'nowIrrelevant.txt', 'formerlyRelevant.mydsl')
//		]
//		val root = new File('some/root')
//
//		// when
//		indexUpdater.updateIndex(root, diffs)
//
//		// then
//		inOrder(index) => [
//			verify(index).add(toAbsoluteFileUri(root, 'nowRelevant.mydsl'))
//			verify(index).remove(toAbsoluteFileUri(root, 'formerlyRelevant.mydsl'))
//		]
//		verifyNoMoreInteractions(index)
//	}
}