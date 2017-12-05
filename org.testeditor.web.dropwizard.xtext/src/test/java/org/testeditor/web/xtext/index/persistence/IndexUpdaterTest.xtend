package org.testeditor.web.xtext.index.persistence

import java.io.File
import org.eclipse.emf.common.util.URI
import org.eclipse.jgit.diff.DiffEntry
import org.eclipse.jgit.diff.DiffEntry.ChangeType
import org.junit.Test
import org.mockito.InjectMocks
import org.mockito.Mock
import org.testeditor.web.xtext.index.AbstractTestWithExampleLanguage
import org.testeditor.web.xtext.index.XtextIndex

import static org.eclipse.jgit.diff.DiffEntry.ChangeType.*

import static extension org.eclipse.emf.common.util.URI.createFileURI
import static extension org.mockito.Mockito.*

class IndexUpdaterTest extends AbstractTestWithExampleLanguage {

	@InjectMocks IndexUpdater indexUpdater
	@Mock XtextIndex index

	@Test
	def void testIsRelevantForIndex() {
		// given
		val testData = #[
			'test.mydsl' -> true,
			'test.MYDSL' -> true,
			'test.mydsl.txt' -> false,
			'test.xml' -> false,
			null -> false,
			'' -> false
		]

		for (entry : testData) {
			// when
			val isRelevant = indexUpdater.isRelevantForIndex(entry.key)

			// then
			isRelevant.assertEquals(entry.value)
		}
	}

	@Test
	def void shouldSkipGitDirectory() {
		// given
		val folder = new File('.git')

		// when + then
		indexUpdater.shouldSkipDirectory(folder).assertTrue
	}

	@Test
	def void updatesIndexCorrectlyForSomeDiffs() {
		// given
		val diffs = #[
			mockDiffEntry(ADD, 'added.mydsl', null),
			mockDiffEntry(COPY, 'theNewCopy.mydsl', 'theOldCopy.mydsl'),
			mockDiffEntry(DELETE, null, 'theDeleted.mydsl'),
			mockDiffEntry(MODIFY, null, 'theModified.mydsl'),
			mockDiffEntry(RENAME, 'theRenamed.mydsl', 'theOldRenamed.mydsl'),
			mockDiffEntry(ADD, 'theIrrelevant', null)
		]
		val root = new File('some/root')

		// when
		indexUpdater.updateIndex(root, diffs)

		// then
		inOrder(index) => [
			verify(index).add(toAbsoluteFileUri(root, 'added.mydsl'))
			verify(index).add(toAbsoluteFileUri(root, 'theNewCopy.mydsl'))
			verify(index).remove(toAbsoluteFileUri(root, 'theDeleted.mydsl'))
			verify(index).update(toAbsoluteFileUri(root, 'theModified.mydsl'))
			verify(index).remove(toAbsoluteFileUri(root, 'theOldRenamed.mydsl'))
			verify(index).add(toAbsoluteFileUri(root, 'theRenamed.mydsl'))
		]
		verifyNoMoreInteractions(index)
	}
	
	private def URI toAbsoluteFileUri(File root, String relative) {
		return (new File(root, relative)).absolutePath.createFileURI
	}

	private def DiffEntry mockDiffEntry(ChangeType type, String newPath, String oldPath) {
		val entry = DiffEntry.mock
		when(entry.changeType).thenReturn(type)
		when(entry.newPath).thenReturn(newPath)
		when(entry.oldPath).thenReturn(oldPath)
		return entry
	}

}
